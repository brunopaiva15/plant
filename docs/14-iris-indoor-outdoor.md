# 14 — Iris 10 / Iris Core : un encodeur botanique, plusieurs spécialistes

> **Direction retenue le 17 septembre 2026.** Iris 10 ne sera pas une simple
> génération supplémentaire du classifieur actuel. La cible est un **encodeur
> visuel botanique embarqué**, distillé depuis de grands modèles de fondation,
> qui produit un embedding réutilisable par plusieurs spécialistes : Indoor,
> Outdoor, taxonomie, prototypes de cultivars et détection d'inconnus.
>
> Iris Indoor — codée « 9.1 » pendant le cadrage — reste la première
> baseline Indoor. Iris 9 reste le dernier gros
> entraînement de la génération « classifieur softmax ». Iris 10 change de
> paradigme.

## 1. Pourquoi changer de paradigme

Iris 8 et le cadrage d'Iris 9 ont établi deux faits qui doivent rester vrais :

- **entraîner large améliore la représentation** ;
- **exposer trop de classes simultanément dégrade la précision** sur les
  espèces qui comptent.

Iris 9 répond à ce problème par « entraîner large, exposer étroit ». Iris 10
va plus loin : le cœur du modèle ne doit plus être entraîné à répondre
uniquement à une liste figée d'espèces. Il doit apprendre **un espace visuel
botanique** dans lequel une photo, une espèce, un genre, une famille et des
prototypes peuvent être comparés.

Le changement conceptuel est celui-ci :

```text
Iris 9 et avant
photo -> backbone -> softmax -> une espèce parmi N

Iris 10
photo -> Iris Core -> embedding botanique -> spécialistes / recherche / OOD
```

Cela permet d'ajouter ou retirer des espèces d'un spécialiste sans forcément
réentraîner Iris Core, de partager le calcul entre Indoor et Outdoor, de
préparer les cultivars et de mieux traiter l'open-set.

## 2. La place des versions précédentes

### Iris Indoor, la première spécialiste

Iris Indoor est déjà dessinée comme une spécialiste Indoor :

- masque court de plantes réellement cultivées à l'intérieur ;
- collecte orientée photos `captive` / plantes en pot ;
- jeu qui ressemble davantage aux photos réelles des utilisateurs ;
- moins de classes concurrentes dans la sortie.

Elle devient donc la **baseline officielle d'Iris Indoor**, pas une branche à
jeter après Iris 9.

### Iris 9 = dernière grande génération « classifier »

Iris 9 reste utile pour deux raisons :

1. pousser au maximum la recette actuelle « entraîner large, exposer étroit » ;
2. donner une baseline forte contre laquelle Iris 10 devra prouver son gain.

Iris 10 ne sera pas considéré meilleur parce qu'il est plus moderne ; il doit
battre Iris Indoor sur son terrain, Iris 9 sur le généraliste, ou apporter une capacité
nouvelle mesurable à coût embarqué acceptable.

## 3. Architecture cible

BioCLIP et DINOv3 ne définissent **pas le même espace de représentation**.
Iris Core ne doit donc pas essayer de faire coïncider son unique embedding
final avec les deux teachers à la fois. **BioCLIP 2.5 définit le repère
canonique d'Iris Core** ; DINOv3 n'est qu'une supervision perceptuelle
auxiliaire, isolée derrière sa propre projection et conservée seulement si une
ablation démontre son intérêt.

```text
                         ENTRAÎNEMENT HORS APP

                         image d'entraînement
                                 │
                                 ▼
                         ┌──────────────┐
                         │  IRIS CORE   │
                         │ shared       │
                         │ backbone     │
                         └──────┬───────┘
                                │
                   ┌────────────┴────────────┐
                   │                         │
                   ▼                         ▼
           projecteur BioCLIP         projecteur DINO
                   │                         │
                   ▼                         ▼
           embedding principal       features auxiliaires
           espace BioCLIP 2.5        locales / denses
                   │                         │
                   │                  entraînement seulement
                   │                  sauf gain produit mesuré
                   ▼
             utilisé dans l'app
                   │
        ┌──────────┼───────────┬──────────────┐
        │          │           │              │
        ▼          ▼           ▼              ▼
     Indoor     Outdoor     Taxonomie      Prototypes
                                             cultivars
        │          │           │              │
        └──────────┴───────────┴──────────────┘
                   │
            arbitrage / OOD
                   │
                Pl@ntNet
```

