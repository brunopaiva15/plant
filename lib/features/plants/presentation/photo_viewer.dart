import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models/models.dart';
import '../../sharing/presentation/share_link_sheet.dart';
import '../application/plant_providers.dart';
import 'photo_sheets.dart';

/// Le nom du héros d'une photo, partagé entre la vignette de départ et la
/// page de la visionneuse. Deux vignettes de la même photo sur un même écran
/// — la bande Croissance et le journal de la fiche — se distinguent par le
/// préfixe, sans quoi Flutter refuserait le vol.
typedef PhotoHeroTag = String Function(PlantPhoto photo);

String defaultPhotoHeroTag(PlantPhoto photo) => 'photo-${photo.id}';

/// Ouvre une photo en plein écran, à partir de [photoId].
///
/// [photos] et [primaryId] servent de première image : la visionneuse
/// s'abonne ensuite aux photos de la plante, si bien qu'une suppression ou
/// un changement de photo principale se voient sans la refermer.
Future<void> showPhotoViewer(
  BuildContext context, {
  required String plantId,
  required String photoId,
  required List<PlantPhoto> photos,
  String? primaryId,
  PhotoHeroTag heroTag = defaultPhotoHeroTag,
}) {
  Haptics.light();
  return Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      opaque: false,
      transitionDuration: Motion.of(context, Motion.emphasis),
      reverseTransitionDuration: Motion.of(context, Motion.standard),
      pageBuilder: (_, anim, _) => FadeTransition(
        opacity: anim,
        child: PhotoViewer(plantId: plantId, photoId: photoId, photos: photos, primaryId: primaryId, heroTag: heroTag),
      ),
    ),
  );
}

/// La visionneuse : une photo à la fois, en noir.
///
/// Les gestes sont ceux qu'on connaît de toutes les galeries : glisser à
/// gauche ou à droite pour passer à la suivante, pincer ou toucher deux fois
/// pour agrandir, tirer vers le bas pour refermer, toucher pour cacher ou
/// montrer ce qui entoure la photo. Avant, toucher la photo la refermait, et
/// tout ce qu'on pouvait en faire tenait derrière trois points.
///
/// Ce qui l'entoure : le compte en haut, et en bas la date, le titre — qui
/// s'écrit là, sans menu — et les quatre gestes nommés : titre, principale,
/// partager, supprimer.
class PhotoViewer extends ConsumerStatefulWidget {
  const PhotoViewer({super.key, required this.plantId, required this.photoId, required this.photos, this.primaryId, this.heroTag = defaultPhotoHeroTag});

  final String plantId;
  final String photoId;
  final List<PlantPhoto> photos;
  final String? primaryId;
  final PhotoHeroTag heroTag;

