import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/diagnosis_labels.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/l10n/likelihood_labels.dart';
import '../../../core/network/connectivity.dart';
import '../../../core/network/network_failure.dart';
import '../../../data/problems/problem_catalog.dart';
import '../../../data/services/photo_storage_service.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/care/care_guide.dart';
import '../../../domain/care/care_profile.dart';
import '../../../domain/diagnosis/diagnosis_observations.dart';
import '../../../domain/diagnosis/diagnosis_policy.dart';
import '../../../domain/diagnosis/diagnosis_record.dart';
import '../../../domain/diagnosis/plant_diagnoser.dart';
import '../../../domain/home/home_climate.dart';
import '../../../domain/models/models.dart';
import '../../../domain/problems/plant_problem.dart';
import '../../../domain/repositories/repositories.dart';
import '../../actions/application/care_actions.dart';
import '../../home_climate/application/home_climate_providers.dart';
import '../../home_climate/presentation/home_climate_widgets.dart';
import '../../network/presentation/offline_notice.dart';
import '../../plants/application/plant_providers.dart';
import '../../plants/presentation/inline_camera.dart';
import '../../plants/presentation/photo_capture_flow.dart';
import '../../weather/application/weather_providers.dart';
import 'analysis_wait.dart';
import 'diagnosis_report.dart';

/// Plafond de photos par analyse (aligné sur l'adaptateur).
abstract final class DiagnosisLimits {
  static const maxImages = 3;
}

/// Ce qui manque encore avant de pouvoir analyser.
enum DiagnosisNeed { photo, symptoms }

/// La photo d'abord, puis ce que la personne a remarqué ; `null` quand
/// l'analyse peut partir.
///
/// La description était facultative, et c'est ce qui rendait les comptes
/// rendus généraux : une photo seule ne dit ni depuis quand, ni ce qui a
/// changé, ni ce qui a été fait à la plante — le modèle n'a alors que des
/// pixels, et il répond ce que des pixels permettent. Deux mots suffisent à
/// tout changer ; on les demande donc.
DiagnosisNeed? diagnosisNeed({required int photos, required String symptoms}) {
  if (photos <= 0) return DiagnosisNeed.photo;
  if (symptoms.trim().isEmpty) return DiagnosisNeed.symptoms;
  return null;
}

/// « Ma plante a un problème » : une page, trois temps.
///
/// C'était une feuille qu'on tirait du bas de la fiche, où un viseur ne
/// tenait pas et où le compte rendu défilait à l'étroit. Le diagnostic est
/// pourtant le geste le plus long de l'application — viser, décrire, aller
/// voir la terre et les racines, lire cinq pistes et leurs gestes : il lui
/// fallait une page, comme à la fiche d'entretien.
///
/// Les trois temps s'y succèdent sans jamais changer d'écran :
///
/// 1. **Montrer.** Le viseur occupe le haut de la page, comme partout
///    ailleurs où l'on photographie une plante (docs/06, « Les photos ») ;
///    dessous, les places des trois photos, puis ce qu'on décrit et ce qu'on
///    est allé vérifier de sa main, une carte par sujet. Tout cela tient
///    sous la ligne de flottaison : une invite le nomme et y mène, et le bas
///    de la page s'efface en fondu plutôt que de s'arrêter net sur la barre.
/// 2. **Chercher.** La photo passe au centre dans son halo, les quatre
///    familles de problèmes tournant autour (`AnalysisWait`).
/// 3. **Répondre.** Le compte rendu prend la page entière : le constat, les
///    pistes, et la photo de plus quand rien ne tranche.
///
/// La barre du bas ne porte qu'un geste à la fois : analyser, puis
/// enregistrer.
class DiagnosisScreen extends ConsumerStatefulWidget {
  const DiagnosisScreen({super.key, required this.plantId});

  final String plantId;

  @override
  ConsumerState<DiagnosisScreen> createState() => _DiagnosisScreenState();
}

class _DiagnosisScreenState extends ConsumerState<DiagnosisScreen> {
  final _photos = <StoredPhoto>[];
  final _symptoms = TextEditingController();

  /// Le viseur de la page, comme à la création d'une plante. Sans lui —
  /// refus, appareil sans caméra —, le cadre garde son invite et ouvre
  /// l'appareil photo du système.
  final _camera = InlineCameraController();

  /// Ce que le capteur ne donne pas se demande, sans obligation.
  final _temperature = TextEditingController();
  final _humidity = TextEditingController();

  /// Ce que la personne est allée vérifier : rien n'est coché au départ, et
  /// une case laissée vide ne part pas.
  SoilState? _soil;
  RootState? _roots;
  LightExposure? _light;
  BugSighting? _bugs;

  bool _busy = false;
  bool _picking = false;
  Diagnosis? _result;

  /// Ce que l'écran fait du compte rendu affiché : le montrer, proposer une
  /// photo de plus, ou dire que rien ne tranche. La règle locale répond tout
  /// de suite, l'arbitrage Jev la corrige s'il arrive (docs/16).
  DiagnosisNextStep _step = DiagnosisNextStep.showResult;

