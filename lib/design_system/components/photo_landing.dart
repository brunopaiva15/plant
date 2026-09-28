import 'dart:async';
import 'dart:io';

import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

import '../tokens/motion.dart';
import '../tokens/radius.dart';
import '../tokens/spacing.dart';

/// Une photo choisie dans la galerie qui rejoint sa place.
///
/// Avant, la photo apparaissait d'un coup à sa place, ou en fondu : le
/// sélecteur du système se refermait sur un écran où quelque chose avait
/// changé, sans qu'on voie quoi. La photo qu'on venait de toucher avait
/// disparu avec lui.
///
/// Ici, elle reste devant quand le sélecteur se referme : en grand, au centre
/// de l'écran, dans ses proportions. Puis elle file se ranger — la case d'une
/// bande de vignettes, le cadre du viseur, l'aperçu d'une étape — portée par
/// un ressort, et ses coins prennent en route l'arrondi de l'arrivée. C'est
/// **un seul objet** qui se déplace, jamais deux images qui se croisent en
/// fondu : l'œil suit la photo jusqu'à l'endroit où la retrouver.
///
/// Deux endroits du code, comme un [Hero] :
///
/// - qui reçoit la photo l'annonce, avec [PhotoLanding.expect] : son
///   étiquette et l'image à faire voler. L'image est le fichier entier, pas
///   la vignette — au départ elle occupe presque tout l'écran ;
/// - l'endroit où elle s'affiche porte un [PhotoLanding] de même [tag]. À sa
///   première construction, ou quand son étiquette change, il réclame
///   l'annonce, se cache, et fait venir l'image jusqu'à lui.
///
/// Une annonce que personne ne réclame expire au bout de [patience] : une
/// photo déjà rangée ne s'envole pas plus tard, le jour où son widget se
/// reconstruit. La destination est suivie à chaque image : si elle bouge
/// pendant le vol — une page qui glisse, une bande qui apparaît —, la photo
/// la rattrape. Hors de l'écran, sans image qui se décode, ou avec *réduire
/// les animations*, pas de vol : la photo est simplement à sa place.
class PhotoLanding extends StatefulWidget {
  const PhotoLanding({super.key, required this.tag, required this.child, this.radius = Radii.mediumAll});

  /// L'étiquette de la photo que [child] affiche — son chemin, en général.
  /// `null` : rien à attendre.
  final Object? tag;

  /// Les coins de la photo à son arrivée.
  final BorderRadius radius;

  final Widget child;

  /// Le temps qu'une annonce attend sa destination.
  static const Duration patience = Duration(seconds: 2);

  /// Le temps qu'on laisse à l'image pour se décoder avant de partir sans
  /// elle. Au-delà, elle vole avec les proportions de l'arrivée.
  static const Duration decodeWait = Duration(milliseconds: 250);

  /// La photo en grand, au départ.
  static const BorderRadius departureRadius = Radii.largeAll;

  /// La photo se pose au départ en grandissant de ce rapport à un.
  static const double appearScale = 0.94;

  static final Map<Object, _Arrival> _expected = {};

  /// Annonce qu'une photo arrive, sous l'étiquette [tag], et commence à
  /// décoder [image] : quand sa destination se construira, elle sera prête.
  static void expect(Object tag, ImageProvider image) {
    _forget();
    _expected.remove(tag)?.release();
    _expected[tag] = _Arrival(image);
  }

  /// [expect] pour une photo sur l'appareil, décodée à la largeur d'un
  /// écran : le fichier entier ferait attendre le départ pour rien.
  static void expectFile(Object tag, File file) => expect(tag, ResizeImage(FileImage(file), width: 1200, allowUpscaling: false));

  /// L'annonce faite pour [tag], si elle attend encore. Une annonce ne se
  /// réclame qu'une fois.
  static _Arrival? _claim(Object? tag) {
    _forget();
    return tag == null ? null : _expected.remove(tag);
  }

  /// Oublie les annonces que personne n'est venu chercher.
  static void _forget() {
    final now = DateTime.now();
    _expected.removeWhere((_, a) {
      final stale = now.difference(a.at) > patience;
      if (stale) a.release();
      return stale;
    });
  }

  /// Les annonces en attente. Pour les tests.
  @visibleForTesting
  static int get pending => _expected.length;

  @visibleForTesting
  static void reset() {
    for (final a in _expected.values) {
      a.release();
    }
    _expected.clear();
  }

  @override
  State<PhotoLanding> createState() => _PhotoLandingState();
}

/// Une photo annoncée : son image, qui se décode déjà, et sa taille dès
/// qu'on la connaît.
class _Arrival {
  _Arrival(this.image) : at = DateTime.now() {
    _stream = image.resolve(ImageConfiguration.empty);
    _listener = ImageStreamListener(
      (info, _) {
        size ??= Size(info.image.width.toDouble(), info.image.height.toDouble());
        info.dispose();
        if (!_ready.isCompleted) _ready.complete();
      },
      onError: (_, _) {
        if (!_ready.isCompleted) _ready.complete();
      },
    );
    // L'écoute garde l'image décodée dans le cache jusqu'à l'atterrissage.
    _stream.addListener(_listener);
  }

  final ImageProvider image;
  final DateTime at;
  late final ImageStream _stream;
  late final ImageStreamListener _listener;
  final _ready = Completer<void>();

  /// Largeur et hauteur de l'image, une fois décodée.
  Size? size;

  Future<void> get ready => _ready.future;

  void release() => _stream.removeListener(_listener);
}

class _PhotoLandingState extends State<PhotoLanding> with TickerProviderStateMixin {
  late final AnimationController _appear = AnimationController(vsync: this, duration: Motion.micro);
  late final AnimationController _travel = AnimationController.unbounded(vsync: this);

