import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flora/domain/identification/cascade_identifier.dart';
import 'package:flora/domain/identification/context_mask.dart';
import 'package:flora/domain/identification/identification_confidence.dart';
import 'package:flora/domain/identification/identification_context.dart';
import 'package:flora/domain/identification/identification_metrics.dart';
import 'package:flora/domain/identification/identification_policy.dart';
import 'package:flora/domain/identification/local_plant_model.dart';
import 'package:flora/domain/identification/plant_identifier.dart';
import 'package:flutter_test/flutter_test.dart';

/// Le masque de lieu, du `model.json` jusqu'au verdict.
///
/// Ce que ces tests tiennent, c'est le § 14 de `docs/09` : un seul fichier
/// livré, le masque appliqué dans l'application rend ce que rendrait le modèle
/// retaillé, et le lieu ne rend jamais la bonne réponse impossible.
void main() {
  String nameOf(String id) => id;

  group('les masques de model.json', () {
    const labels = ['a', 'b', 'c', 'd'];

    test('se lisent par lieu', () {
      final meta = jsonEncode({
        'classes': 4,
        'masks': {
          'indoor': ['a', 'c'],
          'outdoor': ['b', 'c', 'd'],
        },
      });
      final masks = contextMasks(meta, labels);
      expect(masks[IdentificationContext.indoor], {0, 2});
      expect(masks[IdentificationContext.outdoor], {1, 2, 3});
      // Une espèce peut appartenir aux deux : ce sont des contextes, pas deux
      // taxonomies exclusives (`docs/14` § 8).
      expect(masks[IdentificationContext.indoor]!.intersection(masks[IdentificationContext.outdoor]!), {2});
    });

    test('un modèle sans masque n\'en déclare aucun', () {
      expect(contextMasks(jsonEncode({'classes': 4}), labels), isEmpty);
    });

    test('un masque qui couvre tout ne masque rien', () {
      final meta = jsonEncode({
        'masks': {'indoor': labels},
      });
      expect(contextMasks(meta, labels), isEmpty);
    });

    test('une classe que le modèle n\'expose pas est ignorée', () {
      final meta = jsonEncode({
        'masks': {
          'indoor': ['a', 'jamais-apprise'],
        },
      });
      expect(contextMasks(meta, labels)[IdentificationContext.indoor], {0});
    });

    test('des métadonnées illisibles coûtent les masques, pas le modèle', () {
      expect(contextMasks('{ ceci n\'est pas du json', labels), isEmpty);
    });
  });

  group('le masque appliqué aux sorties', () {
    const labels = ['a', 'b', 'c', 'd'];

    test('sans masque, les scores sont rendus tels quels', () {
      final out = maskedCandidates([0.5, 0.2, 0.2, 0.1], labels, nameOf: nameOf);
      expect(out.map((c) => c.internalId), ['a', 'b', 'c', 'd']);
      expect(out.first.score, closeTo(0.5, 1e-9));
      expect(out.first.globalScore, closeTo(0.5, 1e-9));
      expect(out.every((c) => c.inContext), isTrue);
    });

    test('masquer puis renormaliser rend exactement ce que rend un retaillage', () {
      // Le cœur du § 14.2. On part de logits, on en fait un softmax complet
      // — ce que le graphe livré calcule — puis on masque et on renormalise.
      // En face, le softmax d'une tête dont les colonnes non gardées ont été
      // supprimées, c'est-à-dire ce que produit `retailler.py`.
      const logits = [2.1, -0.4, 1.3, 0.7];
      const kept = [0, 2];
      final expSum = logits.map(math.exp).reduce((a, b) => a + b);
      final softmax = [for (final z in logits) math.exp(z) / expSum];
      final keptSum = kept.map((i) => math.exp(logits[i])).reduce((a, b) => a + b);
      final truncated = {for (final i in kept) labels[i]: math.exp(logits[i]) / keptSum};

      final out = maskedCandidates(softmax, labels, nameOf: nameOf, mask: kept.toSet());
      for (final c in out.where((c) => c.inContext)) {
        expect(c.score, closeTo(truncated[c.internalId]!, 1e-12),
            reason: '${c.internalId} doit valoir ce que vaudrait la tête tronquée');
      }
    });

    test('les classes d\'ailleurs sont rendues en plus, à leur score global', () {
      final out = maskedCandidates([0.5, 0.2, 0.2, 0.1], labels,
          nameOf: nameOf, mask: {0, 2});
      final inside = out.where((c) => c.inContext).toList();
      final outside = out.where((c) => !c.inContext).toList();

      expect(inside.map((c) => c.internalId), ['a', 'c']);
      expect(inside.first.score, closeTo(0.5 / 0.7, 1e-9));
      // Le score global, lui, ne bouge pas : c'est la seule échelle sur
      // laquelle le lieu et le reste du monde se comparent.
      expect(inside.first.globalScore, closeTo(0.5, 1e-9));

      expect(outside.map((c) => c.internalId), ['b', 'd']);
      expect(outside.first.score, closeTo(0.2, 1e-9));
      expect(outside.first.globalScore, closeTo(0.2, 1e-9));
    });

    test('un lieu qui n\'explique rien est abandonné plutôt que divisé par zéro', () {
      final out = maskedCandidates([0.0, 0.6, 0.0, 0.4], labels, nameOf: nameOf, mask: {0, 2});
      expect(out.every((c) => c.inContext), isTrue);
      expect(out.map((c) => c.internalId), ['b', 'd']);
    });
  });

  group('la décision, quand le lieu a masqué', () {
    const policy = FallbackPolicy();

    IdentificationCandidate here(String name, double score, double global) => IdentificationCandidate(
          scientificName: name,
          score: score,
          globalScore: global,
          source: IdentificationSource.local,
        );

    IdentificationCandidate elsewhere(String name, double global) => IdentificationCandidate(
          scientificName: name,
          score: global,
          globalScore: global,
          inContext: false,
          source: IdentificationSource.local,
        );

    test('sans masque, rien ne change', () {
      expect(policy.decide([here('Monstera deliciosa', 0.92, 0.92), here('Monstera adansonii', 0.03, 0.03)]),
          IdentificationVerdict.accepted);
    });

    test('le lieu tranche, et le candidat d\'ailleurs ne le conteste pas', () {
      final verdict = policy.decide([
        here('Monstera deliciosa', 0.92, 0.55),
        here('Monstera adansonii', 0.05, 0.03),
        elsewhere('Acer palmatum', 0.40),
      ]);
      expect(verdict, IdentificationVerdict.accepted);
    });

    test('un candidat d\'ailleurs nettement plus fort remonte la liste à plausible', () {
      // Le lieu hésite — ses scores renormalisés restent bas — et une espèce
      // qu'il excluait est très au-dessus sur l'échelle globale. La liste
      // vaut alors d'être montrée plutôt que remplacée par un appel distant.
      final candidates = [
        here('Nephrolepis cordifolia', 0.20, 0.04),
        here('Asplenium nidus', 0.12, 0.02),
        elsewhere('Veronica elliptica', 0.62),
      ];
      expect(policy.decide(candidates), IdentificationVerdict.plausible);
      expect(policy.challenger(candidates)?.scientificName, 'Veronica elliptica');
    });

    test('sous la marge, le candidat d\'ailleurs se tait', () {
      final candidates = [
        here('Nephrolepis cordifolia', 0.20, 0.30),
        elsewhere('Veronica elliptica', 0.40),
      ];
      expect(policy.challenger(candidates), isNull);
      expect(policy.decide(candidates), IdentificationVerdict.uncertain);
    });

    test('un candidat d\'ailleurs sous le plancher ne compte pas', () {
      expect(policy.challenger([here('Monstera deliciosa', 0.20, 0.02), elsewhere('Acer palmatum', 0.06)]), isNull);
    });

    test('sans masque, il n\'y a pas de candidat d\'ailleurs', () {
      expect(policy.challenger([here('Monstera deliciosa', 0.92, 0.92)]), isNull);
    });

    test('le genre ne somme que ce qui est sur la même échelle', () {
      // Trois Monstera du lieu pèsent 0,75 : le genre répond. L'érable
      // d'ailleurs n'a rien à faire dans cette masse.
      final answer = genusAnswer(policy, [
        here('Monstera deliciosa', 0.30, 0.10),
        here('Monstera adansonii', 0.25, 0.08),
        here('Monstera obliqua', 0.20, 0.07),
        elsewhere('Acer palmatum', 0.50),
      ]);
      expect(answer?.genus, 'Monstera');
      expect(answer?.species, 3);
      expect(answer?.mass, closeTo(0.75, 1e-9));
    });
  });

  group('le mot affiché suit la décision', () {
    test('un candidat du lieu, accepté, reste « probable »', () {
      expect(
          IdentificationConfidence.of(const IdentificationCandidate(
            scientificName: 'Monstera deliciosa',
            score: 0.92,
            globalScore: 0.55,
            source: IdentificationSource.local,
          )),
          IdentificationConfidence.likely);
    });

    test('un candidat d\'ailleurs est au mieux « possible »', () {
      // 0,62 dépasserait le seuil d'acceptation si on le lisait sur
      // l'échelle du lieu. Il n'y est pas : il est proposé, pas affirmé.
      expect(
          IdentificationConfidence.of(const IdentificationCandidate(
            scientificName: 'Veronica elliptica',
            score: 0.62,
            globalScore: 0.62,
            inContext: false,
            source: IdentificationSource.local,
          )),
          IdentificationConfidence.possible);
    });
  });

  group('la cascade porte le lieu jusqu\'au modèle', () {
    late Directory dir;
    late File photo;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('flora-contexte');
      photo = File('${dir.path}/a.jpg')..writeAsBytesSync([1, 2, 3]);
    });

    tearDown(() => dir.delete(recursive: true));

    test('le lieu descend jusqu\'à classify', () async {
      final local = _RecordingLocal();
      final cascade = CascadeIdentifier(
        local: local,
        fallback: const UnconfiguredIdentifier(),
        metrics: InMemoryMetricsStore(),
      );
      await cascade.identify([photo], context: IdentificationContext.outdoor);
      expect(local.contextsSeen, [IdentificationContext.outdoor]);
    });

    test('deux lieux ne partagent pas la même réponse en cache', () async {
      final local = _RecordingLocal();
      final cascade = CascadeIdentifier(
        local: local,
        fallback: const UnconfiguredIdentifier(),
        metrics: InMemoryMetricsStore(),
      );
      await cascade.identify([photo], context: IdentificationContext.indoor);
      await cascade.identify([photo], context: IdentificationContext.indoor);
      await cascade.identify([photo], context: IdentificationContext.outdoor);
      // Le même lieu deux fois : une seule inférence. Un lieu différent : une
      // nouvelle, sans quoi la réponse serait renormalisée sur le mauvais
      // ensemble.
      expect(local.contextsSeen, [IdentificationContext.indoor, IdentificationContext.outdoor]);
    });
  });
}

class _RecordingLocal implements LocalPlantModel {
  final contextsSeen = <IdentificationContext>[];

  @override
  bool get isAvailable => true;
  @override
  String? get version => 'test-masque';
  @override
  int get speciesCount => 2;
  @override
  String? get loadError => null;
  @override
  Set<IdentificationContext> get contexts => const {IdentificationContext.indoor, IdentificationContext.outdoor};
  @override
  Future<bool> warmUp() async => true;
  @override
  void dispose() {}

  @override
  Future<List<IdentificationCandidate>> classify(File image,
      {IdentificationContext context = IdentificationContext.unknown}) async {
    contextsSeen.add(context);
    return const [
      IdentificationCandidate(
        scientificName: 'Monstera deliciosa',
        score: 0.92,
        globalScore: 0.55,
        source: IdentificationSource.local,
      ),
    ];
  }
}