Le téléphone n'embarque **ni BioCLIP 2.5 ni DINOv3**. BioCLIP sert de teacher
principal pendant l'entraînement. DINOv3 peut servir de teacher auxiliaire
pour des features intermédiaires, mais sa branche peut disparaître totalement
du modèle exporté.

Le contrat public d'Iris Core est donc simple : **une image doit être projetée
dans un espace compatible avec les références BioCLIP pré-calculées**. Tout
signal auxiliaire doit améliorer ce contrat, jamais le déformer.

## 4. Teachers : BioCLIP 2.5 fixe la géométrie, DINOv3 reste expérimental

### BioCLIP 2.5 = repère canonique

La priorité est donnée à BioCLIP 2.5 car son espace est construit pour le
vivant et la taxonomie, ce qui correspond directement au problème d'Iris.
L'objectif de la distillation n'est pas de copier un softmax, mais de faire
entrer le student mobile dans **le même espace sémantique biologique utile**
que le teacher.

Ce teacher doit surtout apprendre au student :

- proximité entre représentations de la même espèce ;
- structure genre / famille ;
- séparation fine entre taxons voisins ;
- compatibilité image ↔ texte/taxonomie ;
- représentation utilisable par recherche de similarité et prototypes.

Cette géométrie est le **système de coordonnées officiel d'Iris Core**. Les
embeddings textuels d'espèces et les références générées par BioCLIP doivent
rester directement comparables à la sortie principale d'Iris.

Référence de travail au moment de cette décision :
`imageomics/bioclip-2.5-vith14`. La licence et les conditions exactes de
redistribution/distillation doivent être **revalidées avant l'entraînement
final**, même si le modèle est actuellement publié avec une licence permissive.

### DINOv3 = professeur de perception auxiliaire

DINOv3 est intéressant pour les détails visuels et les représentations
locales/denses : nervures, textures, panachures, forme d'un bord de feuille,
structure d'une fleur, port de la plante.

Mais ses représentations n'ont aucune raison d'avoir la même géométrie que
BioCLIP. Une loss DINO ne doit donc **jamais tirer directement l'embedding
principal** vers l'espace DINO.

La première expérience DINO doit passer par une projection séparée depuis des
features intermédiaires du backbone :

```text
features Iris intermédiaires
        │
        ├── projecteur BioCLIP -> embedding principal -> app
        │
        └── projecteur DINO    -> loss perceptuelle auxiliaire
                                  entraînement uniquement
```

Le poids de cette loss doit commencer faible. La branche DINO est supprimée
si elle ne produit pas un gain mesurable sur les confusions fines, ou si elle
dégrade l'alignement BioCLIP, le retrieval, la calibration ou l'OOD.

**Iris 10.0 doit donc pouvoir être entraîné et livré sans DINOv3.** La baseline
obligatoire est BioCLIP seul ; BioCLIP + DINO n'est qu'une ablation candidate.

## 5. Le student mobile n'est pas encore figé

La famille du student doit être choisie par benchmark réel, pas par préférence.
Au minimum :

| candidat | intérêt |
|---|---|
| **FastViT** | très bon compromis mobile, réparamétrisation efficace, bon candidat iOS |
| **MobileNetV4 Hybrid** | architecture moderne, forte portabilité CPU/GPU/NPU |
| **RepViT** | alternative très rapide à tester si elle reste assez expressive |

La cible de départ est un student d'environ **15 à 30 M de paramètres**, mais
la taille n'est pas une exigence : la contrainte réelle est la latence, la RAM,
la taille du binaire et surtout la précision sur nos jeux Indoor / Outdoor.

Le bake-off doit comparer les candidats **avec la même recette de distillation,
les mêmes données et la même géométrie BioCLIP de sortie**.

## 6. Iris Core produit un embedding BioCLIP-compatible, pas un nom

Le contrat principal d'Iris Core devient :

```text
photo -> vecteur L2-normalisé dans l'espace canonique BioCLIP
```

