# Le relevé de la maison : où poser cette plante

> Statut : livrée, sur iPhone et iPad à LiDAR (`AppConfig.roomScanEnabled`).
> Quatre paliers sont codés ; le palier 0 est passé — un relevé réel sur
> un iPhone Pro a confirmé la construction, la présentation par-dessus
> Flutter et la lecture du JSON. L'appartement entier (palier 3) et le
> balcon attendent leur relevé réel. Note créée le 20 septembre 2026.

## L'idée

On relève son appartement ou sa maison avec le LiDAR de l'iPhone. Puis, pour
une plante — une du jardin, ou une espèce du catalogue qu'on hésite à
acheter —, l'application dit où, dans ces pièces, elle serait le mieux :
« Salon, à un mètre de la fenêtre sud-ouest, lumière vive sans soleil
direct. »

La fiche d'entretien répond déjà à « où cette plante serait-elle bien ? »
avec un diorama (docs/13) : une pièce inventée, où la distance à la fenêtre
encode le besoin de lumière. Le relevé remplace la pièce inventée par la
vraie. La question ne change pas ; ce sont les murs qui changent.

Ce que la fonction ne fait pas : elle ne mesure pas la lumière avec un
luxmètre, elle ne devine pas ce que le catalogue ne dit pas, et elle ne
décide pas à la place de la personne. Elle propose des places, classées,
avec la raison de chacune. Une plante peut vivre ailleurs.

## Ce que le téléphone donne

RoomPlan (iOS 16, `RoomCaptureSession`) rend un `CapturedRoom` : murs,
fenêtres, portes, ouvertures, sols (iOS 17), avec leurs dimensions et leur
transformation dans un repère en mètres, l'axe *y* vers le haut ; des
objets classés (`table`, `storage`, `sofa`, `bed`, `sink`, `bathtub`,
`stove`, `fireplace`…) ; et, sur iOS 17, des sections nommées
(`kitchen`, `bathroom`, `bedroom`, `livingRoom`, `diningRoom`,
`laundryRoom`). `StructureBuilder` (iOS 17) assemble plusieurs pièces en
un appartement. Tout cela est `Codable` : un fichier JSON par relevé
suffit, et l'application n'embarque ni moteur 3D ni maillage.

`RoomCaptureSession.isSupported` dit si l'appareil a un LiDAR — les
iPhone Pro depuis le 12, les iPad Pro. La cible de déploiement est iOS 17 :
tout est disponible sans la relever, et sans entitlement.

Ce que RoomPlan ne donne pas, et qu'il faut obtenir autrement :

- **Le nord.** Le repère de RoomPlan est celui d'ARKit, orienté au hasard
  au lancement. Une fenêtre n'a d'orientation que par rapport au nord.
  Pendant le relevé, le canal natif lit en parallèle le cap de la boussole
  (`CLLocationManager.startUpdatingHeading`, `trueHeading`) et le lacet de
  la caméra ARKit (`captureSession.arSession.currentFrame.camera`) au même
  instant, plusieurs fois, et garde la moyenne circulaire de leur écart :
  c'est le décalage entre le repère du relevé et le nord. Moins de cinq
  mesures, ou des mesures qui se contredisent, et il ne rend rien. Une boussole de téléphone
  vaut dix à quinze degrés, et un radiateur en fonte la trouble : l'écran
  de fin de relevé montre l'orientation trouvée pour chaque fenêtre et
  demande de la confirmer ou de la corriger, à huit points cardinaux.
  L'autorisation de position est déjà décrite dans `Info.plist` ; le cap
  vrai en a besoin, le cap magnétique non.
