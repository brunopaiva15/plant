#!/usr/bin/env bash
# Le rendu complet : l'image par Remotion, muette, puis le son posé par
# ffmpeg, calé à l'image près. Passer le son par Remotion le décalait
# d'environ 40 ms et le réencodait par morceaux.
#
#   ./rendu.sh             # la vidéo, sa version muette et la couverture
#   APERCU=1 ./rendu.sh    # un aperçu rapide, en demi-définition, sans flou de bougé
set -euo pipefail
cd "$(dirname "$0")"

FF=node_modules/@remotion/compositor-linux-x64-gnu
ffmpeg() { LD_LIBRARY_PATH=$FF "$FF/ffmpeg" "$@"; }
NAV=()
if [ -n "${CHROME:-}" ]; then NAV=(--browser-executable="$CHROME"); fi

mkdir -p out
if [ -n "${APERCU:-}" ]; then
  npx remotion render src/index.ts Sortie out/apercu.mp4 "${NAV[@]}" --scale=0.5 --props='{"flou":false}' --log=error
  exit 0
fi

npx remotion render src/index.ts Sortie out/auxine-sortie-fr-muette.mp4 "${NAV[@]}" --codec=h264 --crf=16 --muted --log=error
ffmpeg -loglevel error -y -i out/auxine-sortie-fr-muette.mp4 -i public/musique.wav \
  -map 0:v -map 1:a -c:v copy -c:a aac -b:a 256k -shortest -movflags +faststart out/auxine-sortie-fr.mp4
npx remotion still src/index.ts Sortie out/auxine-sortie-fr-couverture.png "${NAV[@]}" --frame=640 --log=error
ls -la out
