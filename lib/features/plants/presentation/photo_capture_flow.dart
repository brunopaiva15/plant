
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../data/services/photo_storage_service.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models/models.dart';
import '../../account/application/membership_providers.dart';
import '../../actions/application/care_actions.dart';
import '../application/plant_providers.dart';
import 'inline_camera.dart';
import 'photo_sheets.dart';

/// Le seul chemin pour ajouter une photo à une plante, d'où qu'on vienne :
/// la fiche, sa section Croissance, la galerie. Retourne la photo enregistrée,
/// ou `null` si l'utilisateur est reparti sans.
///
/// Avant, ajouter une photo, c'était une feuille d'action système
/// (« Appareil photo | Galerie »), puis l'appareil du système, puis un toast.
/// Trois écrans qui ne disaient rien de ce qu'on photographiait ni pourquoi,
/// et un titre à aller chercher après coup dans un menu. Ici, deux étapes qui
/// se suivent : viser, puis nommer.
Future<PlantPhoto?> showPhotoCaptureFlow(BuildContext context, WidgetRef ref, {required String plantId}) async {
  if (!ref.read(canEditProvider)) {
    ref.read(toastProvider.notifier).show(ToastData(message: context.l10n.readOnlyHint, emoji: '🔒'));
    return null;
  }
  return showFloraFlow<PlantPhoto>(context, builder: (_) => PhotoCaptureFlow(plantId: plantId));
}

/// Deux étapes : le viseur, puis le titre.
///
/// **Viser.** L'aperçu de l'appareil est déjà dans le cadre, comme à la
/// création de la plante ; toucher le cadre ou le bouton déclenche. Quand la
/// plante a déjà une photo, celle-ci se pose en transparence par-dessus le
/// viseur : c'est le calque, et c'est ce qui rend un suivi de croissance
/// lisible — même cadrage, même distance, d'un mois à l'autre. Sans viseur
/// (refus, appareil sans caméra, bureau), le cadre garde son invite et les
/// boutons ouvrent l'appareil photo du système.
///
/// **Nommer.** La photo prise, avec sa date ; un titre facultatif, que des
/// suggestions remplissent d'un geste ; et, s'il y a déjà des photos,
/// l'interrupteur qui en fait la photo principale. La première l'est
/// d'office.
class PhotoCaptureFlow extends ConsumerStatefulWidget {
  const PhotoCaptureFlow({super.key, required this.plantId});

  final String plantId;

  @override
  ConsumerState<PhotoCaptureFlow> createState() => _PhotoCaptureFlowState();
}

class _PhotoCaptureFlowState extends ConsumerState<PhotoCaptureFlow> {
  final _page = PageController();
  final _camera = InlineCameraController();
  final _label = TextEditingController();
  int _step = 0;
  StoredPhoto? _stored;
  bool _picking = false;
  bool _saving = false;
  bool _saved = false;
  bool _primary = false;

  /// Le calque de la dernière photo, par-dessus le viseur. Allumé d'office :
  /// c'est le geste que ce flow est venu proposer.
  bool _ghost = true;

  @override
  void initState() {
    super.initState();
    _camera.start();
  }

  @override
  void dispose() {
    _camera.dispose();
    _page.dispose();
    _label.dispose();
    // Parti sans enregistrer : la photo prise n'a pas de ligne, ses fichiers
    // n'ont rien à faire dans le dossier.
    if (!_saved && _stored != null) ref.read(photoStorageProvider).deleteFiles(_stored!.filePath, _stored!.thumbPath);
    super.dispose();
  }

  List<PlantPhoto> get _photos => ref.read(plantPhotosProvider(widget.plantId)).value ?? const <PlantPhoto>[];

  void _go(int step) {
    Haptics.selection();
    if (step != 1) FocusManager.instance.primaryFocus?.unfocus();
    // Le viseur ne tourne qu'à l'étape où l'on vise : ailleurs il ne ferait
    // que tenir la caméra et vider la batterie.
    if (step == 0) {
      _camera.start();
    } else {
      _camera.stop();
    }
    setState(() => _step = step);
    _page.animateToPage(step, duration: Motion.of(context, Motion.emphasis), curve: Motion.emphasized);
  }