- **Les radiateurs.** RoomPlan ne les voit pas. Le plan permet de poser un
  repère « radiateur » sur le plan de la pièce, du doigt — au toucher ou en
  le promenant. Le glissement est à prendre à la feuille, qui arme le sien
  pour se refermer et le déclare plus tôt : le plan s'adjuge donc le doigt au
  premier déplacement (`_GlissementDuPlan`), et la feuille garde tout ce qui
  ne commence pas sur lui. Le plan, lui, ne dépasse jamais la feuille : il
  prenait la largeur qu'on lui donnait et la hauteur qui va avec, ce qui sur
  un iPad mettait « Poser » hors de l'écran. Facultatif, et
  seulement au second palier.
- **Les fenêtres qu'il manque.** RoomPlan ne voit pas une fenêtre derrière
  un rideau tiré. La feuille du relevé en ajoute une : on choisit sa taille
  — petite fenêtre, fenêtre, baie vitrée, chacune avec sa largeur, sa
  hauteur et son appui —, puis on touche le plan ; elle se couche sur le mur
  le plus proche, qui lui donne son orientation, et se voit sur le plan
  avant d'être posée. Elle se range à la suite des fenêtres du relevé, pour
  que leurs rangs tiennent ; la retirer fait descendre d'un cran les rangs
  au-dessus, avec ce qui s'y accroche (orientation, rideau).
- **Les fenêtres qu'il prend pour des vides.** RoomPlan range dans les
  ouvertures ce qu'il n'a pas reconnu comme fenêtre — un vitrage derrière un
  rideau, une baie, un jour de travers. Deux réponses. Un vide dont l'appui
  est à quarante centimètres du sol ou plus ne se traverse pas : la lecture
  du JSON en fait une fenêtre, à la suite de celles du relevé
  (`ScannedRoom.windowSillMin`). Un vide qui part du sol, lui, est une baie
  ou un passage, et c'est la main qui tranche : le doigt qui le vise dans la
  feuille « Ajouter une fenêtre » y couche la fenêtre — un vide est dans le
  plan de son mur, viser l'un c'est viser l'autre, et le vide l'emporte là où
  il perce (`ScannedRoom.openingAt`). Elle en prend les mesures, que le
  relevé connaît, plutôt que celles de la taille demandée, et le vide lui
  cède la place : il ne fait plus courant d'air, et dehors il n'éclaire pas
  une seconde fois. Le plan, enfin, dessine les fenêtres après les vides —
  sans quoi le trou recouvrait la fenêtre qu'on venait d'y poser.
- **La lumière réelle.** ARKit donne une estimation d'éclairement
  (`ARFrame.lightEstimate.ambientIntensity`) qui dépend de l'heure et du
  temps qu'il fait : inutilisable seule pour dire ce qu'une place reçoit à
  l'année. Elle n'entre pas dans le premier palier.

## Le modèle de lumière

C'est le cœur, et il est pur : une géométrie de pièce et une orientation
donnent un `LightNeed` en chaque point, sans widget ni canal. Le fichier
`lib/domain/room/room_light_model.dart` le porte.

Pour un point candidat *P* de la pièce, à hauteur de pot, et pour chaque
fenêtre *W* :

1. **Visibilité.** Le segment *P → centre de W* ne traverse aucun mur de la
   pièce, et aucun meuble ne dépasse la visée. La visée monte : elle part du
   pot et va au milieu de la vitre, presque toujours plus haut — un bureau,
   une table, un lit n'arrêtent donc rien, la lumière leur passe au-dessus,
   là où une armoire la coupe. Un meuble est comparé à la hauteur de la
   visée là où elle entre dans son empreinte, c'est-à-dire là où elle est le
   plus basse. Comparer sa hauteur à celle du pot, comme au premier palier,
   rendait un bureau aussi opaque qu'un mur. Une fenêtre qu'on ne voit pas
   n'éclaire pas.
2. **Distance** *d* en mètres, bornée par le bas à 0,5 m, et **angle** *α*
   entre la normale intérieure de la fenêtre et *P − W*.
3. **Orientation.** Un facteur par point cardinal, miroir dans
   l'hémisphère sud (le jardin sait déjà s'il y est, `southernHemisphere`
   sert au rythme saisonnier) : sud 1,0 ; sud-est et sud-ouest 0,85 ; est
   et ouest 0,6 ; nord-est et nord-ouest 0,4 ; nord 0,3.
