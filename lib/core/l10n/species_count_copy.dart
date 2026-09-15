import '../../l10n/generated/app_localizations.dart';

/// Libellés qui expliquent ce que comptent les trois catalogues d'espèces.
///
/// Ils restent séparés des compteurs génériques : l'encyclopédie compte des
/// fiches détaillées, l'index des sources des espèces référencées et Iris les
/// espèces qu'il sait reconnaître visuellement. Une recherche dans
/// l'encyclopédie compte simplement les résultats réellement affichés.
extension SpeciesCountCopy on AppLocalizations {
  String get _languageCode => localeName.split(RegExp(r'[-_]')).first;

  String encyclopediaDetailedSpeciesCount(int count) => switch (_languageCode) {
        'fr' => count == 1 ? '1 fiche détaillée' : '$count fiches détaillées',
        'de' => count == 1 ? '1 detaillierter Arteneintrag' : '$count detaillierte Arteneinträge',
        'it' => count == 1 ? '1 scheda dettagliata' : '$count schede dettagliate',
        _ => count == 1 ? '1 detailed species profile' : '$count detailed species profiles',
      };

  String encyclopediaSearchResultCount(int count) => switch (_languageCode) {
        'fr' => count == 1 ? '1 résultat' : '$count résultats',
        'de' => count == 1 ? '1 Ergebnis' : '$count Ergebnisse',
        'it' => count == 1 ? '1 risultato' : '$count risultati',
        _ => count == 1 ? '1 result' : '$count results',
      };

  String referencedSpeciesCount(String count) => switch (_languageCode) {
        'fr' => '$count espèces référencées',
        'de' => '$count erfasste Arten',
        'it' => '$count specie censite',
        _ => '$count referenced species',
      };

  String get irisRecognizableSpeciesLabel => switch (_languageCode) {
        'fr' => 'espèces reconnaissables',
        'de' => 'erkennbare Arten',
        'it' => 'specie riconoscibili',
        _ => 'recognizable species',
      };
}
