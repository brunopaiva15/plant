import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../app/window.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/system_settings.dart';
import '../../../design_system/design_system.dart';

/// Où en est le viseur intégré.
enum InlineCameraStatus {
  /// Rien n'est ouvert : le flux a été rendu au système, ou pas encore demandé.
  idle,

  /// Le flux s'ouvre. Quelques centaines de millisecondes au premier passage.
  starting,

  /// L'aperçu est à l'écran et la capture est possible.
  ready,

  /// L'application est passée derrière : le système a repris la caméra, et
  /// le flux reviendra de lui-même au retour. Ce n'est pas une absence de
  /// viseur — la page garde sa mise en page, sans quoi la carte du
  /// multitâche montrait une autre étape, et le retour réagençait tout.
  suspended,

  /// Pas de viseur ici : permission refusée, appareil sans caméra, ou panne
  /// du plugin. L'appelant retombe alors sur l'appareil photo du système.
  unavailable,
}

/// Le viseur de l'étape photo : l'aperçu de l'appareil, posé dans la page.
///
/// Ouvrir l'appareil photo du système demandait deux gestes — un pour aller
/// le chercher, un pour déclencher. Ici l'aperçu est déjà là : le seul geste
/// qui reste est le déclenchement.
///
/// Le contrôleur vit dans l'état de la page, parce que la page a besoin de
/// savoir si le viseur répond : sans lui, son bouton doit ouvrir l'appareil
/// photo du système comme avant. Rien ici ne dépend du rendu ; c'est
/// [InlineCameraPreview] qui affiche le flux.
class InlineCameraController extends ChangeNotifier with WidgetsBindingObserver {
  CameraController? _camera;
  InlineCameraStatus _status = InlineCameraStatus.idle;
  bool _permissionDenied = false;

  /// La page veut un viseur. Sépare l'arrêt volontaire — on change d'étape —
  /// de la mise en veille : quand l'application passe derrière, le système
  /// reprend la caméra de toute façon, et il faudra la redemander au retour.
  bool _wanted = false;
  bool _observing = false;
  bool _capturing = false;
  bool _disposed = false;

  /// Ce que le verrou de capture dit en ce moment, ou `null` quand aucun flux
  /// n'est ouvert. Voir [_alignCaptureToPage].
  bool? _captureLocked;

  /// Le flash demandé. C'est un choix de la personne, pas un état du flux :
  /// il tient d'une ouverture à l'autre, retour d'arrière-plan et « Reprendre »
  /// compris, et se redit au plugin à chaque nouveau flux.
  bool _flash = false;

  /// L'objectif ouvert a un flash. Faux tant que rien n'est ouvert.
  bool _hasFlash = false;

  /// Les bornes du zoom de l'objectif ouvert. `1` et `1` : pas de zoom.
  double _minZoom = 1;
  double _maxZoom = 1;

  /// Le zoom demandé, et celui qui attend son tour pendant qu'un autre est en
  /// route vers le plugin. Voir [setZoom].
  final ValueNotifier<double> _zoom = ValueNotifier<double>(1);
  double? _pendingZoom;
  bool _zoomInFlight = false;

  /// Au-delà, le zoom n'est plus qu'un agrandissement de pixels : la photo
  /// part à Iris, qui n'y verrait qu'un flou. Un iPhone annonce jusqu'à
  /// 100×, un Android souvent 10×.
  static const double maxUsefulZoom = 8;

  /// Le contrôleur du plugin, quand le flux est ouvert.
  CameraController? get camera => _camera;

  InlineCameraStatus get status => _status;

  /// L'utilisateur a refusé l'accès : lui dire, plutôt que de laisser un
  /// cadre vide qui n'attendrait rien.
  bool get permissionDenied => _permissionDenied;

  /// Refusé, et le système sait mener aux Réglages : toucher le cadre y va,
  /// plutôt que d'ouvrir un appareil photo qui refusera aussi.
  bool get opensSettings => _permissionDenied && SystemSettings.isSupported;

  /// Le flux est ouvert et peut prendre une photo.
  bool get isReady => _status == InlineCameraStatus.ready && (_camera?.value.isInitialized ?? false);