4. **Apport** de la fenêtre : *aire × facteur d'orientation × cos α / d²*.
   Les apports s'additionnent.
5. **Soleil direct.** Le point est dans la tache de soleil si la fenêtre
   donne au sud, au sud-est ou au sud-ouest, si sa profondeur depuis la
   vitre est inférieure à la portée de la tache — la hauteur du haut de la
   fenêtre au-dessus du sol, un soleil à 45°, celui d'une mi-saison à nos
   latitudes — et s'il est dans la largeur de l'ouverture, élargie de 15 %
   de la profondeur parce que le soleil balaie. Un meuble entre la vitre et le
   point lui porte son ombre quand il dépasse le rayon qui y descend — un
   bureau collé à la fenêtre ombre le sol derrière lui, tout en laissant
   passer la lumière du jour. Le dernier cinquième de la
   portée est le bord de la tache. À l'est et à l'ouest, la tache ne vaut
   que le bord : le soleil n'y passe qu'une partie de la journée. Le second
   palier fait dépendre la portée de la latitude du lieu et de la saison.

Six seuils sur l'apport total, plus la tache, donnent les six crans de
`LightNeed` : `fullSun` dans la tache, `someSun` à son bord, puis
`brightIndirect`, `indirect`, `lowLight`, `shade` en s'éloignant. Un point
sans fenêtre visible est `shade`, quoi qu'il arrive.

**Les seuils sont calibrés sur la pièce du diorama.** `tool/care_scene/room.py`
décrit une pièce, une fenêtre, et six emplacements sur une droite à pas
constant qui valent chacun un cran de lumière (docs/13, « Les six
lumières »). Cette géométrie est exportée une fois en JSON dans les
fixtures de test, avec sa fenêtre déclarée au sud, et le test
`test/domain/room_light_model_test.dart` exige que le modèle rende
exactement `shade` au `backCorner`, `lowLight` au `back`, et ainsi jusqu'à
`fullSun` dans la `sunZone`. Le modèle de lumière devient l'inverse de
`slotFor` (`care_environment_spec.dart`) sur la pièce de référence : la
fiche et le relevé racontent la même histoire, et un seuil déplacé à la main
casse un test avant de casser une fiche.

Deux autres signaux, plus simples, sortent du même modèle :

- **Courant d'air** : à moins d'un mètre d'une porte ou d'une ouverture.
  Ne compte que si la fiche dit
  `AirflowPreference.sheltered` ou `ventilated` ; `null` reste un silence.
- **Pièce humide** : la section RoomPlan est `kitchen`, `bathroom` ou
  `laundryRoom`. Sans section (iOS 16, ou pièce non reconnue), rien n'est
  supposé — pas même d'après l'émoji de l'emplacement.

Un radiateur posé à la main ajoute un troisième signal au second palier :
à moins de 80 cm, air sec et chaleur, contre `humidityFloor` et
`idealTempMaxC`.

## Le conseil

`lib/domain/room/room_fit_advisor.dart`, calqué sur `HomeClimateAdvisor`
(`lib/domain/home/home_climate_advisor.dart`) : une fonction statique, pure,
sans dépendance, qui prend un `CareProfile` et une pièce relevée, et rend
des places classées.

Le score d'une place, de 0 à 1 :

| Signal | Règle |
|---|---|
| Lumière | dans `[lightFloor, light]` → 1 ; un cran sous le plancher → 0,5 ; deux ou plus → 0. Un cran au-dessus de `light` → 0,6, deux ou plus → 0,2 : une fougère en plein soleil brûle, `lightTolerance` ne va que vers le bas |
| Courant d'air | `sheltered` et place exposée → × 0,5 ; `ventilated` et place exposée → × 1,1, plafonné à 1 ; `null` → rien |
| Pièce humide | `HumidityNeed.high` → × 1,1 plafonné ; `low` (cactées) → × 0,7 ; `average` → rien |
| Radiateur (palier 2) | à moins de 80 cm → × 0,5, sauf si la fiche accepte `idealTempMaxC ≥ 28` et `humidity == low` |

