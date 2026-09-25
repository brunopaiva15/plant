# Journal des versions

Ce qui change d'une version publiée à la suivante. Les textes à saisir dans
le champ « Nouveautés » d'App Store Connect sont dans
[store/listing.md](store/listing.md#nouveautés-de-la-101).

## 1.0.1 (build 25)

Comparée au dernier build de la 1.0.0 (build 23, `6d82ad4`).

### Création d'une plante

- **L'espèce probable est retenue d'office.** Quand Iris juge la première
  candidate « probable » — le seuil où la cascade l'accepterait sans appel —,
  son badge prend le trait vert et une coche, et le nom et l'espèce sont
  préremplis. Toucher un autre badge la remplace. Sous ce seuil, ou dehors,
  où la cascade tempère sa confiance, rien n'est retenu.
- Une espèce retenue d'office ne part pas entraîner Iris tant que personne ne
  l'a confirmée. Une nouvelle photo ou « Reprendre » l'efface, avec le nom et
  le rythme d'arrosage qu'elle avait apportés.
- **Le nom suit la candidate** tant que la personne ne l'a pas modifié :
  choisir le Ficus après le Pothos proposé ne laisse plus une plante
  « Pothos ».
- Le sous-titre de l'aperçu devient une consigne : « L'application retient la
  plus probable. Touchez un autre nom pour la changer. » ou « Touchez le nom
  de votre plante, ou continuez sans choisir. ».
- **La première plante est guidée.** Tant que le jardin n'a aucune plante, les
  étapes photo, nom et emplacement portent une phrase de consigne sur le fond
  sauge des aides. Le guide disparaît avec la première plante créée.

`f2b1e38` — `create_plant_flow.dart`, 5 clés ARB (`identifyChooseHint`,
`identifyPreselectedHint`, `guideAimTip`, `guideNameTip`, `guideLocationTip`).

### Photos

- **Un accès refusé à l'appareil photo ou aux photos mène aux Réglages.**
  Jusqu'ici, un refus donnait « Impossible d'ajouter la photo. Réessayez. » à
  chaque geste, alors qu'iOS ne repose jamais la question. Le toast dit
  désormais quoi autoriser, avec un bouton « Réglages » sur iOS ; toute autre
  erreur garde le message générique.
- Quand l'appareil photo intégré est refusé, toucher le cadre ouvre les
  Réglages, « Ouvrir les Réglages » s'écrit sous la consigne, et l'appareil
  photo se rouvre au retour.
- Les six endroits qui prennent une photo passent par le même traitement. La
  photo d'un emplacement n'attrapait pas l'erreur.

`7493efa` — `PhotoAccessDenied` dans `photo_storage_service.dart`,
`photo_error.dart`, toast avec icône d'action et trois lignes, 2 clés ARB
(`settingsShort`, `photoLibraryPermission`).

### iOS

- **Les demandes d'autorisation sont traduites.** Position, Maison, appareil
  photo et photothèque s'affichaient en français quelle que soit la langue du
  téléphone ; chaque langue a maintenant son `InfoPlist.strings`.
- **L'App Store annonce les quatre langues.** Il les lit dans les dossiers
  `.lproj` du paquet, et le seul présent était `Base.lproj`, rangé sous
  l'anglais.

`787534a` — `ios/Runner/{fr,en,de,it}.lproj/InfoPlist.strings`, projet Xcode.

### Construction

- Le script du SDK Google Home cherche aussi l'archive dans `deprecated/` :
  Google y a rangé la 1.10.1 à la sortie de la 1.11.0, et le post-clone de
  Codemagic échouait (`831ad28`).

### Tests

- `test/data/photo_access_test.dart` : refus, erreur qui passe, toast.
- `test/app/ios_localizations_test.dart` : chaque langue traduit toutes les
  clés `NS…UsageDescription` et le projet embarque les quatre fichiers.
- 6 tests de plus dans `test/features/create_plant_photo_step_test.dart`.