  @override
  ConsumerState<PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends ConsumerState<PhotoViewer> with SingleTickerProviderStateMixin {
  late final int _initialIndex = widget.photos.indexWhere((p) => p.id == widget.photoId).clamp(0, widget.photos.length - 1);
  late final _page = PageController(initialPage: _initialIndex);
  late int _index = _initialIndex;
  final _transforms = <String, TransformationController>{};
  bool _chrome = true;
  bool _zoomed = false;

  /// Le déplacement du doigt qui tire la photo vers le bas.
  double _drag = 0;

  /// D'où la photo repart quand on la lâche trop tôt.
  double _released = 0;
  late final _spring = AnimationController(vsync: this, duration: Motion.standard);
  Offset? _doubleTapAt;

  /// Au-delà, lâcher referme.
  static const double _dismissDistance = 120;
  static const double _dismissVelocity = 700;
  static const double _doubleTapScale = 2.5;

  @override
  void initState() {
    super.initState();
    _spring.addListener(() => setState(() => _drag = _released * (1 - Motion.easeOut.transform(_spring.value))));
  }

  @override
  void dispose() {
    _page.dispose();
    _spring.dispose();
    for (final t in _transforms.values) {
      t.dispose();
    }
    super.dispose();
  }

  TransformationController _transformOf(PlantPhoto photo) => _transforms.putIfAbsent(photo.id, () {
        final t = TransformationController();
        t.addListener(() {
          final zoomed = t.value.getMaxScaleOnAxis() > 1.01;
          if (zoomed != _zoomed) setState(() => _zoomed = zoomed);
        });
        return t;
      });

  List<PlantPhoto> get _photos => ref.watch(plantPhotosProvider(widget.plantId)).value ?? widget.photos;

  String? get _primaryId {
    final summary = ref.watch(plantSummaryProvider(widget.plantId)).value;
    return summary == null ? widget.primaryId : summary.plant.primaryPhotoId;
  }

  void _close() => Navigator.of(context).pop();

  // — Gestes —

  void _onDragUpdate(DragUpdateDetails d) {
    if (_zoomed) return;
    setState(() {
      _drag += d.delta.dy;
      if (_chrome) _chrome = false;
    });
  }

  void _onDragEnd(DragEndDetails d) {
    if (_zoomed) return;
    if (_drag.abs() > _dismissDistance || d.primaryVelocity != null && d.primaryVelocity!.abs() > _dismissVelocity) {
      _close();
      return;
    }
    _released = _drag;
    _spring
      ..reset()
      ..forward().whenComplete(() {
        if (mounted) setState(() => _chrome = true);
      });
  }

  void _onDoubleTap(PlantPhoto photo, Size size) {
    final t = _transformOf(photo);
    if (t.value.getMaxScaleOnAxis() > 1.01) {
      t.value = Matrix4.identity();
      return;
    }
    // Agrandir autour du point touché, pas du centre de l'écran : c'est la
    // feuille qu'on regarde qui doit grossir sous le doigt.
    final at = _doubleTapAt ?? size.center(Offset.zero);
    t.value = Matrix4.identity()
      ..translateByDouble(-at.dx * (_doubleTapScale - 1), -at.dy * (_doubleTapScale - 1), 0, 1)
      ..scaleByDouble(_doubleTapScale, _doubleTapScale, 1, 1);
  }

  // — Actions —

  Future<void> _editLabel(PlantPhoto photo) async {
    final label = await showPhotoLabelSheet(context, initial: photo.label);
    if (label == null) return;
    await ref.read(photoRepositoryProvider).setLabel(photo.id, label.isEmpty ? null : label);
    Haptics.success();
  }

  Future<void> _setPrimary(PlantPhoto photo) async {
    await ref.read(photoRepositoryProvider).setPrimary(widget.plantId, photo.id);
    Haptics.success();
    if (mounted) ref.read(toastProvider.notifier).show(ToastData(message: context.l10n.mainPhotoSet, emoji: '⭐'));
  }

  Future<void> _share(PlantPhoto photo) => showShareLinkSheet(context, plantId: widget.plantId, photoId: photo.id, suggestedTitle: photo.label);

  Future<void> _delete(PlantPhoto photo, int count) async {
    final l10n = context.l10n;
    final ok = await showAdaptiveConfirm(context, title: l10n.confirmDeletePhoto, confirmLabel: l10n.delete, cancelLabel: l10n.cancel, destructive: true);
    if (!ok || !mounted) return;
    await ref.read(photoRepositoryProvider).delete(photo.id);
    // Une photo distante n'a pas de fichier local à effacer.
    if (!photo.isRemote) await ref.read(photoStorageProvider).deleteFiles(photo.filePath, photo.thumbPath);
    Haptics.warning();
    if (!mounted) return;
    // La dernière photo partie, il n'y a plus rien à regarder ; sinon la
    // voisine prend la place, et la liste vivante fera le reste.
    if (count <= 1) {
      _close();
    } else if (_index >= count - 1) {
      setState(() => _index = count - 2);
      _page.jumpToPage(_index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final photos = _photos;
    if (photos.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _close();
      });
      return const SizedBox.shrink();
    }
    final index = _index.clamp(0, photos.length - 1);
    final photo = photos[index];
    final isPrimary = _primaryId == photo.id;
    final progress = (_drag.abs() / 300).clamp(0.0, 0.6);
    final size = MediaQuery.sizeOf(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Le noir s'éclaircit à mesure qu'on tire : l'écran d'en dessous
          // revient, et le geste dit ce qu'il va faire avant de le faire.
          ColoredBox(color: Colors.black.withValues(alpha: 1 - progress)),
          Transform.translate(
            offset: Offset(0, _drag),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _chrome = !_chrome),
              onDoubleTapDown: (d) => _doubleTapAt = d.localPosition,
              onDoubleTap: () => _onDoubleTap(photo, size),
              onVerticalDragUpdate: _zoomed ? null : _onDragUpdate,
              onVerticalDragEnd: _zoomed ? null : _onDragEnd,
              child: PageView.builder(
                controller: _page,
                // Agrandie, la photo se déplace sous le doigt : le glissement
                // de page attendra qu'on la relâche à sa taille.
                physics: _zoomed ? const NeverScrollableScrollPhysics() : const PageScrollPhysics(),
                itemCount: photos.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => _Page(photo: photos[i], transform: _transformOf(photos[i]), heroTag: widget.heroTag),
              ),
            ),
          ),
          _Chrome(
            visible: _chrome,
            top: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(Space.sm),
                child: Row(
                  children: [
                    FloraIconButton(icon: CupertinoIcons.xmark, semanticLabel: l10n.close, onPressed: _close, background: Colors.white24, color: Colors.white),
                    Expanded(
                      child: Text(
                        l10n.photoCounter(index + 1, photos.length),
                        textAlign: TextAlign.center,
                        style: context.text.callout.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
            ),
            bottom: _Caption(
              photo: photo,
              isPrimary: isPrimary,
              onEditLabel: () => _editLabel(photo),
              onSetPrimary: isPrimary ? null : () => _setPrimary(photo),
              onShare: () => _share(photo),
              onDelete: () => _delete(photo, photos.length),
            ),
          ),
        ],
      ),
    );
  }
}

