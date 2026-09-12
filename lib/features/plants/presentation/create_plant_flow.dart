import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/config/app_config.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/observability/observability.dart';
import '../../../data/services/photo_storage_service.dart';
import '../../../domain/identification/cascade_identifier.dart';
import '../../../domain/identification/plant_identifier.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models/models.dart';
import '../../../domain/repositories/repositories.dart';
import '../../locations/presentation/location_edit_sheet.dart';
import '../../locations/presentation/location_picker_sheet.dart';
import '../../../domain/identification/identification_policy.dart';
import '../../identification/presentation/identification_photos.dart';
import '../../identification/presentation/identification_sheet.dart';
import '../../account/application/membership_providers.dart';
import '../../../core/l10n/care_labels.dart';
import '../../../domain/care/care_guide.dart';
import '../../species/presentation/species_field.dart';
import 'inline_camera.dart';

/// Lance le flow de création (3 étapes) et ouvre la fiche de la plante créée.
Future<void> startCreatePlantFlow(BuildContext context, WidgetRef ref, {String? parentPlantId, String? parentName, String? speciesName, String? locationId}) async {
  final l10n = context.l10n;
  if (!ref.read(canEditProvider)) {
    ref.read(toastProvider.notifier).show(ToastData(message: l10n.readOnlyHint, emoji: '🔒'));
    return;
  }
  final plantId = await showFloraFlow<String>(
    context,
    builder: (ctx) => CreatePlantFlow(parentPlantId: parentPlantId, parentName: parentName, speciesName: speciesName, initialLocationId: locationId),
  );
  if (plantId != null && context.mounted) {
    context.push(Routes.plant(plantId));
  }
}

class CreatePlantFlow extends ConsumerStatefulWidget {
  const CreatePlantFlow({super.key, this.parentPlantId, this.parentName, this.speciesName, this.initialLocationId});

  final String? parentPlantId;
  final String? parentName;

  /// Espèce déjà connue : celle de la plante mère pour une bouture, celle
  /// retenue dans « Trouver une plante ». L'utilisateur peut la corriger.
  final String? speciesName;
  final String? initialLocationId;

  @override
  ConsumerState<CreatePlantFlow> createState() => _CreatePlantFlowState();
}

class _CreatePlantFlowState extends ConsumerState<CreatePlantFlow> {
  final _page = PageController();

  /// Le viseur de la première étape. Il ne tourne que là, et seulement tant
  /// qu'il reste une case libre : il ne s'éteint plus à la première photo,
  /// c'est ce qui permet d'en prendre deux ou trois à la file.
  final _camera = InlineCameraController();
  int _step = 0;
  StoredPhoto? _photo;

  /// Où en est l'étape photo : on vise, on regarde la photo prise, ou on
  /// vise une vue de plus pour un emplacement précis.
  _PhotoMode _mode = _PhotoMode.aim;
  bool _picking = false;
  bool _saving = false;
  Future<List<IdentificationCandidate>>? _identification;

  /// Photos prises en plus, seulement pour lever un doute d'identification.
  /// Ce ne sont pas des photos de la plante : elles s'effacent en partant,
  /// que la création aboutisse ou non.
  final _identificationExtras = <StoredPhoto>[];

  /// Chemins absolus envoyés au moteur : la photo de la plante, puis les
  /// autres. Le moteur les fusionne par moyenne géométrique — l'espèce que
  /// toutes les photos voient remonte, celle qui ne tenait qu'à un cliché
  /// ambigu redescend.
  final _identificationPaths = <String>[];

  /// Au-delà, une photo de plus n'apporte plus grand-chose.
  static const int maxIdentificationPhotos = 3;

  late final _name = TextEditingController(text: widget.parentName == null ? '' : context.l10n.cuttingOf(widget.parentName!));
  final _species = TextEditingController();
  final _notes = TextEditingController();
  DateTime? _acquiredAt;
  int _watering = AppConfig.defaultWateringInterval;
  int _fertilizing = AppConfig.defaultFertilizingInterval;

  /// Vrai dès que l'utilisateur règle un intervalle à la main : la fiche
  /// d'entretien ne doit plus écraser son choix.
  bool _intervalsTouched = false;
  bool _more = false;
  late String? _locationId = widget.initialLocationId;
  bool _noLocation = false;

  @override
  void initState() {
    super.initState();
    // Le flux s'ouvre tout de suite : la première étape est celle de la photo,
    // et l'aperçu doit y être avant que l'utilisateur ne pense à viser.
    _camera.start();
    // L'espèce est déjà connue (bouture, proposition retenue) : elle apporte
    // avec elle le rythme de soins conseillé par sa fiche.
    final inherited = widget.speciesName?.trim() ?? '';
    if (inherited.isEmpty) return;
    _species.text = inherited;
    final care = ref.read(careGuideProvider).resolve(inherited, family: speciesFamilyOf(ref, inherited));
    _watering = care.profile.wateringDaysFor(DateTime.now().month, south: ref.read(southernHemisphereProvider));
    _fertilizing = care.profile.fertilizingDays ?? 0;
  }

  @override
  void dispose() {
    _camera.dispose();
    _page.dispose();
    _name.dispose();
    _species.dispose();
    _notes.dispose();
    _dropIdentificationExtras();
    super.dispose();
  }

