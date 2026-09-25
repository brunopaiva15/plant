#!/usr/bin/env bash
# Captures réelles de l'app sur le simulateur, pour les visuels du magasin,
# puis composition. À lancer depuis un Mac avec Xcode et Flutter :
#
#   store/capture_ios.sh                 # les quatre langues, sur le plus grand iPhone installé
#   FORMAT=ipad store/capture_ios.sh     # la même série sur le plus grand iPad
#   LANGS="fr en" store/capture_ios.sh   # deux langues
#   DEVICE="iPhone 17 Pro" store/capture_ios.sh
#   STORE_SCENES=capture,diagnosis LANGS=fr store/capture_ios.sh   # rejouer deux scènes
#
# App Store demande une série par famille d'appareils, et le projet en déclare
# deux (TARGETED_DEVICE_FAMILY = « 1,2 ») : il faut donc les deux passages,
# celui de l'iPhone et celui de l'iPad.
#
# Le simulateur doit exister (Xcode › Settings › Platforms). Le jeu de démo
# (core/demo/demo_seed.dart) est chargé au premier lancement, les photos CC0
# de store/demo-photos étant servies à l'app par store/serve.py. L'app est
# désinstallée avant chaque langue pour repartir de zéro.
set -euo pipefail
cd "$(dirname "$0")/.."

# Le plus grand appareil de la famille que Xcode propose, sauf si DEVICE en
# nomme un autre. Les visuels restent composés au format du magasin par
# compose.py (6,7 pouces ou 13 pouces), quelle que soit la taille de la capture.
FORMAT="${FORMAT:-iphone}"
DEVICE="${DEVICE:-}"
LANGS="${LANGS:-fr en de it}"

case "$FORMAT" in
  iphone) SUFFIX='' ;;
  ipad)   SUFFIX='ipad-' ;;
  *) echo "FORMAT doit être « iphone » ou « ipad », pas « $FORMAT »." >&2; exit 1 ;;
esac

# Le choix se fait par classement et non par une liste de noms : Xcode en
# ajoute à chaque version, et une liste se périme au premier iPad suivant.
UDID=$(xcrun simctl list devices available -j | FAMILY="$FORMAT" WANTED="$DEVICE" python3 -c '
import json, os, re, sys

family, wanted = os.environ["FAMILY"], os.environ["WANTED"]
devices = [d for runtime in json.load(sys.stdin)["devices"].values() for d in runtime]
devices = [d for d in devices if d["name"] == wanted] if wanted else [d for d in devices if d["name"].lower().startswith(family)]


def generation(name):
    # M5, 17, « 6th generation » : la génération, sous le nom quelle porte.
    # Les puces M passent devant les générations numérotées, plus anciennes.
    m = re.search(r"\(m(\d+)\)", name)
    if m:
        return 100 + int(m.group(1))
    m = re.search(r"\((\d+)(?:st|nd|rd|th) generation\)", name) or re.search(r"iphone (\d+)", name)
    return int(m.group(1)) if m else 0


def rank(device):
    # App Store veut la plus grande taille de chaque famille : le plus grand
    # écran dabord, puis le haut de gamme, puis le plus récent.
    n = device["name"].lower()
    if family == "ipad":
        size = 3 if ("13-inch" in n or "12.9-inch" in n) else 0 if "mini" in n else 2 if "11-inch" in n else 1
        tier = 2 if "pro" in n else 1 if "air" in n else 0
    else:
        size = 4 if "pro max" in n else 3 if "plus" in n else 2 if "pro" in n else 0 if ("mini" in n or n.endswith(" se")) else 1
        tier = 0
    return (size, tier, generation(n))


if devices:
    best = max(devices, key=rank)
    print(best["udid"], best["name"], sep="\t")')
if [ -z "$UDID" ]; then
  echo "Aucun simulateur $FORMAT${DEVICE:+ « $DEVICE »} disponible. Ceux qui existent :" >&2
  xcrun simctl list devices available | grep -i "$FORMAT" >&2
  exit 1
fi
NAME="${UDID#*	}"
UDID="${UDID%%	*}"
echo "Simulateur : $NAME ($UDID)"

xcrun simctl boot "$UDID" 2>/dev/null || true
# La fenêtre du simulateur, si la machine en a une : Xcode 26 a remplacé
# Simulator.app par Device Hub, et les versions d'avant n'ont que l'autre.
# Elle ne sert qu'à regarder — `simctl` démarre l'appareil et `flutter drive`
# lui parle sans elle —, donc son absence n'arrête pas les captures.
open -a Simulator 2>/dev/null ||
  open -a "Device Hub" 2>/dev/null ||
  open "$(xcode-select -p)/Applications/Simulator.app" 2>/dev/null ||
  echo "Aucune fenêtre de simulateur à ouvrir : les captures se prennent quand même." >&2
xcrun simctl bootstatus "$UDID" -b
# L'heure d'Apple, batterie pleine : au cas où la capture emporte la barre
# d'état. L'antenne n'existe que sur le téléphone.
if [ "$FORMAT" = ipad ]; then
  xcrun simctl status_bar "$UDID" override --time 9:41 --batteryState charged --batteryLevel 100 --wifiBars 3
else
  xcrun simctl status_bar "$UDID" override --time 9:41 --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3 --operatorName ''
fi

python3 store/serve.py 8081 store &
SERVER=$!
trap 'kill $SERVER 2>/dev/null || true; xcrun simctl status_bar "$UDID" clear' EXIT

# Le jeu de démo télécharge ses photos ici, avant que l'app ne s'ouvre. Si
# personne ne répond — un serveur oublié par une exécution interrompue tient
# souvent le port —, les plantes n'ont pas de fichier, Iris n'a rien à lire,
# et la feuille « Espèce » sort vide. Autant le dire tout de suite.
for i in $(seq 20); do
  curl -sf -o /dev/null http://localhost:8081/demo-photos/SOURCES.md && break
  if [ "$i" = 20 ]; then
    echo "Rien ne répond sur http://localhost:8081. Un autre serveur tient le port :" >&2
    lsof -ti :8081 >&2 || true
    echo "Le libérer : lsof -ti :8081 | xargs kill" >&2
    exit 1
  fi
  sleep 0.5
done

for lang in $LANGS; do
  xcrun simctl uninstall "$UDID" ch.vergasta.plant 2>/dev/null || true
  # Sans STORE_SCENES, on repart de zéro ; avec, les captures gardées restent.
  [ -n "${STORE_SCENES:-}" ] || rm -rf "store/shots-$SUFFIX$lang"
  mkdir -p "store/shots-$SUFFIX$lang"
  # Le marqueur dit à compose.py que ces captures viennent d'un appareil :
  # l'écran est entier, la place de la barre d'état est déjà réservée en haut.
  touch "store/shots-$SUFFIX$lang/.device"
  STORE_SHOTS="store/shots-$SUFFIX$lang" flutter drive -d "$UDID" \
    --driver=test_driver/integration_test.dart \
    --target=integration_test/store_screenshots_test.dart \
    --dart-define=DEMO=true \
    --dart-define=DEMO_PHOTOS=http://localhost:8081/demo-photos \
    --dart-define=STORE_LANG="$lang" \
    --dart-define=STORE_SCENES="${STORE_SCENES:-}"
done

for lang in $LANGS; do
  python3 store/compose.py "store/shots-$SUFFIX$lang" "store/$SUFFIX$lang" "$lang" "$FORMAT"
done
echo "Visuels composés : $(for l in $LANGS; do printf 'store/%s ' "$SUFFIX$l"; done)"
