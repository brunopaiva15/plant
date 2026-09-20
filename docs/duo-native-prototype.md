# Prototype : la chrome de navigation en natif

**Cette branche n'est pas destinée à `main`.** Elle existe pour répondre à
trois questions qu'aucune lecture de la documentation ne tranche, et qu'un
simulateur d'iPhone Duo tranche en cinq minutes.

## Les questions

1. **iOS déplace-t-il vraiment nos boutons dans la bande verticale ?** Apple
   dit qu'une `UINavigationBar` posée seule n'est pas prise en compte, et qu'il
   faut un `UINavigationController`. C'est ce que ce prototype fournit, et rien
   d'autre.
2. **De quoi ont-ils l'air une fois là ?** UIKit les dessine avec ses
   matériaux et des SF Symbols. La colonne d'Auxine est en argile, avec ses
   icônes Cupertino. Il faut voir les deux côte à côte pour en juger.
3. **Que fait iOS quand il y en a trop ?** C'est l'une des deux choses que la
   colonne Flutter ne sait pas faire — le repli dans un menu de débordement.
   Le prototype envoie huit boutons exprès.

## Ce qu'il fait

Un seul geste natif, dans `SceneDelegate` :

```
UINavigationController
└── FlutterViewController   ← inchangé, toute la surface
```

Et un canal, `ch.vergasta.plant/native_chrome`, sur lequel Dart publie un
titre et une liste de boutons. UIKit en fait des `UIBarButtonItem` et les
range en `leftBarButtonItems`, `rightBarButtonItems` et `toolbarItems`.

Le jeu de boutons est une **démonstration**, pas les vrais boutons de
l'application : les pages publient des widgets Flutter, qu'UIKit ne sait pas
dessiner. Voir `lib/app/duo_native_demo.dart`.

## Ce qu'il ne fait pas, volontairement

- **Pas de `UITabBarController`.** Il voudrait quatre contrôleurs enfants,
  donc quatre moteurs Flutter, et go_router ne posséderait plus les onglets.
  La colonne Flutter reste en place pour eux — on verra les deux en même
  temps, ce qui est instructif en soi.
- **Pas de `pinnedTrailingGroup`.** C'est le placement des « actions
  proéminentes ». Une fois le placement de base constaté, ce sera l'étape
  suivante.
- **Pas de bouton retour natif.** La pile de navigation n'a qu'un élément,
  celui de Flutter. Le « retour » envoyé d'ici est un bouton ordinaire.
- **Rien n'est retiré de Flutter.** La colonne, les hauts de page et les
  grands titres sont intacts. C'est une addition, pas un remplacement.

## Ce que la première capture a répondu

Écran extérieur, 20 septembre 2026. **Oui, iOS range les boutons debout dans
la bande**, et dans l'ordre annoncé : le retour tout en haut dans sa propre
capsule, les actions groupées dans une seconde, l'élément de bas de barre
isolé en bas. La première question est tranchée.

Deux coûts sont apparus du même coup.

**La bande horizontale du haut reste.** iOS y affiche le titre de la page, et
elle prend **82 points de marge sûre** — `marges sûres · haut` passe de 0 à 82
dans la même pose. Les boutons sont à droite, mais le haut est quand même
payé. Et « Aujourd'hui » s'affiche au-dessus du « Bonsoir » d'Auxine : deux
titres pour une page.

**Les deux colonnes se superposent.** La bande native et la colonne en argile
occupent le même espace. En production, l'une des deux doit partir.

Pas de débordement : les huit boutons tenaient dans la bande de l'écran
extérieur. À revoir dans une pose plus courte.

## Les deux interrupteurs

Ils sont en bas de la bande native, et évitent une reconstruction par
question :

| bouton | ce qu'il tranche |
|---|---|
| `textformat` — Titre natif | sans titre, la bande horizontale du haut disparaît-elle, et les 82 points avec elle ? |
| `sidebar.right` — Colonne Flutter | la bande native seule, sans l'argile derrière, pour la juger sur pièce |

Le relevé `[auxine:fenêtre]` se réécrit à chaque bascule : c'est lui qui dira
ce que le titre coûte.

## Ce qu'il faut regarder

Sur le simulateur, dans chaque pose :

- où sont les huit boutons — en haut à l'horizontale, ou dans la bande de
  droite à la verticale ;
- si l'un d'eux disparaît dans un menu, et comment ce menu s'ouvre ;
- ce que devient la marge sûre du haut dans le relevé `[auxine:fenêtre]` : la
  barre native la modifie, et c'est un coût à connaître ;
- l'allure : un bouton système à côté d'un bouton en argile.

La console écrit `[auxine:natif] contrôleur de navigation posé autour de …` au
lancement, et `[auxine:natif] bouton touché : …` à chaque appui.

## Si rien ne s'affiche

Le canal est muet quand le binaire n'a pas le prototype : reconstruire.
Le reste est du Swift qui n'a jamais été compilé ici — il n'y a pas de Xcode
dans l'environnement où cette branche a été écrite. Une erreur de compilation
est attendue plutôt que surprenante, et elle sera dans
`ios/Runner/DuoNativeChrome.swift`.

## Revenir en arrière

Retirer l'appel à `DuoNativeChrome.install(in: scene)` dans `SceneDelegate`
suffit à rendre l'application à Flutter seul ; le reste ne fait rien sans lui.
