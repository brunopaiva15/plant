# ============================================================
# Les scenes « environnement ideal » des fiches d'entretien : un diorama de
# piece dont la geometrie encode les besoins de la plante (distance a la
# fenetre = besoin de lumiere, tache de soleil = direct ou indirect), plus
# les plantes rendues seules pour etre posees par l'application.
#
# Toutes les couches sortent de la MEME camera a cadre fixe
# (tool/care_scene/common.py) : l'application les superpose sans decallage.
# Fond transparent partout ; l'ombre de la plante et les effets d'air sont
# dessines par l'application.
#
# Execution — un groupe, ou tous :
#   blender -b -noaudio -P tool/build_care_scene.py -- complet all
#   blender -b -noaudio -P tool/build_care_scene.py -- apercu indoor
#   blender -b -noaudio -P tool/build_care_scene.py -- apercu outdoor shade
#   blender -b -noaudio -P tool/build_care_scene.py -- complet plants monstera
#
# Options, dans cet ordre, toutes facultatives :
#   <apercu|complet> <all|indoor|outdoor|plants> [lumiere|plante] [--res N] [--samples N] [--out DOSSIER]
#
# L'emballage en WebP, la table des emplacements Dart et le recapitulatif
# des poids sont dans `tool/build_care_scene_assets.py`, qui appelle ce
# script.
# ============================================================
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import bpy  # noqa: E402
from clay_scene import purge, rendu_transparent, grain  # noqa: E402
from care_scene import common, room, outdoor, plants, props  # noqa: E402

GROUPES = ["indoor", "outdoor", "plants", "props"]


def _options(argv):
    mode, groupe, filtre = "complet", "all", None
    res, samples, dossier = 1024, 56, "/tmp/care_scene"
    libres = []
    i = 0
    while i < len(argv):
        a = argv[i]
        if a == "--res":
            res = int(argv[i + 1]); i += 2
        elif a == "--samples":
            samples = int(argv[i + 1]); i += 2
        elif a == "--out":
            dossier = argv[i + 1]; i += 2
        else:
            libres.append(a); i += 1
    if libres and libres[0] in ("apercu", "complet"):
        mode = libres.pop(0)
    if libres:
        groupe = libres.pop(0)
    if libres:
        filtre = libres.pop(0)
    return mode, groupe, filtre, res, samples, dossier


def _rend(chemin, res, samples):
    os.makedirs(os.path.dirname(chemin), exist_ok=True)
    rendu_transparent(res, samples)
    bpy.context.scene.render.filepath = chemin
    bpy.ops.render.render(write_still=True)
    grain(chemin)


def exporte_slots(dossier):
    """La table des emplacements : chaque slot, projete dans l'image par la
    camera fixe, en coordonnees fractionnaires lues par Flutter. C'est la
    geometrie de la piece qui fait foi — jamais une table accordee a la main
    cote application."""
    purge()
    cam, _, _, _ = common.camera_fixe()
    # L'humidificateur est pose a cote de la plante par un decalage d'ecran
    # (la projection orthographique est lineaire) : du cote interieur du
    # cadre, pour qu'il ne passe jamais derriere le pot ni dans un mur.
    haut = common.projette(cam, (0.0, 0.0, 0.55))
    base = common.projette(cam, (0.0, 0.0, 0.0))
    dz = haut[1] - base[1]
    humidifier = {}
    humidifier_top = {}
    for nom, (x, y) in common.SLOTS.items():
        sx, sy = common.projette(cam, (x, y, 0.0))
        cote = 1.0 if sx < 0.5 else -1.0
        hx, hy = sx + cote * 0.115, sy + 0.025
        humidifier[nom] = [hx, hy]
        humidifier_top[nom] = [hx, hy + dz]
    donnees = {
        "aspect": 1.0,
        "ancre": list(base),
        "slots": {nom: list(common.projette(cam, (x, y, 0.0)))
                  for nom, (x, y) in common.SLOTS.items()},
        "humidifier": humidifier,
        "humidifierTop": humidifier_top,
        "vent": list(common.projette(cam, props.AERATION)),
    }
    chemin = os.path.join(dossier, "slots.json")
    os.makedirs(dossier, exist_ok=True)
    with open(chemin, "w") as f:
        json.dump(donnees, f, indent=2, sort_keys=True)
    print("SLOTS -> %s" % chemin, flush=True)


