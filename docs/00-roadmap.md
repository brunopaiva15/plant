# Auxine — Roadmap par phases

> Le produit s'appelle **Auxine** (`AppConfig.appName`) ; le code garde son nom de travail, « Flora ». Aucune dépendance profonde au nom.

Le projet est découpé en 4 phases produit + une phase 0 de fondations. Chaque phase livre une application **utilisable et sans bouton mort** : une fonction visible fonctionne, ou elle n'est pas visible.

## Phase 0 — Fondations (livrée avec la Phase 1)
- Architecture Flutter propre (feature-first, domain / data / presentation)
- Design system complet (tokens, thème clair / sombre, composants)
- Navigation native (transitions Cupertino sur iOS, Material 3 sur Android)
- Base locale SQLite (drift) modélisée sur le schéma Postgres cible
- Couche i18n (fr, en, de, it) sans texte codé en dur
- Haptics, animations, `reduced motion`, Dynamic Type

## Phase 1 — MVP « Prendre soin » ✅ (implémentée dans ce dépôt)
| Fonction | État |
|---|---|
| Onboarding interactif (3 écrans max, ajoute la première plante) | ✅ |
| Compte local (sans inscription) + abstraction `AuthRepository` prête pour Apple / Google / e-mail | ✅ (local) |
| Plantes : création en < 20 s (photo → nom → emplacement), fiche, édition | ✅ |
| Photos : caméra / galerie, compression, miniatures, cache local | ✅ |
| Emplacements hiérarchiques (Maison → Salon…), fiche emplacement | ✅ |
| Actions rapides (arrosage, engrais, rempotage, taille, nettoyage, traitement, note, photo, mesure, types personnalisés) | ✅ |
| Timeline / journal de vie par plante | ✅ |
| Planning d'entretien (fixe, saisonnier, manuel) + moteur de rappels testé | ✅ |
| Écran Aujourd'hui (à faire, en retard, à venir) avec action en 1 tap + Undo | ✅ |
| Notifications locales groupées, heure préférée, jours silencieux | ✅ |
| Recherche instantanée (nom, espèce, emplacement, tags, notes) | ✅ |
| Dark mode | ✅ |
| Favoris, tags (optionnels), archives (« Anciennes plantes ») + restauration | ✅ |
| Sélection multiple (long press) → arroser / déplacer / archiver | ✅ |