  /// Le rang de l'analyse en cours. Une décision Jev qui revient après
  /// qu'une nouvelle photo a relancé l'analyse ne concerne plus rien.
  int _round = 0;

  /// Vrai dès que le diagnostic est parti au journal : les photos lui
  /// appartiennent alors, et le compte rendu les remontrera à sa réouverture.
  bool _keepPhotos = false;

  /// Gardé dès le départ : `ref` ne se lit plus au moment de disposer.
  late final PhotoStorageService _storage;

  /// Le début de ce qui se demande sous le viseur : la cible du geste qui y
  /// mène, et le repère de ce que l'invite annonce.
  final _symptomsKey = GlobalKey();

  /// Pour poser le curseur dans le champ quand c'est lui qui manque.
  final _symptomsFocus = FocusNode();

  /// Ce que le service a demandé au fil des tours, et ce qu'on lui a
  /// répondu. Cela s'accumule : chaque analyse repart avec tout, puisqu'elle
  /// se refait en entier.
  final _answered = <DiagnosisAnswer>[];

  /// Vrai dès que le champ dit quelque chose. Gardé à part pour ne rebâtir
  /// la barre du bas qu'au passage du vide au plein, et non à chaque lettre.
  bool _symptomsGiven = false;

  @override
  void initState() {
    super.initState();
    _storage = ref.read(photoStorageProvider);
    _symptoms.addListener(_watchSymptoms);
    _camera.start();
  }

  void _watchSymptoms() {
    final given = _symptoms.text.trim().isNotEmpty;
    if (given != _symptomsGiven) setState(() => _symptomsGiven = given);
  }

  @override
  void dispose() {
    _camera.dispose();
    _symptoms.dispose();
    _symptomsFocus.dispose();
    _temperature.dispose();
    _humidity.dispose();
    // Une analyse qu'on n'a pas gardée n'a laissé que des fichiers : on
    // nettoie. Celle qu'on a enregistrée garde les siens.
    if (!_keepPhotos) {
      for (final p in _photos) {
        _storage.deleteFiles(p.filePath, p.thumbPath);
      }
    }
    super.dispose();
  }

  Plant? get _plant => ref.read(plantSummaryProvider(widget.plantId)).value?.plant;

  bool get _full => _photos.length >= DiagnosisLimits.maxImages;

  /// Déclenche depuis le viseur de la page ; sans viseur, l'appareil du
  /// système prend le relais.
  Future<void> _capture() async {
    if (_picking || _full) return;
    if (!_camera.isReady) return _addPhoto(PhotoSource.camera);
    setState(() => _picking = true);
    final shot = await _camera.capture();
    if (shot == null) {
      if (!mounted) return;
      setState(() => _picking = false);
      return _addPhoto(PhotoSource.camera);
    }
    try {
      final stored = await ref.read(photoStorageProvider).importFile(shot);
      if (mounted) _accept(stored);
    } catch (e, st) {
      ref.read(crashReporterProvider).report(e, st, context: 'diagnosis.capture');
      if (mounted) ref.read(toastProvider.notifier).show(ToastData(message: context.l10n.photoError, emoji: '!'));
    } finally {
      // La copie compressée a remplacé le fichier brut du plugin.
      try {
        await shot.delete();
      } catch (_) {}
      if (mounted) setState(() => _picking = false);
    }
  }

