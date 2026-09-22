# B. Information architecture

## Navigation principale — 4 onglets
Un cinquième onglet « Ajouter » a été évalué et écarté : l'ajout est un bouton flottant discret sur *Plantes* et une entrée dans *Aujourd'hui* quand la collection est vide. Un onglet dédié n'aurait servi qu'à remplir la barre.

```
Tab bar
├── Aujourd'hui   (ce qui demande attention)
├── Plantes       (la collection)
├── Jardin        (emplacements, [inventaire P2], [calendrier P2])
└── Profil        (apparence, notifications, archives, compte, soutien, à propos)
```

## Hiérarchie des écrans
```
Root
├── Ouverture (clin d'œil du logo, docs/06) → Onboarding (5 écrans + lieu + prénom + compte [iOS, backend] + soutien) → Shell
└── Shell (tabs)
    ├── Aujourd'hui
    │   ├── [Plante] → Fiche plante
    │   └── Action rapide (in-place, Undo toast)
    ├── Plantes
    │   ├── Recherche (inline)
    │   ├── Filtres / tri (sheet) : dix tris, mémorisés ; la carte dit ce que le tri regarde
    │   ├── Grille ⇄ liste
    │   ├── Multi-sélection (long press) → barre d'actions
    │   ├── + Ajouter → Flow création (sheet plein écran, 3 étapes)
    │   └── Fiche plante (push plein écran, tab bar masquée)
    │       ├── Ajouter une action (sheet)
    │       ├── Ajouter une note (sheet)
    │       ├── Ajouter une photo (flow 2 étapes : viser avec calque, titrer)
    │       ├── Fiche d'entretien (push) · sous elle, sa place dans la maison relevée [LiDAR] → Où la poser (sheet)
    │       ├── Planning d'entretien (push)
    │       ├── Croissance (push) : timelapse, avant / après, visionneuse plein écran
    │       ├── Timeline complète (push)
    │       ├── Modifier (sheet) : nom, espèce, emplacement, santé (+ problème) · Plus d'options : besoins, détails
    │       └── Menu ⋯ : favori, bouture, déplacer, archiver
    ├── Jardin
    │   ├── Emplacements (arborescence)
    │   │   ├── Nouvel emplacement (sheet)
    │   │   └── Fiche emplacement → plan de la pièce relevée [LiDAR] (feuille du relevé), ou « Scanner cette pièce » ; plantes de l'emplacement
    │   └── [Inventaire, Calendrier — Phase 2]
    └── Profil
        ├── Apparence (système / clair / sombre, reduced motion)
        ├── Notifications (heure, jours silencieux, regroupement)
        ├── Types d'actions personnalisés
        ├── Anciennes plantes (archives) → restaurer
        ├── Unités (métrique / impérial)
        ├── Langue
        ├── Encyclopédie (push) : problèmes (et phénomènes normaux) · espèces · vocabulaire
        │   ├── Problème (push) : famille, étendue, hôtes, plantes du jardin concernées
        │   ├── Phénomène normal (push) : étendue, hôtes, plantes du jardin concernées — rien à soigner
        │   └── Espèce (push) : la fiche d'entretien, hors de toute plante
        ├── Scan de la maison [LiDAR] : toutes les pièces scannées, scanner tout le logement
        ├── Compte
        └── À propos
```

Le relevé d'une pièce vit avec son emplacement, dans *Jardin* : c'est là
qu'on le relève, qu'on voit son plan et ce qu'il apprend au lieu. La ligne
de *Profil* n'est que la vue d'ensemble — toutes les pièces, l'appartement
en une fois. Et une plante dit sa place sur sa propre fiche, sans passer
par un réglage (docs/17, « Les écrans »).

L'encyclopédie est sous *Profil* et non dans un onglet : c'est un contenu
qu'on consulte, pas un lieu où l'on passe. Les mêmes fiches se rejoignent
aussi par le chemin naturel — un problème listé sur la fiche d'entretien
d'une plante ouvre sa page, et une piste du diagnostic, problème ou phénomène
normal, ouvre la sienne.

## Conventions de présentation
| Contenu | Présentation |
|---|---|
| Action courte (ajouter action, note, choisir emplacement) | Bottom sheet, poignée, clavier géré |
| Flow multi-étapes (création plante, ajout de photo) | Sheet plein écran avec progression discrète |
| Photo en grand (visionneuse) | Route transparente sur le noir, héros depuis la vignette, tirer vers le bas pour refermer |
| Contenu immersif (fiche plante) | Push plein écran, header photo collapsible |
| Options secondaires | Menu contextuel (⋯) ou long press |
| Confirmation destructive | Action sheet native (Cupertino) / dialog M3 |
| Feedback | Toast bas d'écran avec Undo 5 s |

## Gestes
- Swipe gauche sur carte *Aujourd'hui* : « Plus tard » (report 1 jour).
- Swipe droite : compléter le soin.
- Long press sur plante : multi-sélection.
- Pull-to-refresh : uniquement quand la synchro distante existe (P2).
