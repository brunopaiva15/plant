# La clarté des textes (`lib/l10n/*.arb`)

> Statut : **lots 1 à 3 livrés**, lots 4 à 11 à faire. La charte du § 3 est reportée
> dans `docs/06-design-system.md`, le relevé mécanique (`tool/audit_textes.py`)
> et le test de parité ICU sont en place. Le registre allemand est tranché :
> *du*.

Ce document tient le chantier de réécriture des textes de l'interface : ce qui
cloche, la règle qui change, les lots, et ce qui vérifie le résultat. Il
concerne les 1 851 clés des quatre ARB, soit 7 404 chaînes.

## 0. Le constat

L'écran « Relevé de la maison » dit, en français :

> Une pièce relevée avec l'appareil photo et le LiDAR donne ses murs, ses
> fenêtres et ses portes. La lumière de chaque place s'en déduit, pour dire où
> poser une plante. Le relevé reste sur l'appareil.

Trois phrases, personne dedans. Le lecteur n'est jamais nommé, l'application
non plus ; les gestes deviennent des états (« une pièce relevée »), les
actions des phénomènes (« la lumière s'en déduit »). C'est un texte qui décrit
la fonctionnalité au lieu de dire quoi faire. Ce qu'il faut lire :

> Scannez une pièce avec l'appareil photo et le LiDAR : l'application y repère
> les murs, les fenêtres et les portes, puis calcule la lumière de chaque
> emplacement pour vous dire où placer vos plantes. Tout reste sur votre
> appareil.

Le défaut n'est pas local. Les trois autres langues calquent mot à mot la
syntaxe française — « A room surveyed with the camera and the LiDAR gives its
walls », « Da questi si ricava la luce di ogni posto, per dire dove posare una
pianta » — et héritent donc de la même gêne, aggravée par des tournures qui
n'existent pas dans ces langues.

## 1. D'où vient le défaut

De `docs/06-design-system.md`, § « Les textes », lu trop loin. La consigne
disait : *sobre, factuel, court*, l'application ne parle pas d'elle-même, on
n'interpelle pas la personne. Appliquée à la lettre, elle a produit une règle
non écrite — **ne jamais nommer d'acteur** — qui laisse trois échappatoires,
toutes mauvaises :

| Échappatoire | Exemple livré | Ce qu'il fallait dire |
|---|---|---|
| le pronominal impersonnel | `gardensHint` : « Le passage de l'un à l'autre se fait ici. » | « Changez de jardin ici. » |
| le passif sans agent | `pgVineClearBody` : « Les feuilles qui tremperaient sont retirées. » | « Retirez les feuilles qui tremperaient. » |
| l'infinitif de notice | `careToxicPets` : « Tenir hors de portée des animaux et des enfants. » | « Tenez-la hors de portée des animaux et des enfants. » |

S'y ajoute une ellipse de style — la phrase nominale, sans verbe — qui fait
passer un mode d'emploi pour un poème : « Lame propre, coupe nette à un
centimètre sous le nœud. »

Le remède ne consiste pas à rallonger. Il consiste à **remettre un sujet** :
la personne quand elle agit (impératif, « vous »), l'application quand c'est
elle qui calcule. Une fois le sujet rendu, la moitié des circonvolutions
tombent d'elles-mêmes, et le texte raccourcit.

## 2. Le relevé chiffré

`tool/audit_textes.py` lit les quatre ARB et signale ce qui est mécaniquement
détectable. État à l'ouverture du chantier :

```
201 clés signalées, 369 chaînes sur les quatre langues
```

| Défaut | fr | en | de | it |
|---|---:|---:|---:|---:|
| nombre en toutes lettres (« dix centimètres ») | 25 | 25 | 25 | 25 |
| phrase de plus de 140 signes | 20 | 14 | 19 | 17 |
| plus de deux phrases dans une aide | 8 | 8 | 8 | 8 |
| pronominal impersonnel | 23 | — | — | — |
| passif sans agent | 15 | — | — | — |
| consigne à l'infinitif | 8 | — | — | — |
| apostrophe courbe (minoritaire : 27 contre 283) | 27 | — | — | 13 |
| tutoiement | — | — | 18 | 55 |
| vouvoiement | — | — | 48 | 18 |

Ce relevé ne voit que la part mécanique. Le gros du travail est éditorial :
**513 chaînes explicatives en français** (aide, sous-titre, note, corps
d'étape, message d'erreur), donc **2 052 chaînes à relire sur les quatre
langues**. Les 1 338 autres clés sont des libellés courts — « Arroser »,
« Substrat », « Salle de bain » — qui vont bien et ne s'ouvrent qu'en cas de
doute.

Deux points sains, à préserver : les marqueurs ICU sont identiques d'une
langue à l'autre sur les 1 851 clés, et aucune clé ne manque nulle part.

## 3. La charte révisée

À reporter dans `docs/06-design-system.md`, § « Les textes », en remplacement
du paragraphe actuel.

1. **On s'adresse à la personne.** Une consigne est à l'impératif, deuxième
   personne : « Scannez la pièce », jamais « Tourner lentement » ni « La pièce
   se scanne ». Ce qui lui appartient se dit « votre » : vos plantes, votre
   appareil, votre jardin.
2. **Chaque phrase a un sujet nommé.** Quand c'est le logiciel qui agit, on le
   dit : « l'application calcule la lumière de chaque emplacement ». Décrire un
   traitement n'est pas se personnifier — ce qui reste interdit, c'est de lui
   prêter des états d'âme (« Auxine regarde la pluie », « il sait dire qu'il
   hésite »).
3. **Une aide dit une chose.** Deux phrases et 140 signes au plus pour une
   aide en ligne, 220 pour un chapeau d'écran. Trois phrases sont réservées aux
   écrans de consentement et de confidentialité, où chaque phrase porte une
   garantie distincte.
4. **On coupe ce qui est déjà dit ailleurs.** « Rien ne quitte l'appareil »
   répété dans le chapeau, dans l'écran d'avant-scan et dans les réglages : une
   fois suffit, à l'endroit où la question se pose.
5. **Le mot courant l'emporte sur le mot juste.** Un *emplacement*, pas une
   *place* ; un *scan*, pas un *relevé* ; *placer* une plante, pas la *poser*.
   Les termes de botanique (nœud, keiki, sphaigne, cal) restent, c'est le
   vocabulaire du sujet.
6. **Les nombres s'écrivent en chiffres, les unités en abrégé** : « 5 à 8 cm »,
   « 10 à 15 semaines », « 2 fois sur 3 ». Les textes d'interface se lisent en
   diagonale ; un chiffre s'y voit, « cinq à huit centimètres » se lit.
7. **Chaque langue s'écrit depuis l'intention, pas depuis le français.** On
   part de ce que la chaîne doit faire comprendre, et on l'écrit dans la
   langue. Une tournure française qui n'a pas d'équivalent idiomatique se perd,
   elle ne se transpose pas.
