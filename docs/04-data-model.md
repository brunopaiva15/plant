# D. Data model

Le schéma est conçu pour Postgres (Supabase) et **répliqué localement** dans SQLite (drift). Les IDs sont des UUID v4 générés côté client pour permettre l'offline-first. Toutes les tables ont `created_at`, `updated_at` ; les entités utilisateur ont `deleted_at` (suppression logique).

## Tables Phase 1 (implémentées localement)
```
users            id, email, display_name, locale, created_at
gardens          id, owner_id, name, created_at, updated_at, deleted_at
garden_members   garden_id, user_id, role(owner|member|viewer), created_at        [P3]
locations        id, garden_id, parent_id?, name, icon, photo_id?, light?, orientation?, sort_order, created_at, updated_at, deleted_at
species          id, scientific_name, common_name?, care_defaults(json), source?, created_at
plants           id, garden_id, name, species_id?, species_name?, location_id?, primary_photo_id?,
                 status(active|archived), health(healthy|watch|sick), is_favorite,
                 acquired_at?, source?, price?, pot_size?, notes?, parent_plant_id?,
                 archived_at?, archive_reason?, created_at, updated_at, deleted_at
plant_photos     id, plant_id, user_id?, file_path, thumb_path, width, height, taken_at, created_at, deleted_at
action_types     id, garden_id?, key(watering|fertilizing|…|custom), label?, emoji, is_builtin, sort_order
plant_actions    id, plant_id, user_id?, type_key, occurred_at, notes?, metadata(json), photo_id?, created_at, deleted_at
care_schedules   id, plant_id, type_key, strategy(fixed|seasonal|manual), interval_days, seasonal_rules(json)?,
                 next_due_at?, last_completed_at?, enabled, created_at, updated_at
tags             id, garden_id, name, color?, created_at
plant_tags       plant_id, tag_id
measurements     id, plant_id, action_id?, kind(height|width|leaves|pot), value, unit, measured_at
sync_outbox      id, entity, entity_id, op(upsert|delete), payload(json), created_at, attempts
```

## Tables Phase 2 (schéma v2)
```
inventory_items  id, garden_id, category_key(fertilizer|soil|substrate|pot|tool|treatment|seed|accessory),
                 name, quantity, unit, low_threshold?, location_id?, notes?, photo_path?, thumb_path?,
                 created_at, updated_at, deleted_at
```
Les catégories intégrées de l'inventaire sont un enum localisé ; les groupes personnalisés vivent dans `inventory_groups` (schéma v9).
Les QR codes encodent `auxine://plant/<id>` et `auxine://item/<id>`, sans table dédiée.

## Phase 3 (schémas v3–v4)
```
locations.is_outdoor           météo (balcon, jardin, serre)
plant_actions.user_id          auteur (compte) ; plant_photos.user_id idem
profiles (cache)               id, display_name, email — membres du jardin
garden_members (cache)         garden_id, user_id, role
```
Le schéma Postgres complet avec RLS, triggers et fonctions (`invite_member`, `garden_members_with_names`) est dans `supabase/schema.sql`.

## Parité HortusFox (schémas v5–v10)
```
tasks             id, garden_id, plant_id?, title, description?, due_at?, all_day,
                  recurrence_value?, recurrence_unit?, done, done_at?, …
plant_attributes  id, garden_id, plant_id, label, datatype(bool|int|double|string|datetime), value?, position
attribute_schemas id, garden_id, label, datatype, position, active   — modèles réutilisables
plant_attachments id, garden_id, plant_id, label, file_path, mime?, size?, user_id?
location_logs     id, garden_id, location_id, user_id?, content      — journal d'un emplacement
inventory_groups  id, garden_id, label, emoji, position              — v9
inventory_tags    item_id, tag_id                                    — v9, réutilise `tags`
event_categories  id, garden_id, label, emoji, color_key?, position  — v10
calendar_entries  id, garden_id, plant_id?, category_id?, title, notes?,
                  start_at, end_at?, all_day, reminder_minutes?      — v10
```
Colonnes ajoutées au passage : `plants.number` et `gardens.plant_counter` (numéros `#42` jamais réattribués, v8),
`locations.notes/photo_path/thumb_path` (v8), `plant_photos.label/remote_url` (v7), `inventory_items.group_id` (v9).

