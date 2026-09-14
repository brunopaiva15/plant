#!/usr/bin/env bash
# Captures réelles de l'app sur le simulateur iPhone, pour les visuels du
# magasin, puis composition. À lancer depuis un Mac avec Xcode et Flutter :
#
#   store/capture_ios.sh              # les quatre langues, sur le plus grand iPhone installé
#   LANGS="fr en" store/capture_ios.sh   # deux langues
#   DEVICE="iPhone 17 Pro" store/capture_ios.sh
#   STORE_SCENES=identify,diagnosis LANGS=fr store/capture_ios.sh   # rejouer deux scènes
#
# Le simulateur doit exister (Xcode › Settings › Platforms). Le jeu de démo
# (core/demo/demo_seed.dart) est chargé au premier lancement, les photos CC0
# de store/demo-photos étant servies à l'app par store/serve.py. L'app est
# désinstallée avant chaque langue pour repartir de zéro.
set -euo pipefail
cd "$(dirname "$0")/.."

# Le plus grand iPhone que Xcode propose, sauf si DEVICE en nomme un autre.
# Les visuels restent composés au format 6,7 pouces par compose.py, quelle
# que soit la taille de la capture.
DEVICE="${DEVICE:-}"
LANGS="${LANGS:-fr en de it}"

UDID=$(xcrun simctl list devices available -j | python3 -c '
import json, sys
wanted = [sys.argv[1]] if sys.argv[1] else ["iPhone 17 Pro Max", "iPhone 16 Pro Max", "iPhone 15 Pro Max", "iPhone 17 Pro", "iPhone 16 Pro", "iPhone 17"]
devices = [d for runtime in json.load(sys.stdin)["devices"].values() for d in runtime]
for name in wanted:
    found = sorted((d for d in devices if d["name"] == name), key=lambda d: d["state"] != "Booted")
    if found:
        print(found[0]["udid"], found[0]["name"], sep="\t")
        break' "$DEVICE")
if [ -z "$UDID" ]; then
  echo "Aucun simulateur iPhone attendu${DEVICE:+ (« $DEVICE »)}. Ceux qui existent :" >&2
  xcrun simctl list devices available | grep -i iphone >&2
  exit 1
fi
NAME="${UDID#*	}"
UDID="${UDID%%	*}"
echo "Simulateur : $NAME ($UDID)"

xcrun simctl boot "$UDID" 2>/dev/null || true
open -a Simulator
xcrun simctl bootstatus "$UDID" -b
# L'heure d'Apple, réseau plein : au cas où la capture emporte la barre d'état.
xcrun simctl status_bar "$UDID" override --time 9:41 --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3 --operatorName ''

python3 store/serve.py 8081 store &
SERVER=$!
trap 'kill $SERVER 2>/dev/null || true; xcrun simctl status_bar "$UDID" clear' EXIT

for lang in $LANGS; do
  xcrun simctl uninstall "$UDID" ch.vergasta.plant 2>/dev/null || true
  # Sans STORE_SCENES, on repart de zéro ; avec, les captures gardées restent.
  [ -n "${STORE_SCENES:-}" ] || rm -rf "store/shots-$lang"
  mkdir -p "store/shots-$lang"
  # Le marqueur dit à compose.py que ces captures viennent d'un appareil :
  # l'écran est entier, la place de la barre d'état est déjà réservée en haut.
  touch "store/shots-$lang/.device"
  STORE_SHOTS="store/shots-$lang" flutter drive -d "$UDID" \
    --driver=test_driver/integration_test.dart \
    --target=integration_test/store_screenshots_test.dart \
    --dart-define=DEMO=true \
    --dart-define=DEMO_PHOTOS=http://localhost:8081/demo-photos \
    --dart-define=STORE_LANG="$lang" \
    --dart-define=STORE_SCENES="${STORE_SCENES:-}"
done

for lang in $LANGS; do
  python3 store/compose.py "store/shots-$lang" "store/$lang" "$lang"
done
echo "Visuels composés dans ${LANGS// /, } : $(for l in $LANGS; do printf 'store/%s ' "$l"; done)"