La dimension principale n'est donc pas choisie arbitrairement : elle doit être
compatible avec les embeddings BioCLIP utilisés comme références. Une réduction
de dimension n'est acceptable que si **images et références** passent par la
même projection validée et que la géométrie utile reste préservée.

Une identification ne dépend plus obligatoirement d'une couche finale figée.
Auxine peut embarquer une matrice de références :

```text
iris_core.tflite
species_embeddings.bin
metadata / masks Indoor-Outdoor
```

Puis rechercher les candidats par produit scalaire / cosine dans cet espace.
Avec quelques milliers d'espèces, une simple multiplication matricielle peut
rester suffisante ; un index ANN ne sera ajouté que si la mesure le justifie.

Le critère fondamental devient notamment :

```text
cosine(IrisCore(image), BioCLIP_reference)
```

Toute modification de la recette d'entraînement doit être jugée aussi sur la
stabilité de cette relation, pas seulement sur un top-1 de classification.

## 7. Embeddings d'espèces : texte et prototypes

Le text encoder de BioCLIP ne doit pas être embarqué sur le téléphone. Les
embeddings textuels d'espèces peuvent être **pré-calculés hors app** à partir
des noms taxonomiques et éventuellement de formulations contrôlées, puis
livrés dans `species_embeddings.bin`.

Une espèce peut aussi posséder un ou plusieurs **prototypes visuels** issus de
photos validées. La représentation finale d'une espèce pourra donc combiner :

- embedding textuel taxonomique ;
- centroid de photos validées ;
- prototypes par domaine (Indoor / Outdoor) si nécessaire ;
- plus tard, prototypes de cultivars.

Cela ouvre la possibilité d'ajouter une espèce à la recherche sans réentraîner
Iris Core, tant que l'espace reste compatible.

## 8. Indoor et Outdoor deviennent deux vues du même cerveau

Indoor et Outdoor ne sont pas deux modèles complets, ni nécessairement deux
têtes neurales. Ce sont d'abord deux **ensembles de références, de priors et de
calibration** qui exploitent le même embedding calculé une seule fois.

```text
                         Iris Core
                             │
                  embedding BioCLIP-compatible
                             │
               ┌─────────────┴─────────────┐
               │                           │
          Iris Indoor                 Iris Outdoor
       références / prior          références / prior
       calibration Indoor          calibration Outdoor
               │                           │
               └─────────────┬─────────────┘
                             │
                        arbitrage
```

Une espèce peut appartenir aux deux domaines. Indoor / Outdoor décrivent un
**contexte de reconnaissance**, pas deux taxonomies exclusives.

Le contexte de l'app fournit un a priori, jamais une interdiction :

- jardin/emplacement intérieur -> Indoor prioritaire ;
- emplacement extérieur -> Outdoor prioritaire ;
- contexte inconnu -> les deux sont évalués ;
- contradiction -> conserver les deux hypothèses jusqu'à l'arbitrage.

Iris Indoor fournit la première liste et le premier jeu de test Indoor. Outdoor
doit recevoir son propre jeu de test avant d'être considéré prêt.

## 9. Taxonomie hiérarchique : espèce, genre, famille

Iris Core doit être entraîné pour que la hiérarchie biologique soit utile,
mais on évite un routage dur du type « si la famille est fausse, toutes les
espèces deviennent impossibles ».

Des têtes auxiliaires genre / famille peuvent être utilisées pendant
l'entraînement et éventuellement à l'inférence pour :

- répondre « Monstera, espèce incertaine » quand l'espèce n'est pas sûre ;
- vérifier la cohérence d'un candidat ;
- aider l'arbitrage Indoor / Outdoor ;
- donner un signal OOD supplémentaire.

La réponse au genre reste une sortie produit légitime, pas un échec.

## 10. Cultivars : prototypes dans le même espace

Les cultivars ne doivent toujours pas devenir automatiquement des classes du
modèle principal. Iris Core doit au contraire créer un espace assez fin pour
que des prototypes puissent distinguer, lorsque le signal existe :

```text
Monstera deliciosa
        │
        ├── 'Thai Constellation'
        ├── 'Albo'
        └── forme verte
```

