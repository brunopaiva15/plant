# Partition de la vidéo de sortie

24 s, 13 mesures de « Porch Swing Days (faster) » à 130 BPM : un temps dure
13,85 images, une mesure 55,4. Les temps sont comptés de 0 à 51 ; la colonne
« accent » donne la force de l'attaque mesurée par `musique.py` (1 = la plus
forte). Les gestes forts sont posés sur les accents les plus forts.

## Les règles

- **Courbes.** Pas de ressorts qui ballottent : des courbes exponentielles
  (sortie rapide, arrivée longue) pour ce qui entre, une accélération franche
  pour ce qui sort, un quint entrée-sortie pour la caméra. Chaque geste part
  deux ou trois images avant le temps et touche sur le temps.
- **Transitions.** Coupe franche avec coup de zoom et éclat de lumière entre
  deux plans réels. On passe d'un monde à l'autre *à travers* l'image : la
  caméra plonge dans l'écran du téléphone filmé pour ressortir dans l'app,
  puis plonge dans l'écran de l'app jusqu'au prix ; la marque monte comme
  une feuille de l'app. Dans l'acte 2, le téléphone reste : ses écrans se
  poussent, il bascule légèrement avec le geste, le fond monte derrière lui.
- **Rien de figé.** La caméra dérive toujours un peu, les disques tournent,
  la fin avance lentement.
- **Flou de bougé.** 6 sous-images par image, obturateur à 180°.
- **Titres.** Un seul emplacement (en haut, à 80 px du bord gauche) ; ils
  entrent et sortent par masque, avec un trait de couleur qui se tire.
- **Couleurs.** Une par fonction, celles du kit : lavande (identification),
  bleu (soins), nuit (diagnostic), rose (collection), jaune (prix), vert
  (marque). Les plans réels sont étalonnés un peu plus chauds et contrastés.
- **Son.** Posé après le rendu par ffmpeg (`rendu.sh`), calé à l'image près,
  normalisé en deux passes à gain fixe.

## Acte 1 — le geste (temps 0 à 8)

| Temps | Accent | Image | Texte | Mouvement |
|---|---|---|---|---|
| 0 | — | Succulentes photographiées au téléphone, vues de dessus | « Quelle est » | Coupe, léger coup de zoom |
| 1 | 0,42 | | « cette plante ? » | La ligne monte de son masque |
| 2 | 0,37 | Des mains autour d'une plante en pot | | Coupe |
| 3 | 0,45 | Des mains dans les feuilles d'une monstera | | Coupe |
| 4 | 0,37 | Des mains cadrent une plante et déclenchent | | Coupe ; le cadrage dure une mesure |

## Acte 2 — l'app répond (temps 8 à 36)

| Temps | Accent | Image | Texte | Mouvement |
|---|---|---|---|---|
| 8 | **0,94** | Sortie de la plongée → téléphone, étape « Aperçu » (lavande) | « Identification » — « Une photo suffit, même sans réseau. » | Le téléphone remonte et se redresse |
| 9–11 | | | | Le trait de lumière rend la photo nette |
| 12 | 0,63 | | | Un anneau autour de « Figuier lyre », la caméra s'approche |
| 14 | 0,53 | Arrosage au pied d'une monstera (plan réel) | « Soins du jour » — « Arrosage, engrais, rempotage : à cocher en un geste. » | Coupe |
| 16 | 0,63 | Téléphone, Aujourd'hui (bleu) | | La caméra descend vers les tuiles |
| 18, 19 | | | | Un toucher, puis la coche, sur deux temps qui se suivent |
| 24 | **0,73** | Poussée vers le Diagnostic (nuit) | « Diagnostic sur photo » — « Plus de 200 troubles, ravageurs et maladies. » | L'écran glisse ; la carte « Air trop sec » passe au premier plan |
| 30 | 0,39 | Poussée vers Plantes (rose) | « Toutes vos plantes » — « Avec leur photo, leur espèce et leur pièce. » | L'écran glisse |
| 31, 32 | 0,60 | | | Les deux premières tuiles arrivent |
| 34–36 | | | | Le téléphone vibre de plus en plus, puis la caméra plonge dans son écran |

## Acte 3 — l'offre et la marque (temps 36 à 52)

| Temps | Accent | Image | Texte | Mouvement |
|---|---|---|---|---|
| 36 | 0,45 | Sortie de la plongée, sur le jaune | « 0,99 € » | Impact : le prix frappe, l'image tremble |
| 37 | | | « Un seul achat. » puis « Sans abonnement. » | Les lignes glissent |
| 38–39 | **0,80 / 0,66** | | Pastilles « Toutes les fonctions », « Sans publicité », « Sans achat intégré » | Une par demi-temps |
| 40 | **1,00** | La feuille verte monte par-dessus le prix | « Auxine » | Le pot se pose, le nom s'écrit lettre par lettre |
| 41–42 | | | « Le carnet de vos plantes. » — « Disponible sur l'App Store. » | |
| 46 | **0,82** | | | Le pot cligne de l'œil |
| 47–52 | | Tenue | | La musique s'éteint |