Les places candidates sont une grille au sol à pas de 25 cm, plus le dessus
des objets `table`, `storage` et le rebord des fenêtres : les plantes vivent
sur les meubles autant que par terre. À score égal, la lumière la plus
proche de l'idéal de la fiche passe devant : le toléré vient après le
préféré. Les places à la hauteur de la meilleure (à 0,05 près) se
regroupent en zones (voisines à moins de 60 cm), et chaque zone donne une
phrase : la pièce, le repère (« à un mètre de la fenêtre sud-ouest », « sur la
commode », « au fond, loin des fenêtres »), et la lumière qu'on y lit.
Trois zones au plus sont nommées ; le reste se voit sur le plan.

Chaque phrase est portée par des faits — la surface, la fenêtre la plus
proche et sa distance, son orientation, l'air qui bouge —, jamais par une
chaîne construite dans le domaine : `room_scan_labels.dart` les dit dans la
langue de l'interface, les ARB tiennent les quatre langues, et
`test/l10n/arb_tone_test.dart` les relit.

**Rien n'est inventé.** Une fiche générique (`CareMatch.generic`) ne donne
pas de places : la lumière d'une fiche par défaut n'est pas celle de la
plante. L'écran le dit, et propose de choisir l'espèce.

## Le modèle de données

Un relevé est un fichier et une ligne. Le JSON du `CapturedRoom` va dans
les documents de l'application, à côté des photos, jamais dans la base ni
dans l'outbox : le plan de chez soi ne se synchronise pas au premier
palier, et ne quitte pas l'appareil. `PrivacyInfo.xcprivacy` et la phrase
de `NSCameraUsageDescription` le disent.

Schéma v13 (`docs/04-data-model.md` reçoit la section) :

```
room_scans     id, garden_id, location_id?, name, captured_at,
               north_offset_deg?, file_path, floor_area_m2,
               section_label?, created_at, updated_at, deleted_at?
room_markers   id, scan_id, kind (window_orientation | radiator | plant),
               x, z, orientation?, plant_id?, created_at, updated_at
```

`room_markers` porte ce que la personne ajoute au relevé : l'orientation
confirmée de chaque fenêtre (`window_orientation`, une par fenêtre,
indexée par son ordre dans le JSON), les radiateurs (palier 2), la
position actuelle d'une plante (palier 3), et les fenêtres que le relevé a
manquées (`windowSmall`, `windowStandard`, `windowWide` — la taille est
dans le genre, comme pour le voilage et le rideau, et la base ne porte
aucune dimension). Séparer ce qui vient du capteur
de ce qui vient de la main permet de refaire un relevé sans perdre les
repères.

Un relevé se lie à un emplacement (`location_id`) : c'est ce qui permet de
dire « votre Monstera est au Salon » et de proposer, une fois pour toutes,
de renseigner `locations.orientation` et `locations.light` depuis le relevé.
`Location.orientation` reste un texte libre : le relevé écrit « Sud-ouest »
dans la langue de l'interface, comme la main l'aurait fait, et ne touche
pas à ce qui est déjà rempli.

Domaine, dans `lib/domain/room/` :

```
scanned_room.dart        ScannedRoom, RoomSurface, RoomObject, Orientation
                         (huit points), parseur du JSON RoomPlan — tolérant :
                         un champ absent vaut une liste vide, jamais une erreur
room_light_model.dart    lightAt(point), isDrafty(point), isHumidRoom
room_fit_advisor.dart    RoomFitAdvisor.place(profile, room) → List<Placement>
placement.dart           Placement, PlacementZone, PlacementReason
```