Le travail `prototypes.py` prévu dans le cadrage précédent reste donc pertinent,
mais Iris 10 lui donne un embedding conçu pour cet usage plutôt que de recycler
une représentation entraînée à confondre tous les cultivars sous le nom de
l'espèce.

## 11. Global + local : ne pas perdre les petits détails botaniques

Un seul embedding global peut être insuffisant pour du fine-grained. La recette
Iris 10 doit tester un second signal local à partir de features intermédiaires :
quelques tokens/patches, ou une projection compacte supervisée par DINOv3.

Objectif :

```text
global BioCLIP -> port général / taxonomie / retrieval
local auxiliaire -> nervure / marge / texture / panachure / fleur
```

La sortie globale BioCLIP reste le contrat principal. Le signal local ne doit
pas modifier sa géométrie directement. Il peut :

- servir uniquement comme loss auxiliaire pendant l'entraînement ;
- être supprimé à l'export ;
- ou être conservé comme petite branche séparée si un benchmark montre un gain
  suffisant sur les confusions fines.

## 12. Réduire le domain shift par augmentation segmentée

Les erreurs terrain actuelles montrent que le contexte visuel compte trop :
un réseau peut apprendre une espèce dans une prairie puis la voir dans un
salon et suivre la texture du décor ou du pot.

La segmentation peut être utilisée **hors ligne pendant la fabrication du jeu**
avec un gros modèle :

```text
photo originale
photo recadrée sur la plante
photo avec fond neutralisé
photo avec fond remplacé
```

Le student apprend alors à reconnaître la plante malgré le contexte. Aucun
segmenter supplémentaire n'est requis dans l'app tant que l'expérience ne
montre pas qu'il apporte un gain suffisant à l'inférence.

## 13. Multi-photo : fusionner les embeddings

Aujourd'hui plusieurs photos améliorent déjà beaucoup Iris. Iris 10 doit
fusionner au niveau de la représentation, avant la décision finale :

```text
photo plante entière ─┐
photo feuille ─────────┼─> Iris Core -> embeddings -> fusion -> recherche
photo fleur ───────────┘
```

Première baseline : moyenne des embeddings L2-normalisés. Ensuite seulement,
tester attention/pooling appris si cela apporte un gain réel.

Le modèle ne doit pas exiger que toutes les images montrent le même organe.
C'est précisément l'intérêt du multi-photo : combiner des preuves différentes.

## 14. Recette d'entraînement cible

La première recette Iris 10 doit commencer **simplement par BioCLIP**, puis
ajouter chaque sophistication par ablation. L'ordre évite de confondre le gain
d'un meilleur student avec celui d'un second teacher.

### Baseline A — Iris Core BioCLIP

1. **distillation BioCLIP 2.5** vers le projecteur principal ;
2. **supervision espèce** sur les labels solides d'Auxine ;
3. **supervision hiérarchique** genre / famille ;
4. **supervised contrastive / metric learning** pour resserrer une espèce et
   séparer les espèces voisines ;
5. **hard negatives taxonomiques** : espèces du même genre/famille plus
   souvent opposées dans les batches ;
6. données de domaine `captive`, `(potted)` et `iris_feedback` ;
7. augmentations de contexte issues de segmentation ;
8. exemples OOD / non-plantes pour apprendre le refus.

### Ablation B — ajouter DINOv3

À backbone, données, epochs et hyperparamètres identiques :

- ajouter une **projection DINO séparée** sur des features intermédiaires ;
- utiliser une loss perceptuelle auxiliaire de poids faible au départ ;
- ne jamais appliquer cette loss directement sur l'embedding BioCLIP final ;
- comparer A contre B sur retrieval BioCLIP, Indoor, Outdoor, fine-grained,
  cultivars, OOD, calibration et coût d'entraînement.

DINOv3 n'entre dans la recette finale que si B améliore nettement A **sans
réduire la compatibilité avec l'espace BioCLIP**. Dans le cas contraire, Iris
10 reste BioCLIP-only.

Chaque autre composant doit également être retiré une fois dans une ablation.
Une sophistication qui ne gagne rien n'entre pas dans la recette finale.

## 15. `iris_feedback` devient une donnée stratégique

Les photos utilisateurs confirmées ont une valeur encore plus grande avec
Iris 10 : elles peuvent affiner **l'espace lui-même**, pas seulement réentraîner
une tête de classification.

