import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Où en est le viseur intégré.
enum InlineCameraStatus {
  /// Rien n'est ouvert : le flux a été rendu au système, ou pas encore demandé.
  idle,

  /// Le flux s'ouvre. Quelques centaines de millisecondes au premier passage.
  starting,

  /// L'aperçu est à l'écran et la capture est possible.
  ready,

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

  /// Le contrôleur du plugin, quand le flux est ouvert.
  CameraController? get camera => _camera;

  InlineCameraStatus get status => _status;

  /// L'utilisateur a refusé l'accès : lui dire, plutôt que de laisser un
  /// cadre vide qui n'attendrait rien.
  bool get permissionDenied => _permissionDenied;

  /// Le flux est ouvert et peut prendre une photo.
  bool get isReady => _status == InlineCameraStatus.ready && (_camera?.value.isInitialized ?? false);

  /// Un viseur intégré n'existe que sur téléphone et tablette. Ailleurs — le
  /// web, le bureau, les tests — l'appelant garde l'appareil du système.
  static bool get isSupported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

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

  /// L'application passe derrière : le système reprend la caméra, autant la
  /// lui rendre proprement et la redemander au retour. Un refus levé entre
  /// deux — l'utilisateur revient des Réglages — se retrouve ici tout seul.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_disposed || !_wanted) return;
    if (state == AppLifecycleState.resumed) {
      _open();
    } else {
      _close();
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
    super.dispose();
  }

  Future<void> _open() async {
    if (_disposed || !_wanted || _status == InlineCameraStatus.starting || isReady) return;
    if (!isSupported) {
      _set(InlineCameraStatus.unavailable);
      return;
    }
    _set(InlineCameraStatus.starting);
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

  Future<void> _close() async {
    final camera = _camera;
    _camera = null;
    // Un refus reste un refus : le redire au lieu de faire croire à un viseur
    // qui n'attendrait qu'un geste.
    if (_status != InlineCameraStatus.unavailable) _set(InlineCameraStatus.idle);
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
  const InlineCameraPreview({super.key, required this.controller});

  final InlineCameraController controller;

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
        return ClipRect(
          child: OverflowBox(
            maxWidth: double.infinity,
            maxHeight: double.infinity,
            alignment: Alignment.center,
            child: SizedBox(width: width, height: height, child: CameraPreview(camera)),
          ),
        );
      },
    );
  }
}