  /// La photo attendue : tant qu'elle est là, [PhotoLanding.child] est caché.
  _Arrival? _arrival;
  OverlayEntry? _entry;
  RenderBox? _overlayBox;
  Timer? _wait;
  Rect? _lastTarget;
  bool _received = false;
  bool _gone = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_received) return;
    _received = true;
    _receive();
  }

  @override
  void didUpdateWidget(PhotoLanding oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Une autre photo à la même place — l'emplacement qui change d'image.
    // Un vol en cours, lui, va au bout.
    if (widget.tag != oldWidget.tag && _arrival == null) _receive();
  }

  void _receive() {
    final arrival = PhotoLanding._claim(widget.tag);
    if (arrival == null) return;
    // Le réglage se lit ici, et pas au départ du vol : c'est le moment où
    // l'élément a encore accès à son `MediaQuery`.
    if (MediaQuery.disableAnimationsOf(context) || !TickerMode.valuesOf(context).enabled) {
      arrival.release();
      return;
    }
    _arrival = arrival;
    _wait = Timer(PhotoLanding.decodeWait, _launch);
    arrival.ready.then((_) => _launch());
  }

  /// Le départ : dès que l'image est décodée, ou au bout de
  /// [PhotoLanding.decodeWait].
  void _launch() {
    _wait?.cancel();
    _wait = null;
    final arrival = _arrival;
    if (_gone || _entry != null || arrival == null) return;
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    final bounds = overlay?.context.findRenderObject();
    if (overlay == null || bounds is! RenderBox || !bounds.hasSize) return _land();
    _overlayBox = bounds;
    final to = _target();
    if (to == null) return _land();
    final screen = Offset.zero & bounds.size;
    // Une destination hors de l'écran : la photo n'irait nulle part où l'œil
    // puisse la suivre.
    if (!screen.overlaps(to)) return _land();
    final from = _departure(screen, MediaQuery.paddingOf(overlay.context), to, arrival.size);
    _entry = OverlayEntry(
      builder: (_) => IgnorePointer(
        child: _Flight(
          appear: _appear,
          travel: _travel,
          image: arrival.image,
          from: from,
          to: () => _target() ?? _lastTarget ?? to,
          fromRadius: PhotoLanding.departureRadius,
          toRadius: widget.radius,
        ),
      ),
    );
    overlay.insert(_entry!);
    _appear.forward().whenCompleteOrCancel(() {
      if (_gone) return;
      _travel.animateWith(SpringSimulation(Springs.glide, 0, 1, 0)).whenCompleteOrCancel(() {
        if (!_gone) _land();
      });
    });
  }

  /// Où la photo se pose, dans le repère de l'overlay racine.
  Rect? _target() {
    final overlay = _overlayBox;
    if (_gone || overlay == null || !overlay.attached) return null;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    return _lastTarget = MatrixUtils.transformRect(box.getTransformTo(overlay), Offset.zero & box.size);
  }

  /// La photo en grand : ses proportions à elle, au centre de l'écran, dans
  /// les marges de la page.
  static Rect _departure(Rect screen, EdgeInsets padding, Rect to, Size? size) {
    final area = EdgeInsets.fromLTRB(Space.page, padding.top + Space.huge, Space.page, padding.bottom + Space.huge).deflateRect(screen);
    final aspect = size != null && size.height > 0 ? size.width / size.height : to.width / to.height;
    final fitted = applyBoxFit(BoxFit.contain, Size(aspect, 1), area.size).destination;
    return Alignment.center.inscribe(fitted, area);
  }

  /// L'arrivée : le vol s'efface, la photo à sa place apparaît.
  void _land() {
    _entry?.remove();
    _entry?.dispose();
    _entry = null;
    _arrival?.release();
    if (_gone) return;
    setState(() => _arrival = null);
  }

  @override
  void dispose() {
    _gone = true;
    _wait?.cancel();
    _entry?.remove();
    _entry?.dispose();
    _entry = null;
    _arrival?.release();
    _appear.dispose();
    _travel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // La même structure caché ou non : la photo à sa place ne se remonte pas
    // à l'atterrissage, elle ne repart donc pas de son aplat d'attente.
    return Opacity(opacity: _arrival == null ? 1 : 0, child: widget.child);
  }
}

/// La photo pendant le vol : elle se pose au départ en s'éclaircissant, puis
/// suit le ressort jusqu'à sa place.
class _Flight extends StatelessWidget {
  const _Flight({
    required this.appear,
    required this.travel,
    required this.image,
    required this.from,
    required this.to,
    required this.fromRadius,
    required this.toRadius,
  });

  final Animation<double> appear;
  final Animation<double> travel;
  final ImageProvider image;
  final Rect from;
  final Rect Function() to;
  final BorderRadius fromRadius;
  final BorderRadius toRadius;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([appear, travel]),
      builder: (context, photo) {
        final t = travel.value;
        final a = Motion.easeOut.transform(appear.value);
        // Le ressort dépasse un peu sa cible : la position et la taille le
        // suivent, les coins non — un rayon qui s'inverse n'a pas de sens.
        final radius = BorderRadius.lerp(fromRadius, toRadius, t.clamp(0.0, 1.0))!;
        return Stack(
          children: [
            Positioned.fromRect(
              rect: Rect.lerp(from, to(), t)!,
              child: Opacity(
                opacity: a,
                child: Transform.scale(
                  scale: PhotoLanding.appearScale + (1 - PhotoLanding.appearScale) * a,
                  child: ClipRRect(borderRadius: radius, child: photo),
                ),
              ),
            ),
          ],
        );
      },
      child: Image(image: image, fit: BoxFit.cover, gaplessPlayback: true, filterQuality: FilterQuality.medium),
    );
  }
}
