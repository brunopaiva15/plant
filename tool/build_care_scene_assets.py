#!/usr/bin/env python3
"""Régénère les scènes d'environnement idéal, de Blender au WebP livré.

Une seule commande fait tout : trouver Blender, rendre les couches sous
`/tmp` (ou le dossier donné), les convertir en WebP transparents dans
`assets/care_scene/`, régénérer la table Dart des emplacements de plante,
composer une planche contact dans le dossier de rendu, et afficher le poids.

    python3 tool/build_care_scene_assets.py                # tout, en qualité livrée
    python3 tool/build_care_scene_assets.py --preview      # aperçu rapide + planche contact
    python3 tool/build_care_scene_assets.py indoor plants  # deux groupes seulement
    python3 tool/build_care_scene_assets.py --only monstera
    python3 tool/build_care_scene_assets.py --poids        # juste le récapitulatif

Blender est cherché dans le PATH, puis aux endroits usuels. Rien n'est
installé, rien n'est modifié hors du dépôt et du dossier de rendu. La
planche contact reste dans le dossier de rendu : elle n'est pas livrée.
"""
import argparse
import glob
import json
import os
import shutil
import subprocess
import sys

RACINE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SCRIPT = os.path.join(RACINE, "tool", "build_care_scene.py")
SORTIE = os.path.join(RACINE, "assets", "care_scene")
DART = os.path.join(RACINE, "lib", "features", "species", "application", "care_environment_slots.dart")

GROUPES = ["indoor", "outdoor", "plants", "props"]
# Miroirs de room.VARIANTES, plants.PLANTES et props.PROPS, pour valider
# --only sans lancer Blender.
LUMIERES = ["shade", "low_light", "indirect", "bright_indirect", "some_sun", "full_sun"]
PLANTES = ["monstera", "broad_leaf", "upright_leaf", "vine", "fern", "rosette", "cactus", "conifer", "orchid"]
PROPS = ["humidifier", "vent"]

# Le grain d'argile reste net à ce niveau ; en dessous, il se lisse.
QUALITE = 80


def trouve_blender():
    """Le binaire Blender, ou rien. On cherche, on n'installe pas."""
    trouve = shutil.which("blender")
    if trouve:
        return trouve
    pistes = [
        "/usr/local/bin/blender",
        "/usr/bin/blender",
        "/snap/bin/blender",
        "/Applications/Blender.app/Contents/MacOS/Blender",
        os.path.expanduser("~/blender/blender"),
    ]
    pistes += sorted(glob.glob("/opt/blender*/blender"))
    for p in pistes:
        if os.path.isfile(p) and os.access(p, os.X_OK):
            return p
    return None


def rend(blender, groupe, dossier, res, samples, apercu, filtre):
    argv = [
        blender, "-b", "-noaudio", "-P", SCRIPT, "--",
        "apercu" if apercu else "complet", groupe,
    ]
    if filtre:
        argv.append(filtre)
    argv += ["--res", str(res), "--samples", str(samples), "--out", dossier]
    print("→ %s" % groupe, flush=True)
    r = subprocess.run(argv, capture_output=True, text=True)
    if r.returncode != 0:
        queue = (r.stdout.splitlines()[-30:] + r.stderr.splitlines()[-10:])
        sys.stderr.write("\n".join(queue) + "\n")
        sys.exit("Blender a échoué sur %s (code %d)" % (groupe, r.returncode))
    for ligne in r.stdout.splitlines():
        if ligne.startswith(("LUMIERE ", "PLANTE ", "SLOTS ")):
            print("   " + ligne, flush=True)


def emballe(groupe, dossier, qualite):
    """Convertit chaque PNG rendu en WebP transparent, sous
    `assets/care_scene/<groupe>/`."""
    from PIL import Image

    source = os.path.join(dossier, groupe)
    if not os.path.isdir(source):
        return []
    faits = []
    for chemin in sorted(glob.glob(os.path.join(source, "**", "*.png"), recursive=True)):
        rel = os.path.relpath(chemin, source)
        cible = os.path.join(SORTIE, groupe, os.path.splitext(rel)[0] + ".webp")
        os.makedirs(os.path.dirname(cible), exist_ok=True)
        im = Image.open(chemin).convert("RGBA")
        im.save(cible, quality=qualite, method=6)
        im.close()
        faits.append((os.path.join(groupe, os.path.splitext(rel)[0] + ".webp"), os.path.getsize(cible)))
    return faits


