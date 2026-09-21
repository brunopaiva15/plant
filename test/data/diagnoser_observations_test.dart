import 'dart:convert';

import 'package:flora/data/services/infomaniak_diagnoser.dart';
import 'package:flora/domain/diagnosis/diagnosis_observations.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ce que la personne a vérifié de sa main part avec la question : la photo
/// ne montre ni une terre détrempée, ni des racines brunes, ni trois pucerons
/// sous une feuille.
void main() {
  test('les quatre observations sont dans la question, données pour vérifiées', () {
    final prompt = InfomaniakDiagnoser.userPrompt(
      language: 'fr',
      plantName: 'Calathea',
      observations: const DiagnosisObservations(
        soil: SoilState.soggy,
        roots: RootState.soft,
        light: LightExposure.direct,
        bugs: BugSighting.onPlant,
      ),
    );
    expect(prompt, contains('the soil is soaked'));
    expect(prompt, contains('brown, soft or smelling'));
    expect(prompt, contains('direct sun for part of the day'));
    expect(prompt, contains('insects are visible on the plant'));
    expect(prompt, contains('verified, not guessed'));
    // Conseiller de regarder les racines qu'on vient de sortir du pot était
    // le travers à couper.
    expect(prompt, contains('never give as an action something that has already been checked'));
  });

  test('ce qui n’a pas été coché ne part pas', () {
    expect(InfomaniakDiagnoser.observationsLine(null), isNull);
    expect(InfomaniakDiagnoser.observationsLine(DiagnosisObservations.none), isNull);
    expect(InfomaniakDiagnoser.userPrompt(language: 'fr'), isNot(contains('Checked by the owner')));
    // Une seule case répondue est une observation comme une autre ; les trois
    // autres questions n'existent pas pour le modèle.
    final seule = InfomaniakDiagnoser.observationsLine(const DiagnosisObservations(soil: SoilState.dry))!;
    expect(seule, contains('the soil is dry'));
    expect(seule, isNot(contains('roots')));
    expect(seule, isNot(contains('insect')));
  });

  test('« aucun insecte vu » est une observation, pas un silence', () {
    // Une case laissée vide ne dit rien ; cochée sur « aucun vu », elle pèse
    // contre les ravageurs, et c'est une information.
    final line = InfomaniakDiagnoser.observationsLine(const DiagnosisObservations(bugs: BugSighting.none))!;
    expect(line, contains('no insect was found'));
    expect(line, contains('undersides of the leaves'));
  });

  test('un constat de la main pèse autant qu’une photo', () {
    final consigne = InfomaniakDiagnoser.systemPrompt('fr');
    // La consigne rangeait tout ce que l'image ne montre pas sous la règle
    // des symptômes racontés, qui interdit « probable » : une terre
    // détrempée et des racines brunes ne menaient alors jamais à une
    // pourriture probable, et ce qu'on était allé vérifier ne pesait rien.
    expect(consigne, contains('checked by hand'));
    expect(consigne, contains('as solid as the photos'));
    expect(consigne, contains('a cause they support may be "likely"'));
    expect(consigne, contains('never "likely" — unless what the owner checked by hand supports them'));
    // Une plante saine en photo dont la terre et les racines disent autre
    // chose : le constat décide, la photo ne le couvre pas.
    expect(consigne, contains('a hand check points to a cause the leaves do not show yet'));
    // Et le compte rendu dit sur quoi il s'appuie, faute de quoi la personne
    // lit un résumé de ses photos et croit ses réponses perdues.
    expect(consigne, contains('say that in "summary" too'));
  });

  test('des insectes vus de ses yeux valent une piste de ravageur', () {
    final consigne = InfomaniakDiagnoser.systemPrompt('fr');
    // Le cas qui a fait revoir la consigne : « insectes sur la plante »
    // coché, deux photos de thrips, et un compte rendu de phénomènes
    // normaux. Un thrips mesure un millimètre : l'image ne le montrera pas.
    expect(consigne, contains('When the owner checked that insects are on the plant or in the soil'));
    expect(consigne, contains('Give a pest among the causes'));
    expect(consigne, contains('never answer with normal phenomena alone'));
    // Et la case « aucun vu » joue dans l'autre sens.
    expect(consigne, contains('weigh pests down instead'));
  });

  test('la passe de repli les emporte aussi', () {
    // Le repli juge sur les mots, les photos n'ayant rien donné : c'est là
    // que ce qui a été vérifié compte le plus.
    final body = InfomaniakDiagnoser.buildFallbackRequest(
      language: 'fr',
      species: 'Calathea orbifolia',
      observations: const DiagnosisObservations(roots: RootState.crowded, light: LightExposure.dim),
    );
    final texte = jsonEncode(body);
    expect(texte, contains('coiled, filling the whole pot'));
    expect(texte, contains('the plant gets little light'));
  });
}
