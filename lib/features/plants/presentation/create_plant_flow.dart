import 'dart:async';
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
import '../../../core/network/connectivity.dart';
import '../../../core/observability/observability.dart';
import '../../../data/services/photo_storage_service.dart';
import '../../../data/services/jev_identification_policy.dart';
import '../../../domain/identification/cascade_identifier.dart';
import '../../../domain/identification/iris_feedback.dart';
import '../../identification/presentation/iris_feedback_prompt.dart';
import '../../identification/presentation/genus_row.dart';
import '../../identification/presentation/identification_source_note.dart';
import '../../../domain/identification/plant_identifier.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/models/models.dart';
import '../../../domain/repositories/repositories.dart';
import '../../locations/presentation/location_edit_sheet.dart';
import '../../locations/presentation/location_picker_sheet.dart';
import '../../../domain/identification/identification_policy.dart';
import '../../identification/presentation/identification_photos.dart';
import '../../identification/presentation/identification_sheet.dart';
import '../../identification/presentation/identification_uncertainty.dart';
import '../../cuttings/presentation/propagation_guide_sheet.dart';
import '../../account/application/membership_providers.dart';
import '../../../core/l10n/care_labels.dart';
import '../../../domain/care/care_guide.dart';
import '../../../domain/identification/identification_context.dart';
import '../../species/presentation/species_field.dart';
import 'inline_camera.dart';