## Champs de plante et précision de santé (schéma v11)
```
plants.health_issue    overwatering|underwatering|pests|disease|rootRot|transplantShock|deficiency|sunburn|frost, ou null
plants.light           LightNeed (shade … fullSun), ou null        — prime sur locations.light dans les conseils
plants.humidity        HumidityNeed (low|average|high), ou null
plants.lifespan        annual|biennial|perennial, ou null
plants.hardiness       hardy|tender, ou null
plants.cutting_month   1–12, ou null
```

Tous facultatifs : `null` veut dire « non renseigné », jamais une valeur par défaut. `health` garde ses trois
états ; `health_issue` ne s'écrit que si l'état n'est pas `healthy` (le dépôt l'efface sinon). Une valeur
inconnue en base, venue d'une version plus récente, se lit comme `null` plutôt que de faire échouer la lecture.
Les noms d'enum sont stockés tels quels, en camelCase, et contrôlés par `check` côté Postgres.

Les tris de la liste qui regardent un dernier soin (`PlantSort.lastWatered`…) lisent `MAX(occurred_at)` dans
`plant_actions` par type, dans la même requête que les cartes ; aucune colonne dénormalisée.

## Caractérisation des engrais (schéma v12)
```
inventory_items.fertilizer_form     liquid|granules|sticks|solublePowder|foliar|other, ou null
inventory_items.fertilizer_origin   mineral|organic|organomineral, ou null
inventory_items.nitrogen            N en %, ou null                — de même phosphorus (P) et potassium (K)
```
Ces cinq colonnes ne valent que pour `category_key = 'fertilizer'` : le dépôt
les efface dès qu'un article passe dans une autre catégorie, et un pourcentage
y est ramené entre 0 et 100. Toutes facultatives, donc nulles sur les articles
d'avant la v12. Les autres catégories d'inventaire ne changent pas.

Le calendrier mêle deux sources : les événements stockés dans `calendar_entries` et les échéances de soin
projetées à la volée par `CalendarProjector` à partir des routines et de l'historique.

## Le relevé de la maison (schéma v13)
```
room_scans     id, garden_id, location_id?, name, captured_at, north_offset_deg?,
               file_path, floor_area_m2, section_label?, structure_id? (v14),
               created_at, updated_at, deleted_at?
room_markers   id, scan_id, kind (windowOrientation | heater | plant), x, z,
               window_index?, orientation?, plant_id?, created_at, updated_at
```
Un relevé est une ligne et un fichier : le JSON du `CapturedRoom` de RoomPlan
vit dans `Documents/rooms/<id>.json`, la base n'en garde que le chemin
relatif. Rien ne part dans l'outbox — le plan de chez soi ne se synchronise
pas ; il part dans l'export ZIP, section « Relevés de la maison », avec le
JSON de chaque pièce sous `rooms/`. `north_offset_deg` est le cap du nord dans
le repère du relevé, mesuré à la boussole ; nul quand elle n'a rien donné de
stable. `section_label` est le type de pièce que RoomPlan reconnaît sur
iOS 17 (`kitchen`, `bathroom`…), nul sinon.

`room_markers` porte ce que la main ajoute au relevé, séparé de ce que le
capteur a vu : refaire un relevé ne perd pas les repères.
`windowOrientation` est l'orientation confirmée d'une fenêtre, indexée par
son rang dans le JSON ; `heater` un radiateur posé du doigt, collé au mur
le plus proche ; `plant` la place d'une plante du jardin (`plant_id`), une
par plante et par relevé ; `windowSheer` et `windowDrawn` ce qui habille
une fenêtre (`window_index`), un au plus par fenêtre. `structure_id` (v14) réunit les pièces d'un même
relevé d'appartement, dont les fichiers vivent dans un dossier
(`rooms/<id>/<n>.json`) et partagent le repère.

