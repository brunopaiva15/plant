# Kit marketing

Les images d'Auxine pour les réseaux, aux formats courants, en quatre
langues : `marketing/fr/`, `en/`, `de/`, `it/`. Chaque dossier a les mêmes
fichiers, sous les mêmes noms. Toutes sortent de `kit.py`, avec les couleurs,
les polices, l'appareil et les objets 3D des visuels du magasin
(`store/compose.py`).

```sh
python3 marketing/kit.py              # les quatre langues
python3 marketing/kit.py de           # une seule
python3 marketing/kit.py fr store/x   # avec un autre dossier de captures
```

Les captures sont celles de `store/shots-<langue>/` (hors du dépôt) : du web
avec `store/capture.mjs`, ou du simulateur avec `store/capture_ios.sh`. Celles
du simulateur donnent la barre d'onglets native ; le script reconnaît les deux.

Les textes sont dans `TEXTES`, un registre par langue comme dans l'app
(« vous », *you*, *du*, *tu*), écrits depuis l'intention plutôt que traduits
du français : le compte à rebours « J-3 » devient « 3 days », « 3 Tage »,
« 3 giorni ». Le prix s'écrit à la façon de chaque langue (« €0.99 » et
« CHF 1 » en anglais).

## Les fichiers

| Fichier | Taille | Usage |
|---|---|---|
| `symbole-1024.png` | 1024 × 1024, transparent | le pot de l'icône, seul |
| `logo-encre.png`, `logo-blanc.png` | transparents | le pot et « Auxine », sur fond clair ou foncé |
| `avatar-1000.jpg` | 1000 × 1000 | photo de profil (le pot tient dans le cercle) |
| `banniere-x-1500x500.jpg` | 1500 × 500 | en-tête X |
| `banniere-linkedin-1584x396.jpg` | 1584 × 396 | en-tête LinkedIn |
| `couverture-facebook-1640x624.jpg` | 1640 × 624 | couverture Facebook |
| `couverture-youtube-2560x1440.jpg` | 2560 × 1440 | bannière YouTube |
| `apercu-lien-1200x630.jpg` | 1200 × 630 | aperçu d'un lien (Open Graph) |
| `miniature-video-1280x720.jpg` | 1280 × 720 | miniature de vidéo |
| `post-carre-*.jpg` | 1080 × 1080 | publication carrée |
| `post-portrait-*.jpg` | 1080 × 1350 | publication 4:5, la plus grande dans un fil |
| `story-*.jpg` | 1080 × 1920 | story, Reels, TikTok |
| `post-paysage-*.jpg` | 1600 × 900 | publication 16:9 (X, LinkedIn) |

Les bannières gardent tout au centre : sur mobile, les réseaux rognent les
côtés et posent l'heure, les boutons et la photo de profil par-dessus. Les
stories laissent libres les 250 px du haut et les 340 px du bas, où passe
l'interface.

## Les thèmes

Chaque publication traite un sujet, défini dans `THEMES` : la marque, le
prix, Iris, les soins du jour, le diagnostic, la fiche d'entretien, la
collection, le calendrier du jardin, les données sur l'appareil. Un thème
nouveau, ou un format de plus, s'ajoute là. Les textes suivent le ton de
`docs/06-design-system.md` : pas de point d'exclamation, des chiffres en
chiffres.

## La sortie

`marketing/fr/sortie/` réunit la série du lancement, définie dans `SORTIE` :

| Thème | Ce qu'il dit | Formats |
|---|---|---|
| `bientot` | « Bientôt sur l'App Store. » | carré, portrait, story |
| `j-3`, `j-2`, `j-1` | le compte à rebours | carré, story |
| `disponible` | « Auxine est disponible. », le pot seul | carré, portrait, story, 16:9 |
| `disponible-ecran` | la même annonce, avec l'écran Aujourd'hui | carré, portrait, story, 16:9 |
| `merci` | « Merci. Pour votre accueil et vos retours. » | carré, portrait, story |
| `nouveautes` | un modèle pour chaque mise à jour | carré, story |

S'y ajoutent les bannières X et LinkedIn « Disponible sur l'App Store. ».
Aucune image ne porte de date : elle va dans le texte qui l'accompagne.

## En francs suisses

Chaque image qui dit le prix existe aussi en francs (« 1 CHF », le palier suisse de
0,99 €), sous le même nom suivi de `-chf` : `post-carre-prix-chf.jpg`,
`sortie/story-disponible-chf.jpg`, etc. (12 images par langue).