  /// Un viseur est là, arrive, ou revient : la page se dessine avec lui —
  /// le déclencheur sur le cadre, pas les boutons de repli — même si
  /// l'aperçu n'est pas encore à l'écran.
  bool get hasViewfinder =>
      _status == InlineCameraStatus.starting || _status == InlineCameraStatus.ready || _status == InlineCameraStatus.suspended;

  /// Le flash est demandé pour la prochaine photo.
  bool get flash => _flash;

  /// Le flux est ouvert et son objectif a un flash : le bouton se montre.
  /// Un iPad sans flash le dit à l'ouverture, et le bouton ne vient pas.
  bool get hasFlash => isReady && _hasFlash;

  /// Le zoom en cours, écouté à part : un pincement en produit des dizaines
  /// par seconde, et seuls l'aperçu et sa pastille ont à se redessiner.
  ValueListenable<double> get zoom => _zoom;

  double get minZoom => _minZoom;
  double get maxZoom => _maxZoom;

  /// L'objectif ouvert sait zoomer.
  bool get canZoom => isReady && _maxZoom > _minZoom;

  /// Le zoom de repos, celui d'un viseur qui s'ouvre : `1×`, ramené dans les
  /// bornes de l'objectif.
  double get baseZoom => 1.0.clamp(_minZoom, _maxZoom).toDouble();

  /// Un viseur intégré n'existe que sur téléphone et tablette. Ailleurs — le
  /// web, le bureau, les tests — l'appelant garde l'appareil du système.
  static bool get isSupported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Vrai quand la page ne peut pas tourner : sur Android le manifeste
  /// verrouille le portrait sur tous les appareils, sur iOS c'est `Info.plist`
  /// — portrait sur iPhone, les quatre orientations sur iPad —, et la taille
  /// de la fenêtre dit lequel des deux on est. Sur tablette libre, et sur un
  /// pliable ouvert, la capture reste au capteur : la page tourne aussi.
  ///
  /// La question se repose à chaque ouverture du viseur, jamais une fois pour
  /// toutes : entre deux photos, l'appareil a pu être déplié.
  static bool get _portraitOnly {
    if (kIsWeb) return false;
    if (Platform.isAndroid) return true;
    return isCompactWindow();
  }

  /// Demande le viseur. Sans effet s'il est déjà là.
  Future<void> start() async {
    if (_disposed) return;
    _wanted = true;
    if (!_observing) {
      WidgetsBinding.instance.addObserver(this);
      _observing = true;
    }
    await _open();
  }

  /// Rend le flux au système : plus d'aperçu, plus de batterie consommée.
  Future<void> stop() async {
    _wanted = false;
    if (_observing) {
      WidgetsBinding.instance.removeObserver(this);
      _observing = false;
    }
    await _close();
  }

  /// Déclenche. Retourne le fichier temporaire produit, ou `null` si le flux
  /// n'était pas prêt — à l'appelant, alors, d'ouvrir l'appareil du système.
  Future<File?> capture() async {
    final camera = _camera;
    if (camera == null || !isReady || _capturing) return null;
    _capturing = true;
    try {
      final shot = await camera.takePicture();
      return File(shot.path);
    } catch (_) {
      return null;
    } finally {
      _capturing = false;
    }
  }

  /// Allume ou éteint le flash de la prochaine photo.
  ///
  /// Le bouton change tout de suite ; si le plugin refuse, il revient à ce
  /// qu'il était, plutôt que d'annoncer un flash qui ne partira pas.
  Future<void> toggleFlash() async {
    final camera = _camera;
    if (camera == null || !hasFlash) return;
    final wanted = !_flash;
    _flash = wanted;
    notifyListeners();
    try {
      await camera.setFlashMode(wanted ? FlashMode.always : FlashMode.off);
    } catch (_) {
      if (_disposed || _camera != camera || _flash != wanted) return;
      _flash = !wanted;
      notifyListeners();
    }
  }

  /// Zoome à [level], ramené dans les bornes de l'objectif.
  ///
  /// Un pincement appelle ceci à chaque image. Le plugin, lui, répond à son
  /// rythme : un seul ordre part à la fois, et pendant qu'il est en route
  /// seul le dernier demandé attend. L'aperçu suit le doigt sans que les
  /// ordres s'empilent derrière lui.
  void setZoom(double level) {
    if (!canZoom) return;
    final clamped = level.clamp(_minZoom, _maxZoom).toDouble();
    if (clamped == _zoom.value) return;
    _zoom.value = clamped;
    _pendingZoom = clamped;
    if (!_zoomInFlight) _flushZoom();
  }