  /// L'appareil photo ou la galerie du système.
  Future<void> _pick(PhotoSource source) async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final stored = await ref.read(photoStorageProvider).pick(source);
      if (stored == null || !mounted) return;
      _accept(stored);
    } catch (e, st) {
      ref.read(crashReporterProvider).report(e, st, context: 'photoFlow.pick');
      if (mounted) ref.read(toastProvider.notifier).show(ToastData(message: context.l10n.photoError, emoji: '!'));
    } finally {
      if (mounted) setState(() => _picking = false);
    }
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
    try {
      final stored = await ref.read(photoStorageProvider).importFile(shot);
      if (mounted) _accept(stored);
    } catch (e, st) {
      ref.read(crashReporterProvider).report(e, st, context: 'photoFlow.capture');
      if (mounted) ref.read(toastProvider.notifier).show(ToastData(message: context.l10n.photoError, emoji: '!'));
    } finally {
      // La copie compressée a remplacé le fichier brut du plugin.
      try {
        await shot.delete();
      } catch (_) {}
      if (mounted) setState(() => _picking = false);
    }
  }

  void _accept(StoredPhoto stored) {
    final old = _stored;
    setState(() => _stored = stored);
    if (old != null) ref.read(photoStorageProvider).deleteFiles(old.filePath, old.thumbPath);
    Haptics.success();
    _go(1);
  }

  /// Retour au viseur : cette prise ne convenait pas.
  void _retake() {
    final old = _stored;
    setState(() => _stored = null);
    if (old != null) ref.read(photoStorageProvider).deleteFiles(old.filePath, old.thumbPath);
    _go(0);
  }

  /// Une photo hébergée ailleurs. La sheet écrit elle-même la ligne ; si elle
  /// en revient avec une photo, le flow a fait son travail.
  Future<void> _fromUrl() async {
    final photo = await showPhotoUrlSheet(context, plantId: widget.plantId);
    if (photo != null && mounted) Navigator.of(context, rootNavigator: true).pop(photo);
  }

  Future<void> _save() async {
    final stored = _stored;
    if (stored == null || _saving) return;
    setState(() => _saving = true);
    final photo = await ref.read(careActionsProvider).savePhoto(
          context,
          plantId: widget.plantId,
          stored: stored,
          label: _label.text.trim(),
          makePrimary: _primary,
        );
    if (!mounted) return;
    if (photo == null) {
      // Rien d'écrit — et les fichiers déjà effacés par le cas d'usage.
      setState(() {
        _saving = false;
        _stored = null;
      });
      _go(0);
      return;
    }
    _saved = true;
    Navigator.of(context, rootNavigator: true).pop(photo);
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
                    icon: _step == 0 ? CupertinoIcons.xmark : CupertinoIcons.chevron_left,
                    semanticLabel: _step == 0 ? l10n.close : l10n.back,
                    onPressed: () => _step == 0 ? Navigator.of(context, rootNavigator: true).pop() : _retake(),
                  ),
                  const Spacer(),
                  StepDots(count: 2, index: _step),
                  const Spacer(),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _page,
                physics: const NeverScrollableScrollPhysics(),
                children: [_captureStep(), _reviewStep()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _captureStep() {
    final l10n = context.l10n;
    final photos = ref.watch(plantPhotosProvider(widget.plantId)).value ?? const <PlantPhoto>[];
    final previous = photos.firstOrNull;
    return ListenableBuilder(
      listenable: _camera,
      builder: (context, _) {
        final ghostAvailable = _camera.isReady && previous != null;
        return PhotoFlowStep(
          title: previous == null ? l10n.photoFirstTitle : l10n.photoNextTitle,
          subtitle: previous == null ? l10n.photoFirstHint : l10n.photoFrameHint,
          body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: AspectRatio(
                  aspectRatio: 4 / 5,
                  child: Pressable(
                    onTap: _camera.isReady ? _capture : () => _pick(PhotoSource.camera),
                    scale: 0.98,
                    semanticLabel: l10n.takePhoto,
                    child: CaptureFrame(
                      camera: _camera,
                      ghost: ghostAvailable && _ghost ? previous : null,
                    ),
                  ),
                ),
              ),
              // Le calque ne se propose que s'il peut se voir : sans viseur,
              // il n'y a rien sur quoi le poser.
              if (ghostAvailable) ...[
                const SizedBox(height: Space.md),
                FloraChip(
                  label: l10n.photoGhostToggle,
                  icon: CupertinoIcons.square_stack,
                  selected: _ghost,
                  onTap: () => setState(() => _ghost = !_ghost),
                ),
                if (_ghost) ...[
                  const SizedBox(height: Space.xs),
                  Text(l10n.photoGhostHint, style: context.text.caption, textAlign: TextAlign.center),
                ],
              ],
            ],
          ),
          actions: [
            FloraButton(label: l10n.takePhoto, icon: CupertinoIcons.camera_fill, expand: true, loading: _picking, onPressed: _capture),
            const SizedBox(height: Space.xs),
            FloraButton(label: l10n.choosePhoto, icon: CupertinoIcons.photo, style: FloraButtonStyle.secondary, expand: true, onPressed: _picking ? null : () => _pick(PhotoSource.gallery)),
            const SizedBox(height: Space.xs),
            FloraButton(label: l10n.addPhotoByUrl, style: FloraButtonStyle.ghost, expand: true, onPressed: _picking ? null : _fromUrl),
          ],
        );
      },
    );
  }

  Widget _reviewStep() {
    final stored = _stored;
    if (stored == null) return const SizedBox.shrink();
    return PhotoReviewStep(
      thumbPath: stored.thumbPath,
      takenAt: stored.takenAt,
      label: _label,
      // La première photo est principale d'office : pas d'interrupteur à
      // montrer pour une question qui ne se pose pas.
      makePrimary: _photos.isEmpty ? null : _primary,
      onPrimaryChanged: (v) => setState(() => _primary = v),
      saving: _saving,
      onSave: _save,
      onRetake: _retake,
    );
  }
}

