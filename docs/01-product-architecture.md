# A. Product architecture

## Le produit en une phrase
Une application personnelle, belle et calme, pour prendre soin de ses plantes et garder leur histoire — capable d'absorber une collection de 1 000 plantes sans jamais ressembler à un logiciel.

## Promesse
> « Je comprends l'état de toutes mes plantes en quelques secondes, et j'enregistre un soin en un ou deux gestes. »

## Ce que l'app est
- Un **journal vivant** : chaque plante a une timeline (photos, soins, notes, mesures).
- Un **assistant discret** : l'écran *Aujourd'hui* dit quoi faire, pas plus.
- Un **outil de collection** : emplacements, tags, recherche, sélection multiple, archives.

## Ce que l'app n'est pas
- Pas un ERP, pas un tableur, pas un dashboard, pas un clone de HortusFox, pas un gadget IA.

## Utilisateurs cibles
| Profil | Besoin principal | Réponse produit |
|---|---|---|
| 3 plantes | « Quand arroser ? » | Aujourd'hui + notification utile |
| 20 plantes | Garder une trace, ne rien oublier | Timeline, planning par plante |
| 100+ plantes / serre | Gérer par lot, retrouver vite | Emplacements, recherche, multi-sélection, QR (P2) |
| Foyer | Partager la charge | Collaboration (P3) |

## Modèle mental
```
Jardin (collection) ─┬─ Emplacements (Maison → Salon…)
                     └─ Plantes ─┬─ Planning (routines)
                                 ├─ Actions (historique)
                                 ├─ Photos (croissance)
                                 ├─ Notes / tags
                                 └─ Boutures (relations)
```
Les **routines** (ce qui doit se passer) sont strictement séparées des **actions** (ce qui s'est passé). Une action complète la routine correspondante et recalcule la prochaine échéance.

## Progressive disclosure
| Surface | Toujours visible | Sous « Plus » |
|---|---|---|
| Création plante | photo, nom, emplacement | espèce, date d'acquisition, source, prix, pot, notes |
| Fiche plante | photo, nom, prochains soins, actions rapides, timeline | informations, relations, fichiers, options avancées |
| Action | type, « Enregistrer » | date, note, quantité |

## Modèle économique : gratuit, avec un soutien facultatif
- **Tout est gratuit et sans limite.** Aucune fonction réservée, aucune publicité,
  aucun compte obligatoire, aucun plafond de plantes.
- Un achat unique, facultatif, permet de remercier le développeur. Il ne
  déverrouille rien : c'est un pourboire, pas une clé.
- `SupportService` (domaine) + adaptateur magasin (`StoreSupportService`, produit
  non consommable `ch.vergasta.plant.support`). Là où le magasin n'existe pas —
  le web, un appareil sans achat intégré — l'écran le dit au lieu d'afficher un
  bouton mort.
- Deux points d'entrée, tous deux évitables d'un geste : la dernière page de
  l'onboarding, et une ligne dans Profil.