  /// Revient au zoom de repos.
  void resetZoom() => setZoom(baseZoom);

  Future<void> _flushZoom() async {
    _zoomInFlight = true;
    try {
      while (_pendingZoom != null) {
        final level = _pendingZoom!;
        _pendingZoom = null;
        final camera = _camera;
        if (_disposed || camera == null) break;
        try {
          await camera.setZoomLevel(level);
        } catch (_) {
          // Refusé : l'ordre suivant, s'il vient, repartira de zéro.
        }
      }
    } finally {
      _zoomInFlight = false;
    }
  }

  /// Lit ce que l'objectif sait faire, et lui redit ce que la personne avait
  /// choisi : le flash, le zoom. Rien ici n'empêche le viseur de s'ouvrir.
  Future<void> _prepareControls(CameraController controller) async {
    try {
      _minZoom = await controller.getMinZoomLevel();
      _maxZoom = math.min(await controller.getMaxZoomLevel(), maxUsefulZoom);
      if (_maxZoom < _minZoom) _maxZoom = _minZoom;
    } catch (_) {
      _minZoom = 1;
      _maxZoom = 1;
    }
    // Un flux neuf part du zoom de repos, sauf si la personne avait zoomé :
    // entre deux photos, le cadrage qu'elle avait choisi reste le sien.
    var zoom = (_zoom.value == 1 ? baseZoom : _zoom.value).clamp(_minZoom, _maxZoom).toDouble();
    if (zoom != 1) {
      try {
        await controller.setZoomLevel(zoom);
      } catch (_) {
        zoom = 1;
      }
    }
    // La page a pu partir pendant ces allers-retours : le compteur n'est
    // alors plus là pour être mis à jour.
    if (_disposed) return;
    _zoom.value = zoom;
    // Le flash est dit explicitement, éteint compris : sans cela, iOS part en
    // automatique et déclenche dans la pénombre sans qu'on l'ait demandé.
    // Un appareil sans flash refuse jusqu'à l'extinction, et c'est ainsi
    // qu'on le sait.
    try {
      await controller.setFlashMode(_flash ? FlashMode.always : FlashMode.off);
      _hasFlash = true;
    } catch (_) {
      _hasFlash = false;
    }
  }

  /// Aligne la capture sur la page : verrouillée en portrait quand la page ne
  /// tourne pas, rendue au capteur sinon.
  ///
  /// Un pliable passe d'un cas à l'autre sans rien relancer, alors l'état
  /// demandé est gardé : un changement de fenêtre est le plus souvent un
  /// clavier qui monte, et il n'y a rien à redire au plugin.
  Future<void> _alignCaptureToPage(CameraController controller) async {
    final locked = _portraitOnly;
    if (locked == _captureLocked) return;
    try {
      if (locked) {
        await controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
      } else {
        await controller.unlockCaptureOrientation();
      }
      _captureLocked = locked;
    } on CameraException {
      // Verrou refusé : la capture suivra le capteur, comme avant.
    }
  }

  /// La fenêtre a changé de taille. Sur un pliable, l'appareil vient peut-être
  /// de s'ouvrir : la page qui ne tournait pas tourne désormais, et la capture
  /// n'a plus de raison d'être tenue en portrait.
  @override
  void didChangeMetrics() {
    final camera = _camera;
    if (_disposed || camera == null) return;
    _alignCaptureToPage(camera);
  }

