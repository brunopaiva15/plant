# Sourcer les fiches d'entretien

La rusticité, la lumière, le substrat, l'eau, les problèmes fréquents,
la multiplication, la floraison, l'humidité de l'air, l'arrosage, l'engrais
et le rempotage sont les champs que les fiches ont confrontés à une source.

Ce document découpe le travail qui reste. Il se lit avec le `CareProfile` et
`care_profiles.dart` sous les yeux.

Pour savoir **quels profils créer en priorité** avant la première version
publique, voir [`15-care-profile-coverage.md`](15-care-profile-coverage.md).
Cette roadmap sépare la couverture produit de la qualité des données : ici on
définit comment sourcer un champ ; là-bas, quels taxons méritent ce travail en
premier.

## Ce que la RHS donne déjà

La page d'une espèce à la RHS porte, en plus de la rusticité :

- **Position** — plein soleil, mi-ombre, ombre ;
- **Soil Types** — calcaire, argile, limon, sable ;
- **Moisture** — bien drainé, frais, humide ;
- **pH** — acide, neutre, alcalin ;
- **Pests** et **Diseases** — les ennemis nommés de la plante ;
- **Propagation** — semis, bouture, division, rejet, marcottage ;
- **Flowering** — la saison et les mois.

Six champs de la fiche, donc, lisibles d'un seul accès. Le pipeline local
(sitemap + lecture du HTML) les extrait comme il extrait la rusticité.

## Ce qu'aucune source ne donne

- **Les intervalles en jours** : « tous les 7 jours » n'est écrit nulle part.
  C'est une sortie de règle — le substrat, la lumière, le pot, la saison.
- **L'humidité de l'air** : la RHS n'en parle pas. Elle se déduit de
  l'habitat d'origine (phase 6) : une inférence documentée, jamais une cote.
- **Les conseils** (`tipKeys`) : éditoriaux.

## Phase 0 — La provenance par champ (faite)

`CareProfile.sourcing` remplace `source` : une table `CareField → CareSource`.
La fiche affiche « Vérifié d'après RHS : Température » et se tait sur le
reste. Seul ce qui y est écrit est vérifié.

## Phase 1 — Lumière (faite)

Source : Position RHS (plein soleil / mi-ombre / ombre). L'idéal va dans
`light` ; si la valeur actuelle est plus basse, elle devient
`lightTolerance` — le plancher que le chercheur de plantes et les signes
foliaires comparent à un emplacement.

Mapping Position → idéal :

- plein soleil seul → `fullSun` ;
- plein soleil et autre chose → `someSun` ;
- mi-ombre seule → `brightIndirect` ;
- mi-ombre et ombre → `indirect` ;
- ombre seule → `shade`.

Les genres et familles s'ancrent sur une espèce représentative, comme la
rusticité. Les catégories d'usage ne sont pas un taxon : elles restent
sans source. Les fiches RHS sans Position renseignée restent des estimations.

Pipeline : `tools/rhs_care/`. 348 profils portent `CareField.light` ;
les 46 restants n'ont pas de Position sur la fiche RHS.

## Phase 2 — Substrat (faite)

Sources : Soil Types, Moisture, pH. Deux champs en sortent : `soil` et
`water`. Le pH de jardin reste fondu dans ces deux-là — un champ propre
dupliquerait `SoilKind.acidic`.

Mapping :

- acide seul → `acidic` + `strict` ;
- acide sans alcalin, déjà terre de bruyère → on confirme ;
- « Acid or Neutral » n'est pas une terre de bruyère : la tomate y pousse ;
- bien drainé seul → `draining`, ou `cactus` si l'espèce l'est déjà ;
- orchid / none : le sol de jardin ne dit pas le mélange, on n'y touche pas ;
- une eau déjà sensible ou stricte n'est pas relâchée.

Les genres et familles s'ancrent sur une espèce représentative. Les
catégories d'usage restent sans source. 223 profils portent
`CareField.soil`, 305 portent `CareField.water`.

## Phase 3 — Problèmes fréquents (faite)

Sources : Pests et Diseases. Les ravageurs et maladies que la RHS nomme
remplacent la liste générique (`aphids`, `powderyMildew` collés à tout le
monde). Les troubles de culture — trop d'eau, moucherons du terreau,
pointes sèches — restent : la fiche de jardin ne les dit pas.

« Generally pest-free » est une cote : la liste d'ennemis s'en va.
Orchid / succulentes d'appartement gardent leurs troubles, plus ce que
la RHS a nommé. Une espèce n'hérite pas des ennemis d'une autre
(tirucalli ≠ poinsettia).

324 profils portent `CareField.issues` ; 105 pages RHS n'ont pas de bloc
Pests/Diseases.

## Phase 4 — Multiplication (faite)

Source : Propagation. `water` n'est pas une méthode : c'est le milieu
d'enracinement déjà écrit dans certaines fiches. On le garde s'il y est ;
`rootingMedium` s'en déduit. Le greffage n'a pas d'entrée Auxine : une
page qui ne dit que ça n'est pas sourcée.

Mapping :

- seed / sowing / spores → `seed` ;
- stem / softwood / semi-hardwood / hardwood / leaf-bud / root cuttings →
  `stemCutting` ;
- leaf cuttings → `leafCutting` ;
- division → `division` ;
- offsets / suckers / keikis / plantlets → `offsets` ;
- layering → `layering` ;
- tubers / corms / bulbs → `tuber`.

