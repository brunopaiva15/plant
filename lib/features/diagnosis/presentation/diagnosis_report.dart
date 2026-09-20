import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/l10n/diagnosis_labels.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/l10n/likelihood_labels.dart';
import '../../../data/problems/problem_catalog.dart';
import '../../../design_system/design_system.dart';
import '../../../domain/care/care_engine.dart';
import '../../../domain/diagnosis/diagnosis_record.dart';
import '../../../domain/diagnosis/plant_diagnoser.dart';
import '../../../domain/problems/natural_cause.dart';
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

/// Le compte rendu d'une analyse : les photos regardées, les pistes, puis le
/// constat et ce qui avait été signalé et coché.
///
/// Les pistes d'abord : c'est ce qu'on est venu lire. Le constat et les
/// symptômes signalés prenaient tout l'écran au-dessus d'elles, et on
/// descendait sous un paragraphe et sa propre phrase pour apprendre ce que
/// la plante a. Ils suivent désormais, pour qui veut comprendre sur quoi
/// les pistes reposent.
///
/// Le même corps sert à l'analyse qui vient d'aboutir et à celle qu'on
/// rouvre des mois plus tard — sans quoi les deux se mettraient à diverger,
/// et « rouvrir le diagnostic » ne rendrait pas ce qu'on avait lu.
class DiagnosisReportView extends ConsumerWidget {
  const DiagnosisReportView({super.key, required this.record, this.uncertain = false});

  final DiagnosisRecord record;

  /// Vrai quand l'analyse ne tranche pas et qu'aucune photo de plus n'est à
  /// demander : les pistes le disent en toutes lettres, sous leur titre,
  /// plutôt que de laisser croire qu'elles concluent. Une analyse rouverte du journal ne
  /// garde pas cet état — elle n'a plus de décision en cours, seulement ce
  /// qui a été écrit ce jour-là.
  final bool uncertain;

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
        if (record.photos.isNotEmpty) ...[
          DiagnosisPhotoStrip(photos: record.photos, side: 108),
          const SizedBox(height: Space.md),
        ],
        // L'urgence avant tout, en terre cuite — la seule chose qui change
        // de couleur dans le compte rendu.
        if (diagnosis.urgent) ...[
          const _UrgentCard(),
          const SizedBox(height: Space.sm),
        ],
        if (diagnosis.causes.isNotEmpty) ...[
          SectionHeader(title: l10n.possibleCauses, padding: const EdgeInsets.only(bottom: Space.xxs)),
          // Quand l'analyse ne tranche pas, c'est dit ici, sur les pistes
          // que cela qualifie.
          Text(uncertain ? l10n.diagnosisUncertain : l10n.causesHint, style: context.text.caption),
          const SizedBox(height: Space.sm),
          for (final cause in diagnosis.causes)
            CauseCard(
              cause: cause,
              title: diagnosisCauseTitle(cause, catalog, language),
              problem: catalog?[cause.problemId],
              naturalCause: catalog?.natural(cause.naturalId),
            ),
          const SizedBox(height: Space.sm),
        ],
        // Puis ce sur quoi les pistes reposent : le constat de l'analyse —
        // la tuile, le nom, la phrase, comme une carte du matin —, ce qui
        // avait été signalé, vérifié et répondu.
        _FindingCard(
          summary: diagnosis.summary,
          uncertain: uncertain && diagnosis.causes.isEmpty,
          natural: diagnosis.onlyNatural,
        ),
        if (record.symptoms != null) ...[
          const SizedBox(height: Space.sm),
          FloraGroup(
            header: l10n.diagnosisSymptomsNoted,
            children: [FloraListRow(title: record.symptoms!, chevron: false, dense: true)],
          ),
        ],
        // Ce qui avait été vérifié à la main ce jour-là. La photo ne le
        // montre pas, et c'est pourtant la moitié de ce qui a mené aux
        // pistes : le compte rendu ne se relit pas sans lui.
        if (record.observations.isNotEmpty) ...[
          const SizedBox(height: Space.sm),
          FloraGroup(
            header: l10n.diagnosisChecks,
            children: [
              for (final (label, value) in l10n.observationRows(record.observations))
                FloraListRow(
                  title: label,
                  chevron: false,
                  trailing: Text(value, style: context.text.callout, textAlign: TextAlign.end),
                  dense: true,
                ),
            ],
          ),
        ],
        // Ce que le service avait demandé et ce qu'on lui a répondu : une part
        // de ce qui a mené aux pistes, au même titre que les symptômes.
        if (record.answers.isNotEmpty) ...[
          const SizedBox(height: Space.sm),
          FloraGroup(
            header: l10n.diagnosisAnswersNoted,
            children: [
              for (final a in record.answers)
                FloraListRow(title: a.question, subtitle: a.answer, chevron: false, dense: true, titleMaxLines: 2),
            ],
          ),
        ],
      ],
    );
  }
}

