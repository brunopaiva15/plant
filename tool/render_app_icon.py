# ============================================================
# Les rendus 3D de l'icône : le pot d'argile et sa pousse, dans Blender.
#
#   python3 tool/render_app_icon.py [--blender CHEMIN] [--echantillons 256]
#
# La scène est décrite entièrement par tool/app_icon_scene.py, sans fichier
# .blend : Blender la construit, la rend avec Cycles et l'enregistre. Ce
# script la rend plusieurs fois, un calque à la fois, dans
# assets/icon/rendu/ :
#
#   icone.png                 l'icône entière, fond sauge compris ;
#   avant_plan.png            le pot seul, fond transparent, même cadrage ;
#   avant_plan_adaptatif.png  le pot seul, champ élargi d'un tiers pour
#                             l'avant-plan adaptatif d'Android ;
#   fond.png                  le dégradé sauge seul ;
#   clin_50/85/100.png        l'œil de droite à mi-fermeture, presque fermé,
#                             fermé en arc — découpé dans la zone OEIL.
#
# Ensuite, tool/build_app_icon.py en tire toutes les déclinaisons. Blender
# n'est donc nécessaire que pour changer le dessin, pas pour régénérer les
# tailles. Un rendu prend environ deux minutes sur quatre cœurs.
#
# Les rendus sont reproductibles : même graine pour Cycles et pour le grain,
# si bien que les images du clin d'œil se posent sur l'icône sans raccord.
# ============================================================
import argparse
import os
import shutil
import subprocess
import tempfile
from pathlib import Path

from PIL import Image

from build_app_icon import OEIL, RENDUS

RACINE = Path(__file__).resolve().parent.parent
SCENE = RACINE / "tool" / "app_icon_scene.py"

# Chaque calque : les variables d'environnement lues par la scène.
CALQUES = {
    "icone": {},
    "avant_plan": {"FOND": "0"},
    # Le lanceur d'Android ne montre que les deux tiers centraux de
    # l'avant-plan : un champ élargi d'autant les fait coïncider avec l'icône.
    "avant_plan_adaptatif": {"FOND": "0", "CADRE": str(2 / 3)},
    "fond": {"OBJETS": "0"},
    "clin_50": {"CLIN": "0.5"},
    "clin_85": {"CLIN": "0.85"},
    "clin_100": {"CLIN": "1"},
}


def rendre(blender, echantillons, nom, variables, dossier):
    sortie = dossier / f"{nom}.png"
    env = {**os.environ, "YEUX": "1", **variables}
    subprocess.run(
        [blender, "-b", "--python", str(SCENE), "--", str(echantillons), str(sortie)],
        env=env, check=True, stdout=subprocess.DEVNULL,
    )
    return sortie


def main():
    parser = argparse.ArgumentParser(description="Rend les calques de l'icône dans Blender.")
    parser.add_argument("--blender", default=shutil.which("blender") or "blender")
    parser.add_argument("--echantillons", type=int, default=256)
    args = parser.parse_args()
    RENDUS.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        for nom, variables in CALQUES.items():
            print(f"Rendu de {nom}…", flush=True)
            image = rendre(args.blender, args.echantillons, nom, variables, Path(tmp))
            if nom.startswith("clin_"):
                # Seul l'œil change : on n'en garde que la zone.
                Image.open(image).crop(OEIL).save(RENDUS / f"{nom}.png")
            else:
                shutil.copy(image, RENDUS / f"{nom}.png")
    print(f"Calques rendus dans {RENDUS.relative_to(RACINE)}")


if __name__ == "__main__":
    main()