Les méthodes que la RHS nomme remplacent la liste d'auteur. L'ordre
conseillé (la première de la fiche) se conserve pour ce qui reste.
Une famille n'est pas un taxon : on ne lui colle pas le keiki d'un
phalaenopsis. Un genre n'hérite pas d'une page d'un autre genre
(Dracaena ≠ sansevieria). Une espèce n'hérite pas d'une autre
(tirucalli ≠ poinsettia).

209 profils portent `CareField.propagation` ; 176 familles restent sans
source ; 38 pages RHS n'ont pas de bloc Propagation.

## Phase 5 — Floraison (faite)

Source : le tableau Colour & Scent, colonne Flower. Quatre saisons
(printemps, été, automne, hiver) deviennent une plage de mois :

- printemps → mars–mai ;
- été → juin–août ;
- automne → septembre–novembre ;
- hiver → décembre–février ;
- les quatre saisons → janvier–décembre.

Les saisons doivent former un arc continu ; printemps et automne sans
l'été ne tiennent pas dans `MonthWindow`, on ne source pas. Les
déclencheurs (nuits fraîches, jours courts) et `indoors` restent ceux
de la fiche : le jardin RHS ne les dit pas.

Une famille n'est pas un taxon. Un genre n'hérite pas d'une page d'un
autre genre. Une espèce n'hérite pas d'une autre.

194 profils portent `CareField.bloom` ; 176 familles restent sans
source ; 56 pages RHS n'ont pas de fleurs dans Colour & Scent.

## Phase 6 — Humidité de l'air (faite)

Pas de cote RHS : l'hygrométrie se déduit de l'habitat d'origine (GBIF
descriptions + Wikipedia). Forêt humide → `high` ; maquis / bassin
méditerranéen → `low` ; savane, forêt sèche, prairie → `average`. Les
listes d'aires WGSRPD et les notices collées à un autre taxon ne
comptent pas. Une plage chiffrée déjà écrite n'est pas touchée.

Une famille n'est pas un taxon. Un genre n'hérite pas d'une page d'un
autre genre. Une espèce n'hérite pas d'une autre.

38 profils portent `CareField.humidity` (`CareSource.habitat`) ; 176
familles restent sans source ; les pages sans habitat nommé restent
des estimations.

## Phase 7 — Arrosage (faite)

Pas de cote RHS : on écrit d'abord `dryDown` d'après la stratégie hydrique
du profil (aquatique / semi-aquatique → `alwaysMoist` ; substrat cactus →
`fullyDry` ; sinon lecture de l'intervalle déjà porté), puis on **dérive**
les jours de cette règle en gardant le rapport saison active / repos.
`CareField.watering` porte `CareSource.derived`. Le drainage du sol n'est
pas une fréquence — un basilic en terre drainante reste `alwaysMoist`.
Sans substrat (tillandsie) : pas de règle, pas sourcé.

Une famille n'est pas un taxon.

252 profils portent `CareField.watering` (`CareSource.derived`) ; 176
familles et la tillandsie (pas de substrat) restent sans source.

## Phase 8 — Engrais et rempotage (faite)

Pas de cote RHS sur la fréquence : la page donne **Time to Maturity**
(1 an, 1–2 ans, 2–5, 5–10, 10–20, 20–50, plus de 50). On en dérive les
jours d'engrais et les mois de rempotage. `CareField.feeding` et
`CareField.repotting` portent `CareSource.derived`. La fenêtre et le
type d'engrais déjà écrits restent.

Verrous : `noFertilizer` / `feedsOnInsects` → pas d'engrais ; substrat
cactus → au plus tous les 60 jours ; orchidée → 14–30 jours ; nécrose
apicale → 14 jours ; plante en pot qui ne tient pas le gel → au plus
30 jours (la maturité de jardin n'est pas une famine) ; annuelle
(maturité 1 ou 1–2 ans, sans rempotage) → pas de rempotage ; pot étroit
/ cactus : on n'accélère pas un rythme déjà plus lent.

Une famille n'est pas un taxon. Un genre n'hérite pas d'une page d'un
autre genre.

212 profils portent `CareField.feeding` et 192 `CareField.repotting`
(`CareSource.derived`) ; 217 restent sans règle (familles, pages sans
maturité, genres mal représentés).

## Phase 9 — Les profils de famille (faite)

Une famille n'est pas un taxon. Chaque champ restant s'ancre sur
l'espèce représentative déjà choisie pour la lumière (`light.json`), et
s'écrit sur le profil de famille — jamais comme donnée d'espèce.

Verrous : le keiki d'un phalaenopsis n'est pas la multiplication des
Orchidaceae ; la floraison d'hiver d'un cactus de Noël ne remplace pas
une fenêtre déjà printanière ; l'air saturé d'une forêt n'humidifie pas
un substrat cactus ; un basilic annuel n'efface pas le rempotage d'une
Lamiaceae rustique. La fenêtre chiffrée d'humidité, les déclencheurs de
floraison, le type d'engrais restent.

143 familles sur 176 portent au moins un champ de plus (130
multiplication, 12 floraison, 18 humidité, 143 arrosage, 134 engrais,
127 rempotage). 33 n'ont pas de représentant RHS.

## Ordre

0 → 1 → 2 → 3 → 4 → 5 (les six champs de la RHS, un lot tous les six, par
paquets de 45 profils) → 6 → 7 → 8 → 9.
