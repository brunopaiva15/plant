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
| Synchronisation Supabase (adapter `RemoteDataSource`, outbox déjà en place) | → Phase 3 |
| Notification « stock bas » (regroupée au rappel quotidien) | → Phase 3 |

## Phase 3 — « Partager » (en cours)
| Fonction | État |
|---|---|
| Météo (Open-Meteo, sans clé) : emplacements « extérieur », ligne météo sur Aujourd'hui, conseil « pluie prévue : pas besoin d'arroser » avec report en un tap | ✅ |
| Export complet (ZIP : `data.json` de toutes les tables + photos), partage natif | ✅ |
| Timelapse de croissance (photos en fondu, chronologiques) | ✅ |
| Stock bas regroupé dans le rappel quotidien | ✅ |
| Collaboration (jardin partagé, rôles Owner / Member / Viewer, « Arrosée par Laura à 08:32 ») | ⏳ nécessite le backend (Supabase) |
| Synchronisation multi-appareils (outbox → `RemoteDataSource`) | ⏳ nécessite le backend |
| Diagnostic (« Ma plante a un problème »), suggestions non affirmatives | ⏳ nécessite un fournisseur d'IA (clé utilisateur, même modèle que l'identification) |
| Partage par lien public révocable | ⏳ nécessite le backend |
| Widgets iOS / Android, Live Activity « session de soin » | ⏳ code natif (WidgetKit / AppWidget) |

## Phase 4 — « Étendre »
- NFC (architecture prévue : `PlantTagLink` table `plant_links` type `nfc` / `qr`)
- Apple Watch
- Automatisations, Shortcuts / Siri, Home Assistant, capteurs
- Import HortusFox, export complet (JSON / CSV / ZIP)

## Principes de livraison
1. Simplicité > élégance > vitesse > clarté > fiabilité > profondeur.
2. Chaque écran passe la *design review* (`docs/06-design-system.md#design-review`).
3. Aucun texte en dur ; toute chaîne passe par `AppLocalizations`.
4. Aucune logique métier dans les widgets : elle vit dans `domain/` et `data/`.
