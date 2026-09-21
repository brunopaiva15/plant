# Auxine

Consignes pour travailler dans ce dépôt. La documentation de référence est
dans `docs/` (index dans `README.md`).

## Textes de l'interface

- Toute chaîne visible passe par les ARB (`lib/l10n/app_*.arb`, `app_fr.arb`
  est le modèle), dans les quatre langues, puis `flutter gen-l10n`. Les
  fichiers générés dans `lib/l10n/generated/` sont commités.
- Le ton suit `docs/06-design-system.md`, section « Les textes » : sobre,
  factuel, court — **mais jamais impersonnel**. C'est la confusion à ne pas
  faire : un mode d'emploi sans personne dedans devient une description, et
  une description ne dit pas quoi faire. Elle a coûté une réécriture de 713
  chaînes (`docs/18-clarte-des-textes.md`).
- **On s'adresse à la personne.** Une consigne est à l'impératif, deuxième
  personne — « Scannez la pièce », et non « Tourner lentement » ni « La pièce
  se scanne ». Ce qui lui appartient se dit « votre ». Un libellé de bouton
  garde l'infinitif (« Ajouter une plante ») : c'est la forme française d'une
  commande, pas une description.
- **Chaque phrase a un sujet nommé.** Quand c'est le logiciel qui agit, on le
  dit : « l'application calcule la lumière de chaque endroit ». Ce qui reste
  interdit, c'est de lui prêter des intentions (« nos propositions »,
  « Auxine regarde la pluie ») — pas de décrire ce qu'il fait.
- **« Ne pas interpeller » vise la politesse creuse**, pas la deuxième
  personne : bannir « s'il vous plaît », « personne ne vous juge », « pas de
  panique », le point d'exclamation et l'à-peu-près (« probablement »).
  S'adresser à quelqu'un pour lui dire quoi faire, oui ; le rassurer, non.
- Un titre est un nom, pas une question. Les nombres s'écrivent en chiffres
  (« 5 à 8 cm »). Une aide tient en deux phrases et 140 signes ; un chapeau
  d'écran, 220.
- **Un seul registre par langue** : « vous » en français, *you* en anglais,
  *du* en allemand, *tu* en italien. Et chaque langue s'écrit depuis
  l'intention, pas depuis le français : une tournure française sans équivalent
  idiomatique se perd, elle ne se transpose pas. C'est ainsi qu'on évite
  qu'une *Spur* allemande traduise une piste de diagnostic, ou qu'une *pianta*
  italienne désigne à la fois la plante et le plan de la pièce.
- `test/l10n/arb_tone_test.dart` verrouille la part mécanique sur les quatre
  langues : exclamation, titre-question, tournures bannies, marqueurs ICU,
  apostrophe droite, longueur, registre. Il doit passer ; une tournure à
  bannir de plus s'ajoute dans sa liste.
- `tool/audit_textes.py` relève ce qui demande un œil et qu'aucun test ne peut
  trancher — consigne à l'infinitif, pronominal impersonnel, passif sans
  agent, phrase trop longue, registre ambigu. Le lancer avant et après avoir
  touché aux textes. Ce qu'il signale n'est pas toujours une faute : en
  allemand « Sie wächst in Erde » parle de la plante, en italien
  « Modificate » est un participe.
