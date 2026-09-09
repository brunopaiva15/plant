import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/l10n/likelihood_labels.dart';
import '../../../data/problems/problem_catalog.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/care/care_engine.dart';
import '../../../domain/diagnosis/diagnosis_record.dart';
import '../../../domain/diagnosis/plant_diagnoser.dart';
import '../../../domain/problems/plant_problem.dart';
import '../../problems/presentation/problem_kind_icon.dart';

/// Rouvre un diagnostic gardé au journal, entier.
///
/// Le journal n'en montre qu'un aperçu — il en garde des dizaines et doit
/// rester lisible —, mais rien n'est perdu : la sheet rend le compte rendu
/// tel que l'analyse l'avait donné, pistes, explications et gestes compris.
Future<void> showDiagnosisReportSheet(BuildContext context, {required DiagnosisRecord record, required DateTime date}) =>
    showFloraSheet<void>(context, scrollable: true, builder: (_) => _SavedReport(record: record, date: date));

class _SavedReport extends StatelessWidget {
  const _SavedReport({required this.record, required this.date});

  final DiagnosisRecord record;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(title: context.l10n.diagnosisEntry),
          Text(
            '${Dates.longDate(context, date)} · ${Dates.time(context, date)}',
            style: context.text.caption,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Space.md),
          DiagnosisReportView(record: record),
          const SizedBox(height: Space.sm),
        ],
      ),
    );
  }
}

/// Le compte rendu d'une analyse : urgence, photos, résumé, symptômes
/// signalés, puis toutes les pistes.
///
/// Le même corps sert à l'analyse qui vient d'aboutir et à celle qu'on
/// rouvre des mois plus tard — sans quoi les deux se mettraient à diverger,
/// et « rouvrir le diagnostic » ne rendrait pas ce qu'on avait lu.
class DiagnosisReportView extends ConsumerWidget {
  const DiagnosisReportView({super.key, required this.record});

  final DiagnosisRecord record;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final catalog = ref.watch(problemCatalogProvider).value;
    final language = Localizations.localeOf(context).languageCode;
    final diagnosis = record.diagnosis;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (diagnosis.urgent) ...[
          DueBadge(emoji: '⚠️', label: l10n.urgentHint, status: DueStatus.overdue),
          const SizedBox(height: Space.xs),
        ],
        if (record.photos.isNotEmpty) ...[
          DiagnosisPhotoStrip(photos: record.photos),
          const SizedBox(height: Space.sm),
        ],
        Text(diagnosis.summary, style: context.text.body),
        if (record.symptoms != null) ...[
          const SizedBox(height: Space.sm),
          Text(l10n.diagnosisSymptomsNoted, style: context.text.caption),
          const SizedBox(height: 2),
          Text(record.symptoms!, style: context.text.callout),
        ],
        if (diagnosis.causes.isNotEmpty) ...[
          const SizedBox(height: Space.lg),
          Text(l10n.possibleCauses, style: context.text.title3),
          const SizedBox(height: Space.xxs),
          Text(l10n.identifyHint, style: context.text.caption),
          const SizedBox(height: Space.sm),
          for (final cause in diagnosis.causes)
            CauseCard(cause: cause, title: diagnosisCauseTitle(cause, catalog, language), problem: catalog?[cause.problemId]),
        ],
      ],
    );
  }
}

/// Le nom d'une piste : celui de la base quand le service en a reconnu une,
/// sinon le titre qu'il a écrit lui-même.
///
/// C'est tout l'intérêt de la base. Le même excès d'eau s'appelait
/// « Arrosage trop fréquent », « Trop d'eau » ou « Excès d'humidité au niveau
/// des racines » d'une analyse à l'autre ; il s'appelle désormais pareil à
/// chaque fois, et dans la langue de l'application — y compris sur une
/// analyse conservée avant un changement de langue.
String diagnosisCauseTitle(DiagnosisCause cause, ProblemCatalog? catalog, String language) =>
    catalog?[cause.problemId]?.nameIn(language) ?? cause.title;