def genere_dart(dossier):
    """La table des emplacements, de `slots.json` (la géométrie projetée par
    la camera fixe) vers une constante Dart. La géométrie fait foi : ce
    fichier est régénéré à chaque construction."""
    chemin = os.path.join(dossier, "slots.json")
    if not os.path.isfile(chemin):
        return
    with open(chemin) as f:
        donnees = json.load(f)

    def paire(xy):
        return "(%.5f, %.5f)" % (xy[0], xy[1])

    lignes = [
        "// Généré par tool/build_care_scene_assets.py — ne pas éditer à la main.",
        "//",
        "// Positions des emplacements de plante dans le cadre de la scène",
        "// d'environnement idéal, en coordonnées fractionnaires (x depuis la",
        "// gauche, y depuis le haut). La géométrie de tool/care_scene/room.py,",
        "// projetée par la caméra fixe, est la source de vérité : ce fichier est",
        "// régénéré à chaque construction des assets.",
        "abstract final class CareEnvironmentSlots {",
        "  /// Format du cadre (largeur / hauteur).",
        "  static const double aspect = %.2f;" % donnees["aspect"],
        "",
        "  /// Point d'ancrage de la plante dans son image : la base du pot,",
        "  /// rendue au centre du monde.",
        "  static const (double, double) anchor = %s;" % paire(donnees["ancre"]),
        "",
        "  /// Les emplacements, nommés comme les valeurs de `CarePlantSlot`.",
        "  static const Map<String, (double, double)> slots = <String, (double, double)>{",
    ]
    for nom in sorted(donnees["slots"]):
        lignes.append("    '%s': %s," % (nom, paire(donnees["slots"][nom])))
    lignes += ["  };", "}", ""]

    def carte(nom, valeurs):
        bloc = [
            "  /// %s" % nom,
            "  static const Map<String, (double, double)> %s = <String, (double, double)>{" % valeurs[0],
        ]
        for slot in sorted(valeurs[1]):
            bloc.append("    '%s': %s," % (slot, paire(valeurs[1][slot])))
        bloc.append("  };")
        return bloc

    lignes = lignes[:-2]
    lignes += carte(
        "L'humidificateur, posé à côté de la plante, par emplacement.",
        ("humidifier", donnees["humidifier"]),
    )
    lignes.append("")
    lignes += carte(
        "Le haut de l'humidificateur, d'où part la vapeur, par emplacement.",
        ("humidifierTop", donnees["humidifierTop"]),
    )
    lignes += [
        "",
        "  /// La grille d'aération, sur le mur du fond.",
        "  static const (double, double) vent = %s;" % paire(donnees["vent"]),
        "}",
        "",
    ]
    os.makedirs(os.path.dirname(DART), exist_ok=True)
    with open(DART, "w") as f:
        f.write("\n".join(lignes))
    # Le fichier sort brut ; `dart format` le met au format du dépôt quand le
    # SDK est là — sinon il reste lisible tel quel.
    if shutil.which("dart"):
        subprocess.run(["dart", "format", DART], capture_output=True)
    print("   slots → %s" % os.path.relpath(DART, RACINE), flush=True)