Le parseur ne lit que ce dont le modèle a besoin — pas les maillages, pas
les `.usdz`. Le JSON de RoomPlan change entre versions d'iOS : un test par
version rencontrée (`test/domain/fixtures/roomplan_ios17.json`, puis les
suivantes) verrouille la lecture.

## Le canal natif

`ios/Runner/RoomScanChannel.swift`, sur le patron de `HomeClimateChannel`
(`ch.vergasta.plant/room_scan`, instance retenue en `shared`, `Once` pour
ne jamais rendre deux fois un résultat, `"error"` en clair plutôt qu'une
`FlutterError` pour un relevé incomplet) :

| Méthode | Rend |
|---|---|
| `support` | `{ lidar: Bool, sections: Bool (iOS 17), structure: Bool (iOS 17) }` |
| `scan` | ouvre `RoomCaptureViewController` par-dessus la fenêtre Flutter, avec le coaching de RoomPlan ; au « Terminer », encode le `CapturedRoom`, l'écrit dans le chemin demandé, et rend `{ path, northOffsetDeg?, windows: [{ index, orientationDeg? }], sectionLabel?, floorAreaM2 }` |
| `scanStructure` (palier 3) | enchaîne les pièces (`stop(pauseARSession: false)` puis `run`), assemble par `StructureBuilder`, rend un chemin par pièce |

Le contrôleur natif est présenté par le `rootViewController` de la scène,
comme une feuille plein écran ; Flutter ne reprend la main qu'à sa
fermeture. Annuler rend `null`, pas une erreur : un relevé qu'on abandonne
n'est pas une panne. La lecture de la boussole vit dans le même contrôleur,
le temps du relevé, et s'arrête avec lui.

Côté Dart, `lib/data/services/room_scan_service.dart` : `abstract class
RoomScanService` avec `isSupported`, `support()`, `scan(toPath)` ;
`ChannelRoomScanService` sur le patron de `ChannelHomeClimateService`,
canal injectable, `PlatformException` et `MissingPluginException` avalées
en `null` ; `UnavailableRoomScanService` partout ailleurs.
`isSupported => !kIsWeb && Platform.isIOS && AppConfig.roomScanEnabled`,
puis `support().lidar` décide de montrer ou non le bouton.

`AppDelegate.swift` gagne une ligne, avec son commentaire.

## Les écrans

Le relevé n'est pas une fonction à part : il vit là où vivent déjà les
pièces et les plantes. Cinq entrées, une par question qu'on se pose :

- **Jardin › Fiche emplacement › « Plan de la pièce »** : la pièce relevée
  qui décrit cet emplacement — son plan avec les plantes posées, ses
  fenêtres, la date —, qui ouvre la feuille du relevé ; et « Renseigner
  l'emplacement » quand le relevé sait l'orientation ou la lumière que le
  lieu ne dit pas encore. Sans relevé, « Scanner cette pièce » lance le
  relevé et le lie d'emblée à l'emplacement. Sur un appareil sans LiDAR,
  la section n'existe pas.
- **Fiche plante › carte « Sa place »** sous « Comment en prendre soin »
  (`plant_place_card.dart`) : posée sur un plan, la pièce et le repère
  (« Salon · à 1 m de la fenêtre sud »), la lumière lue, et « mieux sur la
  table » quand une place la dépasse d'au moins un quart ; pas posée, mais
  dans un emplacement relevé, « Où la poser » avec la meilleure place de
  sa pièce. La feuille s'ouvre sur sa pièce, pas sur la mieux classée.
  Rien sans relevé autour d'elle, rien pour une fiche générique qui n'est
  pas posée.
- **Fiche d'entretien › « Où la poser »** sous le diorama, quand au moins
  une pièce est relevée. Le diorama ne change pas : il montre l'idéal, le
  relevé montre le réel (docs/13, « Idéal et réel »). Pour une plante déjà
  posée, la ligne dit sa place.
