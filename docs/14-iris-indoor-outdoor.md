# 14 — Iris 10 / Iris Core : un encodeur botanique, plusieurs spécialistes

> **Direction retenue le 17 septembre 2026.** Iris 10 ne sera pas une simple
> génération supplémentaire du classifieur actuel. La cible est un **encodeur
> visuel botanique embarqué**, distillé depuis de grands modèles de fondation,
> qui produit un embedding réutilisable par plusieurs spécialistes : Indoor,
> Outdoor, taxonomie, prototypes de cultivars et détection d'inconnus.
>
> Iris 9.1 reste la première baseline Indoor. Iris 9 reste le dernier gros
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

### Iris 9.1 = première Iris Indoor

Iris 9.1 est déjà dessinée comme une spécialiste Indoor :

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
battre Iris 9.1 sur Indoor, Iris 9 sur le généraliste, ou apporter une capacité
nouvelle mesurable à coût embarqué acceptable.

## 3. Architecture cible

```text
                         ENTRAÎNEMENT HORS APP

              BioCLIP 2.5                    DINOv3
        teacher biologique              teacher visuel dense
     taxonomie / espèces / vivant      textures / formes / détails
               │                              │
               └─────────── distillation ─────┘
                              │
                              ▼
                       ┌─────────────┐
                       │ IRIS CORE 10│
                       │ mobile      │
                       │ encoder     │
                       └──────┬──────┘
                              │
                       embedding commun
                              │
          ┌───────────┬───────┼────────┬──────────────┐
          │           │       │        │              │
          ▼           ▼       ▼        ▼              ▼
       Indoor      Outdoor   Genre   Famille      Prototypes
                                                   cultivars
          │           │       │        │              │
          └───────────┴───────┴────────┴──────────────┘
                              │
                       arbitrage calibré
                              │
                       inconnu / OOD ?
                         │          │
                        non        oui
                         │          │
                      résultat   Pl@ntNet
```

Le téléphone n'embarque **ni BioCLIP 2.5 ni DINOv3**. Ils servent de teachers
pendant l'entraînement. L'app n'embarque que le student Iris Core et les
petites données nécessaires aux spécialistes.

## 4. Teachers : BioCLIP 2.5 d'abord, DINOv3 en complément

### BioCLIP 2.5 = teacher principal

La priorité est donnée à BioCLIP 2.5 car son espace est construit pour le
vivant et la taxonomie, ce qui correspond directement au problème d'Iris.
L'objectif de la distillation n'est pas de copier un softmax, mais de faire
entrer le student mobile dans **un espace sémantique biologique utile**.

Ce teacher doit surtout apprendre au student :

- proximité entre représentations de la même espèce ;
- structure genre / famille ;
- séparation fine entre taxons voisins ;
- représentation utilisable par recherche de similarité et prototypes.

Référence de travail au moment de cette décision :
`imageomics/bioclip-2.5-vith14`. La licence et les conditions exactes de
redistribution/distillation doivent être **revalidées avant l'entraînement
final**, même si le modèle est actuellement publié avec une licence permissive.

### DINOv3 = teacher secondaire

DINOv3 complète BioCLIP pour les détails visuels et les représentations
locales/denses : nervures, textures, panachures, forme d'un bord de feuille,
structure d'une fleur, port de la plante.

On ne demande pas au student de reproduire l'intégralité des deux modèles. Il
faut distiller les signaux qui apportent quelque chose au domaine botanique,
avec des poids réglés par ablation.

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
les mêmes données et les mêmes dimensions d'embedding**.

## 6. Iris Core produit un embedding, pas un nom

Le contrat principal d'Iris Core devient :

```text
photo -> vecteur normalisé de D dimensions
```

D sera choisi expérimentalement, probablement entre 256 et 1024 selon le
compromis précision / mémoire / vitesse.

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

Indoor et Outdoor ne sont pas deux modèles complets. Ce sont deux spécialistes
qui exploitent **le même embedding calculé une seule fois**.