## Tables prévues (schéma réservé, UI en P4)
```
notifications, devices, plant_links(nfc), plant_relationships
```

## Relations
```
gardens 1─n locations (self-ref parent_id)
gardens 1─n plants n─1 locations
plants  1─n plant_photos, plant_actions, care_schedules, plant_measurements
plants  n─n tags (plant_tags)
plants  self-ref parent_plant_id (boutures)
species 1─n plants
```

## Règles métier
- Une **action** de type `t` marque la routine `t` de la plante comme complétée à `occurred_at` et recalcule `next_due_at` (voir `CareEngine`).
- Archiver une plante désactive ses routines (pas de rappel), sans supprimer l'historique.
- `primary_photo_id` = première photo si nul ; l'utilisateur peut en choisir une autre.
- Les types d'action personnalisés sont des lignes `action_types` avec `is_builtin = false`.

## `plant_actions.metadata`
Champ libre en JSON, à côté de `notes`. Trois usages aujourd'hui :

| Clé | Écrite par | Contenu |
|---|---|---|
| `kind` `value` `unit` `quantity` | mesures et soins chiffrés | ce que la ligne du journal affiche en second |
| `_prev_next_due` `_prev_last_completed` | `DriftActionRepository.log` | l'échéance d'avant, pour l'Undo |
| `diagnosis` | « Ma plante a un problème » | le compte rendu entier de l'analyse |

Le diagnostic est enregistré comme une note : `notes` en garde le résumé et
les trois premières pistes, lisibles telles quelles à l'export. `metadata.diagnosis`
garde tout le reste — c'est ce qui permet de **rouvrir** l'analyse depuis le
journal des mois plus tard au lieu d'en relire l'aperçu
(`DiagnosisRecord`, `lib/domain/diagnosis/diagnosis_record.dart`) :

```json
{"version": 1, "summary": "…", "urgent": true,
 "symptoms": "ce que l'utilisateur avait décrit",
 "observations": {"soil": "soggy", "roots": "soft", "light": "direct", "bugs": "none"},
 "answers": [{"question": "Depuis quand ?", "answer": "Huit jours"}],
 "causes": [{"title": "…", "problemId": "002", "likelihood": "likely",
             "explanation": "…", "actions": ["…"]}],
 "photos": [{"file": "…jpg", "thumb": "…_thumb.jpg"}]}
```

`answers` garde les questions que le service avait posées quand rien ne
tranchait, et ce qu'on lui a répondu (docs/09, § 9) : elles ont pesé sur les
pistes, le compte rendu ne se relit pas sans elles.

Les `problemId` sont conservés plutôt que les seuls noms : à la réouverture,
les pistes sont renommées par la base des problèmes, dans la langue de
l'application du moment. La relecture est tolérante — une analyse gardée avant
un changement de format se lit pour ce qu'il en reste plutôt que de disparaître.

Les fichiers cités par `photos` restent sur l'appareil qui a fait l'analyse :
seules les photos de `plant_photos` partent en synchronisation et en
sauvegarde, et une photo de feuille malade n'a rien à faire dans le suivi de
croissance. Ailleurs, le compte rendu se lit sans elles.

## Conseils de la communauté (Supabase seul, hors base locale)
Les trois seules tables distantes qui ne portent pas de `garden_id` : un
conseil est rattaché à une **espèce**, pas à un jardin, et se lit depuis
n'importe quel compte. Rien n'en est copié dans SQLite — ce n'est pas l'état
du jardin, c'est ce que d'autres ont écrit, et cela se relit à chaque
ouverture de la fiche.

