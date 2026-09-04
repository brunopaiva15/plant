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
├── Splash → Onboarding (5 écrans + prénom + soutien) → Shell
└── Shell (tabs)
    ├── Aujourd'hui
    │   ├── [Plante] → Fiche plante
    │   └── Action rapide (in-place, Undo toast)
    ├── Plantes
    │   ├── Recherche (inline)
    │   ├── Filtres / tri (sheet)
    │   ├── Grille ⇄ liste
    │   ├── Multi-sélection (long press) → barre d'actions
    │   ├── + Ajouter → Flow création (sheet plein écran, 3 étapes)
    │   └── Fiche plante (push plein écran, tab bar masquée)
    │       ├── Ajouter une action (sheet)
    │       ├── Ajouter une note (sheet)
    │       ├── Ajouter une photo (picker natif)
    │       ├── Planning d'entretien (push)
    │       ├── Galerie (push)
    │       ├── Timeline complète (push)
    │       ├── Modifier (sheet)
    │       └── Menu ⋯ : favori, bouture, déplacer, archiver
    ├── Jardin
    │   ├── Emplacements (arborescence)
    │   │   ├── Nouvel emplacement (sheet)
    │   │   └── Fiche emplacement → plantes de l'emplacement
    │   └── [Inventaire, Calendrier — Phase 2]
    └── Profil
        ├── Apparence (système / clair / sombre, reduced motion)
        ├── Notifications (heure, jours silencieux, regroupement)
        ├── Types d'actions personnalisés
        ├── Anciennes plantes (archives) → restaurer
        ├── Unités (métrique / impérial)
        ├── Langue
        ├── Compte
        └── À propos
```

## Conventions de présentation
| Contenu | Présentation |
|---|---|
| Action courte (ajouter action, note, choisir emplacement) | Bottom sheet, poignée, clavier géré |
| Flow multi-étapes (création plante) | Sheet plein écran avec progression discrète |
| Contenu immersif (fiche plante) | Push plein écran, header photo collapsible |
| Options secondaires | Menu contextuel (⋯) ou long press |
| Confirmation destructive | Action sheet native (Cupertino) / dialog M3 |
| Feedback | Toast bas d'écran avec Undo 5 s |

## Gestes
- Swipe gauche sur carte *Aujourd'hui* : « Plus tard » (report 1 jour).
- Swipe droite : compléter le soin.
- Long press sur plante : multi-sélection.
- Pull-to-refresh : uniquement quand la synchro distante existe (P2).