/// Une page de la visionneuse : la photo, contenue dans l'écran, qu'on peut
/// agrandir.
class _Page extends ConsumerWidget {
  const _Page({required this.photo, required this.transform, required this.heroTag});

  final PlantPhoto photo;
  final TransformationController transform;
  final PhotoHeroTag heroTag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = ref.watch(photoStorageProvider);
    return InteractiveViewer(
      transformationController: transform,
      minScale: 1,
      maxScale: 4,
      // Le héros occupe tout l'écran, la photo est contenue dedans : la
      // vignette de départ grandit jusqu'à la page entière.
      child: PlantHero(
        tag: heroTag(photo),
        child: SizedBox.expand(
          child: photo.isRemote
              ? Image.network(
                  photo.remoteUrl!,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Icon(CupertinoIcons.link, color: Colors.white54, size: 48),
                )
              : FutureBuilder<String>(
                  future: storage.absolutePath(photo.filePath),
                  builder: (context, snap) => snap.hasData ? Image.file(File(snap.data!), fit: BoxFit.contain, gaplessPlayback: true) : const SizedBox.expand(),
                ),
        ),
      ),
    );
  }
}

/// Ce qui entoure la photo, et qui s'efface d'un toucher.
class _Chrome extends StatelessWidget {
  const _Chrome({required this.visible, required this.top, required this.bottom});

  final bool visible;
  final Widget top;
  final Widget bottom;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: Motion.of(context, Motion.standard),
        curve: Motion.easeOut,
        child: Column(
          children: [
            top,
            const Spacer(),
            bottom,
          ],
        ),
      ),
    );
  }
}

/// Le bas de la visionneuse : la date, le titre, les quatre gestes nommés.
class _Caption extends StatelessWidget {
  const _Caption({
    required this.photo,
    required this.isPrimary,
    required this.onEditLabel,
    required this.onSetPrimary,
    required this.onShare,
    required this.onDelete,
  });

  final PlantPhoto photo;
  final bool isPrimary;
  final VoidCallback onEditLabel;

  /// Nul quand c'est déjà la principale : l'étoile est pleine et n'attend
  /// plus rien.
  final VoidCallback? onSetPrimary;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  /// Un rouge clair, lisible sur le noir. La palette du thème est pensée
  /// pour le papier crème ou la terre sombre, pas pour ce fond-ci.
  static const _danger = Color(0xFFF08A7A);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final label = photo.label;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x00000000), Color(0xB3000000)],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Space.page, Space.xl, Space.page, Space.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avec l'année : dans un suivi de croissance, c'est elle qui
              // compte, et une photo de l'an dernier doit le dire.
              Text(Dates.dayYear(context, photo.takenAt), style: context.text.title3.copyWith(color: Colors.white)),
              const SizedBox(height: 2),
              // Le titre s'écrit ici : le texte est le bouton. Sans titre,
              // l'invite prend sa place, en retrait.
              Pressable(
                onTap: onEditLabel,
                scale: 0.98,
                semanticLabel: l10n.photoLabel,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        label ?? l10n.addTitle,
                        style: context.text.callout.copyWith(color: label == null ? Colors.white54 : Colors.white70),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(CupertinoIcons.pencil, size: 14, color: Colors.white54),
                  ],
                ),
              ),
              const SizedBox(height: Space.md),
              Row(
                children: [
                  _Action(icon: CupertinoIcons.textformat, label: l10n.photoTitleShort, onTap: onEditLabel),
                  _Action(
                    icon: isPrimary ? CupertinoIcons.star_fill : CupertinoIcons.star,
                    label: l10n.mainPhotoShort,
                    color: isPrimary ? const Color(0xFFF2C94C) : Colors.white,
                    onTap: onSetPrimary,
                  ),
                  _Action(icon: CupertinoIcons.link, label: l10n.share, onTap: onShare),
                  _Action(icon: CupertinoIcons.trash, label: l10n.delete, color: _danger, onTap: onDelete),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Un geste de la visionneuse : l'icône dans un rond, le mot dessous.
class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.label, required this.onTap, this.color = Colors.white});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final column = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(height: Space.xxs),
        Text(label, style: context.text.caption.copyWith(color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
    // Sans geste — la principale qui l'est déjà —, ce n'est plus un bouton
    // mais un état : il se lit en pleine clarté, et VoiceOver ne promet
    // aucune action.
    if (onTap == null) return Expanded(child: Semantics(label: label, child: column));
    return Expanded(child: Pressable(onTap: onTap, scale: 0.92, semanticLabel: label, child: column));
  }
}