Elles servent à :

- rapprocher les vraies photos Indoor de leur espèce ;
- identifier les erreurs confiantes ;
- apprendre les conditions de prise de vue réelles ;
- construire des prototypes visuels ;
- mesurer la fréquence réelle des espèces ;
- plus tard, découvrir les cultivars les plus présents.

Le consentement et les règles de vie privée du § 13.3 de `docs/09` restent
inchangés.

## 16. Open-set / OOD : un problème séparé

Un embedding proche d'une espèce ne veut pas automatiquement dire que la photo
appartient à une espèce connue. Iris 10 doit mesurer explicitement le refus.

Signaux candidats :

- distance au meilleur prototype ;
- écart entre premier et deuxième candidats ;
- cohérence espèce / genre / famille ;
- accord Indoor / Outdoor ;
- énergie ou tête OOD dédiée ;
- ensemble de non-plantes et plantes hors catalogue.

La règle finale doit être calibrée sur un jeu OOD séparé. Une photo inconnue
qui reçoit un candidat à forte similarité reste une erreur si elle n'est pas
réellement connue.

Pl@ntNet demeure le dernier recours réseau après la décision locale.

## 17. Quantification et export

On ne décrète pas INT8 par principe. Pour un modèle d'embedding, une petite
déformation géométrique peut dégrader fortement la recherche de similarité.

Ordre de travail :

1. FP32 de référence ;
2. FP16 comme première cible mobile ;
3. INT8 post-training uniquement pour mesurer la casse ;
4. QAT si INT8 est nécessaire pour la taille/latence ;
5. comparer non seulement le top-1 mais aussi cosine teacher/student,
   retrieval, calibration et OOD.

La meilleure quantification est celle qui conserve la géométrie utile de
l'espace, pas celle qui produit le plus petit fichier.

## 18. Benchmark obligatoire sur appareils réels

Chaque student candidat doit être mesuré au minimum sur :

- iPhone récent avec Core ML / Neural Engine si la chaîne le permet ;
- Android récent avec l'accélérateur réellement disponible ;
- fallback CPU représentatif ;
- TFLite/Core ML selon la cible finale d'Auxine.

Mesures :

- latence première photo et photos suivantes ;
- RAM pic ;
- taille du modèle ;
- énergie approximative / chauffe sur série d'identifications ;
- top-1 / top-3 espèce ;
- précision genre/famille ;
- retrieval@k ;
- **cosine / alignment avec BioCLIP** ;
- calibration ;
- OOD AUROC/FPR selon le protocole retenu ;
- performances Indoor et Outdoor séparées ;
- erreurs confiantes.

Aucun backbone n'est choisi uniquement sur ImageNet.

## 19. Les expériences qui peuvent tuer l'idée

Avant de construire toute l'architecture produit, cinq portes :

### Porte A — la distillation BioCLIP fonctionne-t-elle ?

Un student mobile doit conserver assez de l'espace BioCLIP pour battre ou au
moins égaler Iris 9 sur nos usages clés, tout en restant compatible avec les
références BioCLIP pré-calculées.

### Porte B — DINOv3 apporte-t-il quelque chose ?

Comparer strictement :

- Iris Core A : BioCLIP 2.5 sans DINO ;
- Iris Core B : même modèle + branche DINO auxiliaire séparée.

B n'est retenu que s'il améliore les détails fins sans dégrader le retrieval et
l'alignement BioCLIP. Sinon DINOv3 sort de la recette.

### Porte C — embedding contre softmax

Comparer, sur exactement le même jeu :

- Iris 9 softmax ;
- Iris Core + embeddings d'espèces ;
- Iris Core + prototypes visuels ;
- combinaison texte + prototypes.

### Porte D — Indoor / Outdoor collaborent-ils vraiment ?

La séparation doit améliorer le produit sans créer une explosion de faux
arbitrages. Mesurer accord, contradiction et gain net.

### Porte E — coût mobile

Si Iris Core apporte peu de gain pour 4x la latence, la taille ou la RAM, la
bonne réponse peut rester un classifieur spécialisé. Le numéro 10 n'impose pas
une architecture.

## 20. Ordre de mise en œuvre