```
species_tips         id, species_id (clé du catalogue, « hoya-kerrii »),
                     species_name, user_id, body (10–300 signes), votes,
                     reports, hidden_at?, created_at, updated_at
                     unique (species_id, user_id) — une personne, un conseil par espèce
species_tip_votes    tip_id, user_id            — une voix par personne et par conseil
species_tip_reports  tip_id, user_id            — un signalement par personne et par conseil
```

- **Lire** : `species_tips_for(species_id)`, ouverte à la clé anonyme — la
  fiche d'entretien s'ouvre sans être connecté, et ce qu'elle montre là est
  déjà public. **Écrire** demande un compte.
- **Écrire ne passe jamais par la table** : `publish_species_tip`,
  `withdraw_species_tip`, `vote_species_tip` et `report_species_tip` sont
  `security definer`, et les tables de votes et de signalements n'ont aucune
  politique — rien d'autre ne les touche. Les bornes de longueur sont tenues
  des deux côtés (`lib/domain/community/species_tip.dart` et une contrainte
  `check`) : un client modifié ne fait pas passer un roman.
- **Signalement** : au troisième, `hidden_at` est posé et le conseil cesse de
  paraître aux autres. Son auteur le reçoit encore, avec la mention qui le
  dit — sans quoi il le croirait toujours en ligne. Rien n'est supprimé : la
  vérification se fait sur la table, et `hidden_at` se remet à `null` à la
  main quand le conseil était bon. Le réécrire ne l'efface pas : les
  signalements ne s'effacent pas d'un coup de clavier.
- Le nom affiché vient de `profiles` : publier, c'est publier sous son nom, et
  la feuille d'écriture le dit avant qu'on écrive.

### Modération
```
moderators           user_id, created_at
```
Une table, et non une colonne sur `profiles` : la politique « profiles write »
laisse chacun écrire sa propre ligne, et un drapeau posé là se donnerait à
soi-même en une requête. `moderators` n'a **aucune politique** — rien ne la lit
ni ne l'écrit hors de l'éditeur SQL et des fonctions `security definer`.
Nommer un modérateur est une ligne dans l'éditeur SQL du projet, l'uuid se
lisant dans *Authentication › Users* :

```sql
insert into moderators (user_id) values ('<uuid du compte>');
```

- `is_moderator()` répond au client ; l'application s'en sert pour montrer ou
  non l'entrée *Profil › Modération*, mais l'autorité est dans les fonctions.
- `reported_species_tips()` rend les conseils signalés au moins une fois, les
  plus signalés d'abord. Pour quelqu'un d'autre : zéro ligne, pas une erreur.
- `moderate_species_tip(id, hidden)` masque ou rétablit. Rétablir **efface les
  signalements** — sans quoi le conseil repasserait le seuil à la première
  humeur, et le même dossier reviendrait indéfiniment.
- `remove_species_tip(id)` retire pour de bon, ce que `withdraw_species_tip`
  ne permet qu'à l'auteur.

## Sécurité (Supabase, P2)
- RLS : `garden_members` détermine l'accès à tout ce qui porte `garden_id` (via `plants.garden_id` pour les tables filles).
- Storage : bucket privé `plant-photos/{garden_id}/{plant_id}/{photo_id}.jpg`, URLs signées, validation MIME + taille.
- Aucune confiance au client : triggers `updated_at`, contraintes de rôle en base.
- Les conseils de la communauté sont l'exception au premier point : ils ne
  portent pas de `garden_id`, et ce sont leurs fonctions `security definer`
  qui tiennent les règles (ci-dessus).

## Catalogue d'espèces (hors base locale)
Deux étages, plus la recherche en ligne :

| Étage | Où | Volume | Rôle |
|---|---|---|---|
| Trié à la main | `lib/data/species/species_catalog.dart` | 1 187 espèces avec catégorie | Parcours par thème, fiches d'entretien précises |
| Étendu | `assets/species/catalog.tsv` | ~40 000 espèces | Recherche hors ligne, quatre langues |
| En ligne | API GBIF | ~450 000 espèces | Le reste, paginé |

