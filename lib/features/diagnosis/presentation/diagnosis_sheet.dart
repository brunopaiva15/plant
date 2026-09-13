import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/l10n/likelihood_labels.dart';
import '../../../core/network/connectivity.dart';
import '../../../core/network/network_failure.dart';
import '../../../data/problems/problem_catalog.dart';
import '../../../data/services/photo_storage_service.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/care/care_guide.dart';
import '../../../domain/care/care_profile.dart';
import '../../../domain/diagnosis/diagnosis_record.dart';
import '../../../domain/diagnosis/plant_diagnoser.dart';
import '../../../domain/home/home_climate.dart';
import '../../../domain/models/models.dart';
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
  bool _busy = false;
  Diagnosis? _result;

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

  Future<void> _addPhoto(PhotoSource source) async {
    final stored = await ref.read(photoStorageProvider).pick(source);
    if (stored != null && mounted) setState(() => _photos.add(stored));
  }

  Future<void> _analyze() async {
    if (_photos.isEmpty || _busy) return;
    final l10n = context.l10n;
    setState(() => _busy = true);
    final storage = ref.read(photoStorageProvider);
    final lang = ref.read(preferencesProvider).locale?.languageCode ?? WidgetsBinding.instance.platformDispatcher.locale.languageCode;
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
          ));
      Haptics.success();
      if (mounted) setState(() => _result = result);
    } on OfflineException {
      // L'analyse se fait chez le prestataire : hors ligne, les photos ne
      // partent pas et il n'y a rien à attendre.
      ref.read(toastProvider.notifier).show(ToastData(message: l10n.offlineDiagnosis, emoji: '📡'));
    } on DiagnosisException catch (e) {
      final message = switch (e.message) {
        'refusal' => l10n.diagnosisRefused,
        'unauthorized' => l10n.diagnosisUnauthorized,
        'quota' => l10n.diagnosisUnauthorized,
        _ => l10n.diagnosisError,
      };
      ref.read(toastProvider.notifier).show(ToastData(message: message, emoji: '!'));
    } catch (e, st) {
      ref.read(crashReporterProvider).report(e, st, context: 'diagnosis');
      ref.read(toastProvider.notifier).show(ToastData(message: l10n.diagnosisError, emoji: '!'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
    final record = DiagnosisRecord(diagnosis: r, symptoms: _symptoms.text.trim(), photos: photos);
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
    await ref.read(plantRepositoryProvider).update(widget.plant.copyWith(health: PlantHealth.watch));
    Haptics.light();
    if (mounted) Navigator.of(context).pop();
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
                      onTap: () => showAdaptiveActionSheet(
                        context,
                        cancelLabel: l10n.cancel,
                        actions: [
                          SheetAction(label: l10n.camera, icon: CupertinoIcons.camera, onPressed: () => _addPhoto(PhotoSource.camera)),
                          SheetAction(label: l10n.gallery, icon: CupertinoIcons.photo, onPressed: () => _addPhoto(PhotoSource.gallery)),
                        ],
                      ),
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
            if (askTemperature || askHumidity) ...[
              // Ce que le capteur ne mesure pas — ou tout, sans capteur, ou
              // pour une plante dehors — se demande, sans obligation : un
              // air à 30 % explique des pointes sèches mieux qu'une photo.
              const SizedBox(height: Space.sm),
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
              const SizedBox(height: Space.xs),
              Text(l10n.diagnosisClimateHint, style: context.text.caption),
            ],
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
            // Le même corps que la réouverture depuis le journal : ce qu'on
            // lit ici est exactement ce qu'on retrouvera plus tard.
            DiagnosisReportView(
              record: DiagnosisRecord(
                diagnosis: _result!,
                symptoms: _symptoms.text.trim(),
                photos: [for (final p in _photos) DiagnosisPhoto(filePath: p.filePath, thumbPath: p.thumbPath)],
              ),
            ),
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

/// Plafond de photos par analyse (aligné sur l'adaptateur).
abstract final class DiagnosisLimits {
  static const maxImages = 3;
}
