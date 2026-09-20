# C. User flows

Notation : `[tap]` = un tap, `⟶` = transition, `✓` = feedback (animation + haptique légère).

## 1. Créer une plante (< 20 s, 3 étapes)
```
Plantes ─[tap +]⟶ Sheet plein écran
  Étape 1 · Photo, en trois états
    Viser      viseur dans le cadre, déclencheur rond dessus, galerie dans un coin
               [tap cadre] ou [◯] déclenche · Continuer sans photo
    On la      la photo prise remplit le cadre (c'est la confirmation)
    garde ?    dessous, si Iris est là : « La plante » · [+ Une feuille de près] · [+ Autre vue]
               [Continuer] · Reprendre
    Une vue    [tap emplacement] ⟶ le viseur revient sous le titre de l'emplacement,
    de plus    rend la main dès la prise ; × ou Annuler ramène à la photo
  Étape 2 · Nom
    Champ unique, clavier fermé — les propositions d'identification se lisent
    d'abord, le champ s'ouvre d'un toucher ; suggestion = nom d'espèce si connu
    [Continuer]
  Étape 3 · Emplacement
    Chips : Salon · Cuisine · Chambre · Balcon · + Nouveau
    [Terminer]
✓ « Monstera ajoutée » ⟶ Fiche plante s'ouvre
```
- Routines par défaut créées automatiquement (arrosage 7 j, engrais 30 j) → « Plus d'options » pour ajuster.
- Étape « Identification » (P2) s'insère entre 1 et 2 uniquement si la fonction est activée et une photo existe.
- Le viseur ne tourne qu'à l'étape 1, tant qu'il reste un emplacement libre. Sans lui — autorisation refusée, appareil sans caméra — le cadre garde son invite, les gestes reviennent en boutons ([Prendre une photo] · [Choisir une photo]) et un emplacement libre ouvre l'appareil ou la galerie du système.
- Quand l'application passe derrière (multitâche, appel), le système reprend la caméra : le viseur est *suspendu*, pas absent. Le cadre garde ses commandes et la page sa mise en page, et l'aperçu revient au retour. La carte du multitâche montre donc la même étape.
- Reprendre efface la photo et les vues prises avec elle : elles montraient le même sujet. Les vues ne sont proposées que si un moteur d'identification est configuré, et ne sont jamais gardées.

## 1b. Multiplier une plante (le guide, puis la création)
```
Fiche plante ─[Créer une bouture]⟶ Guide de multiplication (sheet plein écran)
  Plusieurs méthodes possibles ? un écran de choix d'abord :
    Multiplier cette plante
      Division           Rapide et sûre, la touffe se partage   [Conseillée]
      Bouture de feuille Plus lente, une feuille suffit
  Puis le guide du geste retenu :
  Bouture de tige de Monstera deliciosa   les gestes du guide réunis, qui
                      jouent et dérivent · « 6 étapes » · [Suivant]
  Une étape par écran : un objet d'argile rendu sous Blender joue le geste
  sur un halo, puis respire ; un titre, une phrase, parfois une ligne de plus.
    Le nœud          la plante mère se pose, un anneau entoure le nœud choisi
                     — « À repérer · Nœud et racine aérienne »
    La coupe         les ciseaux se ferment SOUS le nœud, qui part avec la
                     bouture — « À éviter · Couper au-dessus du nœud »
    Le nœud dégagé   la feuille du bas se décroche, le nœud reste nu
    L'eau            la bouture descend dans le verre, le nœud sous la surface
                     — « Enracinement · Dans l'eau », dit par la fiche d'espèce
    Les racines      elles sortent du nœud et s'allongent
    Le pot           la bouture racinée descend dans la terre
  [Continuer] × n · [Créer la bouture] ⟶ flow de création, nom « Bouture de … »
  Passer ⟶ flow de création tout de suite · × ⟶ rien n'est créé
```
- Le geste montré est celui que la plante demande, choisi par
  `resolvePropagationGuide` sur l'espèce, la famille et la fiche d'entretien :
  bouture de tige à nœud, de tige tendre, de feuille, division, rejet, keiki,
  ou segment de succulente. Un spathiphyllum ne voit jamais une bouture de
  liane. Les sept archétypes et leurs règles : docs/12.
