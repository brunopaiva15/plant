import 'dart:convert';

import 'package:flora/domain/diagnosis/diagnosis_observations.dart';
import 'package:flora/domain/diagnosis/diagnosis_record.dart';
import 'package:flora/domain/diagnosis/plant_diagnoser.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ce qui permet de rouvrir un diagnostic des mois plus tard : le compte rendu
/// entier, gardé dans les métadonnées de l'entrée du journal, et relu même
/// quand il a été écrit par une version antérieure.
void main() {
  final diagnostic = Diagnosis(
    summary: 'Feuilles jaunes en bas, terre humide.',
    urgent: true,
    causes: [
      const DiagnosisCause(
        title: "Excès d'eau",
        likelihood: Likelihood.likely,
        explanation: 'La terre ne sèche pas entre deux arrosages.',
        actions: ['Laisser sécher', 'Vérifier le drainage'],
        problemId: '002',
      ),
      const DiagnosisCause(
        title: 'Manque de lumière',
        likelihood: Likelihood.possible,
        explanation: 'La plante est loin de la fenêtre.',
        actions: [],
      ),
    ],
  );

  /// L'aller-retour réel : le compte rendu passe par la colonne `metadata`,
  /// qui est du texte JSON.
  DiagnosisRecord? throughJson(DiagnosisRecord record) {
    final encoded = jsonEncode({DiagnosisRecord.metadataKey: record.toJson()});
    return DiagnosisRecord.fromMetadata((jsonDecode(encoded) as Map).cast<String, Object?>());
  }

  test('un diagnostic enregistré se relit entier', () {
    final relu = throughJson(DiagnosisRecord(
      diagnosis: diagnostic,
      symptoms: 'Les feuilles tombent depuis une semaine.',
      photos: const [DiagnosisPhoto(filePath: 'a.jpg', thumbPath: 'a_thumb.jpg')],
    ))!;

    expect(relu.diagnosis.summary, diagnostic.summary);
    expect(relu.diagnosis.urgent, isTrue);
    expect(relu.symptoms, 'Les feuilles tombent depuis une semaine.');
    expect(relu.photos.single.filePath, 'a.jpg');
    expect(relu.photos.single.thumbPath, 'a_thumb.jpg');

    // Rien de ce que l'analyse a rendu n'est perdu en route : c'est tout
    // l'objet de la réouverture.
    expect(relu.diagnosis.causes, hasLength(2));
    final premiere = relu.diagnosis.causes.first;
    expect(premiere.title, "Excès d'eau");
    expect(premiere.likelihood, Likelihood.likely);
    expect(premiere.explanation, 'La terre ne sèche pas entre deux arrosages.');
    expect(premiere.actions, ['Laisser sécher', 'Vérifier le drainage']);
    expect(premiere.problemId, '002', reason: 'le numéro renomme la piste dans la langue du moment');
    expect(relu.diagnosis.causes.last.problemId, isNull);
    expect(relu.diagnosis.causes.last.actions, isEmpty);
  });

  test('ce qui avait été vérifié se relit aussi', () {
    final relu = throughJson(DiagnosisRecord(
      diagnosis: diagnostic,
      observations: const DiagnosisObservations(soil: SoilState.soggy, roots: RootState.soft, bugs: BugSighting.none),
    ))!;

    expect(relu.observations.soil, SoilState.soggy);
    expect(relu.observations.roots, RootState.soft);
    expect(relu.observations.bugs, BugSighting.none, reason: '« aucun vu » est une réponse, pas une case vide');
    expect(relu.observations.light, isNull, reason: 'une question sans réponse en reste une');

    // Rien de coché, rien de gardé : le compte rendu n'a pas de rubrique
    // « Observations » à afficher.
    final sans = DiagnosisRecord(diagnosis: diagnostic);
    expect(sans.observations.isEmpty, isTrue);
    expect(sans.toJson().containsKey('observations'), isFalse);
  });

  test('un mot d’observation inconnu vaut une case non répondue', () {
    final relu = DiagnosisRecord.fromMetadata(const {
      DiagnosisRecord.metadataKey: {
        'summary': 'Taches brunes.',
        'observations': {'soil': 'humide', 'light': 'direct', 'bugs': 42},
      },
    })!;
    expect(relu.observations.soil, isNull, reason: 'un mot hors vocabulaire ne se devine pas');
    expect(relu.observations.bugs, isNull);
    expect(relu.observations.light, LightExposure.direct, reason: 'le reste de la rubrique se lit quand même');
  });

  test('un champ de symptômes laissé vide ne devient pas un symptôme', () {
    final record = DiagnosisRecord(diagnosis: diagnostic, symptoms: '   ');
    expect(record.symptoms, isNull);
    expect(record.toJson().containsKey('symptoms'), isFalse);
    expect(throughJson(record)!.symptoms, isNull);
  });

  test('une entrée de journal ordinaire ne porte aucun compte rendu', () {
    expect(DiagnosisRecord.fromMetadata(const {}), isNull);
    expect(DiagnosisRecord.fromMetadata(const {'quantity': 250, 'unit': 'ml'}), isNull);
    // Une clé présente mais vide ne fait pas un diagnostic non plus.
    expect(DiagnosisRecord.fromMetadata(const {DiagnosisRecord.metadataKey: 'oui'}), isNull);
    expect(DiagnosisRecord.fromMetadata(const {DiagnosisRecord.metadataKey: {'causes': []}}), isNull);
  });

  test('un compte rendu abîmé se lit pour ce qu\'il en reste', () {
    final relu = DiagnosisRecord.fromMetadata(const {
      DiagnosisRecord.metadataKey: {
        'summary': 'Taches brunes.',
        'urgent': 'peut-être',
        'causes': [
          {'title': 'Anthracnose', 'likelihood': 0.8, 'actions': ['Retirer les feuilles', 42, '']},
          'une cause qui n\'en est pas une',
          {},
        ],
        'photos': [
          {'file': 'b.jpg'},
          {'thumb': 'orphelin.jpg'},
        ],
      },
    })!;

    expect(relu.diagnosis.summary, 'Taches brunes.');
    expect(relu.diagnosis.urgent, isFalse, reason: 'seul un vrai booléen déclenche l\'urgence');
    expect(relu.diagnosis.causes, hasLength(1), reason: 'ni le texte ni la carte vide ne sont des pistes');
    final cause = relu.diagnosis.causes.first;
    expect(cause.likelihood, Likelihood.likely, reason: 'un nombre est rangé dans un cran');
    expect(cause.explanation, '');
    expect(cause.actions, ['Retirer les feuilles']);
    // Une vignette sans original se relit ; une entrée sans fichier est jetée.
    expect(relu.photos, hasLength(1));
    expect(relu.photos.single.thumbPath, 'b.jpg');
  });

  test('une piste naturelle se relit pour ce qu\'elle est', () {
    final relu = throughJson(DiagnosisRecord(
      diagnosis: const Diagnosis(
        summary: 'Des gouttes claires et collantes sous les feuilles.',
        causes: [
          DiagnosisCause(
            title: 'Gouttes sucrées',
            likelihood: Likelihood.likely,
            explanation: 'Le philodendron en produit sur le revers de ses feuilles.',
            actions: [],
            naturalId: 'N01',
            natural: true,
          ),
        ],
      ),
    ))!;

    final piste = relu.diagnosis.causes.single;
    expect(piste.naturalId, 'N01', reason: 'la base la renomme dans la langue du moment');
    expect(piste.natural, isTrue);
    expect(piste.problemId, isNull);
    expect(relu.diagnosis.onlyNatural, isTrue);
  });

  test('un phénomène hors base se relit aussi, et un compte rendu d\'avant reste un problème', () {
    final relu = throughJson(DiagnosisRecord(
      diagnosis: const Diagnosis(
        summary: '…',
        causes: [
          DiagnosisCause(title: 'Vieille fronde qui finit', likelihood: Likelihood.possible, explanation: '…', actions: [], natural: true),
        ],
      ),
    ))!;
    expect(relu.diagnosis.causes.single.natural, isTrue);
    expect(relu.diagnosis.causes.single.naturalId, isNull);

    // Une analyse gardée avant que les phénomènes naturels existent ne porte
    // pas la clé : elle se relit comme un problème, ce qu'elle disait.
    final ancien = Diagnosis.fromJson({
      'summary': '…',
      'causes': [
        {'title': 'Tétranyques', 'likelihood': 'likely', 'problemId': '060'},
      ],
    });
    expect(ancien.causes.single.natural, isFalse);
    expect(ancien.onlyNatural, isFalse);
  });
}