## Phase 2 — « Comprendre » ✅ (implémentée dans ce dépôt)
| Fonction | État |
|---|---|
| Mesures : saisie (hauteur, largeur, feuilles, pot) + cartes « 42 cm · +8 cm depuis juin » avec courbe minimale | ✅ |
| Inventaire : catégories, quantité + unité, [−] [+], seuil de stock bas, emplacement, notes | ✅ |
| Calendrier : agenda 30 jours (historique + échéances + occurrences projetées), vue mois avec points | ✅ |
| QR codes : sheet par plante, scanner (ouvre la fiche), planche d'étiquettes PDF (fiche + multi-sélection) | ✅ |
| Identification : interface `PlantIdentifier`, adaptateur Pl@ntNet (clé fournie par l'utilisateur dans Profil), suggestions à l'étape « nom » et action « Identifier » sur la fiche | ✅ |
| Croissance : comparaison avant / après avec curseur | ✅ |
| Base de connaissances GBIF (sans clé) : suggestions d'espèces à la saisie, fiche espèce (taxonomie, noms communs localisés, observations photographiées avec licence et auteur, lien GBIF) | ✅ |
| Synchronisation Supabase (adapter `RemoteDataSource`, outbox déjà en place) | → Phase 3 |
| Notification « stock bas » (regroupée au rappel quotidien) | → Phase 3 |

## Phase 3 — « Partager » (en cours)
| Fonction | État |
|---|---|
| Météo (Open-Meteo, sans clé) : emplacements « extérieur », ligne météo sur Aujourd'hui, conseil « pluie prévue : pas besoin d'arroser » avec report en un tap | ✅ |
| La pluie tombée vaut un arrosage : au-delà de 5 mm sur trois jours, les arrosages extérieurs du jour sont notés faits, avec Undo ; réglage dans Profil › Météo, actif par défaut | ✅ |
| Gel et chaleur : les trois prochains jours lus pour les plantes du dehors, comparés au minimum et à la plage idéale de chaque fiche ; carte du matin et ligne dans le rappel quotidien quand c'est pour la nuit ou le lendemain | ✅ |
| Stratégie d'arrosage « Météo » : l'intervalle saisonnier corrigé par la semaine du lieu (chaleur sèche ×0,7, pluie ×1,35, borné à 0,6–1,6), et la correction écrite sous le sélecteur | ✅ |
| Climat de la région (archives Open-Meteo sur trois ans, mises en cache) : zone de rusticité du lieu, et propositions de plantes d'extérieur classées par ce qu'elles font de l'hiver — l'IA reçoit le climat, jamais la ville | ✅ |
| Export complet (ZIP : `data.json` de toutes les tables + photos), partage natif | ✅ |
| Timelapse de croissance (photos en fondu, chronologiques) | ✅ |
| Stock bas regroupé dans le rappel quotidien | ✅ |
| Synchronisation multi-appareils : `SyncService` (push depuis l'outbox, pull delta, last-write-wins, photos), adaptateur Supabase, temps réel, coordinateur (démarrage / premier plan / après écriture) | ✅ code + tests ; activé par `--dart-define` (voir docs/08) |
| Comptes : Apple natif (iOS), et lui seul — pas d'e-mail ; compte local conservé sans connexion, et sur Android. Google OAuth codé mais pas livré (`AppConfig.googleSignInEnabled`, Android n'est pas prioritaire) | ✅ |
| Collaboration : membres, rôles owner / member / viewer, « · par Laura » dans la timeline, lecture seule pour viewer | ✅ |
| Partager son jardin : invitation par lien ou code à usage unique (QR compris), l'invité crée un compte s'il n'en a pas, « Mes jardins » pour basculer de l'un à l'autre, changement de rôle, retrait, départ d'un jardin | ✅ |
| Diagnostic « Ma plante a un problème » : photos + symptômes + observations (terre, racines, lumière, insectes) → pistes classées par vraisemblance avec gestes concrets (AI Services d'Infomaniak, modèle Mistral Small 4, clé de l'éditeur au build, sans plafond, jamais présenté comme certain) ; enregistrement dans le journal | ✅ AI Services d'Infomaniak (Mistral Small 4, clé au build, 30/jour) |
| Partage par lien public révocable, page publique servie par la fonction Edge `share` | ✅ |
| Widgets iOS / Android, Live Activity « session de soin » | ⏳ code natif (WidgetKit / AppWidget) |

## Parité HortusFox ✅ (livrée)
Le point de comparaison fonctionnel est [HortusFox](https://github.com/danielbrendel/hortusfox-web). Les 26 écarts relevés sont comblés.

| Fonction | État |
|---|---|
| Tâches libres : titre, description, échéance facultative, plante liée facultative, récurrence en heures / jours / semaines / mois / années, filtres, rappels, section « en retard » sur Aujourd'hui | ✅ |
| Attributs personnalisés (booléen, entier, décimal, texte, date), schémas réutilisables, copie au clonage, recherche et commandes groupées | ✅ |
| Pièces jointes par plante : ajout, libellé, ouverture, renommage, partage, suppression, synchronisation | ✅ |
| Galerie : titre de photo, photo principale, photo par URL externe, aperçu | ✅ |
| Photos : flow guidé (viseur intégré, calque de la dernière photo, titre et photo principale à la prise), section Croissance qui compte et relance, visionneuse à gestes (tirer pour fermer, double toucher), sélecteur visuel de l'avant / après, curseur du timelapse | ✅ |
| Partage de photos par lien : public ou non indexé, titre, description, expiration, révocation | ✅ |
| Notes en Markdown : gras, italique, listes, citations, liens cliquables (analyseur maison, sans dépendance) | ✅ |
| Emplacements : notes, journal, photo d'aperçu, actions groupées | ✅ |
| Actions groupées : arroser, fertiliser, rempoter, action personnalisée, attribut en masse | ✅ |
| Tri des plantes mémorisé, recherche par numéro `#123` | ✅ |
| Inventaire : groupes personnalisés, tags, QR par article (scan compris), planche d'étiquettes PDF, export CSV par sélection | ✅ |
| Calendrier : événements saisis (nom, début, fin, journée entière, rappel), catégories personnalisées | ✅ |
| Tableau de bord : statistiques, avertissements (malade, à surveiller, soin en retard), dernières plantes, journal global d'activité | ✅ |
| Archives : nom personnalisable, recherche, quatre tris, navigation par année, vue liste ou cartes, préférences mémorisées | ✅ |
| Prévisions météo sur cinq jours : min / max, précipitations, risque de pluie, vent, humidité | ✅ |
| Apple Maison (iOS) : température et humidité d'un capteur HomeKit, étape d'onboarding après la ville, ligne et conseils du jour pour les plantes d'intérieur, carte « Chez vous » dans la fiche d'entretien, mesure jointe au diagnostic | ✅ |
| Sauvegarde : export par sections, restauration avec aperçu, rapport d'import | ✅ |
| Champs de plante : lumière, humidité, cycle de vie, rusticité, mois de bouturage — des puces facultatives sous « Plus d'options », lus dans Informations ; la lumière de la plante prime sur celle de l'emplacement dans les conseils d'arrosage | ✅ |
| États de santé : les trois états restent (en forme, à surveiller, malade) et se précisent d'un problème parmi neuf (excès d'eau, manque d'eau, ravageurs, maladie, pourriture des racines, choc de rempotage, carence, brûlure, gel) ; le diagnostic le renseigne quand sa piste la plus vraisemblable est un ravageur ou une maladie | ✅ |
| Tris de la liste : nom, emplacement, prochain soin, santé, dernier arrosage / engrais / rempotage, ajout, modification, acquisition ; la carte écrit sous le nom ce que le tri regarde | ✅ |

## Au-delà de HortusFox
| Fonction | État |
|---|---|
| Fiche d'entretien par plante : arrosage saisonnier, lumière, humidité chiffrée, engrais (lequel, et le calcium), substrat (le mélange, l'eau, le pon), rempotage, sous serre, floraison, toxicité, bouturage, problèmes fréquents (230 espèces au catalogue) | ✅ |
| Eau d'arrosage : ce que l'espèce supporte du calcaire, et les sept eaux jugées une à une — robinet, pluie, carafe, osmosée, déminéralisée, condensat de climatiseur, adoucie — avec ce que chacune emporte avec elle | ✅ |
| Fiche d'entretien, second niveau : hygrométrie de l'espèce en pourcentage (20 à 90 %, pour qui règle une serre), lampe horticole équivalente au besoin de lumière, rapport au pot (à l'étroit ou à l'aise), saison de floraison et conditions à réunir, repos à feuillage disparu des bulbes et tubercules | ✅ |
| Sélecteur d'espèces : catalogue intégré hors ligne + recherche GBIF paginée | ✅ |
| Catalogue étendu : ~40 000 espèces avec leurs noms courants en fr/de/it/en, cherchables hors ligne et sans accents (Wikidata CC0 + familles GBIF) | ✅ |
| Encyclopédie (Profil) : les 200 problèmes de la base rangés par famille avec une page chacun (famille, étendue, hôtes, plantes du jardin concernées), les espèces du catalogue et leur fiche d'entretien, le vocabulaire des fiches défini terme à terme | ✅ |
| Onboarding animé en cinq écrans : objets 3D sur un halo de couleur, boucle qui ralentit jusqu'à se poser sur l'image nette, objets en orbite au rythme du doigt, titres levés ligne à ligne, texte mesuré pour ne jamais être coupé | ✅ |
| Application 100 % gratuite : plus aucun plafond ni fonction réservée | ✅ |
| Soutien facultatif au développeur (achat unique, App Store / Play), à la fin de l'onboarding et dans Profil | ✅ |
| Direction « argile » : papier crème, cartes et boutons modelés (ombre teintée, reflet et ombre intérieurs), grain du papier, titres à la main en Shantell Sans, héros terre cuite du matin — [docs/06-design-system.md](06-design-system.md) | ✅ |

## Phase 4 — « Étendre »
- NFC (architecture prévue : `PlantTagLink` table `plant_links` type `nfc` / `qr`)
- Apple Watch
- Automatisations, Shortcuts / Siri, Home Assistant, capteurs
- Import HortusFox (l'export complet JSON / CSV / ZIP est livré)
- Reconnaissance de plantes sur l'appareil, Pl@ntNet en repli : livrée, et le modèle embarqué en est à **Iris 8** (+6,7 points de top-1 sur Iris 7, au même seuil de repli, en entraînant large pour exposer étroit). Ce qu'il pèse, ce qu'il sait et ce qu'il vaut ne se recopient pas ici : la fiche est au [§ 0 de docs/09](09-plant-recognition.md#0-le-nom), recopiée de `assets/model/model.json`. Deux photos de la même plante valent quatorze points de top-1 — [docs/09-plant-recognition.md](09-plant-recognition.md). Ce qu'il reste à faire, et dans quel ordre : [§ 12](09-plant-recognition.md#12-ce-quil-reste-à-faire-dans-lordre) et [§ 13](09-plant-recognition.md#13-cadrage-de-liris-9--entraîner-large-exposer-étroit)

## Principes de livraison
1. Simplicité > élégance > vitesse > clarté > fiabilité > profondeur.
2. Chaque écran passe la *design review* (`docs/06-design-system.md#design-review`).
3. Aucun texte en dur ; toute chaîne passe par `AppLocalizations`.
4. Aucune logique métier dans les widgets : elle vit dans `domain/` et `data/`.