- Le nombre d'étapes appartient au guide : quatre, six, ou davantage. Les
  points de progression, la grappe d'introduction et le bouton final suivent.
  Une division crée une plante, pas une bouture, et le bouton le dit.
- Les phrases sont celles de l'archétype, déjà justes sans IA. Quand la plante
  mère a une espèce et que « Compléter les fiches avec l'IA » est laissé
  allumé, l'espèce, la méthode et la liste des étapes partent une fois, et les
  phrases sont réécrites pour l'espèce : où est le nœud, eau ou substrat,
  délai, saison. Le modèle ne choisit ni la méthode, ni le nombre d'étapes, ni
  les animations. Le texte local s'affiche d'abord, le texte précis le remplace
  en fondu. Les titres ne changent pas. Le texte reçu est mis au ton de
  l'application : ni point d'exclamation ni point-virgule, une majuscule par
  phrase.
- La réponse est gardée sur l'appareil, par espèce, par langue et par geste :
  la multiplication suivante de la même plante ne redemande rien, et le texte
  d'une division ne ressort pas pour une bouture de feuille. Une réponse vide
  (espèce inconnue) se garde aussi. Sans clé, IA coupée, ou en cas d'erreur, le
  guide garde ses textes locaux et rien ne se voit.
- Chaque séquence se rejoue quand on revient sur son écran ; avec « réduire
  les animations », c'est la dernière image qui est montrée, posée.

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

## 3. Ajouter une photo (2 étapes, un seul chemin)
```
Fiche plante ─[tap 📷 | Croissance | en-tête sans photo]⟶ Sheet plein écran
Galerie Croissance ─[Prendre une photo]⟶ la même
  Étape 1 · Viser
    Viseur ouvert dans le cadre ; [tap cadre] ou [Prendre une photo] déclenche
    Superposition : la dernière photo en transparence par-dessus le viseur (☑ par défaut)
    [Choisir une photo] · Depuis une adresse web
  Étape 2 · Un titre ?
    Aperçu daté · champ titre · puces : Nouvelle feuille · Floraison · Avant rempotage…
    ☐ Photo principale (seulement s'il y en a déjà) · [Enregistrer] · Reprendre
✓ « Photo ajoutée » ⟶ compression (isolate) + miniature ⟶ journal, Croissance, galerie
  ⟶ si première photo : devient la photo principale
```
- La superposition est ce qui rend un suivi de croissance lisible : même cadrage,
  même distance d'un mois à l'autre. Il ne se propose que si le viseur tourne
  et qu'il y a une photo à superposer.
- Sans viseur (autorisation refusée, appareil sans caméra), le cadre garde
  son invite et les boutons ouvrent l'appareil photo du système.
- Repartir sans enregistrer efface les fichiers de la prise ; le titre et la
  photo principale s'écrivent avec la ligne, pas après coup dans un menu.

### Regarder les photos
- **Croissance (fiche)** : la bande des dernières photos — chacune s'ouvre en
  grand d'un toucher —, « 12 photos · depuis mars 2024 », et une relance
  quand la dernière a plus d'un mois.
- **Galerie Croissance** : Timelapse et Avant / après nommés en haut, les
  photos mois par mois avec leur titre, [Prendre une photo] en bas.
- **Visionneuse** : glisser pour passer à la suivante, pincer ou toucher deux
  fois pour agrandir, tirer vers le bas pour refermer, toucher pour cacher ou
  montrer ce qui entoure la photo. En bas : la date, le titre (qui s'écrit
  là), et quatre gestes nommés — Titre, Principale, Partager, Supprimer.
- **Avant / après** : les deux photos se choisissent dans une grille de
  vignettes datées, un geste les inverse. **Timelapse** : un curseur qu'on
  tire, lecture / pause.

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
  [tap ligne]⟶ Sheet : stratégie (Fixe / Saisonnier / Météo / Manuel), intervalle (stepper), activé
    Sous le stepper, d'où sort le chiffre : « Intervalle conseillé · Fiche de
    l'espèce », et la valeur conseillée dès qu'on s'en écarte. Rien quand la
    fiche est générique : l'intervalle ne vient alors pas de la plante.
  [+ Ajouter une routine] ⟶ type (chips) puis même sheet
