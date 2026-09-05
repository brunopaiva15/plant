# Visuels du magasin

Cinq visuels par langue, au format iPhone 6,7 pouces (1290 × 2796), sans le
nom de l'application. Chacun montre une capture réelle de l'app dans un
iPhone dessiné, un objet 3D de la série clay de l'onboarding, un titre, et
parfois un morceau d'interface découpé dans la capture et posé en avant.

| # | Écran | Objet | Teinte |
|---|---|---|---|
| 1 | Plantes (la collection) | pousse en pot | sauge |
| 2 | Aujourd'hui, avec la ligne « Calathea · Arroser » en avant | trois rangées cochées | eau |
| 3 | Fiche d'entretien | anneau et goutte | soleil |
| 4 | Jardin, calendrier, avec quatre tuiles du tableau de bord en avant | quatre tuiles | terre cuite |
| 5 | Sauvegarde | carte, cadenas, nuage | rose |

`fr/` et `en/` contiennent les fichiers prêts à déposer dans App Store Connect.

## Régénérer

```bash
flutter build web --profile --no-web-resources-cdn
python3 store/serve.py 8081 build/web &

# Captures réelles (390 × 844 à 3×), données de démo, iOS
node store/capture.mjs store/shots-fr fr-FR
node store/capture.mjs store/shots-en en-US

# Composition
pip install pillow numpy
python3 store/compose.py store/shots-fr store/fr fr
python3 store/compose.py store/shots-en store/en en
```

`capture.mjs` demande Playwright (`npm i playwright`) ; la variable `CHROMIUM`
peut pointer un binaire précis. Les emojis de l'app sont fournis par Flutter
web depuis Google Fonts : quand le navigateur ne peut pas y aller directement,
le script relaie ces requêtes par `curl`, qui suit le proxy de la machine.

`compose.py` télécharge la police Inter (SIL OFL) dans `store/fonts/` au
premier lancement. Les captures et les polices ne sont pas versionnées.

Les textes des visuels sont dans `compose.py` (`COPY`), coupés à la main pour
que chaque titre tienne sur deux lignes ; la taille est commune aux cinq.