1. ✅ **Finir et mesurer Iris Indoor** comme baseline Indoor — livré le 19
   septembre, 336 classes, mesuré au § 13.3 de `docs/09`.
2. ✅ **Finir Iris 9** comme baseline classifier large/étroit — livré le 21
   septembre, 1 569 classes, deux masques de lieu tirés de la même tête
   (§ 14.6 de `docs/09`).
3. ✅ Construire le jeu de benchmark Iris 10 : Indoor, Outdoor, multi-photo,
   OOD — `tools/plant_model/benchmark.py`, § 20 bis.
4. Cacher les embeddings **BioCLIP 2.5** sur le corpus et générer les références
   textuelles/taxonomiques — outil écrit (`tools/plant_model/bioclip.py`), la
   passe reste à lancer sur la machine.
5. Implémenter une première distillation **BioCLIP-only** vers FastViT et
   MobileNetV4 Hybrid.
6. Choisir le student au benchmark réel.
7. Établir la baseline A complète : BioCLIP + supervision taxonomique +
   contrastive + hard negatives.
8. Cacher les features DINOv3 nécessaires et tester la **branche auxiliaire B**.
9. Garder DINOv3 seulement si l'ablation démontre un gain net sans détériorer
   l'espace BioCLIP.
10. Tester embeddings d'espèces et prototypes.
11. Ajouter la fusion multi-photo.
12. Ajouter OOD/calibration.
13. Tester la branche locale fine-grained si DINO ou les features intermédiaires
   montrent un intérêt.
14. Quantifier/exporter seulement après stabilisation de la géométrie.
15. Brancher Indoor / Outdoor dans l'app.
16. Reprendre `iris_feedback` pour un premier fine-tune de domaine réel.

## 20 bis. Le banc figé, et ce qu'il faut avant la première distillation

Les étapes 3 et 4 ont leur outil : `tools/plant_model/benchmark.py` assemble
le jeu de mesure, `tools/plant_model/bioclip.py` passe le teacher sur le
corpus. Les étapes 4 à 6 ne demandent toujours aucune architecture nouvelle,
seulement du calcul et une discipline. Cette section dit laquelle.

### Le banc

Le script ne produit pas d'images, il produit un **manifeste** — un CSV de
colonnes `tranche,chemin,verite,groupe,captive` — à partir du `splits.csv` du
jeu de données. Cinq tranches : `indoor`, `outdoor`, `multi`, `ood_plante`,
`ood_autre`. Tirage semé à 20260919, deux mille images par tranche au plus.

L'échantillonnage se fait **par groupe**, pas par image : une observation à
plusieurs photos part entière dans une tranche ou n'y va pas. Sans cela, la
tranche `multi` mesurerait la fusion sur des images que les autres tranches
ont déjà servies, et le chiffre serait flatté.

Deux règles vont avec, et elles valent plus que le script :

1. **le manifeste ne se régénère pas pour arranger un modèle.** Il est
   reproductible à la graine près tant que le jeu d'images ne bouge pas ;
   quand le jeu grandit, on le régénère une fois, et les chiffres d'avant
   sont marqués comme appartenant au manifeste précédent. C'est exactement ce
   qui a manqué jusqu'ici — le § 5 de `docs/10` rappelle que les chiffres de
   deux `model.json` ne se comparent pas, parce que chaque entraînement a
   produit son propre test ;
2. **`ood_autre` reste vide tant que les dossiers hors sujet le sont.** La
   tranche existe dans le format pour qu'on n'ait pas à le changer ; un banc
   qui prétendrait mesurer le refus sans une seule photo de chat mentirait
   plus qu'il n'aiderait. C'est la moitié manquante de la porte « autre »
   (§ 12.7 de `docs/09`).

### Étape 4 — cacher les embeddings BioCLIP

Le cache est ce qui rend les étapes suivantes abordables : le teacher tourne
**une fois** sur le corpus, et aucune boucle de distillation ne le rappelle
ensuite.

Le coût disque se calcule et il est petit. BioCLIP 2.5 (`vith14`) rend 1 024
dimensions ; en `float16`, c'est 2 Ko par image :

