#!/usr/bin/env bash
#
# Prépare le SDK des Home APIs de Google pour le projet iOS.
#
# Le SDK ne se prend sur aucun dépôt public : il se télécharge depuis la
# console Google Home pour un projet déclaré. Les mêmes archives sont aussi
# dans un seau public, ce qui permet de rejouer une version sans se
# connecter — c'est celui-là qu'on lit ici.
#
# Trois choses que l'archive fait mal, et que ce script corrige :
#
#   1. Elle porte des attributs `com.apple.quarantine` et des fichiers `._`
#      d'Apple, que `tar` restaure sur macOS et qui font refuser le dossier à
#      Xcode. D'où `--no-xattrs --no-mac-metadata`.
#   2. Ses fichiers sont en lecture seule, y compris pour leur propriétaire,
#      ce qui empêche jusqu'à la suppression d'un attribut étendu.
#   3. `GoogleHomeTypes.framework` n'a pas d'`Info.plist`. C'est une
#      bibliothèque statique dans un dossier `.framework` : elle n'est pas
#      faite pour être copiée dans l'application, donc Google ne lui en a pas
#      mis. Mais Xcode embarque tout `xcframework` d'une cible binaire sans
#      distinguer statique de dynamique, et l'outillage Flutter, qui inspecte
#      ensuite le `.app`, échoue sur ce fichier manquant. On le fabrique.
#
# Usage, depuis n'importe où :
#
#   tool/ios/google_home_sdk.sh              # télécharge la version ci-dessous
#   tool/ios/google_home_sdk.sh ~/archive.tar.gz   # utilise une archive locale
#
# Puis, dans Xcode : File › Add Package Dependencies › Add Local ›
# vendor/GoogleHomeSDK, avec Runner en cible pour les deux produits.
set -euo pipefail

VERSION=1.10.1
URL="https://storage.googleapis.com/home_sdk_ios/GoogleHomeSDK-${VERSION}.tar.gz"

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$root"

archive="${1:-}"
temp=""
if [ -z "$archive" ]; then
  temp="$(mktemp -d)"
  archive="$temp/GoogleHomeSDK-${VERSION}.tar.gz"
  echo "Téléchargement du SDK ${VERSION}…"
  # `-sS` plutôt qu'une barre de progression : sur une CI, la sortie n'est
  # pas un terminal et la barre ne produit que du bruit. Trois tentatives,
  # parce qu'un build ne doit pas échouer sur un paquet perdu.
  curl -fsSL --retry 3 --retry-delay 2 -o "$archive" "$URL"
fi

echo "Extraction dans vendor/GoogleHomeSDK…"
rm -rf vendor/GoogleHomeSDK
mkdir -p vendor
tar xzf "$archive" -C vendor --no-xattrs --no-mac-metadata
[ -n "$temp" ] && rm -rf "$temp"

# Le droit d'écriture, sans quoi on ne peut plus rien faire de ces fichiers.
chmod -R u+w vendor/GoogleHomeSDK

sdk="vendor/GoogleHomeSDK"
[ -f "$sdk/Package.swift" ] || { echo "Échec : $sdk/Package.swift est absent." >&2; exit 1; }

# L'Info.plist manquant de GoogleHomeTypes, une tranche à la fois. Le
# minimum que cherche l'outillage Flutter : de quoi nommer l'exécutable.
for slice in "$sdk/Frameworks/GoogleHomeTypes.xcframework"/*/GoogleHomeTypes.framework; do
  [ -d "$slice" ] || continue
  if [ -f "$slice/Info.plist" ]; then
    echo "Info.plist déjà présent : $slice"
    continue
  fi
  case "$slice" in
    *simulator*) platform=iPhoneSimulator ;;
    *) platform=iPhoneOS ;;
  esac
  cat > "$slice/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>en</string>
	<key>CFBundleExecutable</key>
	<string>GoogleHomeTypes</string>
	<key>CFBundleIdentifier</key>
	<string>com.google.GoogleHomeTypes</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>GoogleHomeTypes</string>
	<key>CFBundlePackageType</key>
	<string>FMWK</string>
	<key>CFBundleShortVersionString</key>
	<string>${VERSION}</string>
	<key>CFBundleVersion</key>
	<string>1</string>
	<key>CFBundleSupportedPlatforms</key>
	<array>
		<string>${platform}</string>
	</array>
	<key>MinimumOSVersion</key>
	<string>17.0</string>
</dict>
</plist>
PLIST
  echo "Info.plist fabriqué : $slice ($platform)"
done

echo
echo "Prêt. Dans Xcode : File › Add Package Dependencies › Add Local ›"
echo "  $root/vendor/GoogleHomeSDK"
echo "puis Runner en cible pour GoogleHomeSDK et GoogleHomeTypes."
