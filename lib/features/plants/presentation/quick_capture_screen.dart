import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/system_settings.dart';
import '../../../data/services/photo_storage_service.dart';
import '../../../design_system/design_system.dart';
import 'inline_camera.dart';
import 'photo_capture_flow.dart';
import 'photo_error.dart';

/// Une photo, prise dans le viseur intégré ou choisie dans la galerie, et
/// rien d'autre : pas de titre à donner, pas de plante à qui l'attacher.
/// Retourne la photo enregistrée, ou `null` si l'utilisateur est reparti sans.
///
/// C'est le chemin des photos qu'un écran demande après coup — la vue que
/// réclame un compte rendu de diagnostic. Avant, ce chemin passait par une
/// feuille « Appareil photo | Galerie » et l'appareil du système : ni flash à
/// la main, ni zoom au pincement, ni repères de cadrage.
Future<StoredPhoto?> showQuickCapture(BuildContext context, {required String title, String? subtitle}) {
  return showFloraFlow<StoredPhoto>(context, builder: (_) => QuickCaptureScreen(title: title, subtitle: subtitle));
}

/// Le viseur en plein écran : le cadre et son déclencheur, le flash et le
/// zoom sur l'aperçu, la galerie en dessous. Sans viseur (refus, appareil
/// sans caméra, bureau), le cadre garde son invite et ouvre l'appareil photo
/// du système — ou les Réglages, si l'accès est refusé.
class QuickCaptureScreen extends ConsumerStatefulWidget {
  const QuickCaptureScreen({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  ConsumerState<QuickCaptureScreen> createState() => _QuickCaptureScreenState();
}

class _QuickCaptureScreenState extends ConsumerState<QuickCaptureScreen> {
  final _camera = InlineCameraController();
  bool _picking = false;

  @override
  void initState() {
    super.initState();
    _camera.start();
  }

  @override
  void dispose() {
    _camera.dispose();
    super.dispose();
  }

  void _done(StoredPhoto stored) => Navigator.of(context, rootNavigator: true).pop(stored);

  /// L'appareil photo ou la galerie du système.
  Future<void> _pick(PhotoSource source) async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final stored = await ref.read(photoStorageProvider).pick(source);
      if (stored != null && mounted) return _done(stored);
    } catch (e, st) {
      ref.read(crashReporterProvider).report(e, st, context: 'quickCapture.pick');
      if (mounted) ref.read(toastProvider.notifier).show(photoErrorToast(context.l10n, e));
    }
    if (mounted) setState(() => _picking = false);
  }

  /// Déclenche depuis le viseur intégré ; sans lui, l'appareil du système.
  Future<void> _capture() async {
    if (_picking) return;
    if (!_camera.isReady) return _pick(PhotoSource.camera);
    setState(() => _picking = true);
    final shot = await _camera.capture();
    if (shot == null) {
      if (!mounted) return;
      setState(() => _picking = false);
      return _pick(PhotoSource.camera);
    }
    StoredPhoto? stored;
    try {
      stored = await ref.read(photoStorageProvider).importFile(shot);
    } catch (e, st) {
      ref.read(crashReporterProvider).report(e, st, context: 'quickCapture.capture');
      if (mounted) ref.read(toastProvider.notifier).show(photoErrorToast(context.l10n, e));
    } finally {
      // La copie compressée a remplacé le fichier brut du plugin.
      try {
        await shot.delete();
      } catch (_) {}
    }
    if (!mounted) {
      // Parti pendant l'enregistrement : la photo n'a plus personne à qui
      // revenir, ses fichiers n'ont rien à faire dans le dossier.
      if (stored != null) ref.read(photoStorageProvider).deleteFiles(stored.filePath, stored.thumbPath);
      return;
    }
    if (stored != null) return _done(stored);
    setState(() => _picking = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.canvas,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.md, Space.xs, Space.md, 0),
              child: Row(
                children: [
                  FloraIconButton(
                    icon: CupertinoIcons.xmark,
                    semanticLabel: l10n.close,
                    onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: _camera,
                builder: (context, _) {
                  final live = _camera.hasViewfinder;
                  return PhotoFlowStep(
                    title: widget.title,
                    subtitle: widget.subtitle,
                    body: Center(
                      child: AspectRatio(
                        aspectRatio: 4 / 5,
                        child: Pressable(
                          onTap: _picking
                              ? null
                              : (live ? (_camera.isReady ? _capture : null) : (_camera.opensSettings ? SystemSettings.open : () => _pick(PhotoSource.camera))),
                          scale: 0.98,
                          haptic: false,
                          semanticLabel: l10n.takePhoto,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CaptureFrame(camera: _camera),
                              if (live)
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: Space.md,
                                  child: Center(
                                    child: Shutter(
                                      busy: _picking,
                                      enabled: _camera.isReady,
                                      semanticLabel: l10n.takePhoto,
                                      onTap: _capture,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    actions: [
                      // Sans viseur, le déclencheur du cadre n'est pas là :
                      // le geste s'écrit en bouton, comme ailleurs.
                      if (!live) ...[
                        FloraButton(label: l10n.takePhoto, icon: CupertinoIcons.camera_fill, expand: true, loading: _picking, onPressed: _capture),
                        const SizedBox(height: Space.xs),
                      ],
                      FloraButton(
                        label: l10n.choosePhoto,
                        icon: CupertinoIcons.photo,
                        style: FloraButtonStyle.secondary,
                        expand: true,
                        onPressed: _picking ? null : () => _pick(PhotoSource.gallery),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