L'actif étendu est un TSV chargé à la demande dans un isolat, jamais au
démarrage : `nom · famille · fr · en · de · it · autres noms`. Les « autres
noms » ne s'affichent pas, ils rendent la recherche tolérante (« Edelweiß »,
« stella alpina »). La recherche compare des chaînes normalisées sans accents
ni casse (`core/utils/search_text.dart`).

Les quatre colonnes de langue sont creuses : sur les 36 342 espèces livrées,
5 283 ont un nom français, 32 123 un nom anglais, 7 639 un nom allemand,
1 414 un nom italien. Une liste n'affiche donc que le nom de la langue lue,
ou le nom scientifique — jamais celui d'une autre langue : « Japanische
Faserbanane » en tête d'une liste française se lit comme une erreur, et
masquer les 31 000 espèces sans nom français viderait l'encyclopédie.
La recherche, elle, continue de comparer tous les noms de toutes les
langues : « Faserbanane » ouvre la fiche de *Musa basjoo*. C'est
`vernacularName(langue)` — le nom de la langue lue, ou `null` — et
`commonName(langue)`, qui retombe alors sur le nom scientifique.

Provenance et régénération : `tool/README.md`. Wikidata (CC0) pour les noms,
GBIF (CC BY) pour les familles.

Une entrée triée à la main l'emporte sur l'actif étendu, y compris sur ses
noms : une entrée écrite sans nom courant prend le nom scientifique dans les
quatre langues et couvre alors ce que l'actif, lui, savait dire. Les paliers
1 000 et 1 200 avaient été générés ainsi — famille et catégorie, aucun nom —
et masquaient 296 noms déjà livrés ; ils rejouaient en plus 72 espèces déjà
curatées, si bien que la même plante s'appelait « Rose du désert » dans le
sélecteur et « Adenium obesum » dans l'encyclopédie. Les noms manquants ont
été repris de l'actif, les doublons retirés, et
`test/data/species_catalog_test.dart` tient les deux règles.

Soixante-trois classes du modèle n'étaient dans ni l'un ni l'autre — le genre
*Euphorbia* en entier, le chêne-liège, le robinier —, et leur fiche s'ouvrait
sans famille ni nom. Cinquante-neuf sont écrites à la main dans
`species_catalog_iris_only.dart` ; les quatre dernières passent par la table
des noms acceptés (`core/utils/scientific_name.dart`), l'app les connaissant
déjà sous leur autre nom.

Les deux étages hors ligne se parcourent aussi pour eux-mêmes, dans
l'encyclopédie : l'étage trié à la main par catégorie, l'étage étendu dès
qu'on cherche, et chaque espèce ouvre sa fiche d'entretien sans qu'il faille
posséder la plante. Cette fiche-là n'est pas complétée par l'IA — la question
reste réservée aux plantes du jardin, où la réponse sert à faire quelque
chose ; ici le catalogue répond, ou dit qu'il ne connaît que le genre.

### Ce qu'une fiche d'entretien déduit (`domain/care/care_profile.dart`)
Cent soixante-sept profils sont écrits à la main ; il aurait fallu les
reprendre un à un pour leur ajouter un mélange, un type d'engrais, un rapport
au calcium. La plupart de ces champs se déduisent de ce que la fiche dit
déjà, et une espèce qui sait mieux le déclare — le champ déclaré l'emporte
toujours sur la déduction.

| Déduit | Règle | Déclaré par |
|---|---|---|
| `soilMix` (le mélange, i18n) | le `SoilKind` : un terreau drainant se prépare toujours pareil | — |
| `inWater` | `aquatic` → oui ; ce qui tient le gel → non ; ce qui bouture dans l'eau → bouture seulement | `waterCulture` |
| `inPon` | terre de bruyère et sans-substrat → non ; ce qui vit en pot (`potGrown`) → oui | `ponCulture` |
| `fertilizerKind` | pas d'engrais → aucun ; nécrose apicale → tomates ; sinon le `SoilKind` (cactées, orchidées, terre de bruyère, équilibré) | `fertilizer` |
| `calciumNeed` | terre de bruyère → à éviter ; nécrose apicale → nécessaire ; cactées → bienvenu ; sinon rien à en dire | `calcium` |
| `benefitsFromGreenhouse` | tout ce qui ne tient pas le gel (`frostHardy`) | — |
| `bloom` | rien : la floraison ne se déduit pas | `bloom` |

