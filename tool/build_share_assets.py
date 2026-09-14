# ============================================================
# Les pièces que la page de partage emporte : la fonte à la main, le grain du
# papier, l'image d'aperçu des messageries.
#
#   python3 tool/build_share_assets.py
#
# Sort `supabase/functions/share/assets.ts`, que la fonction Edge sert sous
# `/asset/`. Elles y sont en base64 plutôt qu'en fichiers : une fonction
# Supabase se déploie en un bundle, et un fichier posé à côté du code n'y
# entre pas de façon sûre.
#
# La fonte est réduite à ce que la page emploie — l'axe de graisse 600–700, le
# latin étendu, donc les quatre langues de l'app et les noms qui s'y écrivent.
# Le reste est repris tel quel : `assets/textures/grain.png`, et l'image
# d'aperçu que produit `node tool/build_share_preview.mjs`.
#
# Refaire après toute mise à jour de la fonte, du grain ou de l'aperçu.
# ============================================================
import base64
import subprocess
import sys
import tempfile
import textwrap
from pathlib import Path

RACINE = Path(__file__).resolve().parent.parent
FONTE = RACINE / "assets" / "fonts" / "ShantellSans-VF.ttf"
GRAIN = RACINE / "assets" / "textures" / "grain.png"
APERCU = RACINE / "supabase" / "functions" / "share" / "preview.jpg"
SORTIE = RACINE / "supabase" / "functions" / "share" / "assets.ts"

# Les deux seules graisses de la page : le titre (700) et le code (600).
AXE = "wght=600:700"
# Latin de base, latin-1 (« » compris), latin étendu A, et la ponctuation
# typographique que les textes emploient.
UNICODES = "U+0020-007E,U+00A0-00FF,U+0100-017F,U+2018-201E,U+2026,U+202F,U+2013-2014,U+20AC"


def sous_ensemble_fonte() -> bytes:
    """La fonte variable, ramenée à son axe utile et à son jeu de signes."""
    with tempfile.TemporaryDirectory() as tmp:
        instance = Path(tmp) / "instance.ttf"
        woff2 = Path(tmp) / "shantell.woff2"
        subprocess.run(
            [sys.executable, "-m", "fontTools.varLib.instancer", str(FONTE), AXE, "-o", str(instance)],
            check=True, capture_output=True,
        )
        subprocess.run(
            [sys.executable, "-m", "fontTools.subset", str(instance),
             f"--output-file={woff2}", "--flavor=woff2", f"--unicodes={UNICODES}",
             "--layout-features=kern,liga,ccmp,locl", "--no-hinting"],
            check=True, capture_output=True,
        )
        return woff2.read_bytes()


def bloc(octets: bytes) -> str:
    lignes = textwrap.wrap(base64.b64encode(octets).decode(), 100)
    return "\n".join(f"  '{l}'," for l in lignes)


def main() -> None:
    for source in (FONTE, GRAIN, APERCU):
        if not source.exists():
            raise SystemExit(f"absent : {source.relative_to(RACINE)}"
                             + (" — lancer `node tool/build_share_preview.mjs`" if source == APERCU else ""))

    fonte = sous_ensemble_fonte()
    grain = GRAIN.read_bytes()
    apercu = APERCU.read_bytes()

    SORTIE.write_text(f"""// Ce que la page de partage emporte : sa fonte, son grain, son image
// d'aperçu. `index.ts` les sert sous `/asset/` plutôt que de les glisser dans
// le HTML — la page pèse alors cinq kilo-octets, et le navigateur garde le
// reste pour un an.
//
// **Fichier produit, pas écrit** : `python3 tool/build_share_assets.py`.

/** Shantell Sans, axe `wght` 600–700, latin étendu. {len(fonte)} octets. */
const SHANTELL_WOFF2_B64 = [
{bloc(fonte)}
].join('');

/** `assets/textures/grain.png` : une tuile de 128 px. {len(grain)} octets. */
const GRAIN_PNG_B64 = [
{bloc(grain)}
].join('');

/** La vignette des messageries, en 1200 × 630. {len(apercu)} octets. */
const PREVIEW_JPG_B64 = [
{bloc(apercu)}
].join('');

function decode(b64: string): Uint8Array {{
  const raw = atob(b64);
  const bytes = new Uint8Array(raw.length);
  for (let i = 0; i < raw.length; i++) bytes[i] = raw.charCodeAt(i);
  return bytes;
}}

/** Ce que sert `/asset/<nom>`, par nom de fichier. */
export const ASSETS: Record<string, {{ bytes: Uint8Array; type: string }}> = {{
  'shantell.woff2': {{ bytes: decode(SHANTELL_WOFF2_B64), type: 'font/woff2' }},
  'grain.png': {{ bytes: decode(GRAIN_PNG_B64), type: 'image/png' }},
  'preview.jpg': {{ bytes: decode(PREVIEW_JPG_B64), type: 'image/jpeg' }},
}};
""", encoding="utf-8")
    print(f"{SORTIE.relative_to(RACINE)} · fonte {len(fonte)} · grain {len(grain)} · aperçu {len(apercu)}")


if __name__ == "__main__":
    main()
