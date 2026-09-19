import '../../domain/diagnosis/diagnosis_observations.dart';
import '../../domain/diagnosis/plant_diagnoser.dart';
import '../../l10n/generated/app_localizations.dart';

/// Les mots des observations : la terre, les racines, la lumière, les
/// insectes. Un seul jeu, partagé par la feuille qui les demande et par le
/// compte rendu qui les relit — sans quoi « Détrempée » deviendrait « Terre
/// gorgée d'eau » d'un écran à l'autre.
extension DiagnosisObservationLabels on AppLocalizations {
  String soilStateLabel(SoilState v) => switch (v) {
        SoilState.dry => diagnosisSoilDry,
        SoilState.moist => diagnosisSoilMoist,
        SoilState.soggy => diagnosisSoilSoggy,
      };

  String rootStateLabel(RootState v) => switch (v) {
        RootState.firm => diagnosisRootsFirm,
        RootState.soft => diagnosisRootsSoft,
        RootState.crowded => diagnosisRootsCrowded,
      };

  String lightExposureLabel(LightExposure v) => switch (v) {
        LightExposure.direct => diagnosisLightDirect,
        LightExposure.bright => diagnosisLightBright,
        LightExposure.dim => diagnosisLightDim,
      };

  String bugSightingLabel(BugSighting v) => switch (v) {
        BugSighting.none => diagnosisBugsNone,
        BugSighting.onPlant => diagnosisBugsOnPlant,
        BugSighting.inSoil => diagnosisBugsInSoil,
      };

  /// Ce qui a été coché, sujet par sujet, pour le compte rendu : le sujet
  /// d'un côté, ce qui a été vu de l'autre. Ce qui n'a pas été coché n'a pas
  /// de ligne — une case vide ne dit rien, et n'a rien à afficher.
  List<(String, String)> observationRows(DiagnosisObservations o) => [
        if (o.soil != null) (diagnosisSoil, soilStateLabel(o.soil!)),
        if (o.roots != null) (diagnosisRoots, rootStateLabel(o.roots!)),
        if (o.light != null) (light, lightExposureLabel(o.light!)),
        if (o.bugs != null) (diagnosisBugs, bugSightingLabel(o.bugs!)),
      ];
}

/// La photo qu'il reste à prendre, nommée.
///
/// « Une meilleure photo » ne dit pas quoi cadrer ; « le revers d'une
/// feuille » se photographie sans y réfléchir. Les cinq vues sont celles que
/// le service a le droit de demander, et elles se lisent comme des groupes
/// nominaux : la phrase qui les accueille les met bout à bout sans article à
/// recoller.
extension DiagnosisViewLabels on AppLocalizations {
  String diagnosisViewLabel(DiagnosisView v) => switch (v) {
        DiagnosisView.leafCloseup => diagnosisViewLeafCloseup,
        DiagnosisView.leafUnderside => diagnosisViewLeafUnderside,
        DiagnosisView.wholePlant => diagnosisViewWholePlant,
        DiagnosisView.stemBase => diagnosisViewStemBase,
        DiagnosisView.soilRoots => diagnosisViewSoilRoots,
      };
}