Quatre-vingt-huit profils déclarent au moins un de ces champs : les agrumes
(engrais agrumes, pas de calcaire, hiver frais), les marantacées (eau de
pluie), le pothos et le spathiphyllum (culture dans l'eau), la tillandsie
(sans substrat, mais pas dans l'eau), les tomates (potasse et calcium), les
orchidées (nuits fraîches), le cactus de Noël (jours courts). L'IA de
complétion ne se prononce sur aucun d'eux : ils restent ceux du catalogue
(`domain/care/care_completion.dart`).

## Base des problèmes (hors base locale)
`assets/problems/catalog.txt` : 200 troubles, ravageurs et maladies couvrant
l'intérieur, les fleurs, les arbustes, le potager et les fruitiers. Un fichier
à séparateurs `|`, écrit à la main, chargé à la demande dans un isolat
(`ProblemCatalogLoader`) et lu par `ProblemCatalog`.

| Champ | Contenu |
|---|---|
| `id` | Trois chiffres, `001` à `200`. C'est lui qui circule. |
| `type` | `ABIOTIQUE` (trouble), `RAVAGEUR`, `MALADIE`, `AFFECTION` |
| `nom_fr` `nom_en` `nom_it` `nom_de` | Le nom affiché, une colonne par langue de l'app |
| `portee` | `GENERAL` (toutes les plantes vasculaires), `LARGE` (beaucoup d'hôtes, exemples), `CIBLE` (hôtes principaux) |
| `taxons_hotes_scientifiques` | Hôtes séparés par `;`, à tous les rangs : espèce, genre, famille, ou `Tracheophyta` |
| `synonymes_recherche` | Facultatif. Les autres noms sous lesquels on cherche l'entrée, séparés par `;`, toutes langues mêlées. 171 entrées sur 200 en portent. |

La recherche de l'encyclopédie (`PlantProblem.matches`) porte sur le numéro,
les quatre noms, les synonymes et les hôtes. Chaque mot tapé doit ouvrir un
mot de l'entrée : le pluriel ne compte pas, l'ordre des mots non plus, le
trait d'union et l'apostrophe séparent comme l'espace, et une lettre isolée
est un article qu'on laisse tomber. Ouvrir un mot, et pas s'y trouver
n'importe où, sinon « rosa » sortirait le manque d'eau, qui parle
d'ar-rosa-ge ; à partir de cinq lettres le mot vaut quand même au milieu d'un
autre, parce que l'allemand soude les siens et que « Milben » doit sortir les
« Spinnmilben ».

Les quatre langues répondent ensemble, pas seulement celle qui est lue :
« spider mites » trouve les tétranyques depuis une application en français.
Un synonyme est un autre **nom** de l'entrée — un nom courant, un nom
scientifique qui circule, une abréviation —, jamais un symptôme, un
traitement ni un nom de plante : les hôtes s'en chargent. Un synonyme déjà
trouvable par le titre n'entre pas, et un test le vérifie.

La fiche du problème les donne, sous « Autres noms », entre l'étendue et les
hôtes : c'est « araignée rouge » qu'on a en tête, pas « tétranyque », et une
fiche de référence doit le dire. Ils s'y lisent toutes langues mêlées, comme
la base les range, et ne remplacent jamais le titre : celui-là garde un seul
nom par langue, pour que deux analyses de la même chose se lisent pareil.

Elle sert de vocabulaire commun au diagnostic. `candidatesFor` réduit la base
aux pistes qui peuvent concerner une plante — l'universel, plus ce qui vise son
espèce, son genre ou sa famille, plus ce que sa fiche d'entretien signale —,
soit trente à soixante-cinq entrées. Cette liste part avec la demande ; le
service rend un numéro, l'application n'accepte que ceux qu'elle a soumis et
affiche son propre nom. Deux analyses de la même chose se lisent donc pareil,
dans la langue de l'utilisateur.

La fiche de soin s'en sert à froid : `specificTo` garde les entrées qui
nomment l'espèce, son genre ou sa famille, retire les troubles universels et
ce que « À surveiller » dit déjà, et affiche le reste replié au-delà de six
lignes. Sur les 297 espèces du catalogue trié à la main, la médiane est d'une
entrée et la moitié n'en a aucune — la section disparaît alors, plutôt que de
meubler.

L'encyclopédie (`features/encyclopedia/`, sous *Profil*) la lit enfin en
entier : les deux cents entrées rangées par famille, cherchables par nom, par
numéro et par hôte, et une page par entrée — sa famille, son étendue, ses
hôtes avec leur nom courant quand un catalogue le connaît, et les plantes du
jardin qui y figurent. Cette dernière section n'apparaît pas sur un problème
`GENERAL` : y aligner toute la collection ne dirait rien. Rien n'est ajouté au
passage, ni texte ni appel à l'IA — l'écran montre l'actif, et une entrée qui
manque manque dans la base.

Chaque entrée peut avoir sa propre illustration, dans
`assets/problems/icons/<id>.webp`. Elles arrivent par lots et la base en
compte deux cents : celles qui n'en ont pas encore retombent sur le symbole de
leur famille, ce qui est l'état normal de la plupart des entrées et non un cas
d'erreur. `illustrated_problems.dart`, écrit par le même outil que les images,
dit lesquelles existent sans interroger le disque.

Elles servent aux cartes de diagnostic, à cinquante-deux points, aux lignes de
l'encyclopédie, à quarante, et en tête de la page d'un problème, à cent douze —
seul objet de la page, et le seul endroit où le dessin se lit vraiment ; il y
a droit à la respiration que les vignettes n'ont pas. En dessous de quarante
elles se valent toutes — une plante en pot reste une plante en pot —, d'où les
lignes sans vignette et le regroupement par famille sur la fiche de soin.

Les neuf problèmes de santé d'une fiche (`HealthIssue`) y puisent aussi :
chacun désigne l'entrée de la base qui dit la même chose (« Manque d'eau » →
`001`) et reprend son dessin ; « Ravageurs » et « Maladie » ne désignent rien
de précis et portent le symbole de leur famille, qui est exactement ce
qu'elles nomment. `HealthIssueIcon` les pose à trente-deux points, seule
entorse à la règle ci-dessus : leur nom est écrit juste à côté, et il y en a
neuf, pas deux cents. `test/features/problem_kind_icon_test.dart` vérifie que
chaque entrée désignée existe et relève bien de la famille annoncée.

Les lignes `#` en tête du fichier portent ses réserves : les hôtes sont des
exemples, un genre ne rend pas toutes ses espèces sensibles, et la
vérification GBIF porte sur les noms de plantes, pas sur les relations
hôte-problème.

## Base des phénomènes naturels (hors base locale)
`assets/problems/natural.txt` : ce que la plante fait normalement et qu'on
prend pour un problème. Deux familles s'y mêlent — ce que la plante fait et
qui inquiète (guttation, nectar extrafloral, vieille feuille du bas qui
jaunit, panachure, racines aériennes, latex à la coupe, repos hivernal), et
ce qu'on prend pour un ravageur ou une maladie (sores d'une fougère pour des
cochenilles, laine des aréoles pour des cochenilles farineuses, liégeage d'un
cactus pour une pourriture, nodosités des légumineuses pour des galles de
nématodes, lichens de l'écorce pour un mal de l'arbre). La seconde est celle
qui coûte le plus cher : l'erreur y fait traiter une plante qui n'a rien.
Même fichier à séparateurs `|`, lu par le même chargeur, dans le même isolat,
et porté par le même `ProblemCatalog` (`naturalCauses`, `natural(id)`,
`naturalFor`).

| Champ | Contenu |
|---|---|
| `id` | `N` et deux chiffres, `N01` à `N32`. Aucune confusion possible avec les trois chiffres d'un problème, ni dans la réponse du service, ni dans un compte rendu gardé. |
| `nom_fr` `nom_en` `nom_it` `nom_de` | Le nom affiché, une colonne par langue de l'app |
| `portee` | `GENERAL`, `LARGE`, `CIBLE`, comme la base des problèmes |
| `taxons_hotes_scientifiques` | Les plantes qui le montrent, aux mêmes rangs : espèce, genre, famille, ou `Tracheophyta` |

Les deux bases restent séparées parce que les choses le sont : un phénomène
naturel n'est pas un problème de plus, il est ce qui n'en est pas un. Il n'a
donc pas de famille, et la fiche de soin ne le lit pas — elle parle de ce qui
se soigne. Le diagnostic s'en sert : `naturalFor` en tire la liste soumise
avec les problèmes, le service rend `N01`, l'application affiche son nom et
sait que la piste n'est pas un souci (docs/09, § 9). L'encyclopédie le montre :
dans le rayon des problèmes, sous son propre titre après les quatre familles,
avec sa puce, son compte et sa recherche (`NaturalCause.matches`, la même règle
que `PlantProblem.matches`, portée par `searchMatches`), et chaque phénomène a
sa page (`/encyclopedia/natural/N01`) — un nom, une étendue, des hôtes, les
plantes du jardin qui le montrent, et la phrase qui fait l'entrée : rien à
soigner. La carte d'une piste naturelle du diagnostic y mène, comme celle d'un
problème mène à la sienne. Le vocabulaire définit « Phénomène normal » à côté
des quatre familles qu'il n'est pas.

Le symbole d'argile de ces pistes, `assets/problems/clay_naturel.webp`, est la
cinquième pièce du studio des quatre familles (`tool/build_category_logos.py`,
rendu par le même script, recadré à la même échelle par
`tool/pack_category_logos.py --seulement naturel`, qui ne réécrit pas les
quatre autres et prévient si le nouveau venu déborde de leur boîte) : une
feuille saine, la goutte claire suspendue à sa pointe, deux perles de nectar
sur la nervure. Ni lésion, ni dépôt, ni insecte — c'est l'absence de tout cela
qui fait le symbole. La goutte est pâle sans être blanche : un blanc mat sur
une feuille, ici, se lirait cochenille farineuse.

Chaque phénomène a ensuite son propre dessin, dans
`assets/problems/natural/<id>.webp`, comme chaque problème a le sien :
trente-deux scènes rendues par `tool/build_natural_icons.py` dans le même
studio, réduites par `tool/pack_natural_icons.py`, qui écrit la liste des
identifiants illustrés dans `illustrated_natural.dart`. Un phénomène que la
base ne nomme pas — le service en trouve hors liste — retombe sur le symbole
commun, ce qui est exactement ce qu'on sait de lui.

N'entre ici que ce dont il n'y a **rien à soigner**. Ce que la base des
problèmes traite déjà n'y a pas sa place, même quand la chose passe pour
anodine : la croûte blanche des sels est l'entrée `023`, l'œdème physiologique
la `038`, et deux réponses contraires sur la même photo valent moins qu'une
seule. `test/data/problem_catalog_test.dart` le vérifie — aucun nom, dans
aucune des quatre langues, ne peut être celui d'un problème ni l'un de ses
synonymes.

La liste soumise à une analyse tient en neuf à quatorze entrées selon
l'espèce, soit une ligne de plus dans la demande.

L'actif peut manquer sans emporter l'autre : le diagnostic repart alors sans
phénomènes naturels, comme avant qu'ils existent.