/// Lance le flow de création (3 étapes) et ouvre la fiche de la plante créée.
///
/// Une multiplication commence par son guide : le geste que demande l'espèce
/// de la plante mère — bouture de tige, de feuille, division, rejet —,
/// illustré étape par étape, précisé par l'IA quand elle connaît l'espèce.
/// Le guide se passe d'un mot ; le refermer, c'est y renoncer.
Future<void> startCreatePlantFlow(BuildContext context, WidgetRef ref, {String? parentPlantId, String? parentName, String? speciesName, String? locationId}) async {
  final l10n = context.l10n;
  if (!ref.read(canEditProvider)) {
    ref.read(toastProvider.notifier).show(ToastData(message: l10n.readOnlyHint, emoji: '🔒'));
    return;
  }
  if (parentPlantId != null) {
    final create = await showPropagationGuide(context, species: speciesName);
    if (create != true || !context.mounted) return;
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

  /// Le viseur de la première étape. Une seule photo suffit au premier
  /// passage d'Iris ; il s'arrête dès qu'elle est prise.
  final _camera = InlineCameraController();
  int _step = 0;
  StoredPhoto? _photo;

  /// Fichier source exact rendu par la caméra ou la photothèque. Il reste
  /// affiché tel quel dans le cadre : la copie 2048 px et la miniature ne
  /// servent qu'au stockage, jamais à cet aperçu.
  File? _reviewSource;
  bool _reviewSourceOwned = false;

  /// Où en est l'étape photo : on vise, puis on regarde la photo pendant
  /// qu'Iris l'analyse.
  _PhotoMode _mode = _PhotoMode.aim;
  bool _picking = false;
  bool _saving = false;
  Future<List<IdentificationCandidate>>? _identification;

  /// La première analyse reste visible au moins une demi-seconde, même si
  /// Iris répond plus vite. Les noms peuvent apparaître dès que le modèle les
  /// a rendus.
  static const Duration _minimumPrimaryScan = Duration(milliseconds: 500);
  Timer? _primaryScanTimer;
  bool _primaryScanMinimumElapsed = true;
  bool _primaryIdentificationDone = false;
  List<IdentificationCandidate> _primaryPreviewCandidates = const [];
  int _identificationRun = 0;

  /// Photos prises en plus, seulement pour lever un doute d'identification.
  /// Ce ne sont pas des photos de la plante : elles s'effacent en partant,
  /// que la création aboutisse ou non.
  final _identificationExtras = <StoredPhoto>[];

  /// Chemins absolus envoyés au moteur : la photo de la plante, puis les
  /// autres. Le moteur les fusionne par moyenne géométrique — l'espèce que
  /// toutes les photos voient remonte, celle qui ne tenait qu'à un cliché
  /// ambigu redescend.
  final _identificationPaths = <String>[];

  /// La candidate retenue et d'où elle vient — `null` tant que le nom a
  /// été tapé à la main, auquel cas rien n'est étiqueté.
  IdentificationCandidate? _chosen;
  ChosenSource? _chosenSource;

  /// Une photo d'abord ; une seconde seulement si Iris hésite.
  static const int maxIdentificationPhotos = 2;

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
    _primaryScanTimer?.cancel();
    _deleteOwnedReviewSource();
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
    // Le clavier ne suit aucun changement d'étape : ouvert, il écrase la mise
    // en page (l'aperçu photo, les propositions d'identification).
    FocusManager.instance.primaryFocus?.unfocus();
    // Le viseur ne tourne que lorsqu'on vise réellement. Une photo déjà
    // prise reste un aperçu, même si on revient à la première étape.
    if (step == 0 && _mode == _PhotoMode.aim) {
      _camera.start();
    } else {
      _camera.stop();
    }
    setState(() => _step = step);
    _page.animateToPage(step, duration: Motion.of(context, Motion.emphasis), curve: Motion.emphasized);
  }

  /// Ouvre l'appareil photo ou la galerie du système. Le viseur intégré a
  /// pris la place du premier cas courant ; celui-ci reste pour la galerie,
  /// et pour les appareils qui n'offrent pas d'aperçu.
  Future<void> _pick(PhotoSource source) async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final storage = ref.read(photoStorageProvider);
      final raw = await storage.pickSource(source);
      if (raw == null || !mounted) return;

      // Le fichier source devient l'aperçu avant toute compression.
      _showRawPreview(raw, owned: source == PhotoSource.camera);

      final stored = await storage.importFile(raw);
      if (mounted) await _accept(stored);
    } catch (e, st) {
      ref.read(crashReporterProvider).report(e, st, context: 'createPlant.pick');
      if (mounted) {
        await _recoverFromPreviewFailure();
        ref.read(toastProvider.notifier).show(ToastData(message: context.l10n.photoError, emoji: '!'));
      }
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
      // Dès que le plugin rend la photo, elle remplace le viseur. La copie
      // optimisée peut ensuite se fabriquer sans changer ce que l'on voit.
      _showRawPreview(shot, owned: true);

      final stored = await ref.read(photoStorageProvider).importFile(shot);
      if (mounted) await _accept(stored);
    } catch (e, st) {
      ref.read(crashReporterProvider).report(e, st, context: 'createPlant.capture');
      if (mounted) {
        await _recoverFromPreviewFailure();
        ref.read(toastProvider.notifier).show(ToastData(message: context.l10n.photoError, emoji: '!'));
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _showRawPreview(File source, {required bool owned}) {
    if (!mounted) return;
    setState(() {
      _reviewSource = source;
      _reviewSourceOwned = owned;
      _identification = null;
      _primaryPreviewCandidates = const [];
      _primaryIdentificationDone = false;
      _primaryScanMinimumElapsed = false;
      _mode = _PhotoMode.review;
    });
    unawaited(_camera.stop());
  }

  Future<void> _recoverFromPreviewFailure() async {
    final source = _reviewSource;
    final owned = _reviewSourceOwned;
    if (mounted) {
      setState(() {
        _reviewSource = null;
        _reviewSourceOwned = false;
        _photo = null;
        _identificationPaths.clear();
        _identification = null;
        _primaryPreviewCandidates = const [];
        _primaryIdentificationDone = false;
        _primaryScanMinimumElapsed = true;
        _mode = _PhotoMode.aim;
      });
      _camera.start();
    }
    if (owned && source != null) {
      try {
        await source.delete();
      } catch (_) {}
    }
  }

  void _deleteOwnedReviewSource() {
    final source = _reviewSource;
    if (!_reviewSourceOwned || source == null) return;
    unawaited(_deleteFileQuietly(source));
  }

  Future<void> _deleteFileQuietly(File file) async {
    try {
      await file.delete();
    } catch (_) {}
  }

  /// Retient la photo principale et lance Iris immédiatement dessus. La
  /// seconde photo, si elle devient utile, sera proposée après les résultats.
  Future<void> _accept(StoredPhoto stored) async {
    final storage = ref.read(photoStorageProvider);
    final path = await storage.absolutePath(stored.filePath);
    if (!mounted) return;
    setState(() {
      _photo = stored;
      _identificationPaths
        ..clear()
        ..add(path);
      _identification = null;
      _primaryPreviewCandidates = const [];
      _primaryIdentificationDone = false;
      _primaryScanMinimumElapsed = false;
      _mode = _PhotoMode.review;
    });
    await _camera.stop();
    _startIdentification(revealOnPrimaryPhoto: true);
    Haptics.success();
  }

  /// Reprendre : la photo de la plante part, et avec elle les vues prises
  /// pour la reconnaître, qui montraient le même sujet. Retour au viseur.
  Future<void> _retake() async {
    final storage = ref.read(photoStorageProvider);
    final old = _photo;
    final raw = _reviewSource;
    final rawOwned = _reviewSourceOwned;
    _dropIdentificationExtras();
    _primaryScanTimer?.cancel();
    _identificationRun++;
    setState(() {
      _photo = null;
      _reviewSource = null;
      _reviewSourceOwned = false;
      _identificationPaths.clear();
      _identification = null;
      _primaryPreviewCandidates = const [];
      _primaryIdentificationDone = false;
      _primaryScanMinimumElapsed = true;
      _mode = _PhotoMode.aim;
    });
    _camera.start();
    if (old != null) await storage.deleteFiles(old.filePath, old.thumbPath);
    if (rawOwned && raw != null) {
      try {
        await raw.delete();
      } catch (_) {}
    }
  }

  /// Le lieu de la plante, quand il est déjà connu — une plante créée depuis
  /// un emplacement le porte dès l'ouverture.
  ///
  /// L'étape de l'emplacement vient **après** celle de la photo : le plus
  /// souvent il n'est donc pas encore choisi, et le modèle répond alors sans
  /// masque. C'est voulu : deviner « intérieur » ferait perdre au premier
  /// geste ce qu'un lieu juste ferait gagner ensuite.
  IdentificationContext get _place {
    final id = _noLocation ? null : _locationId;
    if (id == null) return IdentificationContext.unknown;
    final locations = ref.read(locationsProvider).value ?? const <Location>[];
    return switch (locations.where((l) => l.id == id).firstOrNull?.isOutdoor) {
      true => IdentificationContext.outdoor,
      false => IdentificationContext.indoor,
      null => IdentificationContext.unknown,
    };
  }

  /// Identification en arrière-plan. La première passe démarre dès la photo
  /// principale ; si la confiance est trop faible, une seconde photo peut
  /// relancer exactement le même moteur et fusionner les deux vues.
  void _startIdentification({bool revealOnPrimaryPhoto = false}) {
    final identifier = ref.read(plantIdentifierProvider);
    if (!identifier.isConfigured || _identificationPaths.isEmpty) return;
    final lang = _identificationLanguage;
    final run = ++_identificationRun;
    final pending = identifier
        .identify([for (final p in _identificationPaths) File(p)], language: lang, context: _place)
        .catchError((_) => <IdentificationCandidate>[]);

    if (revealOnPrimaryPhoto) {
      _primaryScanTimer?.cancel();
      _primaryScanTimer = Timer(_minimumPrimaryScan, () {
        if (!mounted || run != _identificationRun) return;
        setState(() => _primaryScanMinimumElapsed = true);
      });
      pending.then((results) {
        if (!mounted || run != _identificationRun) return;
        setState(() {
          _primaryIdentificationDone = true;
          _primaryPreviewCandidates = results.take(3).toList(growable: false);
        });
      });
    }

    // Un bloc, pas une flèche : l'affectation vaut le Future, et un setState
    // qui rend un Future lève en debug — l'étape photo restait alors figée,
    // sans rien dire, là où la version publiée passait.
    setState(() {
      _identification = pending;
    });
  }

  /// Évaluation produit complète : Iris reste le classifieur, Jev décide
  /// seulement de la suite à donner à un résultat ambigu.
  Future<JevPipelineEvaluation> _identificationEvaluation(
      List<IdentificationCandidate> results) {
    final identifier = ref.read(plantIdentifierProvider);
    if (identifier is! CascadeIdentifier) {
      return Future.value(const JevPipelineEvaluation(
        offer: SecondPhotoOffer.none,
        consultedJev: false,
        usedFallback: false,
      ));
    }
    return ref.read(jevIdentificationPolicyProvider).evaluate(
          policy: identifier.policy,
          candidates: results,
          photos: _identificationPaths.length,
          maxPhotos: maxIdentificationPhotos,
          online: ref.read(isOnlineProvider),
        );
  }

  /// Ce que la personne a fait de la décision affichée. Les deux gestes
  /// qui contredisent Jev sont les seuls qui disent quelque chose de la
  /// qualité de son arbitrage.
  void _noteJevChoice(JevProductAction? after) =>
      ref.read(jevIdentificationPolicyProvider).noteCandidateChosen(after);

  void _noteJevOnlineSearch(JevProductAction? after) =>
      ref.read(jevIdentificationPolicyProvider).noteOnlineSearch(after);

  /// La conclusion d'Iris seule, rendue sans attendre le réseau : c'est
  /// l'état montré tant que Jev n'a pas répondu.
  JevPipelineEvaluation? _localIdentificationEvaluation(
      List<IdentificationCandidate> results) {
    final identifier = ref.read(plantIdentifierProvider);
    if (identifier is! CascadeIdentifier) return null;
    return ref.read(jevIdentificationPolicyProvider).localEvaluation(
          policy: identifier.policy,
          candidates: results,
          photos: _identificationPaths.length,
          maxPhotos: maxIdentificationPhotos,
        );
  }

  /// Le genre, quand aucune espèce ne passe le seuil : « Épicéa, espèce
  /// incertaine » vaut mieux que cinq noms dont un serait retenu au hasard,
  /// avec son profil de soin.
  GenusAnswer? _identificationGenus(List<IdentificationCandidate> results) {
    final identifier = ref.read(plantIdentifierProvider);
    return identifier is CascadeIdentifier ? genusAnswer(identifier.policy, results) : null;
  }

  /// Une photo de plus pour trancher. Gratuite, hors ligne et immédiate, là
  /// où la recherche en ligne se prend sur un quota mensuel.
  Future<void> _addIdentificationPhoto(PhotoSource source) async {
    final identifier = ref.read(plantIdentifierProvider);
    if (_picking ||
        !identifier.isConfigured ||
        _identificationPaths.isEmpty ||
        _identificationPaths.length >= maxIdentificationPhotos) {
      return;
    }
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
    // La première photo est réévaluée seule après retrait de la seconde.
    if (_identification != null) _startIdentification();
    await storage.deleteFiles(stored.filePath, stored.thumbPath);
  }

  /// Range une photo d'identification de plus et relance le moteur.
  Future<void> _acceptIdentificationPhoto(StoredPhoto stored) async {
    if (_identificationPaths.length >= maxIdentificationPhotos) return;
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
          .identifyRemotely([for (final p in _identificationPaths) File(p)], language: lang, context: _place)
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

  /// La personne vient d'étiqueter ses photos en enregistrant. Si elle l'a
  /// permis, elles partent entraîner Iris — sans jamais retenir la fiche :
  /// l'envoi se fait à côté, et un échec ne se voit pas.
  void _recordFeedback() {
    final identifier = ref.read(plantIdentifierProvider);
    final source = _chosenSource;
    final species = _species.text.trim();
    if (identifier is! CascadeIdentifier || source == null || species.isEmpty || _identificationPaths.isEmpty) return;
    final chosen = _chosen;
    unawaited(ref.read(irisFeedbackRecorderProvider).record(IrisFeedback(
      photos: [for (final p in _identificationPaths) File(p)],
      local: identifier.lastLocal,
      chosenName: species,
      chosenId: chosen?.internalId,
      chosenSource: source,
      remoteTop: chosen?.source == IdentificationSource.remote ? chosen : null,
      modelVersion: identifier.local.version ?? '',
    )));
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
    _recordFeedback();
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
    if (mounted && _chosenSource != null && _identificationPaths.isNotEmpty) await _maybeAskIrisFeedback();
    if (mounted) Navigator.of(context, rootNavigator: true).pop(plant.id);
  }

  /// Le bon moment pour demander : la personne vient d'enregistrer une
  /// plante identifiée, elle sait de quoi il s'agit. Une seule fois — et rien
  /// n'est parti avant le oui : l'envoi de cette plante-ci est passé par
  /// l'enregistreur muet.
  Future<void> _maybeAskIrisFeedback() async {
    final p = ref.read(preferencesProvider);
    if (!shouldAskForFeedback(asked: p.irisFeedbackAsked, enabled: p.irisFeedbackEnabled,
        available: ref.read(irisFeedbackAvailableProvider))) {
      return;
    }
    await showIrisFeedbackPrompt(context, ref);
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

  /// L'étape photo a deux temps : viser, puis laisser Iris lire la photo.
  ///
  /// La première photo est suffisante pour essayer. On ne demande plus des
  /// vues supplémentaires avant de connaître le résultat ; une seconde photo
  /// n'apparaît que plus tard, si la confiance le justifie.
  Widget _photoStep() {
    final l10n = context.l10n;
    final identifier = ref.watch(plantIdentifierProvider);
    return ListenableBuilder(
      listenable: _camera,
      builder: (context, _) {
        final live = _camera.hasViewfinder;
        final (title, subtitle) = switch (_mode) {
          _PhotoMode.aim => (
              l10n.stepPhotoTitle,
              widget.parentPlantId == null ? l10n.stepPhotoSubtitle : l10n.stepPhotoSubtitleCutting,
            ),
          _PhotoMode.review => (
              l10n.stepPhotoDoneTitle,
              !identifier.isConfigured
                  ? l10n.stepPhotoDonePlain
                  : (!_primaryIdentificationDone || !_primaryScanMinimumElapsed)
                      ? l10n.identifying
                      : _primaryPreviewCandidates.isEmpty
                          ? l10n.identifyNone
                          : l10n.identifyHint,
            ),
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
                    layoutBuilder: (current, previous) => Stack(fit: StackFit.expand, children: [...previous, ?current]),
                    child: KeyedSubtree(key: ValueKey(_mode), child: _photoFrame(live: live)),
                  ),
                ),
              ),
            ],
          ),
          actions: switch (_mode) {
            _PhotoMode.aim => [
                if (!live) ...[
                  FloraButton(label: l10n.takePhoto, icon: CupertinoIcons.camera_fill, expand: true, loading: _picking, onPressed: _capture),
                  const SizedBox(height: Space.xs),
                  FloraButton(label: l10n.choosePhoto, icon: CupertinoIcons.photo, style: FloraButtonStyle.secondary, expand: true, onPressed: _picking ? null : () => _pick(PhotoSource.gallery)),
                  const SizedBox(height: Space.xs),
                ],
                FloraButton(label: l10n.withoutPhoto, style: FloraButtonStyle.ghost, expand: true, onPressed: () => _go(1)),
              ],
            _PhotoMode.review => [
                FloraButton(
                  label: l10n.continueLabel,
                  expand: true,
                  onPressed: _photo == null ||
                          _picking ||
                          (identifier.isConfigured &&
                              (!_primaryIdentificationDone || !_primaryScanMinimumElapsed))
                      ? null
                      : () => _go(1),
                ),
                const SizedBox(height: Space.xs),
                FloraButton(label: l10n.retake, icon: CupertinoIcons.camera, style: FloraButtonStyle.ghost, expand: true, onPressed: _picking ? null : _retake),
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
      final raw = _reviewSource;
      final Widget image = raw != null
          ? Image.file(
              raw,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
              gaplessPlayback: true,
            )
          : _photo != null
              ? PlantImage(relativePath: _photo!.filePath)
              : const SizedBox.expand();
      final identifier = ref.watch(plantIdentifierProvider);
      final scanning = identifier.isConfigured &&
          (!_primaryIdentificationDone || !_primaryScanMinimumElapsed);
      content = Stack(
        fit: StackFit.expand,
        children: [
          AnimatedSwitcher(
            duration: Motion.of(context, const Duration(milliseconds: 280)),
            reverseDuration: Motion.of(context, const Duration(milliseconds: 240)),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            layoutBuilder: (current, previous) =>
                Stack(fit: StackFit.expand, children: [...previous, ?current]),
            transitionBuilder: (child, animation) {
              final scale = Tween<double>(begin: 0.992, end: 1).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              );
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: scale, child: child),
              );
            },
            child: scanning
                ? ProcessingField(
                    key: const ValueKey('iris-processing'),
                    height: null,
                    child: image,
                    foregroundAlignment: Alignment.topRight,
                    foreground: const Padding(
                      padding: EdgeInsets.only(top: Space.xs, right: Space.sm),
                      child: BreathingIrisMark(size: 48),
                    ),
                  )
                : KeyedSubtree(
                    key: const ValueKey('iris-photo'),
                    child: image,
                  ),
          ),
          if (_primaryPreviewCandidates.isNotEmpty)
            _DetectedPlantsOverlay(
              candidates: _primaryPreviewCandidates,
              onPick: _pickPreviewCandidate,
            ),
        ],
      );
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
          // Le déclencheur reste parfaitement centré. La galerie vient
          // simplement se placer à sa gauche, à 12 points du bord du bouton
          // photo : les deux commandes forment un seul groupe sans toucher
          // les repères de cadrage.
          Positioned(
            left: 0,
            right: 0,
            bottom: Space.md,
            child: SizedBox(
              height: 68,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Shutter(
                    busy: _picking,
                    enabled: _camera.isReady,
                    semanticLabel: l10n.takePhoto,
                    onTap: _capture,
                  ),
                  if (_mode == _PhotoMode.aim)
                    Transform.translate(
                      // Demi-déclencheur, l'écart, demi-bouton galerie : douze
                      // points entre les deux, comptés par le composant.
                      offset: const Offset(-Shutter.asideOffset, 0),
                      child: FloraIconButton(
                        icon: CupertinoIcons.photo,
                        semanticLabel: l10n.choosePhoto,
                        background: OnMedia.tile,
                        color: OnMedia.ink,
                        onPressed: _picking ? null : () => _pick(PhotoSource.gallery),
                      ),
                    ),
                ],
              ),
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

  Widget _nameStep() {
    final l10n = context.l10n;
    final c = context.colors;
    return _StepLayout(
      title: l10n.stepNameTitle,
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sans autofocus : en arrivant, ce sont les propositions
          // d'identification qu'il y a à lire, et le clavier les couvrirait.
          // Le champ s'ouvre d'un toucher.
          FloraTextField(
            controller: _name,
            hint: l10n.plantNameHint,
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
              _chosen = null;
              _chosenSource = ChosenSource.picker;
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
              evaluation: _identificationEvaluation,
              localEvaluation: _localIdentificationEvaluation,
              onChoiceMade: _noteJevChoice,
              onOnlineSearchAsked: _noteJevOnlineSearch,
              genus: _identificationGenus,
              selectedScientificName: _chosen?.scientificName,
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

  void _pickPreviewCandidate(IdentificationCandidate candidate) {
    if (_photo == null || _picking) return;

    // Les résultats sont déjà là : le tap est une confirmation explicite,
    // donc inutile de retenir l'utilisateur jusqu'à la fin du délai visuel.
    _primaryScanTimer?.cancel();
    _applyCandidate(candidate);
    if (!mounted) return;
    setState(() => _primaryScanMinimumElapsed = true);
    _go(1);
  }

  void _applyCandidate(IdentificationCandidate c) {
    setState(() {
      _chosen = c;
      _chosenSource = c.source == IdentificationSource.remote
          ? ChosenSource.remote
          : ChosenSource.local;
      _species.text = c.scientificName;
      if (_name.text.trim().isEmpty) {
        _name.text = c.commonName ?? c.scientificName.split(' ').first;
      }
    });
    _applyCareProfile(
      c.scientificName,
      family: speciesFamilyOf(ref, c.scientificName),
    );
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
    this.evaluation,
    this.localEvaluation,
    this.onChoiceMade,
    this.onOnlineSearchAsked,
    this.genus,
    this.selectedScientificName,
  });

  final Future<List<IdentificationCandidate>> future;
  final ValueChanged<IdentificationCandidate> onPick;

  /// Présent quand une recherche en ligne est possible ; le bouton ne
  /// s'affiche que si la liste vient de l'appareil.
  final VoidCallback? onSearchOnline;

  /// Présent seulement quand Iris hésite et qu'une seconde photo peut aider.
  final VoidCallback? onAddPhoto;

  /// Retirer une photo ajoutée pour identifier. Jamais la première : c'est
  /// la photo de la plante.
  final ValueChanged<int>? onRemovePhoto;

  /// Les photos soumises au moteur, en chemins absolus.
  final List<String> paths;

  /// Décision produit finale pour la liste locale courante.
  final Future<JevPipelineEvaluation> Function(List<IdentificationCandidate>)?
      evaluation;

  /// La même décision, telle qu'Iris seule la rend : affichée pendant que
  /// l'arbitrage distant se fait attendre.
  final JevPipelineEvaluation? Function(List<IdentificationCandidate>)?
      localEvaluation;

  /// Les deux gestes qui peuvent contredire la décision Jev affichée, pour
  /// les compteurs : retenir une candidate, et chercher en ligne.
  final ValueChanged<JevProductAction?>? onChoiceMade;
  final ValueChanged<JevProductAction?>? onOnlineSearchAsked;

  /// Le genre à proposer au-dessus des espèces, décidé par la même politique.
  final GenusAnswer? Function(List<IdentificationCandidate>)? genus;

  /// Candidat déjà confirmé par l'utilisateur, y compris depuis l'overlay
  /// affiché directement sur la photo.
  final String? selectedScientificName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FutureBuilder<List<IdentificationCandidate>>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return Padding(
            padding: const EdgeInsets.only(top: Space.sm),
            child: Row(
              children: [
                const AdaptiveProgress(size: 24),
                const SizedBox(width: Space.xs),
                Text(l10n.identifying, style: context.text.caption),
              ],
            ),
          );
        }
        final all = snap.data ?? const <IdentificationCandidate>[];
        final results = all.take(3).toList();
        if (results.isEmpty) return const SizedBox.shrink();
        final evaluationFuture =
            results.first.source == IdentificationSource.local
                ? evaluation?.call(all)
                : null;
        // Sur toutes les candidates rendues, pas sur les trois affichées.
        final genre = genus?.call(all);
        final hasSecondPhoto = paths.length > 1;

        Widget normalContent(JevPipelineEvaluation? state) {
          final action = state?.decision?.action;
          void pick(IdentificationCandidate c) {
            onChoiceMade?.call(action);
            onPick(c);
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (genre != null) ...[
                GenusRow(
                  answer: genre,
                  onUse: () => pick(genusCandidate(genre, l10n.localeName)),
                ),
                const SizedBox(height: Space.xs),
              ],
              FloraGroup(
                children: [
                  for (final c in results)
                    CandidateRow(
                      candidate: c,
                      selected: c.scientificName == selectedScientificName,
                      onUse: () => pick(c),
                    ),
                ],
              ),
              if (state?.offer == SecondPhotoOffer.prominent &&
                  onAddPhoto != null) ...[
                const SizedBox(height: Space.sm),
                Text(l10n.identifyAnotherPhotoHint,
                    style: context.text.caption),
                const SizedBox(height: Space.xs),
                FloraButton(
                  label: l10n.identifyAnotherPhoto,
                  icon: CupertinoIcons.camera,
                  style: FloraButtonStyle.secondary,
                  size: FloraButtonSize.small,
                  onPressed: onAddPhoto,
                ),
              ],
              if (results.first.source == IdentificationSource.local &&
                  onSearchOnline != null) ...[
                const SizedBox(height: Space.sm),
                FloraButton(
                  label: l10n.searchOnline,
                  style: FloraButtonStyle.ghost,
                  size: FloraButtonSize.small,
                  onPressed: () {
                    onOnlineSearchAsked?.call(action);
                    onSearchOnline!();
                  },
                ),
              ],
            ],
          );
        }

        Widget uncertainContent() {
          const after = JevProductAction.keepUncertain;
          void pick(IdentificationCandidate c) {
            onChoiceMade?.call(after);
            onPick(c);
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const IdentificationUncertaintyNotice(),
              if (genre != null) ...[
                const SizedBox(height: Space.sm),
                GenusRow(
                  answer: genre,
                  onUse: () => pick(genusCandidate(genre, l10n.localeName)),
                ),
              ],
              if (onSearchOnline != null) ...[
                const SizedBox(height: Space.sm),
                FloraButton(
                  label: l10n.searchOnline,
                  expand: true,
                  onPressed: () {
                    onOnlineSearchAsked?.call(after);
                    onSearchOnline!();
                  },
                ),
              ],
              const SizedBox(height: Space.md),
              Text(
                l10n.identificationSuggestionsToCheck,
                style: context.text.caption.copyWith(
                  color: context.colors.inkSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: Space.xs),
              FloraGroup(
                children: [
                  for (final c in results)
                    CandidateRow(
                      candidate: c,
                      selected: c.scientificName == selectedScientificName,
                      onUse: () => pick(c),
                    ),
                ],
              ),
            ],
          );
        }

        return Padding(
          padding: const EdgeInsets.only(top: Space.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IdentificationSourceNote(
                source: results.first.source,
                label: switch (results.first.source) {
                  IdentificationSource.local => l10n.suggestionsLocal,
                  IdentificationSource.remote => l10n.suggestionsRemote,
                  IdentificationSource.unknown => l10n.identifyHint,
                },
              ),
              if (hasSecondPhoto) ...[
                const SizedBox(height: Space.xs),
                IdentificationPhotoStrip(
                  paths: paths,
                  maxPhotos: _CreatePlantFlowState.maxIdentificationPhotos,
                  onRemove: onRemovePhoto,
                ),
              ],
              const SizedBox(height: Space.xs),
              if (evaluationFuture == null)
                normalContent(null)
              else
                FutureBuilder<JevPipelineEvaluation>(
                  future: evaluationFuture,
                  initialData: localEvaluation?.call(all),
                  builder: (context, decisionSnap) {
                    final state = decisionSnap.data;
                    return state?.keepsUncertain == true
                        ? uncertainContent()
                        : normalContent(state);
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Les noms qu'Iris vient de rendre, posés directement sur la photo.
///
/// Le modèle rend sa liste d'un coup. L'interface la révèle pourtant en
/// plusieurs temps courts : cela donne à voir la lecture sans prétendre que
/// le modèle produit réellement ses résultats un par un. Positions et petites
/// rotations viennent du nom scientifique, donc elles paraissent organiques
/// tout en restant stables d'un rebuild à l'autre.
class _DetectedPlantsOverlay extends StatefulWidget {
  const _DetectedPlantsOverlay({
    required this.candidates,
    required this.onPick,
  });

  final List<IdentificationCandidate> candidates;
  final ValueChanged<IdentificationCandidate> onPick;

  @override
  State<_DetectedPlantsOverlay> createState() => _DetectedPlantsOverlayState();
}

class _DetectedPlantsOverlayState extends State<_DetectedPlantsOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1250),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else if (!_controller.isAnimating && _controller.value == 0) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant _DetectedPlantsOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    final before = oldWidget.candidates.map((e) => e.scientificName).join('|');
    final after = widget.candidates.map((e) => e.scientificName).join('|');
    if (before == after) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _controller
        ..value = 0
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _stableHash(String value) {
    var hash = 17;
    for (final unit in value.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return hash;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final items = widget.candidates.take(3).toList(growable: false);
    const bases = <Alignment>[
      Alignment(-0.60, -0.60),
      Alignment(0.58, 0.02),
      Alignment(-0.42, 0.60),
    ];

    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < items.length; i++)
          AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final start = 0.04 + i * 0.20;
                final end = (start + 0.40).clamp(0.0, 1.0).toDouble();
                final t = Interval(start, end, curve: Curves.easeOutBack)
                    .transform(_controller.value.clamp(0.0, 1.0).toDouble());
                final seed = _stableHash(items[i].scientificName);
                final dx = ((seed % 19) - 9) / 100;
                final dy = (((seed ~/ 19) % 15) - 7) / 100;
                final rotation = (((seed ~/ 285) % 13) - 6) * 0.008;
                final base = bases[i];

                return Align(
                  alignment: Alignment(base.x + dx, base.y + dy),
                  child: Opacity(
                    opacity: t.clamp(0.0, 1.0).toDouble(),
                    child: Transform.translate(
                      offset: Offset(0, (1 - t) * 10),
                      child: Transform.rotate(
                        angle: rotation,
                        child: Transform.scale(
                          scale: 0.90 + 0.10 * t,
                          child: child,
                        ),
                      ),
                    ),
                  ),
                );
              },
              child: Pressable(
                onTap: () => widget.onPick(items[i]),
                semanticLabel:
                    items[i].commonName?.trim().isNotEmpty == true
                        ? items[i].commonName!
                        : items[i].scientificName,
                scale: 0.96,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 220,
                    minHeight: 48,
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: c.surface.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: (i == 0 ? c.sage : c.inkTertiary)
                            .withValues(alpha: 0.32),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x26000000),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 7,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            items[i].commonName?.trim().isNotEmpty == true
                                ? items[i].commonName!
                                : items[i].scientificName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: context.text.callout.copyWith(
                              color: c.ink,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (items[i].commonName?.trim().isNotEmpty == true) ...[
                            const SizedBox(height: 1),
                            Text(
                              items[i].scientificName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: context.text.caption.copyWith(
                                color: c.inkSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
      ],
    );
  }
}

/// Les deux états de l'étape photo.
enum _PhotoMode { aim, review }

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