  /// L'appareil photo ou la galerie du système.
  Future<void> _addPhoto(PhotoSource source, {bool thenAnalyze = false}) async {
    if (_picking || _full) return;
    setState(() => _picking = true);
    try {
      final stored = await ref.read(photoStorageProvider).pick(source);
      if (stored != null && mounted) _accept(stored, thenAnalyze: thenAnalyze);
    } catch (e, st) {
      ref.read(crashReporterProvider).report(e, st, context: 'diagnosis.pick');
      if (mounted) ref.read(toastProvider.notifier).show(ToastData(message: context.l10n.photoError, emoji: '!'));
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _accept(StoredPhoto stored, {bool thenAnalyze = false}) {
    Haptics.success();
    setState(() {
      _photos.add(stored);
      // La photo demandée relance l'analyse entière, les deux ou trois vues
      // ensemble : c'est le compte rendu qui se refait, pas un complément
      // qui se recolle à côté du précédent.
      if (thenAnalyze) _result = null;
    });
    if (thenAnalyze) unawaited(_analyze());
  }

  void _removePhoto(int index) {
    if (index < 0 || index >= _photos.length) return;
    final gone = _photos[index];
    setState(() => _photos.removeAt(index));
    unawaited(_storage.deleteFiles(gone.filePath, gone.thumbPath));
  }

  /// Descendre au deuxième temps de la page.
  ///
  /// Le viseur occupe le haut de l'écran et la barre du bas referme la page :
  /// le formulaire qui affine le plus l'analyse — les symptômes, puis ce
  /// qu'on est allé vérifier — tient tout entier sous la ligne de flottaison,
  /// et rien dans le dessin ne le laissait deviner. L'invite le nomme et y
  /// mène ; le fondu du bas de page, lui, dit qu'il y a quelque chose.
  ///
  /// La section se pose sous la barre du titre, non derrière elle : la marge
  /// haute de la page est celle sous laquelle le contenu défile.
  Future<void> _showSymptoms() async {
    final target = _symptomsKey.currentContext;
    if (target == null) return;
    final scrollable = Scrollable.maybeOf(target);
    final section = target.findRenderObject();
    final viewport = scrollable?.context.findRenderObject();
    if (scrollable == null || section is! RenderBox || viewport is! RenderBox) return;
    // Ce qui sépare la section de sa place : le haut de la zone défilante,
    // plus la marge sous laquelle le contenu passe — la barre du titre d'iOS
    // est translucide, la page défile dessous.
    final travel = section.localToGlobal(Offset.zero).dy - viewport.localToGlobal(Offset.zero).dy - MediaQuery.paddingOf(target).top;
    final position = scrollable.position;
    final to = (position.pixels + travel).clamp(position.minScrollExtent, position.maxScrollExtent);
    final duration = Motion.of(target, Motion.emphasis);
    if (duration == Duration.zero) return position.jumpTo(to);
    await position.animateTo(to, duration: duration, curve: Motion.easeInOut);
  }

  /// Le champ, et le curseur dedans : ce que demande la pastille de la barre
  /// du bas quand c'est la description qui manque. La page y descend d'abord,
  /// le clavier ensuite — l'inverse ferait deux montées pour un geste.
  Future<void> _writeSymptoms() async {
    await _showSymptoms();
    if (mounted) _symptomsFocus.requestFocus();
  }

  /// Demander la photo qui manque, par l'appareil ou la galerie.
  void _chooseSource({bool thenAnalyze = false}) {
    final l10n = context.l10n;
    showAdaptiveActionSheet(
      context,
      cancelLabel: l10n.cancel,
      actions: [
        SheetAction(label: l10n.camera, icon: CupertinoIcons.camera, onPressed: () => _addPhoto(PhotoSource.camera, thenAnalyze: thenAnalyze)),
        SheetAction(label: l10n.gallery, icon: CupertinoIcons.photo, onPressed: () => _addPhoto(PhotoSource.gallery, thenAnalyze: thenAnalyze)),
      ],
    );
  }

  Future<void> _analyze() async {
    final plant = _plant;
    if (_busy || plant == null) return;
    if (diagnosisNeed(photos: _photos.length, symptoms: _symptoms.text) != null) return;
    final l10n = context.l10n;
    FocusManager.instance.primaryFocus?.unfocus();
    // Le viseur ne tourne que devant quelqu'un qui vise : pendant l'analyse
    // et sous le compte rendu, il ne ferait que tenir la caméra allumée.
    unawaited(_camera.stop());
    setState(() => _busy = true);
    final storage = ref.read(photoStorageProvider);
    final prefs = ref.read(preferencesProvider);
    final lang = prefs.locale?.languageCode ?? WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    final round = ++_round;
    try {
      final files = [for (final p in _photos) File(await storage.absolutePath(p.filePath))];
      final frequent = ProblemCatalog.idsForIssues(_knownIssues(plant)).toSet();
      final catalog = await ref.read(problemCatalogProvider.future);
      final measured = _indoorClimate(plant);
      final result = await ref.online(() => ref.read(plantDiagnoserProvider).diagnose(
            images: files,
            language: lang,
            plantName: plant.name,
            species: plant.speciesName,
            symptoms: _symptoms.text,
            candidates: catalog.candidatesFor(
              species: plant.speciesName,
              family: speciesFamilyOf(ref, plant.speciesName),
              pinned: frequent,
            ),
            // Ce que cette plante fait normalement, soumis avec le reste :
            // des gouttes collantes sous un philodendron sont du nectar
            // aussi souvent que du miellat.
            naturalCauses: catalog.naturalFor(
              species: plant.speciesName,
              family: speciesFamilyOf(ref, plant.speciesName),
            ),
            frequentIds: frequent,
            indoorClimate: measured,
            reportedClimate: _reportedClimate(measured),
            observations: _observations,
            // Ce que le service avait demandé au tour d'avant, avec ses
            // questions : une réponse seule ne voudrait rien dire.
            answers: _answered,
            // Ce qu'aucune photo ne dit : dedans ou dehors, quel jour, quel
            // hémisphère. Une cochenille de salon en février et une brûlure
            // de balcon en juillet ne se confondent pas.
            indoors: _indoors(plant),
            date: DateTime.now(),
            latitude: prefs.weatherPlace?.latitude,
          ));
      Haptics.success();
      if (mounted) {
        setState(() {
          _result = result;
          _step = ref.read(jevDiagnosisPolicyProvider).localStep(result, photos: _photos.length, maxPhotos: DiagnosisLimits.maxImages);
        });
        _arbitrate(result, round);
      }
    } on OfflineException {
      // L'analyse se fait chez le prestataire : hors ligne, les photos ne
      // partent pas et il n'y a rien à attendre.
      ref.read(toastProvider.notifier).show(ToastData(message: l10n.offlineDiagnosis, emoji: '📡'));
    } on DiagnosisException catch (e) {
      // Chaque panne a sa phrase : une clé refusée ne se réessaie pas, un
      // service saturé oui, et un réseau coupé ne dit rien du service. Tout
      // ramener à « Vérifiez votre connexion » envoyait chercher un problème
      // là où il n'y en avait pas.
      final message = switch (e.message) {
        'refusal' => l10n.diagnosisRefused,
        'unauthorized' || 'quota' => l10n.diagnosisUnauthorized,
        'busy' => l10n.diagnosisBusy,
        'unreadable' || 'empty' => l10n.diagnosisUnreadable,
        _ => l10n.diagnosisError,
      };
      ref.read(toastProvider.notifier).show(ToastData(message: message, emoji: '!'));
    } catch (e, st) {
      // Un réseau qui lâche se dit, il ne se rapporte pas comme un plantage.
      if (!isNetworkFailure(e)) ref.read(crashReporterProvider).report(e, st, context: 'diagnosis');
      ref.read(toastProvider.notifier).show(ToastData(message: l10n.diagnosisError, emoji: '!'));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        // Revenu au formulaire faute de compte rendu : le viseur reprend.
        if (_result == null) unawaited(_camera.start());
      }
    }
  }

  /// L'arbitrage Jev, quand le compte rendu ne désigne pas une piste et une
  /// seule.
  ///
  /// Il ne retient pas l'écran : le compte rendu est déjà là, avec la
  /// décision locale, et la réponse distante ne fait que la corriger dans
  /// les trois secondes. Sans clé, sans réseau ou en cas d'incident, la
  /// décision locale reste celle qui s'applique.
  void _arbitrate(Diagnosis result, int round) {
    unawaited(ref
        .read(jevDiagnosisPolicyProvider)
        .evaluate(
          diagnosis: result,
          photos: _photos.length,
          maxPhotos: DiagnosisLimits.maxImages,
          observations: _observations,
          symptomsGiven: _symptoms.text.trim().isNotEmpty,
          online: ref.read(isOnlineProvider),
        )
        .then((step) {
      // Une photo de plus a pu relancer l'analyse entre-temps : cet
      // arbitrage-là ne porte plus sur ce qui est à l'écran.
      if (!mounted || round != _round) return;
      setState(() => _step = step);
    }));
  }

  /// Dedans ou dehors, quand la plante a un emplacement. Sans emplacement,
  /// on ne suppose rien : une plante de balcon rangée nulle part n'est pas
  /// une plante d'intérieur.
  bool? _indoors(Plant plant) {
    final location = plant.locationId;
    if (location == null) return null;
    return !ref.read(outdoorLocationIdsProvider).contains(location);
  }

  /// La mesure de la maison, pour une plante qui y vit. Une plante dehors
  /// n'a rien à faire du thermomètre du salon.
  HomeReading? _indoorClimate(Plant plant, {bool watch = false}) {
    final location = plant.locationId;
    final outdoor = watch ? ref.watch(outdoorLocationIdsProvider) : ref.read(outdoorLocationIdsProvider);
    if (location != null && outdoor.contains(location)) return null;
    final reading = watch ? ref.watch(homeReadingProvider).value : ref.read(homeReadingProvider).value;
    return reading == null || reading.isEmpty ? null : reading;
  }

  /// Ce que la personne a tapé pour ce que le capteur ne donne pas, ou
  /// `null` si elle n'a rien donné. Une valeur que le capteur mesure déjà
  /// n'est pas demandée, donc pas relue.
  ReportedClimate? _reportedClimate(HomeReading? measured) {
    final reported = ReportedClimate.parse(
      temperature: measured?.temperatureC == null ? _temperature.text : null,
      humidity: measured?.humidity == null ? _humidity.text : null,
      fahrenheit: !ref.read(preferencesProvider).metricUnits,
    );
    return reported.isEmpty ? null : reported;
  }

  /// Les questions du compte rendu auxquelles il reste à répondre, et
  /// seulement quand rien ne tranche.
  ///
  /// Un compte rendu qui désigne une piste et une seule ne demande rien :
  /// c'est la même règle que pour la photo de plus (docs/16), une seule
  /// décision à la fois. Ce qui a déjà été répondu ne se redemande pas non
  /// plus — la consigne l'interdit au service, et l'écran ne s'y fie pas.
  List<String> get _openQuestions {
    final result = _result;
    if (result == null || _step == DiagnosisNextStep.showResult) return const [];
    final done = {for (final a in _answered) a.question.trim().toLowerCase()};
    return [
      for (final q in result.questions)
        if (!done.contains(q.trim().toLowerCase())) q,
    ];
  }

  /// Ce qui vient d'être répondu part avec le reste, et l'analyse se refait
  /// en entier : les deux ou trois photos, ce qui a été décrit, ce qui a été
  /// vérifié, et maintenant ce qui a été demandé.
  void _answerAndRetry(List<DiagnosisAnswer> given) {
    if (given.isEmpty || _busy) return;
    setState(() {
      _answered.addAll(given);
      _result = null;
    });
    unawaited(_analyze());
  }

  /// Ce qui a été coché, tel qu'il part à l'analyse et tel qu'il sera gardé
  /// avec elle.
  DiagnosisObservations get _observations => DiagnosisObservations(soil: _soil, roots: _roots, light: _light, bugs: _bugs);

  /// Ce dont l'espèce souffre habituellement, d'après sa fiche d'entretien.
  ///
  /// Le catalogue le sait déjà pour un bon millier d'espèces ; le taire
  /// reviendrait à faire chercher au modèle ce qui est écrit à côté. Une
  /// fiche générique n'a rien à dire et n'envoie rien.
  ///
  /// La fiche est relue telle que le catalogue la donne, sans le complément
  /// de l'IA : lui souffler ses propres suppositions les lui ferait
  /// confirmer.
  List<CommonIssue> _knownIssues(Plant plant) {
    final species = plant.speciesName;
    if (species == null || species.isEmpty) return const [];
    final care = ref.read(careGuideProvider).resolve(species, family: speciesFamilyOf(ref, species));
    return care.match == CareMatch.generic ? const [] : care.profile.issues;
  }

  DiagnosisRecord get _record => DiagnosisRecord(
        diagnosis: _result!,
        symptoms: _symptoms.text.trim(),
        photos: [for (final p in _photos) DiagnosisPhoto(filePath: p.filePath, thumbPath: p.thumbPath)],
        observations: _observations,
        answers: List.of(_answered),
      );

  /// Enregistre le diagnostic entier dans le journal.
  ///
  /// La note reste lisible telle quelle — résumé et trois pistes — pour qui
  /// exporte ses données ou lit la ligne ailleurs ; le compte rendu complet
  /// l'accompagne dans les métadonnées, et c'est lui que la fiche rouvrira.
  Future<void> _save() async {
    final l10n = context.l10n;
    final r = _result!;
    final catalog = ref.read(problemCatalogProvider).value;
    final language = Localizations.localeOf(context).languageCode;
    final text = [
      r.summary,
      // Le cran de vraisemblance entre parenthèses, et pour une piste
      // naturelle ce qui compte davantage : qu'il n'y avait rien à soigner.
      ...r.causes.take(3).map((c) => '• ${diagnosisCauseTitle(c, catalog, language)} '
          '(${c.natural ? l10n.diagnosisNatural : l10n.likelihoodLabel(c.likelihood).toLowerCase()})'),
    ].join('\n');
    final record = _record;
    final kept = List<StoredPhoto>.of(_photos);
    final storage = ref.read(photoStorageProvider);
    await ref.read(careActionsProvider).log(
          NewAction(
            plantId: widget.plantId,
            typeKey: CareKind.note.key,
            notes: text,
            metadata: {DiagnosisRecord.metadataKey: record.toJson()},
          ),
          message: l10n.diagnosisSaved,
          undoLabel: l10n.undo,
          emoji: '🩺',
          // Annuler efface l'entrée : ses photos n'ont plus personne à qui
          // appartenir.
          onUndone: () async {
            for (final p in kept) {
              await storage.deleteFiles(p.filePath, p.thumbPath);
            }
          },
        );
    _keepPhotos = true;
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _markWatch() async {
    final plant = _plant;
    if (plant == null) return;
    await ref.read(plantRepositoryProvider).update(plant.copyWith(health: PlantHealth.watch, healthIssue: () => _suggestedIssue() ?? plant.healthIssue));
    Haptics.light();
    if (mounted) Navigator.of(context).pop();
  }

  /// Ce que la fiche retiendra comme problème : la nature de la piste la plus
  /// vraisemblable, quand la base la classe en ravageur ou en maladie. Les
  /// troubles (eau, lumière, carence) ne se devinent pas d'une catégorie,
  /// on ne les invente pas.
  HealthIssue? _suggestedIssue() {
    final catalog = ref.read(problemCatalogProvider).value;
    final top = _result?.causes.where((c) => c.likelihood == Likelihood.likely && c.problemId != null).firstOrNull;
    return switch (catalog?[top?.problemId]?.kind) {
      ProblemKind.pest => HealthIssue.pests,
      ProblemKind.disease => HealthIssue.disease,
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final plant = ref.watch(plantSummaryProvider(widget.plantId)).value?.plant;
    if (plant == null) {
      return FloraPage(
        title: l10n.diagnosisTitle,
        child: const Padding(padding: EdgeInsets.only(top: Space.huge), child: Center(child: AdaptiveProgress())),
      );
    }
    // Les trois temps se croisent en fondu : on ne change pas d'écran, on
    // passe de ce qu'on montre à ce qu'on cherche, puis à ce qu'on lit.
    final (stage, body) = _busy
        ? ('busy', _AnalysisStage(photo: _photos.first))
        : _result == null
            ? ('form', _form(l10n, plant))
            : ('report', _report(l10n));
    return FloraPage(
      title: l10n.diagnosisTitle,
      bottom: _bottomBar(l10n),
      child: AnimatedSwitcher(
        duration: Motion.of(context, Motion.standard),
        child: KeyedSubtree(key: ValueKey(stage), child: body),
      ),
    );
  }

  /// La barre du bas : un seul geste à la fois, toujours au même endroit.
  Widget? _bottomBar(AppLocalizations l10n) {
    if (_busy) return null;
    if (_result == null) {
      // L'analyse part chez le prestataire : sans réseau le bouton n'aurait
      // qu'un échec à rendre, et il vaut mieux le dire avant.
      if (!ref.watch(isOnlineProvider)) {
        return _Bar(children: [OfflineBanner(message: l10n.offlineDiagnosis, padding: EdgeInsets.zero)]);
      }
      // Un bouton éteint sans raison n'apprend rien : ce qui manque se dit
      // au-dessus de lui, dans l'ordre où cela se donne. La description
      // manquante y mène, puisqu'elle s'écrit hors de vue.
      final need = diagnosisNeed(photos: _photos.length, symptoms: _symptoms.text);
      return _Bar(
        children: [
          if (need == DiagnosisNeed.photo) ...[
            Text(l10n.diagnosisNeedsPhoto, style: context.text.caption, textAlign: TextAlign.center),
            const SizedBox(height: Space.xs),
          ],
          if (need == DiagnosisNeed.symptoms) ...[
            _MoreBelow(label: l10n.diagnosisNeedsSymptoms, onTap: _writeSymptoms),
            const SizedBox(height: Space.xxs),
          ],
          FloraButton(
            label: l10n.analyze,
            icon: CupertinoIcons.sparkles,
            expand: true,
            onPressed: need == null ? _analyze : null,
          ),
        ],
      );
    }
    return _Bar(
      children: [
        FloraButton(label: l10n.saveToJournal, icon: CupertinoIcons.book, expand: true, onPressed: _save),
        const SizedBox(height: Space.xxs),
        FloraButton(label: l10n.markWatch, style: FloraButtonStyle.ghost, expand: true, onPressed: _markWatch),
      ],
    );
  }

  /// Le premier temps : ce qu'on montre et ce qu'on sait.
  Widget _form(AppLocalizations l10n, Plant plant) {
    final c = context.colors;
    final metric = ref.watch(preferencesProvider.select((p) => p.metricUnits));
    final measured = _indoorClimate(plant, watch: true);
    final askTemperature = measured?.temperatureC == null;
    final askHumidity = measured?.humidity == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Le cadre et ce qui l'accompagne se redessinent avec le viseur :
        // celui-ci peut arriver en retard, ou ne jamais venir.
        ListenableBuilder(
          listenable: _camera,
          builder: (context, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Viewfinder(
                camera: _camera,
                full: _full,
                busy: _picking,
                onShoot: _capture,
                onPick: () => _addPhoto(PhotoSource.gallery),
                onSystemCamera: () => _addPhoto(PhotoSource.camera),
              ),
              // Sans viseur (refus, appareil sans caméra, ordinateur), le
              // cadre n'a pas de commandes à porter : les deux gestes
              // s'écrivent sous lui, comme à la création d'une plante.
              if (!_camera.hasViewfinder && !_full) ...[
                const SizedBox(height: Space.sm),
                FloraButton(
                  label: l10n.takePhoto,
                  icon: CupertinoIcons.camera_fill,
                  style: FloraButtonStyle.secondary,
                  expand: true,
                  loading: _picking,
                  onPressed: _capture,
                ),
                const SizedBox(height: Space.xs),
                FloraButton(
                  label: l10n.choosePhoto,
                  icon: CupertinoIcons.photo,
                  style: FloraButtonStyle.ghost,
                  expand: true,
                  onPressed: _picking ? null : () => _addPhoto(PhotoSource.gallery),
                ),
              ],
            ],
          ),
        ),
        if (_photos.isNotEmpty) ...[
          const SizedBox(height: Space.sm),
          _Shots(photos: _photos, max: DiagnosisLimits.maxImages, onRemove: _removePhoto),
        ],
        const SizedBox(height: Space.sm),
        Text(_full ? l10n.diagnosisPhotosFull : l10n.diagnosisHint, style: context.text.caption),
        const SizedBox(height: Space.xs),
        _MoreBelow(label: l10n.diagnosisMoreBelow, onTap: _showSymptoms),

        SectionHeader(key: _symptomsKey, title: l10n.diagnosisSymptoms, padding: const EdgeInsets.only(top: Space.xl, bottom: Space.sm)),
        FloraTextField(controller: _symptoms, focusNode: _symptomsFocus, hint: l10n.diagnosisSymptomsHint, minLines: 2, maxLines: 5),

        SectionHeader(title: l10n.diagnosisChecks, padding: const EdgeInsets.only(top: Space.xl, bottom: Space.xxs)),
        // Ce qu'une photo ne montrera jamais et que la personne, elle, peut
        // aller voir : la terre au doigt, les racines hors du pot, la lumière
        // reçue, les insectes sous les feuilles. Ce sont ces quatre-là qui
        // départagent l'excès d'eau du manque d'eau et la pourriture du choc
        // de rempotage. Une carte par sujet, sa teinte, sa tuile : la même
        // anatomie que la fiche d'entretien.
        Text(l10n.diagnosisChecksHint, style: context.text.caption),
        const SizedBox(height: Space.sm),
        _CheckCard<SoilState>(
          emoji: '🪴',
          variant: 1,
          tint: c.terracottaSoft,
          label: l10n.diagnosisSoil,
          values: SoilState.values,
          selected: _soil,
          labelOf: l10n.soilStateLabel,
          onChanged: (v) => setState(() => _soil = v),
        ),
        const SizedBox(height: Space.sm),
        _CheckCard<RootState>(
          emoji: '🌱',
          variant: 2,
          tint: c.sageSoft,
          label: l10n.diagnosisRoots,
          values: RootState.values,
          selected: _roots,
          labelOf: l10n.rootStateLabel,
          onChanged: (v) => setState(() => _roots = v),
        ),
        const SizedBox(height: Space.sm),
        _CheckCard<LightExposure>(
          emoji: '☀️',
          variant: 0,
          tint: c.sunSoft,
          label: l10n.light,
          values: LightExposure.values,
          selected: _light,
          labelOf: l10n.lightExposureLabel,
          onChanged: (v) => setState(() => _light = v),
        ),
        const SizedBox(height: Space.sm),
        _CheckCard<BugSighting>(
          emoji: '🐛',
          variant: 3,
          tint: c.roseSoft,
          label: l10n.diagnosisBugs,
          values: BugSighting.values,
          selected: _bugs,
          labelOf: l10n.bugSightingLabel,
          onChanged: (v) => setState(() => _bugs = v),
        ),

        // Ce que le capteur ne mesure pas — ou tout, sans capteur, ou pour
        // une plante dehors — se demande là aussi : un air à 30 % explique
        // des pointes sèches mieux qu'une photo.
        if (askTemperature || askHumidity) ...[
          const SizedBox(height: Space.sm),
          FloraCard(
            color: c.waterSoft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EmojiTile(emoji: '🌡️'),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.diagnosisAround, style: context.text.caption),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (askTemperature)
                            Expanded(
                              child: FloraTextField(
                                controller: _temperature,
                                hint: l10n.careTemperature,
                                suffix: Text(metric ? '°C' : '°F', style: context.text.body.copyWith(color: c.inkTertiary)),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                                textCapitalization: TextCapitalization.none,
                              ),
                            ),
                          if (askTemperature && askHumidity) const SizedBox(width: Space.sm),
                          if (askHumidity)
                            Expanded(
                              child: FloraTextField(
                                controller: _humidity,
                                hint: l10n.weatherHumidity,
                                suffix: Text('%', style: context.text.body.copyWith(color: c.inkTertiary)),
                                keyboardType: TextInputType.number,
                                textCapitalization: TextCapitalization.none,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        if (measured != null) ...[
          // Dire ce qui part avec les photos : la mesure du capteur, et rien
          // d'autre.
          const SizedBox(height: Space.sm),
          Text(l10n.diagnosisWithHome(homeReadingLabel(measured, metric: metric)), style: context.text.caption),
        ],
      ],
    );
  }

  /// Le troisième temps : ce que l'analyse répond.
  Widget _report(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Le même corps que la réouverture depuis le journal : ce qu'on lit
        // ici est exactement ce qu'on retrouvera plus tard.
        DiagnosisReportView(record: _record, uncertain: _step == DiagnosisNextStep.keepUncertain),
        // Ce qui manque pour trancher, dans l'ordre du moins coûteux : trois
        // questions se répondent sur place, une photo demande de se relever.
        // Une seule des deux cartes paraît — le compte rendu reste entier
        // au-dessus, c'est une proposition, pas un mur.
        if (_openQuestions case final questions when questions.isNotEmpty) ...[
          const SizedBox(height: Space.lg),
          DiagnosisQuestionsCard(
            key: ValueKey(questions.join('\u0000')),
            questions: questions,
            onAnswered: _answerAndRetry,
          ),
        ] else if (_step == DiagnosisNextStep.askAnotherPhoto && !_full) ...[
          const SizedBox(height: Space.lg),
          AnotherPhotoCard(
            view: _result!.suggestedView,
            onAdd: () => _chooseSource(thenAnalyze: true),
          ),
        ],
      ],
    );
  }
}

/// La barre du bas, posée sous la page : la même marge pour tous les gestes,
/// et la zone sûre de l'appareil dessous.
class _Bar extends StatelessWidget {
  const _Bar({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final inset = readableInset(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(Space.page + inset, Space.xs, Space.page + inset, Space.sm),
        child: Column(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }
}

/// L'invite qui dit que la page continue.
///
/// Elle nomme ce qui attend dessous et y mène d'un toucher. Une pastille
/// posée au milieu, sous la consigne de prise de vue : à cet endroit-là, elle
/// tombe sous l'œil qui vient de lire comment photographier et qui cherche
/// quoi faire ensuite.
class _MoreBelow extends StatelessWidget {
  const _MoreBelow({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Align(
      child: Pressable(
        onTap: onTap,
        scale: 0.96,
        child: DecoratedBox(
          decoration: BoxDecoration(color: c.sageSoft, borderRadius: Radii.fullAll),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.sm, vertical: Space.xs),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(label, style: context.text.caption.copyWith(color: c.sage, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: Space.xxs),
                Icon(CupertinoIcons.chevron_down, size: 13, color: c.sage),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Le viseur de la page, avec ses commandes posées dessus.
///
/// C'est le cadre de la création d'une plante, à l'identique : le
/// déclencheur au centre en bas, la galerie à sa gauche, et le cadre qui
/// déclenche aussi quand on le touche. Sans caméra disponible, le cadre
/// garde son invite, ouvre l'appareil photo du système, et ce sont les deux
/// boutons de la page qui prennent le relais.
class _Viewfinder extends StatelessWidget {
  const _Viewfinder({
    required this.camera,
    required this.full,
    required this.busy,
    required this.onShoot,
    required this.onPick,
    required this.onSystemCamera,
  });

  final InlineCameraController camera;

  /// Trois photos déjà prises : le cadre reste, il ne déclenche plus.
  final bool full;
  final bool busy;
  final VoidCallback onShoot;
  final VoidCallback onPick;
  final VoidCallback onSystemCamera;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListenableBuilder(
      listenable: camera,
      builder: (context, _) {
        final live = camera.hasViewfinder;
        return AspectRatio(
          aspectRatio: 4 / 5,
          child: Opacity(
            opacity: full ? 0.5 : 1,
            child: Pressable(
              onTap: full || busy ? null : (live ? (camera.isReady ? onShoot : null) : onSystemCamera),
              scale: 0.98,
              haptic: false,
              semanticLabel: l10n.takePhoto,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CaptureFrame(camera: camera),
                  if (live && !full)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: Space.md,
                      child: SizedBox(
                        height: Shutter.side,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Shutter(
                              busy: busy,
                              enabled: camera.isReady,
                              semanticLabel: l10n.takePhoto,
                              onTap: onShoot,
                            ),
                            Transform.translate(
                              offset: const Offset(-Shutter.asideOffset, 0),
                              child: FloraIconButton(
                                icon: CupertinoIcons.photo,
                                semanticLabel: l10n.choosePhoto,
                                background: OnMedia.tile,
                                color: OnMedia.ink,
                                onPressed: busy ? null : onPick,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Les photos prises, et les places qui restent.
///
/// La bande ne sert qu'à montrer : elle dit ce qui partira à l'analyse et
/// combien de vues restent possibles. Les deux boutons au-dessus, eux, sont
/// les gestes.
class _Shots extends StatelessWidget {
  const _Shots({required this.photos, required this.max, required this.onRemove});

  final List<StoredPhoto> photos;
  final int max;
  final ValueChanged<int> onRemove;

  static const double side = 76;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SizedBox(
      height: side,
      child: Row(
        // Les places prennent toute la hauteur de la bande : sans cela, une
        // case vide se réduit à son icône et la rangée devient un liseré.
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < max; i++) ...[
            if (i > 0) const SizedBox(width: Space.xs),
            Expanded(
              child: i < photos.length
                  ? _Shot(photo: photos[i], onRemove: () => onRemove(i), label: l10n.diagnosisRemovePhoto)
                  : const _Slot(),
            ),
          ],
        ],
      ),
    );
  }
}

/// La place d'une photo qui n'est pas encore prise.
class _Slot extends StatelessWidget {
  const _Slot();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: Radii.mediumAll,
        border: Border.all(color: c.line),
      ),
      child: Icon(CupertinoIcons.photo, size: 20, color: c.inkTertiary),
    );
  }
}

/// Une photo prise, avec la croix qui la retire.
class _Shot extends StatelessWidget {
  const _Shot({required this.photo, required this.onRemove, required this.label});

  final StoredPhoto photo;
  final VoidCallback onRemove;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: Radii.mediumAll,
          child: PlantImage(relativePath: photo.thumbPath, cacheWidth: 300),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: Pressable(
            onTap: onRemove,
            scale: 0.9,
            semanticLabel: label,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: Colors.black38, shape: BoxShape.circle),
              child: const Icon(CupertinoIcons.xmark, size: 12, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

/// Une question de la main : la tuile du sujet, son nom, ses réponses.
///
/// Même anatomie que les volets de la fiche d'entretien — tuile d'emoji,
/// nom, contenu —, teinte comprise : la terre en terre cuite, les racines en
/// sauge, la lumière en ocre, les insectes en rose.
class _CheckCard<T extends Object> extends StatelessWidget {
  const _CheckCard({
    required this.emoji,
    required this.variant,
    required this.tint,
    required this.label,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
  });

  final String emoji;
  final int variant;
  final Color tint;
  final String label;
  final List<T> values;
  final T? selected;
  final String Function(T) labelOf;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return FloraCard(
      color: tint,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EmojiTile(emoji: emoji),
          const SizedBox(width: Space.md),
          Expanded(
            child: FloraChoice<T>(
              label: label,
              values: values,
              selected: selected,
              labelOf: labelOf,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

/// Le deuxième temps : la photo dans son halo, et ce que la machine cherche
/// autour d'elle.
class _AnalysisStage extends StatelessWidget {
  const _AnalysisStage({required this.photo});

  final StoredPhoto photo;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(top: Space.xl),
      child: Column(
        children: [
          Center(child: AnalysisWait(photo: PlantImage(relativePath: photo.thumbPath, cacheWidth: 500))),
          const SizedBox(height: Space.xl),
          Text(l10n.analyzing, style: context.text.callout, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