  /// Efface les photos prises pour identifier. Appelée en partant, et à
  /// chaque nouvelle photo de plante : les anciennes ne montrent alors plus
  /// le bon sujet.
  void _dropIdentificationExtras() {
    if (_identificationExtras.isEmpty) return;
    final storage = ref.read(photoStorageProvider);
    for (final p in _identificationExtras) {
      storage.deleteFiles(p.filePath, p.thumbPath);
    }
    _identificationExtras.clear();
  }

  void _go(int step) {
    Haptics.selection();
    // Le clavier de l'étape du nom ne doit pas suivre : ouvert, il écrase la
    // mise en page des autres étapes (l'aperçu photo notamment).
    if (step != 1) FocusManager.instance.primaryFocus?.unfocus();
    // Le viseur n'a de raison de tourner qu'à l'étape photo, et seulement
    // tant qu'il reste de la place : ailleurs, il ne ferait que tenir la
    // caméra et vider la batterie. Il ne s'éteint plus à la première photo —
    // c'est ce qui permet d'en prendre deux ou trois à la file.
    if (step == 0 && _identificationPaths.length < maxIdentificationPhotos) {
      _camera.start();
    } else {
      _camera.stop();
    }
    setState(() => _step = step);
    _page.animateToPage(step, duration: Motion.of(context, Motion.emphasis), curve: Motion.emphasized);
    // En arrivant à l'étape du nom, le moteur reçoit toutes les photos d'un
    // coup — et une seule fois : revenir en arrière puis repasser ici ne
    // relance rien tant que les photos n'ont pas changé.
    if (step == 1 && _identification == null) _startIdentification();
  }

