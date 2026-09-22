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

## Modèle économique : un achat unique
- **L'application se paie une fois, au téléchargement sur l'App Store.** Le
  prix est celui que fixe App Store Connect ; l'application ne l'affiche
  nulle part.
- Une fois achetée, **tout est inclus et sans limite** : aucune fonction
  réservée, aucun abonnement, aucune publicité, aucun compte obligatoire,
  aucun plafond de plantes.
- Aucun achat intégré : l'ancien soutien facultatif (un pourboire au
  développeur, dans l'onboarding puis dans Profil) est retiré, avec son
  service et le plugin `in_app_purchase`. Une application déjà payée ne
  redemande rien.