```text
                         Iris Core
                             │
                         embedding
                             │
               ┌─────────────┴─────────────┐
               │                           │
          Iris Indoor                 Iris Outdoor
      références / prior            références / prior
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

Iris 9.1 fournit la première liste et le premier jeu de test Indoor. Outdoor
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
Iris 10 doit tester un second signal local : quelques tokens/patches ou une
projection compacte de features intermédiaires.

Objectif :

```text
global -> port général / famille / genre
local  -> nervure / marge / texture / panachure / fleur
```

Cette branche locale n'entre en production que si elle améliore réellement les
confusions fines pour un coût acceptable.

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

La première recette Iris 10 devra mélanger plusieurs objectifs, avec ablations
obligatoires pour savoir ce qui sert réellement :

1. **distillation BioCLIP 2.5** sur embedding global ;
2. **distillation DINOv3** sur représentation globale et/ou features locales ;
3. **supervision espèce** sur les labels solides d'Auxine ;
4. **supervision hiérarchique** genre / famille ;
5. **supervised contrastive / metric learning** pour resserrer une espèce et
   séparer les espèces voisines ;
6. **hard negatives taxonomiques** : espèces du même genre/famille plus
   souvent opposées dans les batches ;
7. données de domaine `captive`, `(potted)` et `iris_feedback` ;
8. augmentations de contexte issues de segmentation ;
9. exemples OOD / non-plantes pour apprendre le refus.

Chaque composant doit être retiré une fois dans une ablation. Une sophistication
qui ne gagne rien n'entre pas dans la recette finale.

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
- calibration ;
- OOD AUROC/FPR selon le protocole retenu ;
- performances Indoor et Outdoor séparées ;
- erreurs confiantes.

Aucun backbone n'est choisi uniquement sur ImageNet.

## 19. Les expériences qui peuvent tuer l'idée

Avant de construire toute l'architecture produit, quatre portes :

### Porte A — la distillation fonctionne-t-elle ?

Un student mobile doit conserver assez de l'espace BioCLIP pour battre ou au
moins égaler Iris 9 sur nos usages clés.

### Porte B — embedding contre softmax

Comparer, sur exactement le même jeu :

- Iris 9 softmax ;
- Iris Core + embeddings d'espèces ;
- Iris Core + prototypes visuels ;
- combinaison texte + prototypes.

### Porte C — Indoor / Outdoor collaborent-ils vraiment ?

La séparation doit améliorer le produit sans créer une explosion de faux
arbitrages. Mesurer accord, contradiction et gain net.

### Porte D — coût mobile

Si Iris Core apporte peu de gain pour 4x la latence, la taille ou la RAM, la
bonne réponse peut rester un classifieur spécialisé. Le numéro 10 n'impose pas
une architecture.

## 20. Ordre de mise en œuvre

1. **Finir et mesurer Iris 9.1** comme baseline Indoor.
2. **Finir Iris 9** comme baseline classifier large/étroit.
3. Construire le jeu de benchmark Iris 10 : Indoor, Outdoor, multi-photo, OOD.
4. Cacher les embeddings BioCLIP 2.5 et DINOv3 sur le corpus.
5. Implémenter une première distillation simple vers FastViT et MobileNetV4
   Hybrid.
6. Choisir le student au benchmark réel.
7. Ajouter supervision taxonomique + contrastive + hard negatives.
8. Tester embeddings d'espèces et prototypes.
9. Ajouter la fusion multi-photo.
10. Ajouter OOD/calibration.
11. Tester branche locale fine-grained.
12. Quantifier/exporter seulement après stabilisation de la géométrie.
13. Brancher Indoor / Outdoor dans l'app.
14. Reprendre `iris_feedback` pour un premier fine-tune de domaine réel.

## 21. Ce qui est décidé et ce qui reste ouvert

### Décidé

- **Iris 10 = Iris Core**, changement de paradigme ;
- encodeur botanique embarqué plutôt qu'un softmax monolithique ;
- **BioCLIP 2.5 comme teacher principal de départ** ;
- **DINOv3 comme teacher complémentaire** à tester ;
- student mobile distillé ;
- embedding calculé une seule fois ;
- Indoor et Outdoor comme spécialistes partageant ce cerveau ;
- taxonomie et prototypes dans le même espace ;
- multi-photo fusionné au niveau des embeddings ;
- Pl@ntNet reste le repli final.

### Ouvert jusqu'aux mesures

- FastViT vs MobileNetV4 Hybrid vs autre student ;
- dimension exacte de l'embedding ;
- poids BioCLIP/DINO/supervision dans la loss ;
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
évoluer tant que les benchmarks restent reproductibles.**
