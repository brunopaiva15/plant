# Fiche App Store

Ce que l'on saisit dans App Store Connect, par langue. Les visuels sont
décrits dans [README.md](README.md) ; ici, seuls les textes.

Limites d'Apple, respectées ci-dessous : **titre 30 caractères**, **sous-titre
30**, **mots-clés 100 au total, virgules comprises**. Les mots-clés n'ont pas
besoin de reprendre le titre ni le sous-titre — Apple les indexe déjà — ni
d'espace après les virgules, qui coûterait un caractère pour rien.

## Français (langue principale)

| Champ | Valeur | Longueur |
|---|---|---|
| Titre | `Auxin : Carnet de plantes` | 25 / 30 |
| Sous-titre | `Journal, soins, identification` | 30 / 30 |
| Mots-clés | `rappel,arrosage,fleurs,jardinage,entretien,arroser,botanique,malade,calendrier,rempotage,photo,pot` | 98 / 100 |

## Deutsch

| Champ | Valeur | Longueur |
|---|---|---|
| Titre | `Auxin: Pflanzenjournal` | 22 / 30 |
| Sous-titre | `Pflege, Gießen, Erkennung` | 25 / 30 |
| Mots-clés | `tagebuch,erinnerung,garten,blumen,umpflanzen,dünger,zimmerpflanze,wachstum,kalender,botanik,tracker` | 99 / 100 |

## English

| Champ | Valeur | Longueur |
|---|---|---|
| Titre | `Auxin: Plant Journal` | 20 / 30 |
| Sous-titre | `Care, watering, identification` | 30 / 30 |
| Mots-clés | `diary,reminder,garden,flowers,repotting,fertilizer,indoor,houseplant,growth,tracker,calendar,botany` | 99 / 100 |

## Italiano

| Champ | Valeur | Longueur |
|---|---|---|
| Titre | `Auxin: Diario delle piante` | 26 / 30 |
| Sous-titre | `Cura, acqua, riconoscimento` | 27 / 30 |
| Mots-clés | `promemoria,giardino,fiori,annaffiatura,rinvaso,fertilizzante,crescita,calendario,botanica,tracker` | 97 / 100 |

## Reste à faire

- Les visuels ne sont générés qu'en `fr/` et `en/` : l'allemand et l'italien
  reprendront ceux de la langue principale tant que `compose.py` n'a pas de
  `COPY` pour eux.
- La description longue, les nouveautés de version et l'URL de politique de
  confidentialité ne sont pas encore écrites.
