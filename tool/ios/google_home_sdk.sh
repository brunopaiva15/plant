#!/usr/bin/env bash
#
# Prépare le SDK des Home APIs de Google pour le projet iOS.
#
# Le SDK ne se prend sur aucun dépôt public : il se télécharge depuis la
# console Google Home pour un projet déclaré. Les mêmes archives sont aussi
# dans un seau public, ce qui permet de rejouer une version sans se
# connecter — c'est celui-là qu'on lit ici.
#
# Deux choses que l'archive fait mal, et que ce script corrige :
#
#   1. Elle porte des attributs `com.apple.quarantine` et des fichiers `._`
#      d'Apple, que `tar` restaure sur macOS et qui font refuser le dossier à
#      Xcode. D'où `--no-xattrs --no-mac-metadata`.
#   2. Ses fichiers sont en lecture seule, y compris pour leur propriétaire,
#      ce qui empêche jusqu'à la suppression d'un attribut étendu.
#
# Une troisième, que ce script ne corrige pas : `GoogleHomeTypes.framework`
# n'a pas d'`Info.plist`, étant une bibliothèque statique dans un dossier
# `.framework` — elle n'est pas faite pour être copiée dans l'application.
# Lui en fabriquer un la fait passer pour un framework signable, et la
# signature échoue alors sur une archive `ar`. C'est donc une phase de build
# de la cible Runner qui retire cette copie inutile du bundle.
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
# Dès qu'une version sort, Google range la précédente dans `deprecated/` :
# l'URL d'une version épinglée ne tient qu'un mois. On essaie donc les deux
# emplacements, la racine d'abord.
BUCKET="https://storage.googleapis.com/home_sdk_ios"
URLS=(
  "${BUCKET}/GoogleHomeSDK-${VERSION}.tar.gz"
  "${BUCKET}/deprecated/GoogleHomeSDK-${VERSION}.tar.gz"
)

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$root"

archive="${1:-}"
temp=""
if [ -z "$archive" ]; then
  temp="$(mktemp -d)"
  archive="$temp/GoogleHomeSDK-${VERSION}.tar.gz"
  echo "Téléchargement du SDK ${VERSION}…"
  # `-s` plutôt qu'une barre de progression : sur une CI, la sortie n'est
  # pas un terminal et la barre ne produit que du bruit. Sans `-S` non plus :
  # le 404 attendu à la racine se dit en une ligne ci-dessous, pas en erreur
  # de curl. Trois tentatives, parce qu'un build ne doit pas échouer sur un
  # paquet perdu.
  ok=""
  for url in "${URLS[@]}"; do
    if curl -fsL --retry 3 --retry-delay 2 -o "$archive" "$url"; then
      ok=1
      break
    fi
    echo "Absent de ${url}."
  done
  if [ -z "$ok" ]; then
    echo "Échec : GoogleHomeSDK-${VERSION}.tar.gz est introuvable dans ${BUCKET}." >&2
    exit 1
  fi
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

echo
echo "Prêt. Dans Xcode : File › Add Package Dependencies › Add Local ›"
echo "  $root/vendor/GoogleHomeSDK"
echo "puis Runner en cible pour GoogleHomeSDK et GoogleHomeTypes."