/// Le cadre de l'étape du viseur : l'aperçu de l'appareil, le calque de la
/// dernière photo par-dessus, ou — faute de viseur — l'invite qui mène à
/// l'appareil photo du système.
class CaptureFrame extends StatelessWidget {
  const CaptureFrame({super.key, required this.camera, this.ghost});

  final InlineCameraController camera;

  /// La photo à poser en transparence sur le viseur, ou rien.
  final PlantPhoto? ghost;

  /// Assez présente pour aligner un pot dessus, assez discrète pour voir ce
  /// qu'on vise.
  static const double ghostOpacity = 0.38;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final Widget content;
    if (camera.isReady) {
      content = Stack(
        fit: StackFit.expand,
        children: [
          InlineCameraPreview(controller: camera),
          if (ghost != null)
            IgnorePointer(
              child: Opacity(
                opacity: ghostOpacity,
                child: PlantImage(relativePath: ghost!.thumbPath, remoteUrl: ghost!.remoteUrl, cacheWidth: 600),
              ),
            ),
        ],
      );
    } else if (camera.status == InlineCameraStatus.starting) {
      content = Center(child: ClayLoader(size: 32, color: c.sage));
    } else {
      content = FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.all(Space.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.camera, size: 44, color: c.sage),
              const SizedBox(height: Space.sm),
              Text(l10n.takePhoto, style: context.text.callout.copyWith(color: c.sage, fontWeight: FontWeight.w600)),
              if (camera.permissionDenied) ...[
                const SizedBox(height: Space.xs),
                SizedBox(
                  width: 220,
                  child: Text(l10n.cameraPermission, textAlign: TextAlign.center, style: context.text.caption.copyWith(color: c.sage)),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: c.sageSoft, borderRadius: Radii.xlAll),
      child: content,
    );
  }
}