  /// Ouvre l'appareil photo ou la galerie du système. Le viseur intégré a
  /// pris la place du premier cas courant ; celui-ci reste pour la galerie,
  /// et pour les appareils qui n'offrent pas d'aperçu.
  Future<void> _pick(PhotoSource source) async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final stored = await ref.read(photoStorageProvider).pick(source);
      if (stored == null || !mounted) return;
      await _accept(stored);
    } catch (e, st) {
      ref.read(crashReporterProvider).report(e, st, context: 'createPlant.pick');
      if (mounted) ref.read(toastProvider.notifier).show(ToastData(message: context.l10n.photoError, emoji: '!'));
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  /// Déclenche depuis le viseur intégré : un seul geste, sans passer par
  /// l'appareil photo du système. Si le viseur n'a pas pu s'ouvrir — refus,
  /// appareil sans caméra — le bouton retrouve son ancien geste.
  Future<void> _capture() async {
    if (_picking) return;
    if (!_camera.isReady) return _pick(PhotoSource.camera);
    setState(() => _picking = true);
    final shot = await _camera.capture();
    if (shot == null) {
      // Le déclencheur n'a rien donné : plutôt qu'un bouton sans effet,
      // l'appareil photo du système prend le relais.
      if (!mounted) return;
      setState(() => _picking = false);
      return _pick(PhotoSource.camera);
    }
    try {
      final stored = await ref.read(photoStorageProvider).importFile(shot);
      if (mounted) await _accept(stored);
    } catch (e, st) {
      ref.read(crashReporterProvider).report(e, st, context: 'createPlant.capture');
      if (mounted) ref.read(toastProvider.notifier).show(ToastData(message: context.l10n.photoError, emoji: '!'));
    } finally {
      // Le fichier brut du plugin a servi : la copie compressée le remplace,
      // et le dossier temporaire n'a pas à garder de pleine résolution.
      try {
        await shot.delete();
      } catch (_) {}
      if (mounted) setState(() => _picking = false);
    }
  }

  /// Retient une photo, sans quitter l'étape, et la montre : la première est
  /// celle de la plante, les suivantes des vues pour l'identification.
  Future<void> _accept(StoredPhoto stored) async {
    final storage = ref.read(photoStorageProvider);
    final path = await storage.absolutePath(stored.filePath);
    if (!mounted) return;
    setState(() {
      if (_photo == null) {
        _photo = stored;
      } else {
        _identificationExtras.add(stored);
      }
      _identificationPaths.add(path);
      // Les photos ont changé : la réponse d'avant ne vaut plus, et la
      // suivante se demandera en arrivant à l'étape du nom.
      _identification = null;
      // Le cadre montre ce qu'on vient de prendre : c'est la confirmation.
      _mode = _PhotoMode.review;
    });
    // Plus d'emplacement libre : le viseur n'a plus rien à faire.
    if (_identificationPaths.length >= maxIdentificationPhotos) _camera.stop();
    Haptics.success();
  }

  /// Reprendre : la photo de la plante part, et avec elle les vues prises
  /// pour la reconnaître, qui montraient le même sujet. Retour au viseur.
  Future<void> _retake() async {
    final storage = ref.read(photoStorageProvider);
    final old = _photo;
    _dropIdentificationExtras();
    setState(() {
      _photo = null;
      _identificationPaths.clear();
      _identification = null;
      _mode = _PhotoMode.aim;
    });
    _camera.start();
    if (old != null) await storage.deleteFiles(old.filePath, old.thumbPath);
  }

  /// Une vue de plus, pour l'emplacement touché. Avec le viseur, le cadre
  /// repasse en direct ; sans lui, l'appareil ou la galerie du système.
  void _openExtraSlot() {
    if (_picking || _identificationPaths.length >= maxIdentificationPhotos) return;
    if (_camera.hasViewfinder) {
      Haptics.selection();
      setState(() => _mode = _PhotoMode.extra);
      return;
    }
    _showPhotoSources();
  }

  void _cancelExtra() {
    Haptics.selection();
    setState(() => _mode = _PhotoMode.review);
  }

  /// Identification en arrière-plan, sur **toutes** les photos de l'étape
  /// d'avant, en arrivant à l'étape du nom. Les suggestions y apparaissent
  /// sans étape supplémentaire.
  ///
  /// Une seule passe, avec tout ce qu'on a : deux photos valent 13,7 points
  /// de top-1 et trois en valent 22,4 (docs/09 § 6.7). Les demander d'abord
  /// et répondre ensuite vaut mieux que répondre sur une seule photo, puis
  /// se corriger.
  void _startIdentification() {
    final identifier = ref.read(plantIdentifierProvider);
    if (!identifier.isConfigured || _identificationPaths.isEmpty) return;
    final lang = _identificationLanguage;
    setState(() {
      _identification = identifier
          .identify([for (final p in _identificationPaths) File(p)], language: lang)
          .catchError((_) => <IdentificationCandidate>[]);
    });
  }

  /// Le modèle hésite-t-il ? La politique de la cascade le dit, celle-là
  /// même qui décide d'appeler ou non le service distant.
  SecondPhotoOffer _identificationOffer(List<IdentificationCandidate> results) {
    final identifier = ref.read(plantIdentifierProvider);
    if (identifier is! CascadeIdentifier) return SecondPhotoOffer.none;
    return secondPhotoOffer(identifier.policy, results,
        photos: _identificationPaths.length, maxPhotos: maxIdentificationPhotos);
  }

  /// Une photo de plus pour trancher. Gratuite, hors ligne et immédiate, là
  /// où la recherche en ligne se prend sur un quota mensuel.
  Future<void> _addIdentificationPhoto(PhotoSource source) async {
    final identifier = ref.read(plantIdentifierProvider);
    if (_picking || !identifier.isConfigured || _identificationPaths.isEmpty) return;
    setState(() => _picking = true);
    try {
      final stored = await ref.read(photoStorageProvider).pick(source);
      if (stored == null) return;
      await _acceptIdentificationPhoto(stored);
    } catch (e, st) {
      ref.read(crashReporterProvider).report(e, st, context: 'createPlant.identifyMore');
      if (mounted) ref.read(toastProvider.notifier).show(ToastData(message: context.l10n.photoError, emoji: '!'));
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  /// Retirer une photo prise pour identifier, et recommencer sans elle.
  ///
  /// La fusion par moyenne géométrique **exige que les photos soient
  /// d'accord** : un cliché raté tire le résultat vers le bas au lieu de
  /// l'affiner. Le rang zéro est la photo de la plante : elle reste, c'est
  /// l'étape d'avant qui la change.
  Future<void> _removeIdentificationPhoto(int index) async {
    if (_picking || index <= 0 || index >= _identificationPaths.length) return;
    final stored = _identificationExtras.removeAt(index - 1);
    final storage = ref.read(photoStorageProvider);
    setState(() => _identificationPaths.removeAt(index));
    // À l'étape photo, rien n'a encore été demandé au moteur : il n'y a rien
    // à relancer, seulement une case qui se libère — et le viseur qui peut
    // reprendre pour la remplir.
    if (_identification != null) _startIdentification();
    if (_step == 0) _camera.start();
    await storage.deleteFiles(stored.filePath, stored.thumbPath);
  }

  /// Range une photo d'identification de plus et relance le moteur.
  Future<void> _acceptIdentificationPhoto(StoredPhoto stored) async {
    final path = await ref.read(photoStorageProvider).absolutePath(stored.filePath);
    if (!mounted) return;
    setState(() {
      _identificationExtras.add(stored);
      _identificationPaths.add(path);
    });
    _startIdentification();
  }

  void _chooseIdentificationSource() {
    final l10n = context.l10n;
    showAdaptiveActionSheet(
      context,
      cancelLabel: l10n.cancel,
      actions: [
        SheetAction(label: l10n.camera, icon: CupertinoIcons.camera, onPressed: () => _addIdentificationPhoto(PhotoSource.camera)),
        SheetAction(label: l10n.gallery, icon: CupertinoIcons.photo, onPressed: () => _addIdentificationPhoto(PhotoSource.gallery)),
      ],
    );
  }

  String get _identificationLanguage =>
      ref.read(preferencesProvider).locale?.languageCode ?? WidgetsBinding.instance.platformDispatcher.locale.languageCode;

  /// Le service en ligne est-il utilisable ? Sans clé, ou repli coupé, le
  /// bouton n'aurait rien à proposer.
  bool get _canSearchOnline {
    final identifier = ref.read(plantIdentifierProvider);
    return identifier is CascadeIdentifier && identifier.fallbackEnabled && identifier.fallback.isConfigured && identifier.remoteAllowedThisMonth;
  }

  /// Relance la recherche en ligne, parce qu'aucune proposition de
  /// l'appareil ne convenait. L'appel n'a lieu que sur ce geste.
  void _searchOnline() {
    final identifier = ref.read(plantIdentifierProvider);
    if (identifier is! CascadeIdentifier || _identificationPaths.isEmpty) return;
    final lang = _identificationLanguage;
    setState(() {
      // Toutes les photos partent : le quota se compte à l'appel, pas à
      // l'image, et Pl@ntNet en accepte plusieurs.
      _identification = identifier
          .identifyRemotely([for (final p in _identificationPaths) File(p)], language: lang)
          .catchError((_) => <IdentificationCandidate>[]);
    });
  }

  /// Reprend les intervalles conseillés par la fiche d'entretien de l'espèce,
  /// tant que l'utilisateur ne les a pas réglés lui-même.
  void _applyCareProfile(String scientificName, {String? family}) {
    final care = ref.read(careGuideProvider).resolve(scientificName, family: family);
    setState(() {
      if (_intervalsTouched) return;
      _watering = care.profile.wateringDaysFor(DateTime.now().month, south: ref.read(southernHemisphereProvider));
      _fertilizing = care.profile.fertilizingDays ?? 0;
    });
  }

  Future<void> _cancel() async {
    if (_photo != null) await ref.read(photoStorageProvider).deleteFiles(_photo!.filePath, _photo!.thumbPath);
    if (mounted) Navigator.of(context, rootNavigator: true).pop();
  }

  Future<void> _finish() async {
    final name = _name.text.trim();
    if (name.isEmpty || _saving) return;
    setState(() => _saving = true);
    final l10n = context.l10n;
    final plant = await ref.read(plantRepositoryProvider).create(NewPlant(
          name: name,
          speciesName: _species.text,
          locationId: _noLocation ? null : _locationId,
          acquiredAt: _acquiredAt,
          notes: _notes.text,
          parentPlantId: widget.parentPlantId,
          wateringIntervalDays: _watering,
          fertilizingIntervalDays: _fertilizing,
        ));
    // Bouture : la fille hérite des champs personnalisés de la plante mère.
    if (widget.parentPlantId != null) {
      await ref.read(attributeRepositoryProvider).cloneAttributes(fromPlantId: widget.parentPlantId!, toPlantId: plant.id);
    }
    if (_photo != null) {
      final photo = await ref.read(photoRepositoryProvider).add(
            plantId: plant.id,
            filePath: _photo!.filePath,
            thumbPath: _photo!.thumbPath,
            width: _photo!.width,
            height: _photo!.height,
            takenAt: _photo!.takenAt,
          );
      await ref.read(actionRepositoryProvider).log(NewAction(plantId: plant.id, typeKey: CareKind.photo.key, photoId: photo.id));
    }
    ref.read(analyticsProvider).track(AnalyticsEvents.plantCreated, {'with_photo': _photo != null});
    Haptics.success();
    ref.read(toastProvider.notifier).show(ToastData(message: l10n.plantAdded(plant.name), emoji: '🌱'));
    if (mounted) Navigator.of(context, rootNavigator: true).pop(plant.id);
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
                    onPressed: () => _step == 0 ? _cancel() : _go(_step - 1),
                  ),
                  const Spacer(),
                  StepDots(count: 3, index: _step),
                  const Spacer(),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _page,
                physics: const NeverScrollableScrollPhysics(),
                children: [_photoStep(), _nameStep(), _locationStep()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// L'étape photo, en trois états qui se lisent d'un coup d'œil.
  ///
  /// **Viser** : le viseur est dans le cadre, le déclencheur rond posé
  /// dessus, la galerie dans un coin. Rien à chercher ailleurs.
  /// **On la garde ?** : la photo prise remplit le cadre — c'est la confirmation —,
  /// et dessous, des emplacements qui disent quoi photographier de plus pour
  /// aider Iris.
  /// **Une vue de plus** : le viseur revient pour l'emplacement touché, avec
  /// son titre, et rend la main dès la prise.
  ///
  /// Avant, le viseur restait devant la photo prise, qui n'apparaissait
  /// qu'en vignette ; trois cases égales ne disaient ni laquelle était la
  /// photo de la plante, ni à quoi servaient les autres.
  Widget _photoStep() {
    final l10n = context.l10n;
    final identifier = ref.watch(plantIdentifierProvider);
    final taken = _identificationPaths.length;
    final full = taken >= maxIdentificationPhotos;
    final hints = [l10n.viewLeafClose, l10n.viewAnother];
    final extraIndex = _identificationExtras.length;
    return ListenableBuilder(
      listenable: _camera,
      builder: (context, _) {
        // La mise en page suit le viseur, présent ou en train de revenir ;
        // seul l'aperçu lui-même attend d'être prêt.
        final live = _camera.hasViewfinder;
        final (title, subtitle) = switch (_mode) {
          _PhotoMode.aim => (l10n.stepPhotoTitle, l10n.stepPhotoSubtitle),
          _PhotoMode.review => (
              l10n.stepPhotoDoneTitle,
              identifier.isConfigured && !full ? l10n.stepPhotoDoneSubtitle(AppConfig.modelName) : l10n.stepPhotoDonePlain,
            ),
          _PhotoMode.extra => (hints[extraIndex.clamp(0, hints.length - 1)], l10n.viewForModel(AppConfig.modelName)),
        };
        return _StepLayout(
          title: title,
          subtitle: subtitle,
          body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: AspectRatio(
                  aspectRatio: 4 / 5,
                  child: AnimatedSwitcher(
                    duration: Motion.of(context, Motion.standard),
                    // La pile du fondu doit remplir le cadre : lâche, elle
                    // laisserait l'invite flotter au milieu et la photo
                    // prise reprendre son propre format.
                    layoutBuilder: (current, previous) => Stack(fit: StackFit.expand, children: [...previous, ?current]),
                    child: KeyedSubtree(key: ValueKey(_mode == _PhotoMode.review), child: _photoFrame(live: live)),
                  ),
                ),
              ),
              // Les vues pour l'identification n'ont de sens que si un
              // moteur peut les lire : sans lui, rien n'est proposé.
              if (_mode == _PhotoMode.review && identifier.isConfigured) ...[
                const SizedBox(height: Space.md),
                _ViewsStrip(
                  plantThumb: _photo!.thumbPath,
                  extras: _identificationExtras,
                  hints: hints,
                  onAdd: full ? null : _openExtraSlot,
                  onRemove: _removeIdentificationPhoto,
                ),
              ],
            ],
          ),
          actions: switch (_mode) {
            _PhotoMode.aim => [
                // Le viseur porte son déclencheur : ici, seulement la porte de
                // sortie. Sans viseur, les deux gestes reviennent en boutons.
                if (!live) ...[
                  FloraButton(label: l10n.takePhoto, icon: CupertinoIcons.camera_fill, expand: true, loading: _picking, onPressed: _capture),
                  const SizedBox(height: Space.xs),
                  FloraButton(label: l10n.choosePhoto, icon: CupertinoIcons.photo, style: FloraButtonStyle.secondary, expand: true, onPressed: _picking ? null : () => _pick(PhotoSource.gallery)),
                  const SizedBox(height: Space.xs),
                ],
                FloraButton(label: l10n.withoutPhoto, style: FloraButtonStyle.ghost, expand: true, onPressed: () => _go(1)),
              ],
            _PhotoMode.review => [
                FloraButton(label: l10n.continueLabel, expand: true, onPressed: () => _go(1)),
                const SizedBox(height: Space.xs),
                FloraButton(label: l10n.retake, icon: CupertinoIcons.camera, style: FloraButtonStyle.ghost, expand: true, onPressed: _picking ? null : _retake),
              ],
            _PhotoMode.extra => [
                FloraButton(label: l10n.continueLabel, expand: true, onPressed: () => _go(1)),
                const SizedBox(height: Space.xs),
                FloraButton(label: l10n.cancel, style: FloraButtonStyle.ghost, expand: true, onPressed: _cancelExtra),
              ],
          },
        );
      },
    );
  }

  /// Ce que montre le cadre : la photo prise, ou le viseur avec ses
  /// commandes posées dessus, ou — faute de viseur — l'invite qui mène à
  /// l'appareil photo du système.
  Widget _photoFrame({required bool live}) {
    final l10n = context.l10n;
    final c = context.colors;
    final Widget content;
    if (_mode == _PhotoMode.review) {
      content = PlantImage(relativePath: _photo!.thumbPath, cacheWidth: 900);
    } else if (live) {
      content = Stack(
        fit: StackFit.expand,
        children: [
          // Le flux, ou ce qui le remplace le temps qu'il arrive : la motte
          // pendant l'ouverture, un appareil posé pendant que l'application
          // est derrière. Le cadre et ses commandes ne bougent pas.
          if (_camera.isReady)
            InlineCameraPreview(controller: _camera)
          else if (_camera.status == InlineCameraStatus.starting)
            Center(child: ClayLoader(size: 32, color: c.sage))
          else
            Center(child: Icon(CupertinoIcons.camera, size: 44, color: c.sage)),
          // Le déclencheur, au bas du cadre, comme sur n'importe quel appareil.
          Positioned(
            left: 0,
            right: 0,
            bottom: Space.md,
            child: Center(child: _Shutter(busy: _picking, enabled: _camera.isReady, onTap: _capture)),
          ),
          if (_mode == _PhotoMode.aim)
            Positioned(
              left: Space.md,
              bottom: Space.lg,
              child: FloraIconButton(
                icon: CupertinoIcons.photo,
                semanticLabel: l10n.choosePhoto,
                background: Colors.white.withValues(alpha: 0.85),
                color: c.ink,
                onPressed: _picking ? null : () => _pick(PhotoSource.gallery),
              ),
            ),
          if (_mode == _PhotoMode.extra)
            Positioned(
              top: Space.sm,
              right: Space.sm,
              child: FloraIconButton(
                icon: CupertinoIcons.xmark,
                semanticLabel: l10n.cancel,
                background: Colors.white.withValues(alpha: 0.85),
                color: c.ink,
                onPressed: _cancelExtra,
              ),
            ),
        ],
      );
    } else {
      // Le cadre rétrécit quand la place manque (petit écran) : l'invite se
      // met à l'échelle plutôt que de déborder.
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
              // Sans l'autorisation, l'aperçu ne viendra jamais : le dire
              // ici, là où l'utilisateur attend l'image.
              if (_camera.permissionDenied) ...[
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
    final frame = Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: c.sageSoft, borderRadius: Radii.xlAll),
      child: content,
    );
    // La photo prise ne se touche pas : « Reprendre » est en dessous. Le
    // viseur, lui, se déclenche du doigt ; sans viseur, toucher l'invite
    // ouvre l'appareil photo du système.
    if (_mode == _PhotoMode.review) return frame;
    return Pressable(onTap: live ? (_camera.isReady ? _capture : null) : () => _pick(PhotoSource.camera), scale: 0.98, haptic: false, child: frame);
  }

  /// Les deux sources du système, pour une vue de plus quand le viseur
  /// n'est pas là.
  Future<void> _showPhotoSources() {
    final l10n = context.l10n;
    return showAdaptiveActionSheet(
      context,
      cancelLabel: l10n.cancel,
      actions: [
        SheetAction(label: l10n.takePhoto, icon: CupertinoIcons.camera, onPressed: () => _pick(PhotoSource.camera)),
        SheetAction(label: l10n.choosePhoto, icon: CupertinoIcons.photo, onPressed: () => _pick(PhotoSource.gallery)),
      ],
    );
  }

  Widget _nameStep() {
    final l10n = context.l10n;
    final c = context.colors;
    return _StepLayout(
      title: l10n.stepNameTitle,
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FloraTextField(
            controller: _name,
            hint: l10n.plantNameHint,
            autofocus: _step == 1,
            large: true,
            textInputAction: TextInputAction.next,
            // Une majuscule à la première lettre seulement : « Monstera du
            // salon », pas « Monstera Du Salon ».
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: Space.sm),
          SpeciesField(
            controller: _species,
            onPicked: (s) {
              if (_name.text.trim().isEmpty) _name.text = s.commonName ?? s.scientificName.split(' ').first;
              _applyCareProfile(s.scientificName, family: s.family);
            },
          ),
          _CarePreview(speciesName: _species.text),
          if (_identification != null)
            _IdentificationSuggestions(
              future: _identification!,
              onPick: _applyCandidate,
              onSearchOnline: _canSearchOnline ? _searchOnline : null,
              paths: _identificationPaths,
              // Sans gêne pour `_picking` : retirer les cases libres pendant
              // qu'on prend une photo ferait rétrécir la bande puis revenir.
              // Les deux gestes se gardent eux-mêmes.
              onAddPhoto: _identificationPaths.length < maxIdentificationPhotos ? _chooseIdentificationSource : null,
              onRemovePhoto: _removeIdentificationPhoto,
              offer: _identificationOffer,
            ),
          const SizedBox(height: Space.lg),
          Pressable(
            onTap: () => setState(() => _more = !_more),
            scale: 1,
            child: Row(
              children: [
                Text(l10n.moreOptions, style: context.text.callout.copyWith(color: c.sage, fontWeight: FontWeight.w600)),
                const SizedBox(width: 4),
                AnimatedRotation(turns: _more ? 0.5 : 0, duration: Motion.of(context, Motion.standard), child: Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: c.sage)),
              ],
            ),
          ),
          AnimatedSize(
            duration: Motion.of(context, Motion.standard),
            curve: Motion.easeOut,
            alignment: Alignment.topCenter,
            child: !_more
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: Space.md),
                    child: FloraGroup(
                      children: [
                        FloraListRow(
                          leading: const Text('💧', style: TextStyle(fontSize: 18)),
                          title: l10n.wateringEvery,
                          trailing: QuantityStepper(value: _watering, min: 0, max: 120, label: _watering == 0 ? l10n.none : l10n.daysCount(_watering), onChanged: (v) => setState(() { _watering = v; _intervalsTouched = true; })),
                        ),
                        FloraListRow(
                          leading: const Text('🌱', style: TextStyle(fontSize: 18)),
                          title: l10n.fertilizingEvery,
                          trailing: QuantityStepper(value: _fertilizing, min: 0, max: 365, step: 5, label: _fertilizing == 0 ? l10n.none : l10n.daysCount(_fertilizing), onChanged: (v) => setState(() { _fertilizing = v; _intervalsTouched = true; })),
                        ),
                        FloraListRow(
                          leading: Icon(CupertinoIcons.calendar, size: 20, color: c.inkSecondary),
                          title: l10n.acquiredAt,
                          trailing: Text(_acquiredAt == null ? l10n.none : Dates.dayYear(context, _acquiredAt!), style: context.text.callout.copyWith(color: c.sage, fontWeight: FontWeight.w600)),
                          chevron: false,
                          onTap: () async {
                            final d = await showAdaptiveDatePicker(context, initial: _acquiredAt ?? DateTime.now(), last: DateTime.now(), doneLabel: l10n.done);
                            if (d != null) setState(() => _acquiredAt = d);
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.all(Space.sm),
                          child: FloraTextField(controller: _notes, hint: l10n.notesHint, minLines: 2, maxLines: 5),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
      actions: [
        FloraButton(label: l10n.continueLabel, expand: true, onPressed: _name.text.trim().isEmpty ? null : () => _go(2)),
      ],
    );
  }

  void _applyCandidate(IdentificationCandidate c) {
    setState(() {
      _species.text = c.scientificName;
      if (_name.text.trim().isEmpty) _name.text = c.commonName ?? c.scientificName.split(' ').first;
    });
  }

  Widget _locationStep() {
    final l10n = context.l10n;
    final locations = ref.watch(locationsProvider).value ?? const <Location>[];
    return _StepLayout(
      title: l10n.stepLocationTitle,
      scrollable: true,
      body: LocationChips(
        locations: locations,
        selectedId: _noLocation ? null : _locationId,
        noneSelected: _noLocation,
        onSelect: (id) => setState(() {
          _locationId = id;
          _noLocation = id == null;
        }),
        onCreate: () async {
          final created = await showLocationEditSheet(context);
          if (created != null) {
            setState(() {
              _locationId = created.id;
              _noLocation = false;
            });
          }
        },
      ),
      actions: [
        FloraButton(label: l10n.finish, expand: true, loading: _saving, onPressed: _finish),
      ],
    );
  }
}

class _IdentificationSuggestions extends StatelessWidget {
  const _IdentificationSuggestions({
    required this.future,
    required this.onPick,
    required this.paths,
    this.onSearchOnline,
    this.onAddPhoto,
    this.onRemovePhoto,
    this.offer,
  });

  final Future<List<IdentificationCandidate>> future;
  final ValueChanged<IdentificationCandidate> onPick;

  /// Présent quand une recherche en ligne est possible ; le bouton ne
  /// s'affiche que si la liste vient de l'appareil.
  final VoidCallback? onSearchOnline;

  /// Présent tant qu'une photo de plus est acceptée.
  final VoidCallback? onAddPhoto;

  /// Retirer une photo ajoutée pour identifier. Jamais la première : c'est
  /// la photo de la plante.
  final ValueChanged<int>? onRemovePhoto;

  /// Les photos soumises au moteur, en chemins absolus.
  final List<String> paths;

  /// Faut-il proposer une photo de plus, et sur quel ton ? Décidé par la
  /// cascade, comme dans la fiche d'identification.
  final SecondPhotoOffer Function(List<IdentificationCandidate>)? offer;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FutureBuilder<List<IdentificationCandidate>>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return Padding(
            padding: const EdgeInsets.only(top: Space.sm),
            child: Row(children: [const AdaptiveProgress(), const SizedBox(width: Space.xs), Text(l10n.identifying, style: context.text.caption)]),
          );
        }
        final results = (snap.data ?? const <IdentificationCandidate>[]).take(3).toList();
        if (results.isEmpty) return const SizedBox.shrink();
        final photoOffer = offer?.call(results) ?? SecondPhotoOffer.none;
        // La bande montre ce qui est parti dès qu'il y a plusieurs photos, et
        // la place libre seulement si la cascade en veut une de plus. Le
        // compte n'est plus écrit — « · 2 photos » disait l'état sans jamais
        // dire le geste ; deux vignettes et une case vide disent les deux.
        final showStrip = paths.length > 1 || photoOffer != SecondPhotoOffer.none;
        return Padding(
          padding: const EdgeInsets.only(top: Space.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // D'où viennent ces noms : l'utilisateur a le droit de savoir si
              // sa photo est partie sur le réseau, et de le demander sinon.
              Text(
                switch (results.first.source) {
                  IdentificationSource.local => l10n.suggestionsLocal,
                  IdentificationSource.remote => l10n.suggestionsRemote,
                  IdentificationSource.unknown => l10n.identifyHint,
                },
                style: context.text.caption,
              ),
              if (showStrip) ...[
                const SizedBox(height: Space.xs),
                IdentificationPhotoStrip(
                  paths: paths,
                  maxPhotos: _CreatePlantFlowState.maxIdentificationPhotos,
                  onAdd: photoOffer == SecondPhotoOffer.none ? null : onAddPhoto,
                  onRemove: onRemovePhoto,
                ),
                // Le modèle hésite : la photo est le geste qui tranche, et il
                // vaut la phrase qui dit quoi photographier.
                if (photoOffer == SecondPhotoOffer.prominent) ...[
                  const SizedBox(height: Space.xs),
                  Text(l10n.identifyAnotherPhotoHint, style: context.text.caption),
                ],
              ],
              const SizedBox(height: Space.xs),
              FloraGroup(children: [for (final c in results) CandidateRow(candidate: c, onUse: () => onPick(c))]),
              // La photo d'abord, l'appel réseau ensuite : l'une est gratuite
              // et immédiate, l'autre se prend sur un quota mensuel. Le geste
              // gratuit est donc au-dessus de la liste, dans la bande, et
              // celui qui se paie reste ici-bas.
              if (results.first.source == IdentificationSource.local && onSearchOnline != null) ...[
                const SizedBox(height: Space.sm),
                FloraButton(label: l10n.searchOnline, style: FloraButtonStyle.ghost, size: FloraButtonSize.small, onPressed: onSearchOnline),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Les trois états de l'étape photo.
enum _PhotoMode { aim, review, extra }

/// Le déclencheur : un anneau blanc et son disque, posés sur le viseur.
class _Shutter extends StatelessWidget {
  const _Shutter({required this.onTap, required this.busy, this.enabled = true});

  final VoidCallback onTap;
  final bool busy;

  /// Faux tant que le flux n'est pas prêt : le déclencheur est là, il
  /// n'écoute pas encore.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Pressable(
      onTap: busy || !enabled ? null : onTap,
      enabled: enabled,
      scale: 0.86,
      semanticLabel: l10n.takePhoto,
      child: Container(
        width: 68,
        height: 68,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 3))],
        ),
        child: Container(
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: busy ? ClayLoader(size: 16, color: context.colors.sage) : null,
        ),
      ),
    );
  }
}