/// Une piste : son nom, sa vraisemblance, ce qu'elle explique, les gestes.
class CauseCard extends StatelessWidget {
  const CauseCard({super.key, required this.cause, required this.title, this.problem});

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
                  emoji: likelihoodMark(cause.likelihood),
                  label: context.l10n.likelihoodLabel(cause.likelihood),
                  status: likelihoodStatus(cause.likelihood),
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

/// Le losange d'une vraisemblance : plein, à moitié, vide.
String likelihoodMark(Likelihood likelihood) => switch (likelihood) {
      Likelihood.likely => '◆',
      Likelihood.possible => '◈',
      Likelihood.unlikely => '◇',
    };

/// La teinte d'une vraisemblance, empruntée aux badges d'échéance.
DueStatus likelihoodStatus(Likelihood likelihood) => switch (likelihood) {
      Likelihood.likely => DueStatus.today,
      Likelihood.possible => DueStatus.upcoming,
      Likelihood.unlikely => DueStatus.none,
    };

/// Les photos analysées, quand elles sont encore là.
///
/// Elles restent sur l'appareil qui a fait l'analyse : seules les photos de
/// la galerie partent en synchronisation et en sauvegarde, et une photo de
/// feuille malade n'a rien à faire dans le suivi de croissance ni dans le
/// timelapse. Ailleurs — autre appareil, sauvegarde restaurée — le compte
/// rendu se lit sans elles plutôt que d'aligner des cadres vides.
class DiagnosisPhotoStrip extends ConsumerStatefulWidget {
  const DiagnosisPhotoStrip({super.key, required this.photos, this.side = 92});

  final List<DiagnosisPhoto> photos;
  final double side;

  @override
  ConsumerState<DiagnosisPhotoStrip> createState() => _DiagnosisPhotoStripState();
}

class _DiagnosisPhotoStripState extends ConsumerState<DiagnosisPhotoStrip> {
  /// Retenue une fois pour toutes : recréée à chaque construction, la bande
  /// clignoterait à chaque image du défilement.
  late Future<List<DiagnosisPhoto>> _kept = _stillThere();

  @override
  void didUpdateWidget(DiagnosisPhotoStrip old) {
    super.didUpdateWidget(old);
    if (old.photos != widget.photos) _kept = _stillThere();
  }

  Future<List<DiagnosisPhoto>> _stillThere() async {
    final storage = ref.read(photoStorageProvider);
    final kept = <DiagnosisPhoto>[];
    for (final photo in widget.photos) {
      if (await File(await storage.absolutePath(photo.thumbPath)).exists()) kept.add(photo);
    }
    return kept;
  }

  @override
  Widget build(BuildContext context) {
    final side = widget.side;
    return FutureBuilder<List<DiagnosisPhoto>>(
      future: _kept,
      builder: (context, snap) {
        final kept = snap.data ?? const <DiagnosisPhoto>[];
        if (kept.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: side,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final (i, photo) in kept.indexed)
                Padding(
                  padding: const EdgeInsets.only(right: Space.xs),
                  child: Pressable(
                    onTap: () => Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute<void>(builder: (_) => DiagnosisPhotoViewer(photos: kept, index: i), fullscreenDialog: true),
                    ),
                    scale: 0.95,
                    child: ClipRRect(
                      borderRadius: Radii.mediumAll,
                      child: SizedBox(width: side, height: side, child: PlantImage(relativePath: photo.thumbPath, cacheWidth: 300)),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Une photo de diagnostic en grand : c'est de près qu'on juge une tache.
class DiagnosisPhotoViewer extends ConsumerStatefulWidget {
  const DiagnosisPhotoViewer({super.key, required this.photos, required this.index});

  final List<DiagnosisPhoto> photos;
  final int index;

  @override
  ConsumerState<DiagnosisPhotoViewer> createState() => _DiagnosisPhotoViewerState();
}

class _DiagnosisPhotoViewerState extends ConsumerState<DiagnosisPhotoViewer> {
  late final _controller = PageController(initialPage: widget.index);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storage = ref.watch(photoStorageProvider);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.photos.length,
            itemBuilder: (context, i) => GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: FutureBuilder<String>(
                  future: storage.absolutePath(widget.photos[i].filePath),
                  builder: (context, snap) => snap.hasData
                      ? Image.file(File(snap.data!), fit: BoxFit.contain, gaplessPlayback: true)
                      : const SizedBox.expand(),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(Space.sm),
              child: FloraIconButton(
                icon: CupertinoIcons.xmark,
                semanticLabel: context.l10n.close,
                onPressed: () => Navigator.of(context).pop(),
                background: Colors.white24,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