/// L'étape du titre : la photo, sa date, un titre facultatif et ses
/// suggestions, la photo principale.
class PhotoReviewStep extends StatelessWidget {
  const PhotoReviewStep({
    super.key,
    required this.thumbPath,
    required this.label,
    required this.onSave,
    required this.onRetake,
    this.takenAt,
    this.makePrimary,
    this.onPrimaryChanged,
    this.saving = false,
  });

  final String thumbPath;

  /// Date de prise de vue lue dans la photo ; `null` pour l'instant présent.
  final DateTime? takenAt;
  final TextEditingController label;

  /// `null` : la question ne se pose pas (première photo), la ligne n'est
  /// pas montrée.
  final bool? makePrimary;
  final ValueChanged<bool>? onPrimaryChanged;
  final bool saving;
  final VoidCallback onSave;
  final VoidCallback onRetake;

  /// Les titres qu'on donne le plus souvent, à portée de pouce.
  static List<String> suggestions(AppLocalizations l10n) => [
        l10n.photoTagNewLeaf,
        l10n.photoTagFlowering,
        l10n.photoTagBeforeRepotting,
        l10n.photoTagAfterRepotting,
        l10n.photoTagCutting,
        l10n.photoTagAfterPruning,
      ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    return PhotoFlowStep(
      title: l10n.photoTitleStepTitle,
      subtitle: l10n.photoTitleStepSubtitle,
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: Radii.xlAll,
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PlantImage(relativePath: thumbPath, cacheWidth: 900),
                  Positioned(
                    left: Space.sm,
                    bottom: Space.sm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: Space.xs, vertical: 3),
                      decoration: BoxDecoration(color: c.ink.withValues(alpha: 0.55), borderRadius: Radii.fullAll),
                      child: Text(
                        Dates.relativeDay(context, takenAt ?? DateTime.now()),
                        style: context.text.caption.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Space.lg),
          FloraTextField(
            controller: label,
            hint: l10n.photoLabelHint,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onSave(),
          ),
          const SizedBox(height: Space.sm),
          ListenableBuilder(
            listenable: label,
            builder: (context, _) {
              final current = label.text.trim();
              return Wrap(
                spacing: Space.xs,
                runSpacing: Space.xs,
                children: [
                  for (final s in suggestions(l10n))
                    FloraChip(
                      label: s,
                      selected: current == s,
                      // Le même titre une seconde fois l'efface : la puce
                      // se comporte comme une case, pas comme un bouton.
                      onTap: () => label.text = current == s ? '' : s,
                    ),
                ],
              );
            },
          ),
          if (makePrimary != null) ...[
            const SizedBox(height: Space.lg),
            FloraGroup(
              children: [
                FloraListRow(
                  leading: Icon(CupertinoIcons.star, size: 20, color: c.sun),
                  title: l10n.setAsMainPhoto,
                  subtitle: l10n.mainPhotoHint,
                  trailing: AdaptiveSwitch(value: makePrimary!, onChanged: onPrimaryChanged),
                ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        FloraButton(label: l10n.save, expand: true, loading: saving, onPressed: onSave),
        const SizedBox(height: Space.xs),
        FloraButton(label: l10n.retake, icon: CupertinoIcons.camera, style: FloraButtonStyle.ghost, expand: true, onPressed: saving ? null : onRetake),
      ],
    );
  }
}

/// Une étape du flow : titre, sous-titre, corps, boutons en bas.
class PhotoFlowStep extends StatelessWidget {
  const PhotoFlowStep({super.key, required this.title, required this.body, required this.actions, this.subtitle, this.scrollable = false});

  final String title;
  final String? subtitle;
  final Widget body;
  final List<Widget> actions;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: Space.lg),
        Text(title, style: context.text.title1),
        if (subtitle != null) ...[const SizedBox(height: Space.xs), Text(subtitle!, style: context.text.callout)],
        const SizedBox(height: Space.xl),
      ],
    );
    final content = scrollable
        ? SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(horizontal: Space.page),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [header, body]),
          )
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.page),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [header, Expanded(child: body)]),
          );
    return Column(
      children: [
        Expanded(child: content),
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.page, Space.md, Space.page, Space.md),
          child: Column(mainAxisSize: MainAxisSize.min, children: actions),
        ),
      ],
    );
  }
}