- **Profil › Réglages › Scan de la maison** : la vue d'ensemble — la
  liste des pièces relevées (nom, surface, emplacement lié, date),
  « Scanner une pièce », « Scanner tout le logement », et pour chaque pièce :
  renommer, lier à un emplacement, corriger l'orientation des fenêtres,
  supprimer. Une pièce relevée d'ici se lie d'elle-même à l'emplacement
  qui porte son nom (« Salon » reconnu par RoomPlan, un emplacement
  « Salon » sans relevé), à la casse près ; deux emplacements du même nom,
  et c'est la main qui décide. Sur un appareil sans LiDAR, la ligne
  n'existe pas.
- **Fiche de la pièce relevée › « Le jardin dans cette pièce »** (palier 2) : les
  plantes du jardin classées par leur score dans cette pièce.

La pièce porte le nom de l'emplacement depuis lequel on la relève : relevée
depuis la fiche de la Cuisine, elle s'appelle Cuisine ; liée à un emplacement
depuis sa feuille, elle en prend le nom. L'emplacement retrouvé par son nom,
lui, ne la renomme pas : le rapprochement tolère la casse, il ne l'impose
pas. Le type reconnu par RoomPlan nomme la pièce relevée de nulle part.

Le flux du relevé est le même d'où qu'on parte (`room_scan_flow.dart`) ;
seul change l'emplacement auquel la pièce se lie.

L'écran de résultat, `lib/features/room_scan/presentation/room_fit_screen.dart` :

```
Fiche d'entretien ─[tap « Où la poser »]⟶ Résultat
  Sélecteur de pièce (segmented, une par relevé)
  Plan vu de dessus (CustomPainter) : murs, fenêtres avec leur point
    cardinal, portes, meubles en silhouette, dans la direction argile ;
    un lavis de lumière du fond de la pièce à la fenêtre, et les zones
    retenues en pastilles numérotées
  Trois lignes : « 1 · À un mètre de la fenêtre sud-ouest · lumière vive »
  Une ligne de réserve quand la fiche est générique ou sans lumière connue
  [Poser ici] (palier 3) ⟶ pose un repère « plant » et
    renseigne l'emplacement de la plante
```

Le lavis de lumière — de l'ombre à la tache de soleil — vient de la pièce
seule (`RoomFitAdvisor.survey`), pas d'une fiche : il se dessine sur tout
plan, la feuille du relevé et la fiche de l'emplacement compris, avec une
légende ombre → plein soleil. C'est ce que le relevé apporte avant toute
plante ; les pastilles numérotées, elles, demandent une fiche.

Le plan est en deux dimensions, vu de dessus, dessiné par l'application :
pas de moteur 3D, pas de vue AR au premier palier. C'est la même décision
que pour le diorama, pour la même raison : ce qu'on veut lire, c'est une
distance et une direction, pas une pièce en relief.

Le flux du relevé lui-même est celui de RoomPlan, avec son coaching,
dans sa langue système. Avant lui, une feuille d'une phrase dit ce qui va
se passer et que rien ne quitte l'appareil ; après lui, l'écran des
fenêtres : une ligne par fenêtre avec l'orientation trouvée, corrigeable,
puis le nom de la pièce (proposé depuis la section RoomPlan quand il y en
a une) et l'emplacement à lier.

Textes : tout passe par les quatre ARB, clés préfixées `roomScan` et
`placement`, titres qui sont des noms. Le mot « LiDAR » n'apparaît qu'une
fois, dans la ligne de réglage, parce que c'est ce qui décide de l'appareil.

## Les paliers

Chaque palier livre quelque chose d'utilisable, sans bouton mort.

**Palier 0 — la preuve, un à deux jours.** Un canal jetable qui ouvre
`RoomCaptureView` et rend le JSON, sur un iPhone Pro. Vérifier trois
choses avant d'écrire une ligne de domaine : que la boussole et le lacet
ARKit donnent un décalage stable à dix degrés près sur un relevé réel ;
que les fenêtres sortent avec leurs dimensions dans un appartement
ordinaire (RoomPlan les manque derrière un rideau tiré) ; et que la
présentation UIKit par-dessus Flutter rend la main proprement. Si le nord
n'est pas fiable, l'orientation devient une question posée à la personne,
et le plan reste valable.

