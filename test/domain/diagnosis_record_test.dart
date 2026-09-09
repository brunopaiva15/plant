import 'dart:convert';

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
}
