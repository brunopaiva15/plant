import '../models/care_kind.dart';
import 'care_profile.dart';

/// Intervalles conseillés par la fiche d'entretien, pour préremplir une
/// routine plutôt que de partir d'un chiffre rond arbitraire.
///
/// `null` quand la fiche n'a rien à dire du type demandé (type personnalisé,
/// ou espèce qu'on ne rempote pas) : l'appelant retombe alors sur son défaut.
extension CareProfileSuggestions on CareProfile {
  int? suggestedIntervalDays(String typeKey, {DateTime? now, LightNeed? actualLight, bool south = false}) {
    final month = (now ?? DateTime.now()).month;
    return switch (CareKind.fromKey(typeKey)) {
      CareKind.watering => wateringDaysFor(month, south: south, actualLight: actualLight),
      CareKind.fertilizing => fertilizingDays,
      // Le rempotage se compte en mois ; le mois vaut 30 jours, ce qui
      // suffit pour une échéance à deux ans près.
      CareKind.repotting => repotEveryMonths == null ? null : repotEveryMonths! * 30,
      // La fiche ne chiffre ni le nettoyage ni le traitement. On part de ce
      // qu'elle dit de la plante : un feuillage qu'on brumise est un feuillage
      // large, qui prend la poussière plus vite ; une espèce à ravageurs
      // connus mérite un contrôle plus rapproché.
      CareKind.cleaning => mistLeaves ? 21 : 30,
      CareKind.treatment => issues.any(_isPest) ? 60 : 90,
      // La taille dépend de la forme voulue et de la saison, pas d'un
      // intervalle : un trimestre pour cadrer, à ajuster.
      CareKind.pruning => 90,
      _ => null,
    };
  }
}

bool _isPest(CommonIssue issue) => switch (issue) {
      CommonIssue.spiderMites ||
      CommonIssue.mealybugs ||
      CommonIssue.scale ||
      CommonIssue.aphids ||
      CommonIssue.fungusGnats ||
      CommonIssue.whitefly ||
      CommonIssue.slugs =>
        true,
      _ => false,
    };
