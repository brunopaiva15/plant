import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

import '../tokens/motion.dart';
import '../tokens/radius.dart';

/// Une photo qui devient sa vignette, à la manière de l'application ChatGPT.
///
/// Chez ChatGPT, rien n'apparaît : tout se transforme. Le menu « + » devient
/// la carte de l'appareil photo ; la photo prise se rétracte en vignette
/// dans la barre de saisie ; la vignette file jusqu'à la bulle du message.
/// Chaque fois, **l'élément part de l'endroit exact où il était à l'écran**,
/// sans fondu, sans temps d'arrêt, en un cinquième de seconde environ, et ses
/// coins prennent en route l'arrondi de l'arrivée.
///
/// Ici, la photo part de ce que la personne a touché :
///
/// - le viseur, pour une photo prise : elle s'en détache à sa taille et se
///   rétracte jusqu'à sa place — c'est le geste de la vidéo ;
/// - le bouton qui a ouvert la galerie : la photo en sort, bouton rond ou
///   bouton pilule, et grandit jusqu'à sa place en perdant la forme du
///   bouton.
///
/// Deux endroits du code, comme un [Hero] :
///
/// - qui reçoit la photo l'annonce avec [PhotoLanding.expectFile] : son
///   étiquette, le fichier, et d'où elle part ([PhotoOrigin.of], relevé au
///   moment du toucher — le sélecteur du système couvre ensuite l'écran) ;
/// - l'endroit où elle s'affiche porte un [PhotoLanding] de même [tag]. À sa
///   première construction, ou quand son étiquette change, il réclame
///   l'annonce, se cache, et fait venir l'image jusqu'à lui.
///
/// Sans point de départ (une photo choisie depuis un menu), elle se pose sur
/// place en grandissant un peu. Une annonce que personne ne réclame expire au
/// bout de [patience]. La destination est suivie à chaque image : si elle
/// bouge pendant le vol — une page qui glisse, une bande qui apparaît —, la
/// photo la rattrape. Hors de l'écran, ou avec *réduire les animations*, pas
/// de vol : la photo est simplement à sa place.
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
  /// elle : une photo qui se détache du viseur doit être là dès la première
  /// image, sinon on verrait le viseur, puis la photo surgir en route.
  static const Duration decodeWait = Duration(milliseconds: 250);

  /// Sans point de départ, la photo se pose sur place à partir de cette
  /// taille.
  static const double settleScale = 0.86;

  /// La part du trajet pendant laquelle une photo sortie d'un bouton se
  /// dessine : le bouton ne montrait pas la photo, elle ne peut pas y être
  /// tout entière à la première image.
  static const double revealShare = 0.2;

  static final Map<Object, _Arrival> _expected = {};

  /// Annonce qu'une photo arrive sous l'étiquette [tag], partie de [from],
  /// et commence à décoder [image] : quand sa destination se construira,
  /// elle sera prête.
  static void expect(Object tag, ImageProvider image, {PhotoOrigin? from}) {
    _forget();
    _expected.remove(tag)?.release();
    _expected[tag] = _Arrival(image, from);
  }

  /// [expect] pour une photo sur l'appareil, décodée à la largeur d'un
  /// écran : le fichier entier ferait attendre le départ pour rien.
  static void expectFile(Object tag, File file, {PhotoOrigin? from}) =>
      expect(tag, ResizeImage(FileImage(file), width: 1200, allowUpscaling: false), from: from);

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

/// D'où part une photo : le rectangle à l'écran de ce qu'on a touché, et ses
/// coins.
@immutable
class PhotoOrigin {
  const PhotoOrigin(this.rect, {this.radius = BorderRadius.zero, this.showsPhoto = false});

  /// En coordonnées globales.
  final Rect rect;
  final BorderRadius radius;

  /// Le départ montrait déjà la photo — le viseur au déclenchement : elle
  /// s'en détache telle quelle, sans se dessiner.
  final bool showsPhoto;