  /// L'application passe derrière : le système reprend la caméra, autant la
  /// lui rendre proprement et la redemander au retour. Un refus levé entre
  /// deux — l'utilisateur revient des Réglages — se retrouve ici tout seul.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_disposed || !_wanted) return;
    if (state == AppLifecycleState.resumed) {
      _open();
    } else {
      _close(suspended: true);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _wanted = false;
    if (_observing) {
      WidgetsBinding.instance.removeObserver(this);
      _observing = false;
    }
    _camera?.dispose();
    _camera = null;
    _captureLocked = null;
    _zoom.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    if (_disposed || !_wanted || _status == InlineCameraStatus.starting || isReady) return;
    if (!isSupported) {
      _set(InlineCameraStatus.unavailable);
      return;
    }
    _set(InlineCameraStatus.starting);
    // Le flux qui s'ouvre est neuf : quoi qu'ait demandé le précédent, son
    // orientation est à redire.
    _captureLocked = null;
    CameraController? controller;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _set(InlineCameraStatus.unavailable);
        return;
      }
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      // 1080p : au-delà, l'aperçu rame sur les appareils modestes alors que
      // la photo finit de toute façon redimensionnée au stockage.
      controller = CameraController(back, ResolutionPreset.veryHigh, enableAudio: false);
      await controller.initialize();
      // Le plugin suit le capteur, pas la page : appareil penché, il couche
      // l'aperçu et la photo. Or sur un téléphone la page ne tourne pas —
      // `ios/Runner/Info.plist` et le manifeste Android le déclarent — et la
      // capture s'aligne donc sur elle.
      await _alignCaptureToPage(controller);
      await _prepareControls(controller);
      // La page a pu partir, ou changer d'étape, pendant l'ouverture : le
      // flux n'a alors plus personne devant lui.
      if (_disposed || !_wanted || _status != InlineCameraStatus.starting) {
        await controller.dispose();
        return;
      }
      _camera = controller;
      _permissionDenied = false;
      _set(InlineCameraStatus.ready);
    } on CameraException catch (e) {
      await controller?.dispose();
      _permissionDenied = const {
        'CameraAccessDenied',
        'CameraAccessDeniedWithoutPrompt',
        'CameraAccessRestricted',
      }.contains(e.code);
      _set(InlineCameraStatus.unavailable);
    } catch (_) {
      // Plugin absent, appareil sans caméra : le repli suffit, personne n'a
      // besoin d'en savoir plus.
      await controller?.dispose();
      _set(InlineCameraStatus.unavailable);
    }
  }

  /// [suspended] : le système a repris la caméra le temps d'un passage en
  /// arrière-plan, et le flux reviendra ; sinon, c'est un arrêt voulu.
  Future<void> _close({bool suspended = false}) async {
    final camera = _camera;
    _camera = null;
    // Le prochain flux repart d'un plugin neuf : son orientation est à redire.
    _captureLocked = null;
    // Un refus reste un refus : le redire au lieu de faire croire à un viseur
    // qui n'attendrait qu'un geste.
    if (_status != InlineCameraStatus.unavailable) {
      _set(suspended && _status != InlineCameraStatus.idle ? InlineCameraStatus.suspended : InlineCameraStatus.idle);
    }
    await camera?.dispose();
  }

  void _set(InlineCameraStatus status) {
    if (_disposed || _status == status) return;
    _status = status;
    notifyListeners();
  }
}

/// L'aperçu de l'appareil, recadré pour remplir son cadre.
///
/// Ne dessine rien tant que le flux n'est pas prêt : le cadre de la page
/// garde alors son invite, et rien ne clignote entre les deux.
class InlineCameraPreview extends StatelessWidget {
  const InlineCameraPreview({super.key, required this.controller, this.scanningOverlay = true});

  final InlineCameraController controller;

  /// Le viseur principal porte les quatre repères de cadrage d'Iris. Le
  /// paramètre reste disponible pour les écrans qui ont besoin d'un aperçu
  /// totalement neutre sans dupliquer le composant caméra.
  final bool scanningOverlay;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final camera = controller.camera;
        if (!controller.isReady || camera == null) return const SizedBox.shrink();
        // La valeur du plugin change aussi à la rotation de l'appareil, sans
        // passer par le contrôleur au-dessus : on l'écoute pour elle-même.
        return ValueListenableBuilder<CameraValue>(
          valueListenable: camera,
          builder: (context, value, _) => _cover(camera, value),
        );
      },
    );
  }

  /// `CameraPreview` se dimensionne au ratio du flux ; le cadre, lui, a le
  /// sien. On agrandit l'aperçu jusqu'à couvrir le cadre, et on rogne le
  /// débord — comme un `BoxFit.cover`, que le ratio seul ne donne pas.
  Widget _cover(CameraController camera, CameraValue value) {
    final orientation = value.lockedCaptureOrientation ?? value.deviceOrientation;
    final landscape =
        orientation == DeviceOrientation.landscapeLeft || orientation == DeviceOrientation.landscapeRight;
    // `aspectRatio` est celui du capteur, toujours en paysage.
    final previewRatio = landscape ? value.aspectRatio : 1 / value.aspectRatio;
    return LayoutBuilder(
      builder: (context, constraints) {
        var width = constraints.maxWidth;
        var height = constraints.maxHeight;
        if (width.isFinite && height.isFinite && height > 0) {
          if (previewRatio > width / height) {
            width = height * previewRatio;
          } else {
            height = width / previewRatio;
          }
        }
        // L'overlay est volontairement hors de l'OverflowBox : ses repères
        // suivent le cadre visible, pas la taille réelle du flux recadré.
        return _PinchToZoom(
          controller: controller,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRect(
                child: OverflowBox(
                  maxWidth: double.infinity,
                  maxHeight: double.infinity,
                  alignment: Alignment.center,
                  child: SizedBox(width: width, height: height, child: CameraPreview(camera)),
                ),
              ),
              if (scanningOverlay) const ScanningOverlay(),
            ],
          ),
        );
      },
    );
  }
}