**Palier 1 — relever et lire.** Le canal, le service Dart, la table
`room_scans` et son dépôt (schéma v13), l'écran de réglage avec la liste
des pièces et l'écran des fenêtres, le parseur et le modèle de lumière
avec leur calibration sur la pièce du diorama, `RoomFitAdvisor`, l'écran
de résultat depuis la fiche d'entretien. Drapeau `AppConfig.roomScanEnabled`,
ouvert : la fonction est dans l'application, sur les appareils à LiDAR.
**Livré dans ce dépôt**, aux réserves du palier 0 près :
le résultat s'ouvre en feuille depuis la fiche, sans route, parce qu'une
fiche ne se met pas dans une URL ; « refaire » un relevé est le supprimer
et en relever un autre.

**Palier 2 — la maison telle qu'elle est.** Les radiateurs posés du doigt
(`room_markers`, collés au mur le plus proche), la latitude du lieu de la
météo dans la portée de la tache de soleil, « Le jardin dans cette pièce » sur la
pièce, le croisement avec la mesure des capteurs de la maison
(`homeReadingProvider`) quand le capteur porte le nom de la pièce ou de
son emplacement, et le remplissage proposé de `locations.orientation` et
`locations.light`. **Livré dans ce dépôt.** Deux écarts avec ce qui était
prévu : la saison n'entre pas dans la portée de la tache — l'équinoxe est
le compromis retenu, une place qui changerait d'avis d'un mois à l'autre
ne se lirait pas — ; et la pièce se relève une fois pour toutes les fiches
(`RoomFitAdvisor.survey`, puis `placeIn` par fiche), parce que « Qui
serait bien ici » juge tout le jardin sur la même grille.

**Palier 3 — l'appartement entier.** « Scanner tout le logement » enchaîne
les pièces dans le même repère (`stop(pauseARSession: false)`, puis
`run` ; « Pièce suivante » entre chaque), `StructureBuilder` les assemble
au « Terminer », et chaque pièce part dans son fichier sous un même
`structure_id` (schéma v14). « Où la poser » classe d'abord les pièces —
toutes, pas seulement celles d'un même relevé —, la meilleure s'ouvre
d'elle-même. Une plante du jardin se pose sur le plan de la pièce ; elle
est alors jugée là où elle est, et « Le jardin dans cette pièce » dit « mieux
sur la table » quand la meilleure place dépasse la sienne d'au moins un
quart. Depuis sa fiche, « Poser ici » la pose sur le plan et la
déménage dans l'emplacement du relevé s'il en a un. **Livré dans ce
dépôt.** La synchronisation des relevés n'est pas faite : un plan de chez
soi dans un jardin partagé pose la question de ce qu'on partage, qui
n'est pas tranchée ici.

**Palier 4 — affiner et garder.** Ce que RoomPlan ne voit pas et que la
main peut dire : une fenêtre manquée, à sa taille (`windowSmall`,
`windowStandard`, `windowWide`), couchée sur le mur le plus proche du
doigt — ou sur le vide qu'il vise, dont elle prend alors les mesures — et
rangée à la suite des fenêtres du relevé ; un voilage ou un rideau
souvent tiré, par fenêtre (`windowSheer`, `windowDrawn` dans `room_markers`) — le voilage divise
l'apport par deux et ne laisse du soleil que le bord, le rideau tiré le
divise par trois et n'en laisse rien. Le balcon : un relevé lié à un
emplacement extérieur est lu par `ScannedRoom.asOutdoor()`, ses ouvertures
éclairent comme des fenêtres, à la suite des fenêtres pour que leurs rangs
tiennent, et rien n'y est un courant d'air. Et la sauvegarde : une section
« Relevés de la maison » dans l'export ZIP (`room_scans`, `room_markers`,
et le JSON de chaque pièce sous `rooms/`), restaurée sans écraser ce qui
existe. **Livré dans ce dépôt.**