/// La photo de la plante, puis les vues prises pour la reconnaître, chacune
/// sous son nom ; les emplacements libres disent quoi photographier.
///
/// Trois cases égales ne disaient rien : laquelle est la photo de la plante,
/// à quoi servent les autres, que deviennent-elles. Ici la première est
/// « La plante », les suivantes portent le sujet conseillé.
class _ViewsStrip extends StatelessWidget {
  const _ViewsStrip({required this.plantThumb, required this.extras, required this.hints, required this.onAdd, required this.onRemove});

  final String plantThumb;
  final List<StoredPhoto> extras;

  /// Un sujet conseillé par emplacement libre, dans l'ordre.
  final List<String> hints;

  /// Nul quand tous les emplacements sont pris.
  final VoidCallback? onAdd;

  /// Retirer une vue, par son rang global (la photo de la plante est 0).
  final ValueChanged<int> onRemove;

  static const double _size = 64;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final slots = <Widget>[
      _slot(context, caption: l10n.viewPlant, child: _thumb(context, PlantImage(relativePath: plantThumb, cacheWidth: 200))),
      for (final (i, e) in extras.indexed)
        _slot(
          context,
          caption: hints[i.clamp(0, hints.length - 1)],
          child: _thumb(
            context,
            PlantImage(relativePath: e.thumbPath, cacheWidth: 200),
            onRemove: () => onRemove(i + 1),
          ),
        ),
      for (var i = extras.length; i < hints.length; i++)
        // Seul le premier emplacement libre écoute : deux cibles pour le
        // même geste n'en font pas un plus clair. La cible, c'est la tuile
        // et son libellé ensemble.
        if (i == extras.length && onAdd != null)
          Pressable(
            onTap: onAdd,
            scale: 0.95,
            semanticLabel: hints[i],
            child: _slot(
              context,
              caption: hints[i],
              child: Container(
                width: _size,
                height: _size,
                decoration: BoxDecoration(color: c.sageSoft, borderRadius: Radii.mediumAll),
                child: Icon(CupertinoIcons.camera_fill, color: c.sage, size: 22),
              ),
            ),
          )
        else
          _slot(
            context,
            caption: hints[i],
            muted: true,
            child: Container(
              width: _size,
              height: _size,
              decoration: BoxDecoration(borderRadius: Radii.mediumAll, border: Border.all(color: c.line)),
              child: Icon(CupertinoIcons.plus, color: c.inkTertiary, size: 14),
            ),
          ),
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (i, s) in slots.indexed) ...[
          if (i > 0) const SizedBox(width: Space.sm),
          s,
        ],
      ],
    );
  }

  Widget _slot(BuildContext context, {required String caption, required Widget child, bool muted = false}) {
    return SizedBox(
      width: 84,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          child,
          const SizedBox(height: Space.xxs),
          Text(
            caption,
            style: context.text.caption.copyWith(color: muted ? context.colors.inkTertiary : context.colors.inkSecondary, fontSize: 11),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _thumb(BuildContext context, Widget image, {VoidCallback? onRemove}) {
    final c = context.colors;
    final clipped = ClipRRect(borderRadius: Radii.mediumAll, child: SizedBox(width: _size, height: _size, child: image));
    if (onRemove == null) return clipped;
    return SizedBox(
      width: _size,
      height: _size,
      child: Stack(
        children: [
          clipped,
          Positioned(
            top: 0,
            right: 0,
            child: Pressable(
              onTap: onRemove,
              scale: 0.9,
              minTapTarget: false,
              semanticLabel: context.l10n.deletePhoto,
              child: Padding(
                padding: const EdgeInsets.all(Space.xxs),
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(color: c.surface.withValues(alpha: 0.92), shape: BoxShape.circle),
                  child: Icon(CupertinoIcons.xmark, size: 11, color: c.ink),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepLayout extends StatelessWidget {
  const _StepLayout({required this.title, required this.body, required this.actions, this.subtitle, this.scrollable = false});

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
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [header, body]),
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

/// Aperçu de la fiche d'entretien pendant la création : l'utilisateur voit
/// tout de suite ce que l'app sait de son espèce.
class _CarePreview extends ConsumerWidget {
  const _CarePreview({required this.speciesName});

  final String speciesName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    if (speciesName.trim().length < 3) return const SizedBox.shrink();
    final care = ref.watch(careGuideProvider).resolve(speciesName, family: speciesFamilyLookup(ref)(speciesName));
    if (care.match == CareMatch.generic) return const SizedBox.shrink();
    final p = care.profile;
    return Padding(
      padding: const EdgeInsets.only(top: Space.sm),
      child: FloraCard(
        color: c.sageSoft,
        padding: const EdgeInsets.all(Space.md),
        child: Row(
          children: [
            const Text('📖', style: TextStyle(fontSize: 18)),
            const SizedBox(width: Space.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.careWateringNow(p.wateringDaysFor(DateTime.now().month, south: ref.watch(southernHemisphereProvider))), style: context.text.callout.copyWith(color: c.ink, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text('${l10n.lightName(p.light)} · ${l10n.careMatchLabel(care)}', style: context.text.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
