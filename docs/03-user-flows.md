# C. User flows

Notation : `[tap]` = un tap, `⟶` = transition, `✓` = feedback (animation + haptique légère).

## 1. Créer une plante (< 20 s, 3 étapes)
```
Plantes ─[tap +]⟶ Sheet plein écran
  Étape 1 · Photo
    [Prendre une photo] | [Choisir une photo] | Continuer sans photo
  Étape 2 · Nom
    Champ unique, clavier ouvert, suggestion = nom d'espèce si connu
    [Continuer]
  Étape 3 · Emplacement
    Chips : Salon · Cuisine · Chambre · Balcon · + Nouveau
    [Terminer]
✓ « Monstera ajoutée » ⟶ Fiche plante s'ouvre
```
- Routines par défaut créées automatiquement (arrosage 7 j, engrais 30 j) → « Plus d'options » pour ajuster.
- Étape « Identification » (P2) s'insère entre 1 et 2 uniquement si la fonction est activée et une photo existe.

## 2. Arroser une plante (1 tap)
```
Aujourd'hui ─ carte Monstera « 💧 Arroser aujourd'hui » ─[tap Arroser]⟶
  bouton se transforme en « ✓ Arrosée » (morph 250 ms, haptique success)
  carte glisse hors de la liste après 600 ms
  toast bas : « Monstera arrosée · Annuler » (5 s)
Effets : PlantAction(watering) créée · CareSchedule(watering).next_due recalculée · notification replanifiée
Undo : action supprimée, échéance restaurée, carte revient.
```
Variante depuis la fiche plante : chip 💧 ⟶ identique. Variante multi-sélection : « 6 plantes arrosées ».

## 3. Ajouter une photo
```
Fiche plante ─[tap 📷]⟶ Action sheet native : Caméra | Galerie
  ⟶ picker natif ⟶ compression (isolate) + miniature
  ⟶ ✓ photo apparaît dans la timeline et la galerie (hero)
  ⟶ si première photo : devient la photo principale
```

## 4. Créer un emplacement
```
Jardin ─[tap +]⟶ Sheet
  Nom (« Bureau »), icône (grille de 12), parent optionnel (Maison / Extérieur)
  Conditions optionnelles sous « Plus » : lumière, orientation
  [Créer]
✓ apparaît dans l'arborescence
```
Aussi accessible inline depuis l'étape 3 de création de plante (« + Nouveau »).

## 5. Créer / modifier un rappel (routine)
```
Fiche plante ─[tap « Planning »]⟶ Écran planning
  Liste des routines : 💧 Arrosage · tous les 7 jours · prochain : dans 2 j
  [tap ligne]⟶ Sheet : stratégie (Fixe / Saisonnier / Manuel), intervalle (stepper), activé
  [+ Ajouter une routine] ⟶ type (chips) puis même sheet
✓ prochaine échéance recalculée et affichée immédiatement
```
Stratégie *Intelligent* (météo / exposition) : Phase 3, même sheet, explication textuelle du décalage.

## 6. Première expérience (onboarding)
```
Splash ⟶ « Votre jardin, simplement. » [Ajouter ma première plante] · Plus tard
  ⟶ Flow création (identique au 1)
  ⟶ Fiche plante : « 💧 Arrosage recommandé dans 7 jours » [Arroser maintenant]
  ⟶ Notification proposée après la première action (permission demandée en contexte)
```

## 7. Archiver / restaurer
```
Fiche ─[⋯]⟶ Archiver ⟶ sheet : raison optionnelle (Morte · Donnée · Vendue · Autre)
✓ « Monstera archivée · Annuler »
Profil ⟶ Anciennes plantes ⟶ [Restaurer]
```

## 8. Trouver une plante (quatre questions)
```
Plantes (vide) ─[Trouver une plante]⟶ | Choisir une espèce ─[🧭 Trouver une plante]⟶
  Q1 · Où va-t-elle vivre ?      Pièce lumineuse · Lumière moyenne · Coin sombre · Dehors
  Q2 · Quel entretien ?          J'oublie souvent · Régulier · J'aime m'en occuper
  Q3 · Animaux ou enfants ?      Sans risque · Pas de contrainte
  Q4 · Quel genre ?              Chips multi-choix + texte libre (facultatif)
  ⟶ 5 propositions du catalogue, chacune avec sa raison (« Supporte l'ombre · Facile à vivre »)
  ─[tap]⟶ Fiche d'entretien en sheet ⟶ [Ajouter au jardin] (ou [Utiliser] depuis le sélecteur)
```
- Le tri se fait hors ligne sur les fiches d'entretien embarquées : lumière, difficulté,
  arrosage, toxicité, tenue dehors. Un critère sans réponse ne pèse pas.
- Éliminatoire, jamais négociable : toxicité inconnue quand on demande « sans risque »,
  plein soleil dans un coin sombre, espèce exigeante pour qui oublie d'arroser.
- Rien de convaincant ? On le dit, plutôt que de remplir la liste. [Demander à l'IA]
  élargit alors hors catalogue — appel réseau seulement sur ce geste, propositions
  marquées « à vérifier avant d'acheter ».
