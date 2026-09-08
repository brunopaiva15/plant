import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/l10n/likelihood_labels.dart';
import '../../../data/problems/problem_catalog.dart';
import '../../../data/services/photo_storage_service.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/care/care_engine.dart';
import '../../../domain/care/care_guide.dart';
import '../../../domain/care/care_profile.dart';
import '../../../domain/diagnosis/plant_diagnoser.dart';
import '../../../domain/problems/plant_problem.dart';
import '../../../domain/models/models.dart';
import '../../../domain/repositories/repositories.dart';
import '../../actions/application/care_actions.dart';
import 'analysis_wait.dart';
import '../../problems/presentation/problem_kind_icon.dart';

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
  bool _busy = false;
  Diagnosis? _result;

  @override
  void dispose() {
    _symptoms.dispose();
    // Les photos de diagnostic sont temporaires : on nettoie.
    final storage = ref.read(photoStorageProvider);
    for (final p in _photos) {
      storage.deleteFiles(p.filePath, p.thumbPath);
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
      final result = await ref.read(plantDiagnoserProvider).diagnose(
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
          );
      Haptics.success();
      if (mounted) setState(() => _result = result);
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

  /// L'entrée de la base que le service a reconnue, s'il en a reconnu une.
  PlantProblem? _problemOf(DiagnosisCause cause, ProblemCatalog? catalog) => catalog?[cause.problemId];

  /// Le nom de la piste : celui de la base quand le service en a reconnu une,
  /// sinon le titre qu'il a écrit lui-même.
  ///
  /// C'est tout l'intérêt de la base. Le même excès d'eau s'appelait
  /// « Arrosage trop fréquent », « Trop d'eau » ou « Excès d'humidité au
  /// niveau des racines » d'une analyse à l'autre ; il s'appelle désormais
  /// pareil à chaque fois, et dans la langue de l'application.
  String _titleOf(DiagnosisCause cause, ProblemCatalog? catalog, String language) =>
      _problemOf(cause, catalog)?.nameIn(language) ?? cause.title;

  Future<void> _save() async {
    final l10n = context.l10n;
    final r = _result!;
    final catalog = ref.read(problemCatalogProvider).value;
    final language = Localizations.localeOf(context).languageCode;
    final text = [
      r.summary,
      ...r.causes.take(3).map((c) => '• ${_titleOf(c, catalog, language)} (${l10n.likelihoodLabel(c.likelihood).toLowerCase()})'),
    ].join('\n');
    await ref.read(careActionsProvider).log(
          NewAction(plantId: widget.plant.id, typeKey: CareKind.note.key, notes: text),
          message: l10n.diagnosisSaved,
          undoLabel: l10n.undo,
          emoji: '🩺',
        );
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
            const SizedBox(height: Space.lg),
            FloraButton(label: l10n.analyze, icon: CupertinoIcons.sparkles, expand: true, onPressed: _photos.isEmpty ? null : _analyze),
          ] else ...[
            if (_result!.urgent) DueBadge(emoji: '⚠️', label: l10n.urgentHint, status: DueStatus.overdue),
            if (_result!.urgent) const SizedBox(height: Space.xs),
            Text(_result!.summary, style: context.text.body),
            const SizedBox(height: Space.lg),
            Text(l10n.possibleCauses, style: context.text.title3),
            const SizedBox(height: Space.xxs),
            Text(l10n.identifyHint, style: context.text.caption),
            const SizedBox(height: Space.sm),
            for (final cause in _result!.causes)
              () {
                final catalog = ref.watch(problemCatalogProvider).value;
                return _CauseCard(
                  cause: cause,
                  title: _titleOf(cause, catalog, Localizations.localeOf(context).languageCode),
                  problem: _problemOf(cause, catalog),
                );
              }(),
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

class _CauseCard extends StatelessWidget {
  const _CauseCard({required this.cause, required this.title, this.problem});

  final DiagnosisCause cause;

  /// Déjà résolu par la base : la carte n'a plus qu'à l'afficher.
  final String title;

  /// L'entrée de la base, quand le service en a reconnu une. `null` pour une
  /// cause hors base, qui n'a alors pas d'image plutôt qu'une image
  /// approximative.
  final PlantProblem? problem;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.xs),
      child: FloraCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (problem != null) ...[
                  ProblemIcon(problem: problem!),
                  const SizedBox(width: Space.sm),
                ],
                Expanded(child: Text(title, style: context.text.title3)),
                const SizedBox(width: Space.xs),
                // Trois crans, pas de barre : il n'y a rien à remplir quand
                // il n'y a rien à mesurer.
                DueBadge(
                  emoji: switch (cause.likelihood) { Likelihood.likely => '◆', Likelihood.possible => '◈', Likelihood.unlikely => '◇' },
                  label: context.l10n.likelihoodLabel(cause.likelihood),
                  status: switch (cause.likelihood) {
                    Likelihood.likely => DueStatus.today,
                    Likelihood.possible => DueStatus.upcoming,
                    Likelihood.unlikely => DueStatus.none,
                  },
                  compact: true,
                ),
              ],
            ),
            const SizedBox(height: Space.xs),
            Text(cause.explanation, style: context.text.callout),
            if (cause.actions.isNotEmpty) ...[
              const SizedBox(height: Space.xs),
              for (final a in cause.actions)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('→ ', style: context.text.callout.copyWith(color: c.sage)),
                      Expanded(child: Text(a, style: context.text.callout.copyWith(color: c.ink))),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