8. **Ce qui ne change pas** (et que `test/l10n/arb_tone_test.dart` verrouille
   déjà) : pas de point d'exclamation, pas de « nos » ni de « notre », pas de
   réassurance ni de politesse de remplissage, un titre est un nom et non une
   question, les `careTip…` gardent le registre du jardinage.

## 4. Les quatre langues

| Langue | Registre | État actuel |
|---|---|---|
| fr | vouvoiement, impératif | cohérent (54 chaînes avec « vous ») |
| en | *you* | cohérent (60 chaînes) |
| de | **du** (tranché) | 48 chaînes en *Sie* à convertir, lot 11 |
| it | **tu** (tranché) | 18 chaînes en *voi* à convertir, lot 11 |

L'italien se tranche seul : le *tu* est déjà majoritaire, c'est la convention
d'iOS en italien, et les 18 chaînes en *voi* (`supportOffer`, `onbWelcomeBody`,
`emptyPlantsSubtitle`…) passent au *tu*.

L'allemand passe au ***du***, malgré le *Sie* majoritaire à l'ouverture du
chantier (48 contre 18) : c'est la convention d'Apple en allemand depuis 2021,
elle s'accorde avec le sujet domestique et avec le *tu* italien. Les 48
chaînes en *Sie* se convertissent au lot 11 ; d'ici là, `tool/audit_textes.py`
les signale sous `registre-de-trop`. Tout texte allemand écrit à partir du lot
1 est au *du*.

Aucune des deux langues ne mélange les guillemets : l'allemand tient son
`„ … “`, le français ses `« … »`. Seules deux chaînes italiennes
(`markWatch`, `speciesUseText`) portent des `“ … ”` au lieu des `« … »`
utilisés par les dix autres.

## 5. Ce qui ne se touche pas

- Les 74 clés `careTip…` : registre du jardinage, exemptées par `docs/06` et
  par le test de ton.
- Les noms propres et les marques : Pl@ntNet, GBIF, Open-Meteo, Apple Maison,
  Google Home, Iris, Auxine, AI Services d'Infomaniak.
- Le vocabulaire de botanique et les noms d'espèces.
- Les clés elles-mêmes : aucun renommage. Une clé qui garde son nom garde son
  historique et évite une passe sur le code appelant.
- La structure ICU : `{count, plural, …}`, `{name}`, `{area}` restent à
  l'identique, catégories comprises.

## 6. Les lots

Onze lots, du plus visible au moins visible. Chacun se relit, se réécrit, se
teste et se livre seul. Les `avant → après` ci-dessous sont les réécritures
retenues, pas des exemples : elles se reportent telles quelles dans
`app_fr.arb`, et les trois autres langues s'écrivent depuis l'intention selon
la règle 7.

### Lot 1 — Le relevé de la maison (95 clés, 27 explicatives)

Préfixes `roomScan…`, `roomSection…`, `placement…`. C'est l'écran qui a ouvert
le chantier ; il concentre les trois échappatoires à la fois.

> **Livré.** Les 125 chaînes ci-dessous sont dans les quatre ARB, `flutter
> gen-l10n` est passé, la suite `test/l10n/` est verte (16 tests, dont la
> parité ICU) et `flutter analyze` ne dit rien. Le relevé du lot tombe de 9
> clés signalées à 4, toutes dans les bornes de la charte.

**Décision de vocabulaire** : *relevé* devient *scan*, *poser* devient
*placer*, et *place* devient **endroit** — non pas *emplacement* comme annoncé
d'abord : « Emplacement » désigne déjà les `Location` du jardin
(`roomScanLinkedLocation`, `roomScanFillLocation`), et les confondre aurait
rendu « Renseigner l'emplacement » ambigu sur un écran qui parle des deux. Le
mot est celui de la charte, règle 5 ; il vaut pour toute l'application. Les
trois autres langues n'avaient pas la collision et gardent *spot*, *Platz*,
*posto*.

Trois corrections de vocabulaire s'y ajoutent, trouvées en relisant les quatre
langues ensemble :

- **it** : `pianta` désignait à la fois la plante et le plan de la pièce —
  « Tocca la pianta dove si trova {plant} » se lisait « touche la plante ». Le
  plan devient `planimetria` partout.