✓ prochaine échéance recalculée et affichée immédiatement
```
Stratégie *Météo* : l'intervalle saisonnier corrigé par la semaine du lieu.
Sous le sélecteur, ce qu'elle donne aujourd'hui — « Avec le temps de la
semaine : 6 jours » —, ou ce qui manque pour le dire : un lieu météo. Sans
réseau elle vaut exactement le saisonnier, et ne le dit pas : le stepper
montre déjà ce chiffre.

## 6. Première expérience (onboarding)
```
Bienvenue ⟶ la plante de l'icône pousse : terre nue, fuseau, feuilles qui
  s'ouvrent et se découpent, jusqu'à l'icône.
Toutes vos plantes ⟶ cinq plantes différentes qui gravitent, chacune à son
  rythme. Puis les autres présentations.
Iris ⟶ la marque du modèle embarqué : « Iris reconnaît vos plantes hors
  ligne », le geste (photographier la plante), et le repli en ligne quand Iris
  ne la reconnaît pas. Juste avant l'écran de vie privée qu'il annonce.
Où sont vos plantes ? ⟶ [Utiliser ma position] · Plus tard
Comment vous appelez-vous ? ⟶ [Ajouter ma première plante] · Plus tard
Et si vous changez de téléphone ? ⟶ deux phrases (sauvegarde, jardin partagé,
  l'identifiant Apple suffit), puis [Continuer avec Apple] · Plus tard. L'étape
  n'existe que sur iOS avec un backend : ailleurs, le prénom mène droit au
  soutien.
Auxine est gratuite ⟶ soutien facultatif, [Non merci]
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

## 8. Trouver une plante (trois questions, puis un atelier)
```
Plantes ─[tap 💡]⟶ | Plantes (vide) ─[Trouver une plante]⟶ | Choisir une espèce ─[🧭]⟶
  Q1 · Où va-t-elle vivre ?      ☀️ Pièce lumineuse · 🌤️ Lumière moyenne · 🌑 Coin sombre · 🏡 Dehors   [Peu importe]
  Q2 · Quel entretien ?          😅 J'oublie souvent · 🙂 Régulier · 🥰 J'aime m'en occuper            [Peu importe]
  Q3 · Animaux ou enfants ?      🐾 Sans risque · 🙅 Pas de contrainte
  ⟶ Nos propositions
       puces des réponses (☀️ Pièce lumineuse · 😅 J'oublie… · 🐾 Sans risque) ─[tap]⟶ la question, puis retour ici
       filtre par genre (Toutes · 🪴 Intérieur · 🌵 Succulentes · …) : la liste se refait sur place
       ★ Notre premier choix : carte de couleur, photo ou emoji, raisons en pastilles, 💧 ☀️ 📈 en un coup d'œil
       Elles s'y plairaient aussi : quatre cartes, mêmes raisons
       ✨ Aller plus loin : texte libre + [Demander à l'IA] (seulement si une clé est configurée)
  ─[tap]⟶ Fiche en sheet : tuile, noms, raisons, fiche d'entretien ⟶ [Ajouter au jardin] (ou [Utiliser] depuis le sélecteur)
```
- Une réponse touchée se colore, puis la page tourne d'elle-même : c'est un
  questionnaire, pas un formulaire. Chaque tuile dit sous son libellé ce qu'elle
  recouvre (« Loin des fenêtres, peu de jour »), pour que « Coin sombre » veuille
  dire la même chose pour tout le monde.
- Le genre de plante n'est plus une question : c'est un filtre sur les
  propositions, qui se refont sous les yeux. Une puce de réponse ramène à sa
  question, et la nouvelle réponse revient droit aux propositions.
- Le tri se fait hors ligne sur les fiches d'entretien embarquées : lumière, difficulté,
  arrosage, toxicité, tenue dehors. Un critère sans réponse ne pèse pas. Les photos
  sont celles des observations GBIF libres de droits, cherchées après coup ; sans
  réseau, l'emoji de la catégorie tient la tuile, de la même forme.
- Éliminatoire, jamais négociable : toxicité inconnue quand on demande « sans risque »,
  plein soleil dans un coin sombre, espèce exigeante pour qui oublie d'arroser.
- Rien de convaincant ? On le dit, plutôt que de remplir la liste. [Demander à l'IA]
  élargit alors hors catalogue, avec le texte libre en plus — appel réseau seulement
  sur ce geste, propositions marquées « à vérifier avant d'acheter ».

## 9. Après une mise à jour (fenêtre des nouveautés)
1. L'application s'ouvre sur l'onglet du jour ; `WhatsNewGate`, posé autour de
   la coquille à onglets, interroge la règle une fois, après la première image.
2. La règle (`WhatsNew.take`) ne dit oui que si l'onboarding est fait **et** que
   l'appareil a déjà enregistré une version : une installation neuve ne se voit
   pas raconter ce qu'elle n'a jamais connu, elle note seulement son point de
   départ. Le lancement qui suit une mise à jour, lui, montre la plus récente
   des nouveautés jamais vues — une seule, même si deux versions ont été
   sautées.
3. La fenêtre s'ouvre (sheet native iOS / dialogue plein écran Android), se
   ferme par « Continuer », par la croix, ou — sur iOS, une fois la page
   revenue en haut — d'un glissement vers le bas. Un lien discret peut mener au
   réglage concerné, ouvert après fermeture.
4. Elle est marquée comme vue **avant** d'être affichée : une application tuée
   en cours de lecture ne la rouvre pas au lancement suivant.
5. Pas de porte d'entrée manuelle pour l'instant : les réglages n'ont pas de
   ligne « Nouveautés » tant que le catalogue ne contient que l'exemple, dont
   les chiffres sont inventés. Rouvrir cette ligne à la première vraie
   livraison est une FloraListRow — la marche à suivre est dans
   `profile_screen.dart`.

Ajouter une version = une entrée dans `releaseNotes()` et ses clés dans les
quatre `.arb`. Un identifiant de nouveauté ne se renomme ni ne se réemploie :
le renommer rouvre la fenêtre chez tous ceux qui l'avaient fermée, le
réemployer avale en silence celle qui devait s'ouvrir. L'identifiant de
l'exemple (`iris-8`) est déjà dépensé sur tout appareil ayant lancé cette
version — la vraie livraison d'Iris 8 en prendra donc un autre.

## 10. Relever une pièce, puis poser une plante (iPhone et iPad à LiDAR)
```
Jardin ─[tap Salon]⟶ Fiche emplacement ─[tap « Relever cette pièce »]⟶ une phrase
  (ce qui va se passer, rien ne quitte l'appareil)
    ⟶ le relevé du système (RoomPlan, coaching) ─[Terminer]⟶ feuille du relevé,
      déjà liée au Salon : plan vu de dessus, nom (proposé d'après le type de
      pièce), une ligne par fenêtre : « sud-ouest · D'après la boussole »
      ─[tap]⟶ huit points cardinaux ; « Renseigner l'emplacement » quand le
      Salon n'a ni orientation ni lumière
  ⟶ la fiche du Salon montre son plan, ses fenêtres, les plantes posées ;
    [tap] rouvre la feuille du relevé
Profil ─[tap « Relevé de la maison »]⟶ la même chose pour toutes les pièces,
  et « Relever l'appartement » ; une pièce reconnue (« Salon ») se lie d'elle-même
  à l'emplacement qui porte ce nom
Fiche plante ─ carte « Où la poser · Salon · à 1 m de la fenêtre sud » sous
  « Comment en prendre soin », dès que son emplacement est relevé ─[tap]⟶ Où la poser
  ouvert sur sa pièce · plan avec le lavis de lumière et les places numérotées
  « Pièce adaptée. » puis 1 · à 1 m de la fenêtre sud · Lumière vive
  [Poser ici] ⟶ la plante est posée sur le plan
  ⟶ la carte devient « Salon · à 1 m de la fenêtre sud » · « Place adaptée · Lumière
    vive », ou « mieux sur la table » si une place la dépasse nettement
Fiche d'entretien ─[tap « Où la poser », sous le diorama]⟶ la même feuille
```
La ligne, la carte et l'entrée n'existent que sur un appareil à LiDAR ;
l'entrée seulement quand une pièce est relevée, la carte seulement quand la
maison est relevée autour de la plante.
Une fiche générique ne donne pas de place : l'écran le dit. Détails : docs/17.