  /// Le départ que dessine [context] : un bouton, un cadre. Les coins par
  /// défaut sont ceux d'une pilule ou d'un rond, ramenés à la
  /// demi-hauteur — un rayon plus grand ne changerait rien au dessin, mais
  /// fausserait le passage à l'arrondi de l'arrivée.
  static PhotoOrigin? of(BuildContext? context, {BorderRadius radius = Radii.fullAll, bool showsPhoto = false}) {
    final box = context?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    final rect = MatrixUtils.transformRect(box.getTransformTo(null), Offset.zero & box.size);
    final cap = rect.shortestSide / 2;
    return PhotoOrigin(
      rect,
      radius: BorderRadius.only(
        topLeft: Radius.circular(math.min(radius.topLeft.x, cap)),
        topRight: Radius.circular(math.min(radius.topRight.x, cap)),
        bottomLeft: Radius.circular(math.min(radius.bottomLeft.x, cap)),
        bottomRight: Radius.circular(math.min(radius.bottomRight.x, cap)),
      ),
      showsPhoto: showsPhoto,
    );
  }
}

/// Une photo annoncée : son image, qui se décode déjà, et d'où elle part.
class _Arrival {
  _Arrival(this.image, this.from) : at = DateTime.now() {
    _stream = image.resolve(ImageConfiguration.empty);
    _listener = ImageStreamListener(
      (info, _) {
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
  final PhotoOrigin? from;
  final DateTime at;
  late final ImageStream _stream;
  late final ImageStreamListener _listener;
  final _ready = Completer<void>();

  Future<void> get ready => _ready.future;

  void release() => _stream.removeListener(_listener);
}

class _PhotoLandingState extends State<PhotoLanding> with SingleTickerProviderStateMixin {
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
    // Une destination hors de l'écran : la photo n'irait nulle part où l'œil
    // puisse la suivre.
    if (to == null || !(Offset.zero & bounds.size).overlaps(to)) return _land();
    final origin = arrival.from;
    final Rect from;
    final BorderRadius fromRadius;
    final bool reveal;
    if (origin == null) {
      from = Rect.fromCenter(center: to.center, width: to.width * PhotoLanding.settleScale, height: to.height * PhotoLanding.settleScale);
      fromRadius = widget.radius;
      reveal = true;
    } else {
      from = origin.rect.shift(-bounds.localToGlobal(Offset.zero));
      fromRadius = origin.radius;
      reveal = !origin.showsPhoto;
    }
    _entry = OverlayEntry(
      builder: (_) => IgnorePointer(
        child: _Flight(
          travel: _travel,
          image: arrival.image,
          from: from,
          to: () => _target() ?? _lastTarget ?? to,
          fromRadius: fromRadius,
          toRadius: widget.radius,
          reveal: reveal,
        ),
      ),
    );
    overlay.insert(_entry!);
    _travel.animateWith(SpringSimulation(Springs.morph, 0, 1, 0)).whenCompleteOrCancel(() {
      if (!_gone) _land();
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

/// La photo pendant le vol : un seul rectangle qui passe du départ à
/// l'arrivée, l'image recadrée dedans à chaque image.
class _Flight extends StatelessWidget {
  const _Flight({
    required this.travel,
    required this.image,
    required this.from,
    required this.to,
    required this.fromRadius,
    required this.toRadius,
    required this.reveal,
  });

  final Animation<double> travel;
  final ImageProvider image;
  final Rect from;
  final Rect Function() to;
  final BorderRadius fromRadius;
  final BorderRadius toRadius;

  /// La photo se dessine en début de trajet : le départ ne la montrait pas.
  final bool reveal;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: travel,
      builder: (context, photo) {
        final t = travel.value;
        // Le ressort dépasse à peine sa cible : la position et la taille le
        // suivent, les coins non — un rayon qui s'inverse n'a pas de sens.
        final radius = BorderRadius.lerp(fromRadius, toRadius, t.clamp(0.0, 1.0))!;
        final opacity = reveal ? (t / PhotoLanding.revealShare).clamp(0.0, 1.0) : 1.0;
        return Stack(
          children: [
            Positioned.fromRect(
              rect: Rect.lerp(from, to(), t)!,
              child: Opacity(
                opacity: opacity,
                child: ClipRRect(borderRadius: radius, child: photo),
              ),
            ),
          ],
        );
      },
      child: Image(image: image, fit: BoxFit.cover, gaplessPlayback: true, filterQuality: FilterQuality.medium),
    );
  }
}