| corpus | embeddings | disque |
|---|---|---|
| images d'entraînement | 794 000 | ~1,6 Go |
| toutes les images gardées | 991 926 | ~2,0 Go |

Le coût en calcul, lui, ne se devine pas : un ViT-H/14 n'a pas le débit d'un
MobileNet. **On le mesure sur cent images avant de lancer le corpus**, et on
multiplie ; une passe qui dépasserait la nuit se découpe par dossier, le
cache étant incrémental par construction.

**Mesuré le 21 septembre 2026** sur la RTX 2070 Super, `float16`, lot 32 :
**36,6 images/s**, soit **7,5 h** pour les 991 926 images et 1,89 Gio de
vecteurs. Le lot de 32 réserve 3,74 Gio de VRAM sur les 8.

Vingt-trois fois plus lent que les 831 images/s de `train.py` à 320 px — et
c'est l'argument du cache plutôt qu'une objection contre lui : le teacher
passe **une fois**, l'entraînement repasse trente époques. Sept heures et
demie pour BioCLIP contre huit pour une passe d'Iris 9, et plus jamais
ensuite. Une nuit suffit, donc les parts ne servent pas ici ; elles restent
pour le jour où le corpus grandira.

Deux précautions, parce qu'un cache faux est pire qu'un cache absent :

- **la clé porte le prétraitement**, pas seulement le chemin de l'image. Un
  redimensionnement changé, une normalisation changée, et le cache devient
  silencieusement incohérent avec ce qu'il prétend décrire ;
- **les références textuelles et taxonomiques se calculent dans la même
  passe** (§ 7), avec la même version du teacher. Des références d'une
  version et des images d'une autre ne vivent pas dans le même espace.

#### Ce que l'outil en fait

`tools/plant_model/bioclip.py`, quatre commandes dans l'ordre où elles se
lancent : `mesure`, `cache`, `textes`, `centroides`.

Les deux précautions ci-dessus n'y sont pas des consignes mais des refus.
Le dossier de cache porte un `signature.json` — teacher, dimension, taille
d'entrée, normalisation — et une passe d'une autre signature **refuse
d'écrire dedans** au lieu d'y mêler deux espaces ; `textes` et `centroides`
relisent cette signature plutôt que d'en refaire une, si bien qu'on ne peut
pas produire de références d'une autre version du teacher que celle qui a vu
les images.

Trois choses que l'écriture a tranchées, et qui n'étaient pas dans le
cadrage :

- **les vecteurs sont rangés normalisés.** La perte cosinus de l'étape 5 et
  le k-plus-proches-voisins de l'étape 6 ne lisent que la direction ; garder
  la norme coûterait la moitié de la précision utile du `float16` sans rien
  servir ;
- **le découpage se fait en parts entrelacées, pas par dossier.**
  `splits.csv` est rangé par espèce : deux parts contiguës donneraient à
  l'une les classes riches et à l'autre les pauvres, donc deux durées
  différentes là où on les veut égales. C'est la leçon des parts de collecte
  (§ 3 de `docs/10`), et elle s'applique telle quelle ;
- **le tableau s'écrit avant l'index.** L'index est la vérité du cache ; une
  coupure entre les deux perd un fragment à recalculer, jamais un vecteur
  qu'on croirait présent.

Le cache est incrémental : relancer la même ligne reprend où elle s'est
arrêtée. Contrairement à la reprise de `train.py` (§ 13.6 de `docs/09`), il
n'y a ici rien à perdre à reprendre — un vecteur ne dépend d'aucun état
d'optimiseur, seulement de l'image et de la signature.

**Un venv séparé de celui d'entraînement.** `tensorflow[and-cuda]` et
PyTorch embarquent chacun leurs CUDA et cuDNN ; les mettre ensemble rejoue
en plus gros l'accident de `tensorflow-cpu` installé à côté de la version
GPU (§ 2 de `docs/10`), et c'est la version lente qui gagne, sans un
message. Voir `requirements-bioclip.txt`.

**Et les 8 Go de VRAM sont la même contrainte dure qu'à 320 px.** Un
ViT-H/14 en `float16` tient ses poids dans 1,3 Go, le reste est de
l'activation et croît avec le lot : `--batch 32` est le défaut. `mesure`
affiche ce que la carte a réellement réservé, et c'est ce chiffre-là qu'on
lit avant de lancer la nuit — pas celui qu'on espère.

