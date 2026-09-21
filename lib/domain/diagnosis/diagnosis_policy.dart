import 'plant_diagnoser.dart';

/// Ce que l'écran fait d'un compte rendu qui vient d'arriver.
///
/// Une seule décision produit, comme pour l'identification (docs/16) : juger
/// la fiabilité d'un côté et demander une photo de l'autre finissait par se
/// contredire — un compte rendu jugé net qui redemandait malgré tout une
/// photo. Ici il n'y a qu'une sortie, et les trois cas sont exclusifs.
enum DiagnosisNextStep {
  /// Le compte rendu se lit tel quel.
  showResult,

  /// Les photos ne tranchent pas et il reste de la place pour une vue de
  /// plus : l'écran la propose, sans rien cacher de ce qui est déjà là.
  askAnotherPhoto,

  /// Rien ne tranche et il n'y a plus de photo à demander : les pistes
  /// restent des pistes, et l'écran le dit.
  keepUncertain,
}

/// Vrai quand le compte rendu désigne une piste et une seule.
///
/// C'est la seule forme de netteté qui vaille ici. Deux pistes « probables »
/// ne sont pas une réponse plus riche : elles appellent deux gestes
/// différents, et c'est à la personne qu'on laisse le tri. Aucune piste
/// probable non plus : le service a rempli son compte rendu sans rien voir
/// qui l'emporte.
bool diagnosisIsSettled(Diagnosis diagnosis) =>
    diagnosis.causes.where((c) => c.likelihood == Likelihood.likely).length == 1;

/// La décision locale, celle qui vaut sans réseau et qui sert de repli à
/// Jev.
///
/// Elle ne regarde que ce que le compte rendu porte : le nombre de pistes
/// probables et le nombre de photos déjà envoyées. Des règles, pas des
/// seuils sur une intuition — un modèle de langue ne rend aucun score qu'on
/// puisse comparer d'une analyse à l'autre.
DiagnosisNextStep diagnosisNextStep(
  Diagnosis diagnosis, {
  required int photos,
  required int maxPhotos,
}) {
  if (diagnosis.causes.isNotEmpty && diagnosisIsSettled(diagnosis)) return DiagnosisNextStep.showResult;
  return photos < maxPhotos ? DiagnosisNextStep.askAnotherPhoto : DiagnosisNextStep.keepUncertain;
}