def planche(dossier):
    """La planche contact : les six lumieres sur trois colonnes, puis les
    plantes, sur fond gris pour lire la transparence. Reste dans le dossier
    de rendu."""
    from PIL import Image

    lumieres = [os.path.join(dossier, "indoor", "light", nom + ".png") for nom in LUMIERES]
    lumieres += [os.path.join(dossier, "outdoor", "light", nom + ".png") for nom in LUMIERES]
    lumieres = [p for p in lumieres if os.path.isfile(p)]
    plantes = sorted(glob.glob(os.path.join(dossier, "plants", "*.png")))
    plantes += sorted(glob.glob(os.path.join(dossier, "props", "*.png")))
    if not lumieres and not plantes:
        return None
    cellule, cols = 384, 3
    rangs = ((len(lumieres) + cols - 1) // cols) + ((len(plantes) + cols - 1) // cols)
    feuille = Image.new("RGBA", (cols * cellule, max(rangs, 1) * cellule), (138, 138, 138, 255))

    def colle(chemins, decalage):
        for i, p in enumerate(chemins):
            im = Image.open(p).convert("RGBA").resize((cellule, cellule))
            feuille.paste(im, ((i % cols) * cellule, (decalage + i // cols) * cellule), im)
            im.close()

    colle(lumieres, 0)
    if plantes:
        colle(plantes, (len(lumieres) + cols - 1) // cols)
    chemin = os.path.join(dossier, "contact_sheet.png")
    feuille.save(chemin)
    return chemin


def poids():
    """Le récapitulatif : ce que pèse chaque groupe, et le total. Le budget
    de la fonctionnalité est de 8 Mo."""
    total = 0
    print()
    if not os.path.isdir(SORTIE):
        print("(aucun asset livré)")
    for groupe in sorted(os.listdir(SORTIE)) if os.path.isdir(SORTIE) else []:
        dossier = os.path.join(SORTIE, groupe)
        if not os.path.isdir(dossier):
            continue
        p = sum(os.path.getsize(f) for f in glob.glob(os.path.join(dossier, "**", "*.webp"), recursive=True))
        total += p
        print("%-18s %6.2f Mo" % (groupe + ":", p / 1e6))
    print("%-18s %6.2f Mo" % ("TOTAL:", total / 1e6))
    print("%-18s %6.2f Mo" % ("budget:", 8.0))


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("groupes", nargs="*", help="groupes à régénérer : %s (par défaut : tous)" % ", ".join(GROUPES))
    ap.add_argument("--preview", action="store_true", help="rendu rapide 512/16, pour juger la scène")
    ap.add_argument("--only", help="une seule lumière (%s) ou plante (%s)" % (", ".join(LUMIERES), ", ".join(PLANTES)))
    ap.add_argument("--res", type=int, help="résolution (défaut : 1024, 512 en --preview)")
    ap.add_argument("--samples", type=int, help="échantillons Cycles (défaut : 56, 16 en --preview)")
    ap.add_argument("--q", type=int, default=QUALITE, help="qualité WebP (0-100)")
    ap.add_argument("--out", default="/tmp/care_scene", help="dossier de rendu, hors dépôt")
    ap.add_argument("--poids", action="store_true", help="afficher seulement le poids des assets livrés")
    args = ap.parse_args()

    if args.poids:
        poids()
        return

    groupes = args.groupes or GROUPES
    for g in groupes:
        if g not in GROUPES:
            sys.exit("groupe inconnu : %s (parmi %s)" % (g, ", ".join(GROUPES)))
    filtre = None
    if args.only:
        if args.only in LUMIERES:
            groupes, filtre = ["indoor", "outdoor"], args.only
        elif args.only in PLANTES:
            groupes, filtre = ["plants"], args.only
        elif args.only in PROPS:
            groupes, filtre = ["props"], args.only
        else:
            sys.exit("inconnu : %s (ni lumière %s, ni plante %s, ni prop %s)" % (args.only, LUMIERES, PLANTES, PROPS))

    res = args.res or (512 if args.preview else 1024)
    samples = args.samples or (16 if args.preview else 56)

    blender = trouve_blender()
    if not blender:
        sys.exit("Blender est introuvable. Installez-le, ou mettez-le dans le PATH.")
    version = subprocess.run([blender, "--version"], capture_output=True, text=True).stdout.splitlines()
    print("Blender : %s (%s)" % (version[0].strip() if version else "?", blender))

    for groupe in groupes:
        rend(blender, groupe, args.out, res, samples, args.preview, filtre)
        # En aperçu, on juge la scène sur la planche contact ; les assets
        # livrés ne sont pas remplacés par des rendus de moindre qualité.
        if args.preview:
            continue
        for rel, taille in emballe(groupe, args.out, args.q):
            print("   %-40s %5.0f ko" % (rel, taille / 1024), flush=True)

    genere_dart(args.out)
    chemin = planche(args.out)
    if chemin:
        print("planche contact : %s" % chemin)

    poids()


if __name__ == "__main__":
    main()
