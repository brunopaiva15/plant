# ============================================================
# Remplace l'exécutable Blender par le module bpy (pip install bpy), pour
# les scripts qui lancent « blender -b --python SCÈNE -- ARGUMENTS » :
#
#   python3 store/entete.py SORTIE --blender "python3 tool/blender_bpy.py"
#
# Utile là où Blender n'est pas installé (une machine Linux sans écran, un
# conteneur) : le module rend avec le même Cycles, sur le processeur.
# ============================================================
import runpy
import sys

args = sys.argv[1:]
scene = args[args.index("--python") + 1]
sys.argv = ["blender"] + (args[args.index("--"):] if "--" in args else [])
runpy.run_path(scene, run_name="__main__")
