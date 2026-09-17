# 14 — Iris Indoor / Outdoor : un cerveau, deux spécialistes

> **Piste post-Iris 9, posée le 17 septembre 2026.** Ce document ne promet pas
> une « Iris 10 » et ne remplace pas le cadrage du § 13 de
> `09-plant-recognition.md`. Il conserve une architecture à tester une fois
> Iris 9 entraînée : partager une représentation large, puis spécialiser les
> sorties selon le domaine visuel plutôt que faire grossir indéfiniment un
> unique softmax.

## Pourquoi cette piste existe

Iris 8 a donné deux résultats qui vont ensemble :

- apprendre sur beaucoup d'espèces et beaucoup d'images améliore la
  représentation ;
- exposer beaucoup de classes simultanément fait au contraire baisser la
  précision sur les espèces qui comptent.

C'est le principe déjà retenu pour Iris 9 : **entraîner large, exposer
étroit**.

Iris 9.1 ajoute une observation produit : une liste courte de plantes
réellement cultivées à l'intérieur est un domaine utile en soi. Le masque
`masque_9_1.txt` en est la première matérialisation. À l'inverse, arbres,
arbustes, vivaces, plantes sauvages, potager et plantes de massif constituent
un autre domaine visuel, avec d'autres arrière-plans, distances de prise de
vue et ports de plante.

La suite naturelle à mesurer n'est donc pas forcément « une version avec
encore plus de classes », mais **deux spécialistes qui partagent le même
cerveau**.

## Architecture candidate

```text
                         Iris Core
             backbone entraîné largement
                              │
                 embedding calculé une fois
                              │
              ┌───────────────┴───────────────┐
              │                               │
        Iris Indoor                     Iris Outdoor
    tête étroite, plantes          tête étroite, plantes
       cultivées dedans              cultivées/dehors
              │                               │
              └───────────────┬───────────────┘
                              │
                     arbitrage calibré
                              │
                     réponse au genre
                              │
                         Pl@ntNet
```

Le point important est **un seul backbone**. L'image ne devrait pas être
encodée deux fois par deux modèles MobileNet séparés si les deux spécialistes
peuvent consommer le même embedding. On garde ainsi le bénéfice de
l'entraînement large sans payer deux fois le calcul principal sur le
téléphone.

Les deux têtes peuvent être deux exports du même entraînement, ou deux petites
têtes réellement distinctes apprises sur le même backbone. Le choix doit être
mesuré : commencer par l'option la plus simple, deux masques/exports, puis ne
entraîner deux têtes différentes que si elle apporte un gain réel.

## Rôle des deux spécialistes

### Iris Indoor

Priorité aux plantes possédées et photographiées en intérieur : plantes en
pot, tropicales, succulentes, orchidées et autres espèces du catalogue dont
le domaine réel ressemble aux photos `captive`, `(potted)` et aux futurs
retours `iris_feedback`.

**Iris 9.1 est le prototype naturel de cette branche.** Elle permet de
mesurer dès maintenant ce qu'apporte une sortie beaucoup plus étroite sur ce
domaine avant de construire une architecture à deux têtes.

### Iris Outdoor

Priorité aux plantes vues dehors : arbres, arbustes, vivaces, annuelles,
potager, plantes sauvages et de massif. Sa liste n'a aucune raison d'avoir la
même taille que celle d'Indoor ; elle doit être choisie par usage et mesure,
pas par symétrie.

Une espèce peut appartenir aux deux ensembles. Un *Ficus*, un agrume ou une
succulente peut être cultivé dedans ou dehors : les têtes sont des **domaines
de reconnaissance**, pas deux taxonomies disjointes.

## Comment elles collaborent

Le contexte de l'application peut donner un **a priori**, jamais imposer la
réponse :

- identification depuis un jardin/emplacement intérieur → Indoor prioritaire ;
- identification depuis un emplacement extérieur → Outdoor prioritaire ;
- contexte inconnu → les deux têtes sont évaluées ;
- contradiction ou confiance insuffisante → on conserve plusieurs candidats,
  puis réponse au genre et repli Pl@ntNet selon la politique de cascade.

Le contexte ne doit jamais suffire à masquer une espèce plausible de l'autre
tête. Une plante déplacée sur un balcon ne change pas de taxon.

## Le piège principal : comparer deux confiances

`0,80` dans Indoor et `0,80` dans Outdoor ne sont comparables que si les deux
têtes sont **calibrées sur une base commune**. Avec des nombres de classes et
des distributions différents, comparer directement deux softmax serait une
fausse précision.

Avant toute mise en production il faut donc mesurer, sur un jeu test commun :

1. la calibration de chaque tête ;
2. le taux d'erreurs confiantes de chacune ;
3. les cas où les deux têtes sont d'accord ;
4. les cas où elles se contredisent ;
5. la précision de l'arbitrage final, pas seulement celle de chaque tête
   isolément.

Une calibration de température ou une fonction d'arbitrage apprise n'est à
ajouter que si la mesure montre qu'elle est nécessaire.

## Ce que le système ne doit pas faire

Une cascade naïve du type « essayer Indoor ; s'il dépasse 0,70, ne jamais
regarder Outdoor » est insuffisante. Les premiers retours terrain ont déjà
montré qu'Iris peut produire une **erreur confiante** ; un seuil ne voit pas
ce cas.

De même, faire tourner deux modèles complets indépendants en série serait la
version la plus coûteuse de l'idée : poids doublés, backbone calculé deux
fois et deux modèles à maintenir. Ce n'est pas la cible tant qu'un backbone
commun est possible.

## Porte de décision

Cette architecture ne devient un chantier qu'après trois mesures :

1. **Iris 9.1 contre une tête plus large**, sur un vrai jeu de photos
   d'intérieur, pour vérifier que la spécialisation apporte effectivement un
   gain produit ;
2. **Iris 9 entraînée large**, pour disposer du backbone qui doit être
   partagé ;
3. **un jeu test Outdoor dédié**, séparé du test Indoor, afin que le gain de
   l'un ne soit pas obtenu en sacrifiant silencieusement l'autre.

Si deux têtes issues du même backbone battent de façon mesurable une tête
unique à coût embarqué raisonnable, cette architecture devient la candidate
naturelle d'une génération suivant Iris 9. Son numéro n'est volontairement
pas fixé ici.
