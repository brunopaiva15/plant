# Flora — Roadmap par phases

> Nom de travail : **Flora** (configurable via `AppConfig.appName`). Aucune dépendance profonde au nom dans le code.

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
| Export complet (ZIP : `data.json` de toutes les tables + photos), partage natif | ✅ |
| Timelapse de croissance (photos en fondu, chronologiques) | ✅ |
| Stock bas regroupé dans le rappel quotidien | ✅ |
| Synchronisation multi-appareils : `SyncService` (push depuis l'outbox, pull delta, last-write-wins, photos), adaptateur Supabase, temps réel, coordinateur (démarrage / premier plan / après écriture) | ✅ code + tests ; activé par `--dart-define` (voir docs/08) |
| Comptes : e-mail par code, Apple natif (iOS), Google OAuth ; compte local conservé sans connexion | ✅ |
| Collaboration : membres, invitation par e-mail (RPC), rôles owner / member / viewer, « · par Laura » dans la timeline, lecture seule pour viewer | ✅ |
| Diagnostic « Ma plante a un problème » : photos + symptômes → pistes classées par vraisemblance avec gestes concrets (API Claude, clé fournie par l'utilisateur, sortie structurée, jamais présenté comme certain) ; enregistrement dans le journal | ✅ |
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
| Sauvegarde : export par sections, restauration avec aperçu, rapport d'import | ✅ |
| API externe : API REST du projet Supabase, jeton de session, ressources documentées dans l'app | ✅ |

## Au-delà de HortusFox
| Fonction | État |
|---|---|
| Fiche d'entretien par plante : arrosage saisonnier, lumière, humidité, substrat, rempotage, toxicité, bouturage, problèmes fréquents (230 espèces au catalogue) | ✅ |
| Sélecteur d'espèces : catalogue intégré hors ligne + recherche GBIF paginée | ✅ |
| Catalogue étendu : ~40 000 espèces avec leurs noms courants en fr/de/it/en, cherchables hors ligne et sans accents (Wikidata CC0 + familles GBIF) | ✅ |
| Onboarding animé en cinq écrans, illustrations 3D en boucle (24 im/s), objets en orbite, fond qui vire de teinte, titres levés mot à mot | ✅ |
| Application 100 % gratuite : plus aucun plafond ni fonction réservée | ✅ |
| Soutien facultatif au développeur (achat unique, App Store / Play), à la fin de l'onboarding et dans Profil | ✅ |

## Phase 4 — « Étendre »
- NFC (architecture prévue : `PlantTagLink` table `plant_links` type `nfc` / `qr`)
- Apple Watch
- Automatisations, Shortcuts / Siri, Home Assistant, capteurs
- Import HortusFox (l'export complet JSON / CSV / ZIP est livré)

## Principes de livraison
1. Simplicité > élégance > vitesse > clarté > fiabilité > profondeur.
2. Chaque écran passe la *design review* (`docs/06-design-system.md#design-review`).
3. Aucun texte en dur ; toute chaîne passe par `AppLocalizations`.
4. Aucune logique métier dans les widgets : elle vit dans `domain/` et `data/`.
