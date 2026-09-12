# Auxine

Consignes pour travailler dans ce dépôt. La documentation de référence est
dans `docs/` (index dans `README.md`).

## Textes de l'interface

- Toute chaîne visible passe par les ARB (`lib/l10n/app_*.arb`, `app_fr.arb`
  est le modèle), dans les quatre langues, puis `flutter gen-l10n`. Les
  fichiers générés dans `lib/l10n/generated/` sont commités.
- Le ton suit `docs/06-design-system.md`, section « Les textes » : sobre,
  factuel, court. L'application ne parle pas d'elle-même (« nos », « notre »,
  « Auxine regarde »), n'interpelle pas la personne (« s'il vous plaît »,
  « personne ne vous juge », point d'exclamation), ne suppose pas
  (« probablement »). Un titre est un nom, pas une question.
- `test/l10n/arb_tone_test.dart` vérifie ces règles sur les quatre langues.
  Il doit passer ; une tournure à bannir de plus s'ajoute dans sa liste.