- **en** : *survey* et *scan* se partageaient l'écran ; tout passe à *scan*.
- **it** : les boutons à l'infinitif (`Rilevare una stanza`, `Posare una
  pianta`) passent à l'impératif, comme le veut le registre *tu*.

Les libellés cités dans `docs/02`, `docs/03`, `docs/17`, `docs/00`,
`app_config.dart` et `room_scan_settings_screen.dart` suivent le lot.
`docs/17-releve-de-la-maison.md` garde son nom de fichier.

| Clé | Avant | Après |
|---|---|---|
| `roomScan` | Relevé de la maison | Scan de la maison |
| `roomScanHint` | Une pièce relevée avec l'appareil photo et le LiDAR donne ses murs, ses fenêtres et ses portes. La lumière de chaque place s'en déduit, pour dire où poser une plante. Le relevé reste sur l'appareil. | Scannez une pièce avec l'appareil photo et le LiDAR : l'application repère les murs, fenêtres et portes, puis calcule la lumière de chaque endroit pour vous dire où placer vos plantes. Tout reste sur votre appareil. |
| `roomScanStart` | Relever une pièce | Scanner une pièce |
| `roomScanStartStructure` | Relever l'appartement | Scanner tout le logement |
| `roomScanRooms` | Pièces relevées | Pièces scannées |
| `roomScanEmptyTitle` | Aucune pièce relevée | Aucune pièce scannée |
| `roomScanEmptySubtitle` | Le relevé prend une à deux minutes par pièce, en tournant lentement le long des murs. | Comptez 1 à 2 minutes par pièce. |
| `roomScanNoLidar` | Cet appareil n'a pas de LiDAR : le relevé demande un iPhone Pro ou un iPad Pro. | Cet appareil n'a pas de LiDAR. Le scan demande un iPhone Pro ou un iPad Pro. |
| `roomScanBeforeText` | L'appareil photo s'ouvre sur le relevé du système. Tourner lentement le long des murs jusqu'à ce que la pièce soit dessinée, puis terminer. Rien ne quitte l'appareil. | L'appareil photo s'ouvre sur le scanner d'iOS. Avancez lentement le long des murs jusqu'à ce que la pièce soit entièrement dessinée, puis touchez Terminé. |
| `roomScanFailed` | Le relevé n'a pas abouti. | Le scan n'a pas abouti. |
| `roomScanCapturedOn` | Relevée le {date} | Scannée le {date} |
| `roomScanOrientationHelp` | La boussole a dix à quinze degrés d'erreur. L'orientation de chaque fenêtre se corrige ici. | La boussole se trompe de 10 à 15°. Corrigez ici l'orientation de chaque fenêtre. |
| `roomScanDelete` | Supprimer le relevé | Supprimer le scan |
| `roomScanDeleteConfirm` | Le relevé et ses repères disparaissent de l'appareil. | Le scan et ses repères seront supprimés de votre appareil. |
| `roomScanHeatersHelp` | Le relevé ne voit pas les radiateurs. Posé sur le plan, un radiateur compte comme air sec et chaud à moins de 80 cm. | Le scan ne détecte pas les radiateurs. Placez-les sur le plan : l'air compte comme sec et chaud à moins de 80 cm. |
| `roomScanAddHeater` | Poser un radiateur | Placer un radiateur |
| `roomScanTapForHeater` | Toucher le plan là où se trouve le radiateur. | Touchez le plan à l'endroit du radiateur. |
| `roomScanCurtainHelp` | Le relevé ne voit ni les voilages ni les rideaux. Un voilage divise la lumière par deux et ôte le soleil direct ; un rideau souvent tiré la divise par trois. | Le scan ne détecte pas les rideaux. Un voilage divise la lumière par 2 et ôte le soleil direct ; un rideau souvent tiré la divise par 3. |
| `roomScanStructureHint` | Relever l'appartement enchaîne les pièces : « Pièce suivante » entre chaque, « Terminé » à la fin. Les pièces se placent les unes par rapport aux autres. | Scannez vos pièces à la suite : touchez « Pièce suivante » après chacune, « Terminé » à la fin. L'application les assemble en un seul plan. |
| `roomScanPlantsHelp` | Une plante posée sur le plan est notée à sa place. La liste signale une place nettement meilleure. | Placez vos plantes sur le plan : chacune reçoit une note, et la liste signale un endroit nettement meilleur. |
| `roomScanAddPlant` | Poser une plante | Placer une plante |
| `roomScanTapForPlant` | Toucher le plan là où se trouve {plant}. | Touchez le plan à l'endroit où se trouve {plant}. |
| `roomScanNoPlantToPlace` | Aucune plante à poser. | Aucune plante à placer. |
| `roomScanPlantWellPlaced` | Place adaptée · {light} | Endroit adapté · {light} |
| `roomScanPlantBetterAt` | Place actuelle {light} · mieux {place} | Ici {light} · mieux {place} |
| `roomScanWhoFitsHint` | Chaque plante est notée d'après la lumière de la pièce et sa fiche. | Chaque plante est notée en comparant la lumière de la pièce à celle que demande sa fiche. |
| `roomScanThisRoomHint` | Le plan de la pièce donne la lumière de chaque place, pour choisir où poser une plante. | Le plan indique la lumière de chaque endroit, pour choisir où placer une plante. |
| `roomScanFillLocationDetail` | Orientation {orientation}, lumière {light}, d'après le relevé. Les champs déjà remplis ne changent pas. | D'après le scan : orientation {orientation}, lumière {light}. Vos champs déjà remplis ne changent pas. |
| `roomScanPlace` | Poser | Placer |
| `placementHint` | Les places sont classées d'après la lumière qu'elles reçoivent, comparée à celle de la fiche. | Les endroits sont classés en comparant la lumière qu'ils reçoivent à celle que demande la fiche. |
| `placementRoomsCount` | {count} pièces relevées | {count} pièces scannées *(les deux branches du pluriel)* |
| `placementGeneric` | Fiche générique : sans espèce, la lumière demandée n'est pas connue. | Sans espèce renseignée, la lumière demandée est inconnue : la fiche reste générique. |
| `placementShortfallHeater` | Chaque place est près d'un radiateur : air sec et chaud. | Tous les endroits sont près d'un radiateur : l'air y est sec et chaud. |

Les quatre langues, sur la chaîne d'ouverture :

- **en** — Scan a room with the camera and LiDAR: the app finds the walls,
  windows and doors, then works out how much light each spot gets, so you know
  where to put your plants. Everything stays on your device.
- **de** (*du*) — Scanne einen Raum mit Kamera und LiDAR: Die App erkennt
  Wände, Fenster und Türen und berechnet, wie viel Licht jeder Platz bekommt –
  damit du weißt, wohin deine Pflanzen gehören. Alles bleibt auf deinem Gerät.
- **it** — Scansiona una stanza con la fotocamera e il LiDAR: l'app individua
  muri, finestre e porte, poi calcola quanta luce riceve ogni punto e ti dice
  dove mettere le piante. Tutto resta sul tuo dispositivo.

### Lot 2 — Les guides de multiplication (133 clés, 62 explicatives, 45 signalées)

> **Livré.** 201 chaînes réécrites sur les quatre langues, le relevé du lot
> tombe de 45 clés signalées à 0. `flutter gen-l10n` passé, `flutter test` et
> `flutter analyze` verts.

Préfixe `pg…`. Le lot le plus atteint du dépôt : un mode d'emploi en sept
gestes écrit entièrement au constatif. Chaque `…Body` est une étape que la
personne exécute, donc chaque `…Body` passe à l'impératif, et les mesures aux
chiffres. Les `…Body` qui ne sont pas des gestes mais des observations — « Les
racines sortent du nœud, pas du bas de la tige » — restent à l'indicatif, avec
leur sujet nommé : la charte demande un acteur, pas un impératif partout.

Les 14 apostrophes courbes du lot sont redressées au passage, plutôt que
d'être laissées au lot 11 : elles étaient dans les chaînes déjà en train d'être
réécrites.

| Clé | Avant | Après |
|---|---|---|
| `pgPickBody` | Cette plante se multiplie de plusieurs façons. Le geste choisi décide des étapes. | Cette plante se multiplie de plusieurs façons. Choisissez-en une : les étapes en dépendent. |
| `pgIntroBody` | {count} étapes. Chacune est montrée en geste, puis dite en une phrase, adaptée à l'espèce quand elle est connue. | {count} étapes, chacune montrée en image et expliquée en une phrase, adaptée à l'espèce quand elle est connue. |
| `pgVineNodeBody` | Le renflement d'où part une feuille, souvent doublé d'une racine aérienne. La bouture en garde au moins un. | Repérez le renflement d'où part une feuille, souvent accompagné d'une racine aérienne. Gardez-en au moins un sur la bouture. |
| `pgVineCutBody` | Lame propre, coupe nette à un centimètre sous le nœud. Le nœud reste du côté de la bouture. | Avec une lame propre, coupez net 1 cm sous le nœud : le nœud reste du côté de la bouture. |
| `pgVineClearBody` | Les feuilles qui tremperaient sont retirées. Deux ou trois feuilles en haut nourrissent la bouture. | Retirez les feuilles qui tremperaient. Gardez-en 2 ou 3 en haut : elles nourrissent la bouture. |
| `pgVineWaterBody` | Le nœud sous la surface, les feuilles au-dessus. Lumière vive, sans soleil direct. | Plongez le nœud sous l'eau, les feuilles au-dessus. Placez le verre en lumière vive, sans soleil direct. |
| `pgVineRootsBody` | Elles sortent du nœud, pas du bas de la tige. L'eau se change chaque semaine. | Les racines sortent du nœud, pas du bas de la tige. Changez l'eau chaque semaine. |
| `pgVinePotBody` | À quelques centimètres de racines, la bouture passe en terreau léger. Le nœud reste à fleur de terre. | Quand les racines font quelques centimètres, rempotez la bouture en terreau léger, le nœud à fleur de terre. |
| `pgSoftStemBody` | Un jeune brin ferme, sans fleur, de dix centimètres environ. Le vieux bois s'enracine mal. | Choisissez un jeune brin ferme, sans fleur, d'environ 10 cm : le vieux bois s'enracine mal. |
| `pgSoftCutBody` | Lame propre, coupe juste sous une paire de feuilles. Les racines partiront de là. | Avec une lame propre, coupez juste sous une paire de feuilles : les racines partiront de là. |
| `pgSoftStripBody` | La paire du bas est retirée : la tige reste nue sur trois ou quatre centimètres. | Retirez la paire du bas pour dénuder la tige sur 3 à 4 cm. |
| `pgSoftRootBody` | La tige nue trempe, les feuilles restent au sec. Lumière vive, sans soleil direct. | Faites tremper la tige nue en gardant les feuilles au sec, en lumière vive et sans soleil direct. |
| `pgSoftPotBody` | Repiquée tôt, à deux ou trois centimètres de racines : une tige tendre supporte mal l'attente. | Repiquez tôt, dès 2 à 3 cm de racines : une tige tendre supporte mal l'attente. |
| `pgLeafChooseBody` | Une feuille mature, ferme, sans marque. Les jeunes feuilles manquent de réserves. | Choisissez une feuille mature, ferme et sans marque : les jeunes feuilles manquent de réserves. |
| `pgLeafCutBody` | Lame propre, coupe à la base de la feuille, au ras du substrat. | Avec une lame propre, coupez la feuille à sa base, au ras du substrat. |
| `pgLeafSplitBody` | La feuille se partage en morceaux de cinq à huit centimètres. Un V taillé en bas de chacun dit quel bout va en terre. | Coupez la feuille en morceaux de 5 à 8 cm. Taillez un V en bas de chacun pour repérer le côté qui va en terre. |
| `pgLeafCallusBody` | Les coupes sèchent à l'air, à l'ombre, avant d'aller en terre. | Laissez les coupes sécher à l'air et à l'ombre avant de les planter. |
| `pgLeafPlantBody` | Le V s'enfonce de deux centimètres dans un substrat drainant. | Enfoncez le V de 2 cm dans un substrat drainant. |
| `pgLeafGrowthBody` | Les racines viennent d'abord, la jeune pousse sort du substrat à côté du segment. | Les racines viennent d'abord ; la jeune pousse sort du substrat à côté du segment. |
| `pgDivPlantBody` | La plante se sort du pot en entier. Un substrat arrosé la veille tient mieux. | Sortez la plante du pot en entier. Un substrat arrosé la veille se tient mieux. |
| `pgDivUnpotBody` | Le pot glisse le long de la motte, la plante est libre. | Faites glisser le pot le long de la motte pour libérer la plante. |
| `pgDivRootsBody` | La terre s'émiette jusqu'à voir les racines et le pied des pousses. | Émiettez la terre jusqu'à voir les racines et le pied des pousses. |
| `pgDivSplitBody` | Les groupes se défont à la main. La lame ne sert que si les couronnes tiennent. | Séparez les groupes à la main. N'utilisez la lame que si les couronnes résistent. |
| `pgDivRepotBody` | Chaque division part dans son pot, à la même profondeur qu'avant, et reçoit un premier arrosage. | Rempotez chaque division dans son pot, à la même profondeur qu'avant, puis arrosez une première fois. |
| `pgOffSpotBody` | Un rejet du tiers de la mère, avec ses propres feuilles, est prêt à partir. | Un rejet qui fait le tiers de la plante mère, avec ses propres feuilles, est prêt à partir. |
| `pgOffClearBody` | Le substrat s'écarte autour du pied : le lien avec la plante mère paraît. | Écartez le substrat autour du pied jusqu'à voir le lien avec la plante mère. |
| `pgOffDetachBody` | Le rejet se détache du lien, avec ses racines. La lame ne sert que si le lien est ligneux. | Détachez le rejet avec ses racines. N'utilisez la lame que si le lien est ligneux. |
| `pgOffPotBody` | Un petit pot, le substrat de l'espèce, et un arrosage léger. | Rempotez dans un petit pot, avec le substrat de l'espèce, puis arrosez légèrement. |
| `pgOffSettleBody` | Une feuille neuve au cœur dit que le rejet a pris. | Une feuille neuve au cœur signale que le rejet a pris. |
| `pgKeikiWaitBody` | Les racines s'allongent sur la hampe. Trois à cinq, longues de quelques centimètres, et le keiki vivra seul. | Les racines s'allongent sur la hampe. À 3 à 5 racines de quelques centimètres, le keiki peut vivre seul. |
| `pgKeikiDetachBody` | La hampe se coupe de part et d'autre du keiki, à un ou deux centimètres. Tirer meurtrissait la base. | Coupez la hampe de part et d'autre du keiki, à 1 ou 2 cm. Ne tirez pas : vous abîmeriez la base. |
| `pgKeikiPotBody` | Un petit pot d'écorces, la base du keiki affleurant le substrat, sans l'enterrer. | Rempotez dans un petit pot d'écorces, la base du keiki affleurant le substrat, sans l'enterrer. |
| `pgSegChooseBody` | Un segment terminal ferme et sans ride, de deux ou trois articles. | Choisissez un segment terminal ferme et sans ride, de 2 ou 3 articles. |
| `pgSegDetachBody` | Le segment se détache à l'articulation, en le tournant. Une lame propre si l'article résiste. | Détachez le segment à l'articulation, en le tournant. Prenez une lame propre s'il résiste. |
| `pgSegWoundBody` | La coupe est claire et humide. Mise en terre tout de suite, elle pourrit. | La coupe est claire et humide : plantée tout de suite, elle pourrirait. |
| `pgSegCallusBody` | La plaie sèche à l'air, à l'ombre, jusqu'à former un cal mat. | Laissez la plaie sécher à l'air et à l'ombre, jusqu'à former un cal mat. |
| `pgSegPlantBody` | Le cal se pose à peine dans un substrat très drainant, sur un centimètre. | Posez le cal sur 1 cm à peine, dans un substrat très drainant. |
| `pgSegRootsBody` | Les racines viennent d'abord, un nouvel article ensuite. L'arrosage attend que les racines tiennent. | Les racines viennent d'abord, un nouvel article ensuite. Attendez que les racines tiennent pour arroser. |

Les 21 clés `pg…Note` restent à l'infinitif : ce sont les étiquettes des
encarts « À repérer » et « À éviter » (« Arracher le rejet sans racines »),
où l'infinitif est la forme juste. Seules leurs mesures passent aux chiffres
(`pgVineRootsNote` : « Premières racines en deux à six semaines » → « en 2 à
6 semaines »).

### Lot 3 — L'écran du matin, la météo, les rappels (132 clés, 35 explicatives)

> **Livré.** 72 chaînes réécrites sur les quatre langues, le relevé du lot
> tombe de 15 clés signalées à 1 — un passif d'état (« l'arrosage est noté
> fait ») que rendre actif ferait déborder la ligne, et dont l'acteur est
> évident. `flutter gen-l10n` passé, tests et `flutter analyze` verts.

Préfixes `home…`, `weather…`, `today…`, `notif…`, `strategy…`, `rain…`.

Trois choses s'y ajoutent à ce que le plan prévoyait :

- **Les conseils de l'air de la maison étaient à l'infinitif** — « Air sec :
  brumiser ou regrouper {names} », « Chaleur : … vérifier la terre ». Ce sont
  des consignes sur l'écran du matin, elles passent à l'impératif.
- **Les alertes de gel et de canicule étaient nominales** — « À rentrer ou à
  couvrir : {names} » devient « Rentrez ou couvrez {names} », dans la carte
  comme dans la notification.
- **`homeClimateAtHome` disait « Da voi » en italien**, seul reste de
  vouvoiement de ce lot ; il passe au *tu*.

`weatherRainCountsHint` perd sa troisième phrase (« Coupé, l'écran du matin le
propose en un tap ») : le bouton « Noter arrosé » est déjà sur l'écran du
matin, la phrase décrivait ce qui se voit. C'est la règle 4 appliquée.

| Clé | Avant | Après |
|---|---|---|
| `weatherHint` | Pour les plantes en extérieur : la pluie tombée vaut un arrosage, la pluie annoncée le reporte, et le gel comme la canicule sont signalés. Données Open-Meteo. | Pour vos plantes en extérieur : la pluie tombée vaut un arrosage, la pluie annoncée le reporte, gel et canicule sont signalés (Open-Meteo). |
| `weatherRainCountsHint` | Au-delà de 5 mm sur trois jours, l'arrosage des emplacements extérieurs est noté fait. Coupé, l'écran du matin le propose en un tap. Un pot abrité par un feuillage reçoit moins de pluie. | Au-delà de 5 mm sur 3 jours, l'arrosage de vos emplacements extérieurs est noté fait. Un pot sous un feuillage reçoit moins de pluie. |
| `weatherClimateHint` | Les propositions de plantes pour l'extérieur suivent les hivers et les étés du lieu. | Les plantes proposées pour l'extérieur tiennent compte des hivers et des étés de votre région. |
| `homeClimateHint` | La température et l'humidité d'un capteur de la maison ajustent les conseils des plantes d'intérieur et complètent les diagnostics. La mesure ne quitte pas l'application. | Un capteur de la maison ajuste les conseils de vos plantes d'intérieur et complète les diagnostics. La mesure ne quitte pas l'application. |
| `homeClimateHumidityMissing` | Humidité non reçue de ce capteur. Un autre se choisit dans la ligne Humidité. | Ce capteur n'envoie pas l'humidité. Choisissez-en un autre dans la ligne Humidité. |
| `homeClimateDeniedApple` | Accès à Apple Maison refusé. Il se rouvre dans Réglages › Confidentialité › Maison. | Accès à Apple Maison refusé. Vous pouvez le rétablir dans Réglages › Confidentialité › Maison. |
| `homeClimateDeniedGoogle` | Accès à Google Home refusé. Il se rouvre dans l'application Google Home, aux autorisations. | Accès à Google Home refusé. Vous pouvez le rétablir dans les autorisations de l'application Google Home. |
| `homeClimateDisconnectGoogleHint` | Les capteurs de Google Home sont oubliés sur cet appareil. L'autorisation accordée reste dans le compte Google, et se retire depuis ce compte. | Les capteurs Google Home sont oubliés sur cet appareil. L'autorisation reste dans votre compte Google : retirez-la depuis ce compte. |
| `homeClimateFailedIn` | {home} indisponible. Vous pourrez connecter un capteur dans Profil › Capteurs de la maison. | {home} est indisponible. Vous pourrez connecter un capteur dans Profil › Capteurs de la maison. |
| `strategyWeatherHint` | L'intervalle de la saison, resserré par la chaleur sèche, espacé par la pluie et le froid. | L'intervalle de la saison se resserre par temps chaud et sec, s'espace par temps pluvieux ou froid. |
| `strategyWeatherNoPlace` | Sans lieu météo, l'intervalle reste celui de la saison. | Sans lieu météo renseigné, l'intervalle reste celui de la saison. |
| `notificationPermissionDenied` | Autorisez les notifications dans les Réglages de votre téléphone. | *(inchangé — « Réglages » est le nom de l'app d'iOS, la majuscule est juste)* |

### Lot 4 — L'identification et Iris (84 clés, 21 explicatives)

Préfixes `identif…`, `iris…`, `suggestions…`, `species…`. Lot sensible : trois
chaînes y portent un consentement, et la règle 3 leur accorde trois phrases.

| Clé | Avant | Après |
|---|---|---|
| `identificationHint` | Reconnaissance des espèces sur l'appareil par {name}, sans réseau. En cas de doute, la photo peut être envoyée à Pl@ntNet. | {name} reconnaît les espèces directement sur votre appareil, sans réseau. En cas de doute, la photo peut être envoyée à Pl@ntNet. |
| `identificationFallbackHint` | En cas de doute de {name}, la photo est envoyée à Pl@ntNet. Désactivé, tout reste sur l'appareil. | Quand {name} hésite, la photo est envoyée à Pl@ntNet. Désactivé, tout reste sur votre appareil. |
| `identificationUncertainBody` | Même avec les photos disponibles, aucune espèce ne ressort assez nettement. Vous pouvez chercher en ligne ou choisir manuellement si vous reconnaissez la plante. | Aucune espèce ne ressort assez nettement. Cherchez en ligne, ou choisissez l'espèce vous-même si vous reconnaissez la plante. |
| `irisFeedbackHint` | Les photos prises pour identifier et le nom retenu sont envoyés dès qu'une plante est nommée, et entraînent les prochaines versions du modèle {name}. Elles ne sont lisibles que par le compte qui les envoie, et sa suppression les efface. Désactivé, elles ne quittent pas l'appareil. | Quand vous nommez une plante, ses photos et le nom retenu sont envoyés pour entraîner les prochaines versions de {name}. Vous seul pouvez les lire, et supprimer votre compte les efface. Désactivé, elles ne quittent pas votre appareil. |
| `irisFeedbackAskBody` | Les photos prises pour identifier et le nom retenu peuvent être envoyés pour entraîner les prochaines versions du modèle {name}. Elles ne sont lisibles que par le compte qui les envoie, et sa suppression les efface. Le choix se change dans les réglages d'identification. | Vos photos d'identification et le nom retenu peuvent être envoyés pour entraîner les prochaines versions de {name}. Vous seul pouvez les lire, et supprimer votre compte les efface. Vous pourrez revenir sur ce choix dans les réglages d'identification. |
| `irisTagline` | Reconnaissance des espèces sur le téléphone, sans réseau ni compte. | Reconnaît les espèces sur votre téléphone, sans réseau ni compte. |
| `irisTwoPhotosBody` | La plante entière, puis une feuille de près. Avec deux photos, {name} trouve la bonne espèce deux fois sur trois, contre une fois sur deux. | Photographiez la plante entière, puis une feuille de près : avec deux photos, {name} trouve la bonne espèce 2 fois sur 3, contre 1 fois sur 2. |
| `identifyAnotherPhotoHint` | Une feuille, une fleur ou la plante entière permet d'affiner. | Ajoutez une feuille, une fleur ou la plante entière pour affiner. |
| `identifyPhotoSource` | Photos Pl@ntNet et GBIF. Touchez-en une pour ouvrir la fiche de l'espèce. | Photos Pl@ntNet et GBIF. Touchez-en une pour ouvrir la fiche de l'espèce. *(inchangé)* |
| `identificationStats` | {local} analysées sur l'appareil, dont {accepted} tranchées ici ; {remote} envoyées en ligne | {local} analysées sur votre appareil, dont {accepted} sans envoi ; {remote} envoyées en ligne |
| `speciesOffline` | La liste complète nécessite une connexion. Les espèces courantes restent disponibles. | La liste complète demande une connexion. Les espèces courantes restent disponibles. |

### Lot 5 — Le diagnostic et l'encyclopédie (138 clés, 23 explicatives)

Préfixes `diagnosis…`, `cause…`, `problem…`, `natural…`, `leaf…`,
`encyclopedia…`. Les définitions de l'encyclopédie (`problemKind…Note`) sont
des entrées de glossaire : la phrase nominale y est justifiée et reste.

| Clé | Avant | Après |
|---|---|---|
| `diagnosisHint` | Photographiez les feuilles, la tige et la terre, de près et en entier. Les résultats sont indicatifs. | Photographiez les feuilles, la tige et la terre, de près puis en entier. Les résultats sont indicatifs. |
| `diagnosisUncertain` | Les photos ne suffisent pas pour conclure. Les pistes ci-dessous restent à vérifier. | Les photos ne suffisent pas pour conclure. Vérifiez les pistes ci-dessous. |
| `diagnosisChecksHint` | Facultatif : ce que la photo ne montre pas affine l'analyse. | Facultatif : précisez ce que la photo ne montre pas pour affiner l'analyse. |
| `diagnosisAnotherPhotoHint` | Une photo de plus préciserait l'analyse. | Une photo de plus affinerait l'analyse. |
| `diagnosisSettingsHint` | Les photos sont analysées par un modèle hébergé en Suisse (AI Services d'Infomaniak). Elles ne partent que lorsque vous lancez une analyse, et ne sont pas conservées. | Vos photos sont analysées par un modèle hébergé en Suisse (AI Services d'Infomaniak). Elles ne partent qu'au moment où vous lancez une analyse, et ne sont pas conservées. |
| `diagnosisRefused` | L'analyse n'a pas pu être effectuée pour cette photo. | Cette photo n'a pas pu être analysée. |
| `naturalCauseNote` | Ce que la plante fait normalement et qu'on prend pour un problème : rien à soigner. | Ce que la plante fait normalement et qu'on prend pour un problème : il n'y a rien à soigner. |
| `encyclopediaHint` | Les problèmes de la base, les espèces du catalogue et le vocabulaire des fiches d'entretien. | Les problèmes recensés, les espèces du catalogue et le vocabulaire des fiches d'entretien. |
| `careLeafSignsNote` | Ce qu'une feuille montre, et ce qui l'explique le plus souvent. | Ce qu'une feuille montre, et ce qui l'explique le plus souvent. *(inchangé)* |

### Lot 6 — Les fiches d'entretien (303 clés, 117 explicatives)

Préfixe `care…` hors `careTip…`. Le lot le plus volumineux, mais le mieux
écrit : l'impératif y est déjà courant (« Rempotez quand… », « Comptez… »).
Le travail y est de trois ordres, et se fait au fil des sections de
`docs/06`, § « La fiche d'entretien » :

1. **Les mesures aux chiffres** — `careBloomChillBulbNote` « dix à quinze
   semaines » → « 10 à 15 semaines », `careGreenhouseEarly` « quatre à six
   semaines » → « 4 à 6 semaines », `careDifficulty…`, `careSoilMix…`.
2. **Les consignes à l'infinitif** — `careToxicPets` « Tenir hors de portée
   des animaux et des enfants. » → « Tenez-la hors de portée des animaux et
   des enfants. » ; `careGreenhouseAir` « Aérer chaque jour : … » → « Aérez
   chaque jour : … » ; `careSupportMossPoleCare` « Humidifier le tuteur à
   chaque arrosage » → « Humidifiez le tuteur à chaque arrosage » ;
   `careSupportStakeCare`, `careSupportTrellisCare` de même.
3. **Les descriptions qui cachent l'acteur** — `carePotDormantNote` « Le
   rempotage se fait à la reprise, quand le repos s'achève, et non sur une
   racine qui sort. » → « Rempotez à la reprise, quand le repos s'achève, et
   non parce qu'une racine sort. » ; `carePropTuberNote` « Le tubercule se
   coupe en morceaux portant chacun un œil. » → « Coupez le tubercule en
   morceaux portant chacun un œil. » ; `carePropDivisionNote`,
   `carePropWaterNote` de même.
4. **Les trois `care…Risk` trop longs** — `careWaterCondensateRisk` (238
   signes, 3 phrases), `careWaterOsmosisRisk`, `careWaterSoftenedRisk` : garder
   le risque et le remède, couper la justification.

Les 62 `careTip…` explicatives ne sont pas dans ce lot. Les libellés courts
(`careLight…`, `careSoil…`, `careWater…`, `careFert…`) sont bons et restent.

### Lot 7 — La découverte, l'accueil, le soutien (111 clés, 36 explicatives)

Préfixes `onb…`, `whatsNew…`, `support…`, `about…`, `finder…`.

| Clé | Avant | Après |
|---|---|---|
| `onbHomeBody` | Les capteurs d'Apple Maison et de Google Home donnent la température et l'humidité de la pièce. Les conseils et les diagnostics des plantes d'intérieur en tiennent compte. La mesure ne quitte pas l'application. | Les capteurs Apple Maison et Google Home donnent la température et l'humidité de vos pièces. Les conseils et les diagnostics d'intérieur en tiennent compte, et la mesure ne quitte pas l'application. |
| `onbPlaceBody` | Pour la météo et l'arrosage en extérieur. Une ville suffit, la position exacte n'est pas conservée. | Pour la météo et l'arrosage en extérieur. Une ville suffit : votre position exacte n'est pas conservée. |
| `onbAccountBody` | Un compte sauvegarde vos données et permet de partager un jardin. Connexion avec votre identifiant Apple. | Un compte sauvegarde vos données et vous permet de partager un jardin. Connectez-vous avec votre identifiant Apple. |
| `onbGardenBody` | Chaque arrosage, chaque rempotage est daté et rangé avec la plante. | L'application date chaque arrosage et chaque rempotage, et les range avec la plante. |
| `onbIrisBody` | Plante inconnue d'Iris : la recherche continue en ligne. | Si Iris ne connaît pas la plante, la recherche continue en ligne. |
| `supportOffer` | Si vous souhaitez néanmoins aider le développeur, un achat unique suffit. | Pour aider le développeur, un achat unique suffit. |
| `whatsNewIrisOfflineBody` | La reconnaissance reste locale : rien ne part sans votre accord, et le repli en ligne se coupe d'un interrupteur. | La reconnaissance reste locale : rien ne part sans votre accord, et vous pouvez couper le repli en ligne. |
| `whatsNewIrisSpeciesBody` | Des plantes d'intérieur plus rares s'ajoutent au catalogue. | Le catalogue accueille des plantes d'intérieur plus rares. |
| `finderEmptySubtitle` | Aucune espèce du catalogue ne correspond à tous les critères. Modifiez une réponse ou élargissez les genres de plantes. | Aucune espèce du catalogue ne coche tous les critères. Modifiez une réponse ou élargissez les genres de plantes. |
| `finderAiBody` | Recherche hors du catalogue, à partir de vos réponses et de ce que vous ajoutez ici. | Recherche hors catalogue, à partir de vos réponses et de ce que vous ajoutez ici. |
| `finderStepSafetyHint` | Beaucoup de plantes d'intérieur sont toxiques si on les mordille. | Beaucoup de plantes d'intérieur sont toxiques si un animal ou un enfant les mordille. |

Les `finderStep…` gardent leur forme interrogative : ce sont les questions
d'un questionnaire, et `docs/06` les exempte explicitement.

### Lot 8 — Le compte, le partage, la collaboration (132 clés, 35 explicatives)

Préfixes `sign…`, `auth…`, `sync…`, `share…`, `invite…`, `join…`, `member…`,
`garden…`, `community…`, `moderation…`.

| Clé | Avant | Après |
|---|---|---|
| `gardensHint` | Le jardin ouvert est celui affiché partout dans l'application. Le passage de l'un à l'autre se fait ici. | Le jardin ouvert est celui affiché partout dans l'application. Changez-en ici. |
| `openGardenHint` | Ce compte donne accès à ces jardins. Ouvrez celui où sont vos plantes. | Ce compte donne accès à ces jardins. Ouvrez celui qui contient vos plantes. |
| `joinInvalid` | Ce code ne vaut plus rien. Il a déjà servi, a expiré, ou n'existe pas. | Ce code n'est plus valable : il a déjà servi, a expiré, ou n'existe pas. |
| `joinGardenHint` | Saisissez le code reçu, ou ouvrez le lien d'invitation qu'on vous a envoyé. | Saisissez le code reçu, ou ouvrez le lien d'invitation qui vous a été envoyé. |
| `inviteShareHint` | Envoyez ce lien ou ce code. L'application n'est pas nécessaire pour le recevoir. | Envoyez ce lien ou ce code. La personne n'a pas besoin de l'application pour le recevoir. |
| `inviteHint` | L'invité doit déjà avoir un compte Auxine avec cette adresse. | La personne invitée doit déjà avoir un compte Auxine à cette adresse. |
| `shareUnlistedHint` | La page demande aux moteurs de recherche de ne pas l'indexer. Toute personne ayant le lien peut la voir. | La page demande aux moteurs de recherche de ne pas l'indexer, mais toute personne qui a le lien peut la voir. |
| `membersHint` | Les membres voient les mêmes plantes et peuvent s'en occuper. | Les membres voient vos plantes et peuvent s'en occuper. |
| `communityTipsHint` | Ce que d'autres personnes ont observé en gardant cette espèce, hors du catalogue. | Ce que d'autres personnes ont observé en cultivant cette espèce, hors catalogue. |
| `communityTipPublicNote` | Le conseil paraît sous votre nom sur la fiche de cette espèce, pour tout le monde. | Votre conseil sera visible par tout le monde, sous votre nom, sur la fiche de cette espèce. |
| `moderationHint` | Les conseils signalés, du plus signalé au moins signalé. | Les conseils signalés, du plus au moins signalé. |
| `readOnlyHint` | Vous consultez ce jardin en lecture seule. | Vous consultez ce jardin en lecture seule. *(inchangé)* |

### Lot 9 — Les données, la sauvegarde, le hors-ligne (74 clés, 26 explicatives)

Préfixes `export…`, `import…`, `backup…`, `offline…`, `delete…`, `confirm…`,
`archive…`.

| Clé | Avant | Après |
|---|---|---|
| `offlineHint` | Cette fonction demande une connexion. Les données déjà sur l'appareil restent lisibles. | Cette fonction demande une connexion. Les données déjà sur votre appareil restent consultables. |
| `offlineIdentification` | La recherche en ligne demande une connexion. La reconnaissance sur l'appareil, non. | La recherche en ligne demande une connexion ; la reconnaissance sur votre appareil, non. |
| `offlineCommunityTips` | Lire et publier des conseils demande une connexion. | Lire et publier des conseils demande une connexion. *(inchangé)* |
| `exportHint` | Un fichier ZIP avec vos plantes, historiques, inventaire, réglages et photos. | Un fichier ZIP contenant vos plantes, vos historiques, votre inventaire, vos réglages et vos photos. |
| `importConfirm` | Les données du fichier remplacent celles de même identifiant. Rien n'est supprimé. | Les données du fichier remplacent celles qui portent le même identifiant. Rien n'est supprimé. |
| `deleteGroupHint` | Les articles ne sont pas supprimés, ils rejoignent le groupe choisi. | Les articles ne sont pas supprimés : ils rejoignent le groupe choisi. |
| `deleteGardenConfirm` | Le jardin « {name} », ses plantes et son journal seront supprimés, pour vous comme pour les personnes invitées. | Le jardin « {name} », ses plantes et son journal seront supprimés, pour vous comme pour les personnes invitées. *(inchangé)* |
| `confirmDeleteAttachment` | Supprimer ce document ? Le fichier sera effacé de l'appareil. | Supprimer ce document ? Le fichier sera effacé de votre appareil. |

### Lot 10 — Le jardin au jour le jour (575 clés, 69 explicatives)

Tout le reste : `plant…`, `task…`, `photo…`, `event…`, `field…`, `note…`,
`item…`, `add…`, `edit…`, `sort…`, `filter…`, `empty…`, `no…`. Pas de tableau :
ce sont des libellés courts, bons dans l'ensemble. Le lot consiste à passer
les 69 chaînes explicatives à la charte, en particulier les états vides et les
aides de champ (`photoFrameHint`, `growthEmptySubtitle`, `searchByNumberHint`,
`notesMarkdownHint`, `actionTypesHint`, `noPlantsHereSubtitle`…), et à vérifier
que chaque libellé de bouton reste à l'infinitif (« Ajouter une plante »), qui
est la forme française juste pour une commande.

### Lot 11 — Les passes mécaniques, quatre langues

À passer en dernier, quand plus aucune chaîne ne bouge :

1. **L'apostrophe** — 27 chaînes françaises et 13 italiennes portent `’` là où
   283 et 135 portent `'`. Aligner sur l'apostrophe droite, qui est la
   convention majoritaire du dépôt. Presque tout le lot `pg…` est concerné.