/// Le pincement du viseur : deux doigts qui s'écartent zooment, qui se
/// rapprochent dézooment.
///
/// Le zoom suit le rapport des écartements depuis le début du geste, pas
/// leur différence : c'est ce qui le rend régulier de bout en bout, de 1× à
/// 2× comme de 4× à 8×. Un doigt qui se lève en cours de route ne fait pas
/// sauter l'image : le geste repart de là où il en était.
class _PinchToZoom extends StatefulWidget {
  const _PinchToZoom({required this.controller, required this.child});

  final InlineCameraController controller;
  final Widget child;

  @override
  State<_PinchToZoom> createState() => _PinchToZoomState();
}

class _PinchToZoomState extends State<_PinchToZoom> {
  /// Le zoom au moment où le geste a pris sa forme actuelle.
  double _base = 1;

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      behavior: HitTestBehavior.opaque,
      gestures: {
        PinchRecognizer: GestureRecognizerFactoryWithHandlers<PinchRecognizer>(
          () => PinchRecognizer(debugOwner: this),
          (recognizer) => recognizer
            // Le recognizer redonne un départ chaque fois qu'un doigt se pose
            // ou se lève, avec une échelle remise à 1.
            ..onStart = (_) {
              _base = widget.controller.zoom.value;
            }
            ..onUpdate = (details) {
              if (details.pointerCount < 2) return;
              widget.controller.setZoom(_base * details.scale);
            },
        ),
      },
      child: widget.child,
    );
  }
}

/// Le pincement, qui se réserve le geste dès que le second doigt se pose.
///
/// Le cadre se touche pour déclencher, et il vit parfois dans une page qui
/// défile. Laisser le pincement attendre son seuil, c'était laisser le
/// premier doigt, resté presque immobile, déclencher la photo en se levant,
/// ou la page défiler sous les deux doigts. À deux doigts, le geste est un
/// pincement, et rien d'autre ne le reçoit. À un doigt, rien ne change : un
/// toucher déclenche, un glissé fait défiler.
@visibleForTesting
class PinchRecognizer extends ScaleGestureRecognizer {
  PinchRecognizer({super.debugOwner});

  final Set<int> _pointers = {};

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    _pointers.add(event.pointer);
    if (_pointers.length >= 2) resolve(GestureDisposition.accepted);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerUpEvent || event is PointerCancelEvent) _pointers.remove(event.pointer);
    super.handleEvent(event);
  }

  @override
  void rejectGesture(int pointer) {
    _pointers.remove(pointer);
    super.rejectGesture(pointer);
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    _pointers.clear();
    super.didStopTrackingLastPointer(pointer);
  }
}

/// Les commandes posées sur le viseur : le flash en haut à droite, niché
/// dans le repère de cadrage, et la pastille du zoom en bas, au centre.
///
/// À poser par-dessus l'aperçu — et par-dessus ce qui le recouvre, comme le
/// calque de la photo précédente. Ne dessine rien tant que le flux n'est pas
/// prêt, et rien de ce que l'objectif ne sait pas faire : pas de flash sur
/// un iPad qui n'en a pas.
class InlineCameraControls extends StatelessWidget {
  const InlineCameraControls({super.key, required this.controller, this.bottom = Space.md});

