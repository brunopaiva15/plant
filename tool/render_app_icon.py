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
#   lancement.png             le pot raccourci, entier, fond transparent :
#                             le logo de l'écran de lancement et de
#                             l'ouverture ;
#   lancement_clin_50/85/100  l'œil de droite à mi-fermeture, presque fermé,
#                             fermé en arc, au cadrage du lancement —
#                             découpé dans la zone OEIL.
#
# Avec --pousse, il rend aussi la séquence de l'écran de bienvenue : le pot
# du lancement, de la terre nue à la pousse adulte, en quarante images que
# tool/pack_growth.py assemble dans assets/onboarding/pousse.webp. La
# dernière image est exactement le pot du lancement, sans son ombre :
# l'application dessine la sienne.
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
POUSSE = RACINE / "assets" / "onboarding" / "pousse.webp"

# Chaque calque : les variables d'environnement lues par la scène.
CALQUES = {
    "icone": {},
    "avant_plan": {"FOND": "0"},
    # Le lanceur d'Android ne montre que les deux tiers centraux de
    # l'avant-plan : un champ élargi d'autant les fait coïncider avec l'icône.
    "avant_plan_adaptatif": {"FOND": "0", "CADRE": str(2 / 3)},
    "fond": {"OBJETS": "0"},
}
# Le pot de l'écran de lancement : raccourci pour qu'on le voie entier sans
# qu'il paraisse plus long que sur l'icône, champ un peu élargi, caméra
# baissée sur son milieu.
LANCEMENT = {"FOND": "0", "POT_BAS": "-0.3", "CADRE": "0.88", "CIBLE_Z": "0.95"}
CALQUES["lancement"] = LANCEMENT
for clin in ("50", "85", "100"):
    CALQUES[f"lancement_clin_{clin}"] = {**LANCEMENT, "CLIN": str(int(clin) / 100)}


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
    parser.add_argument("--seulement", nargs="*", choices=CALQUES, help="ne rendre que ces calques (aucun : seulement la pousse)")
    parser.add_argument("--pousse", type=int, metavar="IMAGES", help="rendre aussi la séquence de pousse, en IMAGES images")
    args = parser.parse_args()
    RENDUS.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        for nom, variables in CALQUES.items():
            if args.seulement is not None and nom not in args.seulement:
                continue
            print(f"Rendu de {nom}…", flush=True)
            image = rendre(args.blender, args.echantillons, nom, variables, Path(tmp))
            if "_clin_" in nom:
                # Seul l'œil change : on n'en garde que la zone.
                Image.open(image).crop(OEIL).save(RENDUS / f"{nom}.png")
            else:
                shutil.copy(image, RENDUS / f"{nom}.png")
        if args.pousse:
            dossier = Path(tmp) / "pousse"
            dossier.mkdir()
            for i in range(args.pousse):
                age = i / (args.pousse - 1)
                print(f"Pousse {i + 1}/{args.pousse}…", flush=True)
                # Quarante échantillons suffisent : l'image est petite à l'écran et bouge.
                rendre(args.blender, 40, f"{i:03d}", {**LANCEMENT, "AGE": str(age)}, dossier)
            subprocess.run(
                ["python3", str(RACINE / "tool" / "pack_growth.py"), str(dossier), str(POUSSE), "--fps", "14"],
                check=True,
            )
    print(f"Calques rendus dans {RENDUS.relative_to(RACINE)}")


if __name__ == "__main__":
    main()