2. **Les nombres** — 25 chaînes par langue, cent au total.
3. **Le registre** — l'italien au *tu* (18 chaînes en *voi*), l'allemand selon
   la décision du § 4 (48 ou 18 chaînes).
4. **Les guillemets italiens** — `markWatch` et `speciesUseText` passent de
   `“ … ”` à `« … »`, comme les dix autres chaînes italiennes.
5. **Les deux chaînes françaises en dur** dans
   `lib/features/profile/presentation/service_status_screen.dart` (« Décisions
   Jev », « Aucun arbitrage pour l'instant. ») : les passer aux ARB, ou noter
   dans le fichier que cet écran est un outil de développement hors
   localisation.

## 7. Les garde-fous

**`tool/audit_textes.py`** (livré) relève ce qui est mécanique :

```bash
python3 tool/audit_textes.py                 # le compte, par défaut et par langue
python3 tool/audit_textes.py --lot pg --liste # une ligne par chaîne d'un lot
python3 tool/audit_textes.py --csv > audit.csv
```

Le script n'est pas un test : il désigne les endroits à relire, et il se
relance avant et après chaque lot pour voir le compte descendre.

**`test/l10n/arb_tone_test.dart`** garde ses trois tests et en reçoit quatre,
ajoutés **au fil des lots** — un test n'entre que quand le dernier lot
concerné est vert, sinon la suite casse dès le premier commit :

| Test | Verrouille | Entre après |
|---|---|---|
| longueur maximale | 140 signes pour une aide, 220 pour un chapeau, la liste des exceptions de consentement étant écrite dans le test | lot 10 |
| apostrophe unique | aucune `’` dans les quatre ARB | lot 11 |
| registre unique | aucun *Sie* en allemand (ou aucun *du*), aucun *voi* en italien | lot 11 |
| parité ICU ✓ | chaque marqueur déclaré par `@clé.placeholders` du modèle français se retrouve dans les quatre langues | **en place** |

## 8. Le déroulé d'un lot

1. `python3 tool/audit_textes.py --lot <préfixe> --liste` pour l'état d'entrée.
2. Réécrire `app_fr.arb`, lot par lot, d'après la charte du § 3.
3. Réécrire `app_en.arb`, `app_de.arb`, `app_it.arb` **depuis l'intention**,
   le français sous les yeux mais pas sous la plume (règle 7).
4. `flutter gen-l10n` — les fichiers de `lib/l10n/generated/` sont commités.
5. `flutter test test/l10n/` puis `flutter analyze`.
6. Ouvrir les écrans du lot sur un appareil, en allemand : c'est la langue qui
   déborde (§ 9).
7. Un commit par lot : `textes(relevé) : s'adresser à la personne`.

## 9. Les risques

- **Le débordement.** L'allemand fait 10 à 20 % de plus que le français, et la
  charte rallonge les chaînes courtes qu'elle remet à l'impératif. Les boutons
  et les pilules de l'écran du matin sont les premiers exposés. Vérifier à
  l'écran, pas dans l'ARB.
- **Les fichiers générés.** `lib/l10n/generated/` est commité : un lot livré
  sans `flutter gen-l10n` laisse l'application sur les anciens textes.
- **Les marqueurs ICU.** Une réécriture qui perd `{count}` ou change une
  catégorie de pluriel casse à l'exécution, pas à la compilation. Le test de
  parité du § 7 entre dès le premier lot pour cette raison.
- **Le vocabulaire qui déborde du lot.** *Relevé* → *scan* touche
  `docs/17-releve-de-la-maison.md` et les libellés d'`AppConfig` ; *place* →
  *emplacement* croise `location…` et `placement…`, déjà traduits par
  « emplacement ». Vérifier qu'un même mot français ne désigne pas deux choses
  après le lot 1.
- **`docs/06-design-system.md`.** La charte du § 3 y remplace le paragraphe
  « Les textes » dans le même commit que le premier lot, sinon les deux
  documents se contredisent.

## 10. L'ordre et le volume

| Ordre | Lot | Clés | Explicatives | Pourquoi là |
|---:|---|---:|---:|---|
| 1 ✓ | Relevé de la maison | 95 | 27 | **livré** — l'écran qui a ouvert le chantier ; sert de patron aux autres |
| 2 ✓ | Guides de multiplication | 133 | 62 | **livré** — le plus atteint, et le plus lu quand on s'en sert |
| 3 ✓ | Écran du matin, météo | 132 | 35 | **livré** — vu tous les jours |
| 4 | Identification, Iris | 84 | 21 | porte trois consentements |
| 5 | Diagnostic, encyclopédie | 138 | 23 | |
| 6 | Fiches d'entretien | 303 | 117 | volumineux mais déjà propre |
| 7 | Découverte, soutien | 111 | 36 | première impression |
| 8 | Compte, partage | 132 | 35 | |
| 9 | Données, hors-ligne | 74 | 26 | |
| 10 | Jardin au jour le jour | 575 | 69 | libellés courts, passe rapide |
| 11 | Passes mécaniques | — | — | quand plus rien ne bouge |
| | **Total** | **1 851** | **513** | soit 2 052 chaînes sur quatre langues |