def rendre_indoor(res, samples, dossier, filtre):
    for nom in room.VARIANTES:
        if filtre and nom != filtre:
            continue
        purge()
        bpy.context.scene.name = "indoor_" + nom
        _, Rv, Uv, Cv = common.camera_fixe()
        room.construire(nom, Rv, Uv, Cv)
        chemin = os.path.join(dossier, "indoor", "light", nom + ".png")
        _rend(chemin, res, samples)
        print("LUMIERE %s -> %s" % (nom, chemin), flush=True)


def rendre_outdoor(res, samples, dossier, filtre):
    for nom in outdoor.VARIANTES:
        if filtre and nom != filtre:
            continue
        purge()
        bpy.context.scene.name = "outdoor_" + nom
        _, Rv, Uv, Cv = common.camera_fixe()
        outdoor.construire(nom, Rv, Uv, Cv)
        chemin = os.path.join(dossier, "outdoor", "light", nom + ".png")
        _rend(chemin, res, samples)
        print("LUMIERE outdoor/%s -> %s" % (nom, chemin), flush=True)


def rendre_plantes(res, samples, dossier, filtre):
    for nom in plants.PLANTES:
        if filtre and nom != filtre:
            continue
        purge()
        bpy.context.scene.name = "plants_" + nom
        _, Rv, Uv, Cv = common.camera_fixe()
        plants.construire(nom, common.ANCRE_MONDE)
        common.eclairage_plante((0.0, 0.0, 1.0), Rv, Uv, Cv)
        chemin = os.path.join(dossier, "plants", nom + ".png")
        _rend(chemin, res, samples)
        print("PLANTE %s -> %s" % (nom, chemin), flush=True)


def rendre_props(res, samples, dossier, filtre):
    for nom, batisseur in props.PROPS.items():
        if filtre and nom != filtre:
            continue
        purge()
        bpy.context.scene.name = "props_" + nom
        _, Rv, Uv, Cv = common.camera_fixe()
        objets = batisseur()
        # Le centre de l'eclairage studio : l'objet, rendu seul, doit etre
        # lumineux quelle que soit la variante de la piece.
        z = sum((v.co.z for v in objets[0].data.vertices)) / max(len(objets[0].data.vertices), 1)
        centre = (objets[0].location.x, objets[0].location.y, z)
        common.eclairage_plante(centre, Rv, Uv, Cv)
        chemin = os.path.join(dossier, "props", nom + ".png")
        _rend(chemin, res, samples)
        print("PROP %s -> %s" % (nom, chemin), flush=True)


argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
MODE, GROUPE, FILTRE, RES, SAMPLES, DOSSIER = _options(argv)

if GROUPE not in GROUPES + ["all"]:
    sys.exit("groupe inconnu : %s (parmi %s)" % (GROUPE, ", ".join(GROUPES + ["all"])))

exporte_slots(DOSSIER)
if GROUPE in ("indoor", "all"):
    rendre_indoor(RES, SAMPLES, DOSSIER, FILTRE)
if GROUPE in ("outdoor", "all"):
    rendre_outdoor(RES, SAMPLES, DOSSIER, FILTRE)
if GROUPE in ("plants", "all"):
    rendre_plantes(RES, SAMPLES, DOSSIER, FILTRE)
if GROUPE in ("props", "all"):
    rendre_props(RES, SAMPLES, DOSSIER, FILTRE)

print("CARE_SCENE: %s (%s)" % (DOSSIER, MODE), flush=True)