/// L'urgence, en tête du compte rendu : un ravageur, une pourriture, un
/// déclin rapide. Elle passe avant les pistes — c'est ce qui presse — et
/// ne redit rien d'autre : les pistes disent quoi, juste dessous.
class _UrgentCard extends StatelessWidget {
  const _UrgentCard();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return FloraCard(
      color: c.terracottaSoft,
      child: Row(
        children: [
          EmojiTile(emoji: '⚠️', background: c.surface, variant: 2),
          const SizedBox(width: Space.md),
          Expanded(child: Text(context.l10n.urgentHint, style: context.text.callout.copyWith(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

/// Ce que l'analyse a vu, sous les pistes.
class _FindingCard extends StatelessWidget {
  const _FindingCard({required this.summary, required this.uncertain, this.natural = false});

  final String summary;

  /// Vrai quand l'analyse ne tranche pas et qu'aucune piste ne porte déjà la
  /// mention : sans piste, le constat est le seul endroit où le dire.
  final bool uncertain;

  /// Vrai quand aucune piste n'est un problème. Les pistes le disent déjà
  /// par leur pastille ; le constat le redit en titre, sur la feuille.
  final bool natural;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FloraCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EmojiTile(emoji: natural ? '🌿' : '🩺', variant: 2),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  natural ? l10n.diagnosisNothingWrong : l10n.diagnosisFinding,
                  style: context.text.caption.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                if (summary.isNotEmpty) Text(summary, style: context.text.body),
                if (uncertain) ...[
                  const SizedBox(height: Space.xs),
                  Text(l10n.diagnosisUncertain, style: context.text.caption),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// La photo qui préciserait l'analyse, proposée après le compte rendu.
///
/// Elle vient après les pistes, jamais à leur place : ce qui est déjà su se
/// lit d'abord, et la photo de plus est un geste offert, pas un péage.
class AnotherPhotoCard extends StatelessWidget {
  const AnotherPhotoCard({super.key, required this.onAdd, this.view});

  final VoidCallback onAdd;
  final DiagnosisView? view;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    return FloraCard(
      color: c.sageSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EmojiTile(emoji: '📷', background: c.surface, variant: 3),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.diagnosisAnotherPhotoHint, style: context.text.callout),
                    if (view case final v?) ...[
                      const SizedBox(height: 2),
                      Text(l10n.diagnosisAnotherPhotoView(l10n.diagnosisViewLabel(v)), style: context.text.caption),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.sm),
          FloraButton(
            label: l10n.diagnosisAnotherPhoto,
            icon: CupertinoIcons.camera,
            style: FloraButtonStyle.secondary,
            expand: true,
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}

/// Les questions du service, avec de quoi y répondre.
///
/// Une photo ne dit ni depuis quand, ni ce qui a changé dans la pièce, ni ce
/// qui a déjà été tenté ; le service répondait donc avec ce qu'il avait.
/// Quand rien ne tranche, il pose une à trois questions, et la réponse
/// relance l'analyse entière — ce n'est pas un complément qui se recolle à
/// côté du compte rendu précédent, c'est le compte rendu qui se refait.
///
/// Elle porte ses champs elle-même : des questions qui changent emportent les
/// brouillons qu'on leur destinait, ce qui est exactement ce qu'on veut.
class DiagnosisQuestionsCard extends StatefulWidget {
  const DiagnosisQuestionsCard({super.key, required this.questions, required this.onAnswered});

  final List<String> questions;

  /// Ce qui a été rempli — les questions laissées vides ne partent pas.
  final ValueChanged<List<DiagnosisAnswer>> onAnswered;

  @override
  State<DiagnosisQuestionsCard> createState() => _DiagnosisQuestionsCardState();
}

class _DiagnosisQuestionsCardState extends State<DiagnosisQuestionsCard> {
  late final _fields = {for (final q in widget.questions) q: TextEditingController()};

  @override
  void dispose() {
    for (final field in _fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  List<DiagnosisAnswer> get _given => [
        for (final e in _fields.entries)
          if (e.value.text.trim().isNotEmpty) DiagnosisAnswer(question: e.key, answer: e.value.text.trim()),
      ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final given = _given;
    return FloraCard(
      color: c.sunSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EmojiTile(emoji: '💬', background: c.surface, variant: 1),
              const SizedBox(width: Space.md),
              Expanded(child: Text(l10n.diagnosisQuestionsHint, style: context.text.callout)),
            ],
          ),
          for (final q in widget.questions) ...[
            const SizedBox(height: Space.sm),
            Text(q, style: context.text.body),
            const SizedBox(height: Space.xxs),
            FloraTextField(
              controller: _fields[q],
              hint: l10n.diagnosisAnswerHint,
              minLines: 1,
              maxLines: 3,
              // La carte se redessine à mesure : c'est ce qui allume le
              // geste dès la première réponse écrite.
              onChanged: (_) => setState(() {}),
            ),
          ],
          const SizedBox(height: Space.sm),
          FloraButton(
            label: l10n.diagnosisAnswerAgain,
            icon: CupertinoIcons.sparkles,
            style: FloraButtonStyle.secondary,
            expand: true,
            onPressed: given.isEmpty ? null : () => widget.onAnswered(given),
          ),
        ],
      ),
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
    catalog?[cause.problemId]?.nameIn(language) ?? catalog?.natural(cause.naturalId)?.nameIn(language) ?? cause.title;

/// Une piste : son nom, sa vraisemblance, ce qu'elle explique, les gestes.
class CauseCard extends StatelessWidget {
  const CauseCard({super.key, required this.cause, required this.title, this.problem, this.naturalCause});

  final DiagnosisCause cause;

  /// Déjà résolu par la base : la carte n'a plus qu'à l'afficher.
  final String title;

  /// L'entrée de la base, quand le service en a reconnu une. `null` pour une
  /// cause hors base, qui n'a alors pas d'image plutôt qu'une image
  /// approximative.
  final PlantProblem? problem;

  /// L'entrée de la base des phénomènes naturels, même chose de l'autre
  /// côté : elle porte le dessin de ce phénomène-là.
  final NaturalCause? naturalCause;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final known = problem;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: FloraCard(
        // Une piste que la base connaît mène à sa fiche : ce que c'est, qui
        // elle touche, à quoi elle ressemble. Une piste hors base n'a nulle
        // part où mener et ne se presse pas.
        onTap: known == null ? null : () => context.push(Routes.encyclopediaProblem(known.id)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // La tuile du compte rendu : l'illustration d'argile de la
                // base, posée sur la teinte de sa famille — l'ocre des
                // troubles, la terre cuite des ravageurs, le rose des
                // maladies. Une piste hors base garde la tuile, sans dessin,
                // et un phénomène naturel porte la feuille : il n'a pas de
                // famille.
                _KindTile(problem: known, natural: cause.natural, naturalCause: naturalCause),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: context.text.title3),
                      const SizedBox(height: Space.xxs),
                      // Trois crans, pas de barre : il n'y a rien à remplir
                      // quand il n'y a rien à mesurer. Une piste naturelle
                      // garde le sien — le service n'est pas plus sûr de
                      // reconnaître du nectar qu'une cochenille — et dit en
                      // plus qu'elle n'est pas un problème.
                      Wrap(
                        spacing: Space.xxs,
                        runSpacing: Space.xxs,
                        children: [
                          DueBadge(
                            emoji: likelihoodMark(cause.likelihood),
                            label: context.l10n.likelihoodLabel(cause.likelihood),
                            status: likelihoodStatus(cause.likelihood),
                            compact: true,
                          ),
                          if (cause.natural)
                            DueBadge(
                              emoji: '🌿',
                              label: context.l10n.diagnosisNatural,
                              status: DueStatus.none,
                              // Le vert du fait accompli : ici il ne confirme
                              // pas un soin, il dit qu'il n'y en a pas à
                              // faire.
                              done: true,
                              compact: true,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (known != null) ...[
                  const SizedBox(width: Space.xs),
                  Icon(CupertinoIcons.chevron_right, size: 15, color: c.inkTertiary),
                ],
              ],
            ),
            if (cause.explanation.isNotEmpty) ...[
              const SizedBox(height: Space.sm),
              Text(cause.explanation, style: context.text.callout),
            ],
            // Les gestes se détachent de l'explication : on lit pourquoi,
            // puis on fait quoi.
            if (cause.actions.isNotEmpty) ...[
              const SizedBox(height: Space.sm),
              Container(height: 1, color: c.line),
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

/// La tuile d'une piste : le dessin de la base sur la teinte de sa famille.
class _KindTile extends StatelessWidget {
  const _KindTile({required this.problem, this.natural = false, this.naturalCause});

  final PlantProblem? problem;

  /// Le phénomène nommé par la base, quand il l'est : il a son dessin, comme
  /// un problème a le sien.
  final NaturalCause? naturalCause;

  /// Une piste qui n'est pas un problème : elle a son symbole d'argile, la
  /// feuille et sa goutte claire, qui ne se confond avec aucune des quatre
  /// familles.
  final bool natural;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final p = problem;
    final tint = natural && p == null
        ? c.sageSoft
        : switch (p?.kind) {
            ProblemKind.disorder => c.sunSoft,
            ProblemKind.pest => c.terracottaSoft,
            ProblemKind.disease => c.roseSoft,
            ProblemKind.condition => c.sageSoft,
            null => c.surfaceMuted,
          };
    return Container(
      width: EmojiTile.side,
      height: EmojiTile.side,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: tint, borderRadius: Radii.mediumAll),
      child: p != null
          ? ProblemIcon(problem: p, side: 30)
          : natural
              ? NaturalCauseIcon(cause: naturalCause, side: 30)
              : Icon(CupertinoIcons.question, size: 18, color: c.inkTertiary),
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