### Étape 5 — la première distillation, et une seule variable

Le student apprend à reproduire l'embedding du teacher : un projecteur de sa
dimension de sortie vers 1 024, une perte cosinus sur le cache. Rien d'autre
à ce stade — pas de supervision taxonomique, pas de contrastive, pas de
hard negatives. Ce sont les étapes 7 et au-delà ; les mêler ici rendrait la
porte A illisible.

FastViT contre MobileNetV4 Hybrid se compare **à recette identique** : même
cache, même calendrier de taux, mêmes augmentations, même nombre d'époques.
La leçon du § 13.6 de `docs/09` s'applique mot pour mot — un run, deux
variables, et on ne sait plus ce qu'on a mesuré. Là-bas, le lot était passé
de 128 à 32 sans décision, et trois points d'écart sont restés inexplicables
une nuit entière.

### Étape 6 — choisir le student, et sur quoi

Iris Core ne rend pas un softmax : « top-1 » y signifie **la référence la
plus proche dans l'espace d'embedding**, donc la mesure au banc suppose les
références d'espèces de l'étape 4. Tant qu'elles ne sont pas prêtes, le
substitut honnête est un k-plus-proches-voisins sur les embeddings du
teacher : il dit si le student a gardé la géométrie, sans rien prétendre sur
le produit.

L'ordre est donc : cache, distillation, k-NN pour éliminer un student, puis
banc complet pour trancher entre les survivants. La porte E — le coût mobile
— se lit au même moment, sur un téléphone réel et pas sur un ordinateur de
bureau (§ 18).

## 21. Ce qui est décidé et ce qui reste ouvert

### Décidé

- **Iris 10 = Iris Core**, changement de paradigme ;
- encodeur botanique embarqué plutôt qu'un softmax monolithique ;
- **BioCLIP 2.5 définit l'espace canonique d'Iris Core** ;
- la sortie principale reste compatible avec les références BioCLIP ;
- DINOv3 ne partage pas directement la géométrie de l'embedding principal ;
- student mobile distillé ;
- embedding calculé une seule fois ;
- Indoor et Outdoor comme vues/références partageant ce cerveau ;
- taxonomie et prototypes dans le même espace ;
- multi-photo fusionné au niveau des embeddings ;
- Pl@ntNet reste le repli final.

### Ouvert jusqu'aux mesures

- **DINOv3 : présent seulement si l'ablation BioCLIP-only vs BioCLIP+DINO gagne** ;
- FastViT vs MobileNetV4 Hybrid vs autre student ;
- projecteur exact et dimension de sortie, sous contrainte de compatibilité
  avec les références BioCLIP ;
- poids de la supervision espèce/taxonomie/contrastive ;
- utilité d'une branche locale ;
- représentation exacte des espèces (texte, centroid, prototypes ou mélange) ;
- règle d'arbitrage Indoor/Outdoor ;
- méthode OOD finale ;
- FP16 vs INT8/QAT ;
- taille finale acceptable du modèle.

## 22. Références de départ

Ces références servent à reproduire l'état de la recherche qui a motivé la
décision ; elles devront être réévaluées au moment de lancer Iris 10 :

- BioCLIP 2.5 : `https://huggingface.co/imageomics/bioclip-2.5-vith14`
- BioCLIP 2 : `https://arxiv.org/abs/2505.23883`
- DINOv3 : `https://ai.meta.com/blog/dinov3-self-supervised-vision-model/`
- FastViT : `https://machinelearning.apple.com/research/fastvit`
- MobileNetV4 : `https://arxiv.org/abs/2404.10518`
- distillation d'un foundation model vers edge — CustomKD :
  `https://openaccess.thecvf.com/content/CVPR2025/html/Lee_CustomKD_Customizing_Large_Vision_Foundation_for_Edge_Model_Improvement_via_CVPR_2025_paper.html`

Le but de ces références n'est pas de figer le stack pour plusieurs années.
**Iris Core est un contrat d'architecture ; les teachers et le student peuvent
évoluer tant que les benchmarks restent reproductibles et que l'espace
canonique choisi reste explicitement versionné.**