## Ce qui reste ouvert

- **La finesse du modèle.** Un apport en *1/d²* n'est pas un facteur de
  lumière du jour ; c'est une heuristique qui rend les six crans dans le
  bon ordre. Un luxmètre (ARKit à heure fixe, ou un capteur HomeKit de
  luminosité, que `HomeClimateChannel` pourrait lire) affinerait au second
  ou troisième palier. La calibration sur le diorama garde le modèle
  cohérent avec les fiches ; elle ne le rend pas vrai.
- **Les vitrages.** RoomPlan ne les distingue pas, et le plan ne les
  demande pas : un double vitrage teinté ou un verre dépoli passent pour
  une vitre claire. Les rideaux, eux, se disent depuis le palier 4.
- **La porte vitrée.** Une porte-fenêtre sort du relevé comme une porte, et
  une porte n'éclaire pas : la main pose une fenêtre sur un vide, pas encore
  sur une porte. Le jour où elle le pourra, la porte devra rester un courant
  d'air tout en éclairant.
- **Le vide relu comme fenêtre.** Un passage surélevé — un passe-plat vers la
  cuisine — est lu comme une fenêtre, et éclaire alors une pièce qu'il
  n'éclaire pas vraiment. Le cas est rare devant celui qu'il répare, et il se
  corrige par le rideau tiré, faute de pouvoir retirer une fenêtre du relevé.
  Un relevé qui gagne ainsi une fenêtre décale par ailleurs les rangs des
  fenêtres ajoutées à la main : leur orientation confirmée et leur rideau
  tiennent au rang, pas à la fenêtre.
- **Les étages et les balcons.** Un balcon relevé est une pièce sans mur
  d'un côté ; le modèle le traite comme une fenêtre de la largeur de
  l'ouverture, et la fiche décide du gel comme aujourd'hui. À vérifier au
  palier 0 que RoomPlan accepte de relever un balcon.
- **Android.** Rien. ARCore n'a pas d'équivalent de RoomPlan ; la ligne
  n'existe pas sur Android, comme les widgets.

## Les fichiers

```
ios/Runner/RoomScanChannel.swift
lib/core/config/app_config.dart              roomScanEnabled
lib/data/services/room_scan_service.dart
lib/data/db/tables.dart, database.dart       RoomScans, RoomMarkers, v13
lib/data/repositories/room_scan_repository_impl.dart
lib/domain/repositories/repositories.dart    RoomScanRepository
lib/domain/room/                             scanned_room, room_light_model,
                                             room_fit_advisor, placement
lib/features/room_scan/application/room_scan_providers.dart
                                             dont roomScanForLocation, plantRoomPlace,
                                             roomFillSuggestion
lib/features/room_scan/presentation/         room_scan_settings_screen, room_scan_flow,
                                             room_scan_detail_sheet, room_plan_painter,
                                             room_fit_sheet, room_fit_entry, room_scan_labels,
                                             location_room_section (fiche emplacement),
                                             plant_place_card (fiche plante)
lib/app/router.dart                          Routes.roomScan
lib/l10n/app_*.arb                           roomScan*, placement*
test/domain/room_light_model_test.dart       calibration sur la pièce du diorama
test/domain/room_fit_advisor_test.dart
test/domain/room_plan_parser_test.dart       fixtures par version d'iOS
test/data/room_scan_service_test.dart        canal simulé, patron HomeKit
test/data/room_scan_repository_test.dart     SQLite en mémoire
test/features/plant_room_place_test.dart     le relevé lié à l'emplacement, la place d'une plante
docs/02, 03, 04, 05, 07, README              les entrées, le flux, le schéma, le canal, l'arbre
```