  final InlineCameraController controller;

  /// La distance entre la pastille du zoom et le bas du cadre : au-dessus du
  /// déclencheur quand le cadre en porte un, voir [aboveShutter].
  final double bottom;

  /// La pastille au-dessus d'un déclencheur posé à [Space.md] du bas : le
  /// déclencheur, puis douze points d'écart.
  static const double aboveShutter = Space.md + Shutter.side + Space.sm;

  /// Le bouton du flash tient dans le coin du repère de cadrage : les 18
  /// points du repère, puis 10 d'écart.
  static const double _nest = 28;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Stack(
        fit: StackFit.expand,
        children: [
          if (controller.hasFlash)
            Positioned(
              top: _nest,
              right: _nest,
              child: FloraIconButton(
                icon: controller.flash ? CupertinoIcons.bolt_fill : CupertinoIcons.bolt_slash,
                semanticLabel: controller.flash ? l10n.cameraFlashOff : l10n.cameraFlashOn,
                background: OnMedia.tile,
                color: OnMedia.ink,
                onPressed: controller.toggleFlash,
              ),
            ),
          if (controller.canZoom)
            Positioned(
              left: 0,
              right: 0,
              bottom: bottom,
              child: Center(child: _ZoomBadge(controller: controller)),
            ),
        ],
      ),
    );
  }
}

/// La pastille du zoom : elle dit où l'on en est, et d'un toucher passe de
/// 1× à 2×, ou revient à 1× — le zoom glisse de l'un à l'autre au lieu de
/// sauter.
class _ZoomBadge extends StatefulWidget {
  const _ZoomBadge({required this.controller});

  final InlineCameraController controller;

  /// Le zoom qu'un toucher propose depuis le repos.
  static const double step = 2;

  @override
  State<_ZoomBadge> createState() => _ZoomBadgeState();
}

class _ZoomBadgeState extends State<_ZoomBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _glide = AnimationController(vsync: this);
  Animation<double>? _levels;

  /// Le dernier zoom que la glissade a demandé : s'il n'est plus celui du
  /// viseur, c'est qu'un pincement a repris la main, et la glissade s'efface.
  double? _driven;

  @override
  void initState() {
    super.initState();
    _glide.addListener(_step);
  }

  @override
  void dispose() {
    _glide.dispose();
    super.dispose();
  }

  InlineCameraController get _camera => widget.controller;

  /// Au repos, ou presque : l'écart qu'un pincement laisse en revenant à la
  /// main ne compte pas.
  bool _atBase(double zoom) => (zoom - _camera.baseZoom).abs() < 0.05;

  void _step() {
    final levels = _levels;
    if (levels == null) return;
    if (_driven != null && _camera.zoom.value != _driven) {
      _glide.stop();
      return;
    }
    _driven = levels.value.clamp(_camera.minZoom, _camera.maxZoom).toDouble();
    _camera.setZoom(_driven!);
  }

  void _toggle() {
    final from = _camera.zoom.value;
    final to = _atBase(from) ? math.min(_ZoomBadge.step, _camera.maxZoom) : _camera.baseZoom;
    if (to == from) return;
    _driven = null;
    _levels = Tween<double>(begin: from, end: to).animate(CurvedAnimation(parent: _glide, curve: Motion.easeInOut));
    _glide
      ..duration = Motion.of(context, Motion.standard)
      ..forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final format = NumberFormat('0.#', l10n.localeName);
    return ValueListenableBuilder<double>(
      valueListenable: _camera.zoom,
      builder: (context, zoom, _) {
        final atBase = _atBase(zoom);
        return Pressable(
          onTap: _toggle,
          scale: 0.92,
          semanticLabel: atBase ? l10n.cameraZoomIn : l10n.cameraZoomReset,
          child: Container(
            constraints: const BoxConstraints(minWidth: 44, minHeight: 32),
            padding: const EdgeInsets.symmetric(horizontal: Space.sm),
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: OnMedia.tile, borderRadius: BorderRadius.all(Radius.circular(16))),
            child: Text(
              l10n.cameraZoomLevel(format.format(atBase ? _camera.baseZoom : zoom)),
              style: context.text.caption.copyWith(color: OnMedia.ink, fontWeight: FontWeight.w600, fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ),
        );
      },
    );
  }
}
