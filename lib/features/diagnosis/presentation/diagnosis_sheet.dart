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
import '../../weather/application/weather_providers.dart';
import 'analysis_wait.dart';
import 'diagnosis_report.dart';

/// « Ma plante a un problème » : photos, symptômes, analyse, pistes.
Future<void> showDiagnosisSheet(BuildContext context, {required Plant plant}) =>
    showFloraSheet<void>(context, scrollable: true, builder: (_) => _DiagnosisBody(plant: plant));

class _DiagnosisBody extends ConsumerStatefulWidget {
  const _DiagnosisBody({required this.plant});

  final Plant plant;

  @override
  ConsumerState<_DiagnosisBody> createState() => _DiagnosisBodyState();
}

class _DiagnosisBodyState extends ConsumerState<_DiagnosisBody> {
  final _photos = <StoredPhoto>[];
  final _symptoms = TextEditingController();

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

  @override
  void initState() {
    super.initState();
    _storage = ref.read(photoStorageProvider);
  }

  @override
  void dispose() {
    _symptoms.dispose();
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

  Future<void> _addPhoto(PhotoSource source, {bool thenAnalyze = false}) async {
    final stored = await ref.read(photoStorageProvider).pick(source);
    if (stored == null || !mounted) return;
    setState(() {
      _photos.add(stored);
      // La photo demandée relance l'analyse entière, les deux ou trois vues
      // ensemble : c'est le compte rendu qui se refait, pas un complément
      // qui se recolle à côté du précédent.
      if (thenAnalyze) _result = null;
    });
    if (thenAnalyze) await _analyze();
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
    if (_photos.isEmpty || _busy) return;
    final l10n = context.l10n;
    setState(() => _busy = true);
    final storage = ref.read(photoStorageProvider);
    final prefs = ref.read(preferencesProvider);
    final lang = prefs.locale?.languageCode ?? WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    final round = ++_round;
    try {
      final files = [for (final p in _photos) File(await storage.absolutePath(p.filePath))];
      final frequent = ProblemCatalog.idsForIssues(_knownIssues()).toSet();
      final catalog = await ref.read(problemCatalogProvider.future);
      final measured = _indoorClimate();
      final result = await ref.online(() => ref.read(plantDiagnoserProvider).diagnose(
            images: files,
            language: lang,
            plantName: widget.plant.name,
            species: widget.plant.speciesName,
            symptoms: _symptoms.text,
            candidates: catalog.candidatesFor(
              species: widget.plant.speciesName,
              family: speciesFamilyOf(ref, widget.plant.speciesName),
              pinned: frequent,
            ),
            frequentIds: frequent,
            indoorClimate: measured,
            reportedClimate: _reportedClimate(measured),
            observations: _observations,
            // Ce qu'aucune photo ne dit : dedans ou dehors, quel jour, quel
            // hémisphère. Une cochenille de salon en février et une brûlure
            // de balcon en juillet ne se confondent pas.
            indoors: _indoors(),
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
      if (mounted) setState(() => _busy = false);
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
  bool? _indoors() {
    final location = widget.plant.locationId;
    if (location == null) return null;
    return !ref.read(outdoorLocationIdsProvider).contains(location);
  }

  /// La mesure de la maison, pour une plante qui y vit. Une plante dehors
  /// n'a rien à faire du thermomètre du salon.
  HomeReading? _indoorClimate({bool watch = false}) {
    final location = widget.plant.locationId;
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
  List<CommonIssue> _knownIssues() {
    final species = widget.plant.speciesName;
    if (species == null || species.isEmpty) return const [];
    final care = ref.read(careGuideProvider).resolve(species, family: speciesFamilyOf(ref, species));
    return care.match == CareMatch.generic ? const [] : care.profile.issues;
  }

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
      ...r.causes.take(3).map((c) => '• ${diagnosisCauseTitle(c, catalog, language)} (${l10n.likelihoodLabel(c.likelihood).toLowerCase()})'),
    ].join('\n');
    final photos = [for (final p in _photos) DiagnosisPhoto(filePath: p.filePath, thumbPath: p.thumbPath)];
    final record = DiagnosisRecord(diagnosis: r, symptoms: _symptoms.text.trim(), photos: photos, observations: _observations);
    final kept = List<StoredPhoto>.of(_photos);
    final storage = ref.read(photoStorageProvider);
    await ref.read(careActionsProvider).log(
          NewAction(
            plantId: widget.plant.id,
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
    await ref.read(plantRepositoryProvider).update(widget.plant.copyWith(health: PlantHealth.watch, healthIssue: () => _suggestedIssue() ?? widget.plant.healthIssue));
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
    final c = context.colors;
    final metric = ref.watch(preferencesProvider.select((p) => p.metricUnits));
    final measured = _indoorClimate(watch: true);
    final askTemperature = measured?.temperatureC == null;
    final askHumidity = measured?.humidity == null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(title: l10n.diagnosisTitle),
          if (_busy) ...[
            // Pendant l'analyse, le formulaire n'a plus rien à offrir : la
            // photo prend toute la place, dans son propre halo, entourée de
            // ce que la machine est en train de chercher.
            const SizedBox(height: Space.lg),
            Center(child: AnalysisWait(photo: PlantImage(relativePath: _photos.first.thumbPath, cacheWidth: 500))),
            const SizedBox(height: Space.lg),
            Text(l10n.analyzing, style: context.text.callout, textAlign: TextAlign.center),
            const SizedBox(height: Space.lg),
          ] else if (_result == null) ...[
            Text(l10n.diagnosisHint, style: context.text.callout),
            const SizedBox(height: Space.md),
            SizedBox(
              height: 92,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final p in _photos)
                    Padding(
                      padding: const EdgeInsets.only(right: Space.xs),
                      child: ClipRRect(borderRadius: Radii.mediumAll, child: SizedBox(width: 92, height: 92, child: PlantImage(relativePath: p.thumbPath, cacheWidth: 300))),
                    ),
                  if (_photos.length < DiagnosisLimits.maxImages)
                    Pressable(
                      onTap: _chooseSource,
                      scale: 0.95,
                      semanticLabel: l10n.addPhotos,
                      child: Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(color: c.sageSoft, borderRadius: Radii.mediumAll),
                        child: Icon(CupertinoIcons.camera_fill, color: c.sage),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: Space.sm),
            FloraTextField(controller: _symptoms, hint: l10n.diagnosisSymptomsHint, minLines: 1, maxLines: 3),
            const SizedBox(height: Space.md),
            // Ce qu'une photo ne montrera jamais et que la personne, elle,
            // peut aller voir : la terre au doigt, les racines hors du pot,
            // la lumière reçue, les insectes sous les feuilles. Ce sont ces
            // quatre-là qui départagent l'excès d'eau du manque d'eau et la
            // pourriture du choc de rempotage. Rien n'est obligatoire, et ce
            // qui n'est pas coché ne part pas.
            FloraGroup(
              header: l10n.diagnosisChecks,
              footer: l10n.diagnosisChecksHint,
              children: [
                _field(FloraChoice<SoilState>(
                  label: l10n.diagnosisSoil,
                  values: SoilState.values,
                  selected: _soil,
                  labelOf: l10n.soilStateLabel,
                  onChanged: (v) => setState(() => _soil = v),
                )),
                _field(FloraChoice<RootState>(
                  label: l10n.diagnosisRoots,
                  values: RootState.values,
                  selected: _roots,
                  labelOf: l10n.rootStateLabel,
                  onChanged: (v) => setState(() => _roots = v),
                )),
                _field(FloraChoice<LightExposure>(
                  label: l10n.light,
                  values: LightExposure.values,
                  selected: _light,
                  labelOf: l10n.lightExposureLabel,
                  onChanged: (v) => setState(() => _light = v),
                )),
                _field(FloraChoice<BugSighting>(
                  label: l10n.diagnosisBugs,
                  values: BugSighting.values,
                  selected: _bugs,
                  labelOf: l10n.bugSightingLabel,
                  onChanged: (v) => setState(() => _bugs = v),
                )),
                // Ce que le capteur ne mesure pas — ou tout, sans capteur, ou
                // pour une plante dehors — se demande là aussi : un air à
                // 30 % explique des pointes sèches mieux qu'une photo.
                if (askTemperature || askHumidity)
                  _field(Row(
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
                  )),
              ],
            ),
            if (measured != null) ...[
              // Dire ce qui part avec les photos : la mesure du capteur, et
              // rien d'autre.
              const SizedBox(height: Space.sm),
              Text(l10n.diagnosisWithHome(homeReadingLabel(measured, metric: metric)), style: context.text.caption),
            ],
            const SizedBox(height: Space.lg),
            // L'analyse part chez le prestataire : sans réseau le bouton
            // n'aurait qu'un échec à rendre, et il vaut mieux le dire avant.
            if (!ref.watch(isOnlineProvider))
              OfflineBanner(message: l10n.offlineDiagnosis, padding: EdgeInsets.zero)
            else
              FloraButton(label: l10n.analyze, icon: CupertinoIcons.sparkles, expand: true, onPressed: _photos.isEmpty ? null : _analyze),
          ] else ...[
            // Ce que les photos n'ont pas tranché se dit avant les pistes, pas
            // après : lire trois causes en croyant qu'elles concluent, puis
            // apprendre en bas qu'elles ne concluent rien, c'est lire deux
            // fois.
            if (_step == DiagnosisNextStep.keepUncertain) ...[
              Text(l10n.diagnosisUncertain, style: context.text.callout.copyWith(color: c.inkSecondary)),
              const SizedBox(height: Space.sm),
            ],
            // Le même corps que la réouverture depuis le journal : ce qu'on
            // lit ici est exactement ce qu'on retrouvera plus tard.
            DiagnosisReportView(
              record: DiagnosisRecord(
                diagnosis: _result!,
                symptoms: _symptoms.text.trim(),
                photos: [for (final p in _photos) DiagnosisPhoto(filePath: p.filePath, thumbPath: p.thumbPath)],
                observations: _observations,
              ),
            ),
            // Une photo de plus quand rien ne se détache, et de préférence
            // celle que le service a nommée. Le compte rendu reste entier
            // au-dessus : c'est une proposition, pas un mur.
            if (_step == DiagnosisNextStep.askAnotherPhoto && _photos.length < DiagnosisLimits.maxImages) ...[
              const SizedBox(height: Space.md),
              Text(l10n.diagnosisAnotherPhotoHint, style: context.text.callout),
              if (_result!.suggestedView case final view?) ...[
                const SizedBox(height: Space.xxs),
                Text(l10n.diagnosisAnotherPhotoView(l10n.diagnosisViewLabel(view)), style: context.text.caption),
              ],
              const SizedBox(height: Space.xs),
              FloraButton(
                label: l10n.diagnosisAnotherPhoto,
                icon: CupertinoIcons.camera,
                style: FloraButtonStyle.secondary,
                expand: true,
                onPressed: () => _chooseSource(thenAnalyze: true),
              ),
            ],
            const SizedBox(height: Space.md),
            FloraButton(label: l10n.saveToJournal, icon: CupertinoIcons.book, expand: true, onPressed: _save),
            const SizedBox(height: Space.xs),
            FloraButton(label: l10n.markWatch, style: FloraButtonStyle.ghost, expand: true, onPressed: _markWatch),
          ],
        ],
      ),
    );
  }
}

/// Une ligne du groupe des observations : la marge commune, une fois.
Widget _field(Widget child) => Padding(padding: const EdgeInsets.fromLTRB(Space.md, Space.sm, Space.md, Space.sm), child: child);

/// Plafond de photos par analyse (aligné sur l'adaptateur).
abstract final class DiagnosisLimits {
  static const maxImages = 3;
}
