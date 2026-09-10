# ============================================================
# Les icônes de l'application, composées à partir du master détouré.
#
#   python3 tool/build_app_icon.py
#
# Le master est `assets/icon/plant.png` : la monstera en papier découpé dans
# son pot, sur fond transparent, cadrée au plus juste. Tout le reste en
# dérive — les sources de `assets/icon/`, puis les déclinaisons d'iOS,
# d'Android et du web, c'est-à-dire ce que produit
# `dart run flutter_launcher_icons`, reproduit ici pour que l'icône se
# régénère sans chaîne Flutter installée.
#
# Ce que le script ne touche pas : les manifestes (Contents.json,
# ic_launcher.xml, manifest.json). Ils ne dépendent pas du dessin.
# ============================================================
import json
import math
from pathlib import Path

from PIL import Image

RACINE = Path(__file__).resolve().parent.parent
ICONES = RACINE / "assets" / "icon"
MASTER = ICONES / "plant.png"
COTE = 1024

# Largeur de la plante, en part du côté de l'icône. Le master étant plus
# large que haut, c'est la largeur qui commande : la hauteur suit.
#
#   PLEINE — iOS, Android hérité, web. La plante remplit le carré comme sur
#     les icônes système ; les pointes de feuilles s'arrêtent à 4 % des
#     bords, bien à l'intérieur du squircle d'iOS, dont le rayon d'angle
#     vaut 22 % du côté et n'entame que les coins.
#   ADAPTATIVE — avant-plan adaptatif d'Android. Le lanceur rogne 16 % de
#     chaque côté avant d'appliquer son masque, d'où la marge large.
#   MASQUABLE — icônes web « maskable ». Leur zone de sûreté est un disque
#     de 80 % du côté : tout ce qui déborde peut être rogné.
LARGEUR_PLEINE = 0.92
LARGEUR_ADAPTATIVE = 0.619
LARGEUR_MASQUABLE = 0.72

# Part du blanc vertical posée au-dessus de la plante. Un peu plus de la
# moitié : le pot pose sur le bas, les feuilles respirent vers le haut.
HAUT_PLEINE = 0.53
HAUT_CENTRE = 0.5

BLANC = (255, 255, 255, 255)
TRANSPARENT = (0, 0, 0, 0)

APPICONSET = RACINE / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
# Tailles absentes de Contents.json qu'Xcode ignore, mais que le générateur
# Flutter écrit tout de même : on les tient à jour pour ne pas laisser
# traîner une vieille plante dans le dépôt.
IOS_HERITE = (20, 29, 40, 76)

ANDROID_RES = RACINE / "android/app/src/main/res"
ANDROID_DENSITES = {
    "mdpi": 1,
    "hdpi": 1.5,
    "xhdpi": 2,
    "xxhdpi": 3,
    "xxxhdpi": 4,
}
WEB = RACINE / "web"


def poser(largeur, part_haute, fond):
    """La plante mise à l'échelle et posée sur une toile carrée."""
    master = Image.open(MASTER).convert("RGBA")
    large = round(COTE * largeur)
    haut = round(large * master.height / master.width)
    plante = master.resize((large, haut), Image.LANCZOS)
    toile = Image.new("RGBA", (COTE, COTE), fond)
    coin = ((COTE - large) // 2, math.floor((COTE - haut) * part_haute))
    # Sur fond blanc il faut le masque alpha ; sur fond transparent la copie
    # directe garde les couleurs du master sous les bords adoucis.
    toile.paste(plante, coin, plante if fond[3] else None)
    return toile


def silhouette(source):
    """La même forme, remplie de noir : l'icône thématique d'Android 13+."""
    noir = Image.new("RGBA", source.size, TRANSPARENT)
    noir.putalpha(source.getchannel("A"))
    return noir


def gris(source):
    """La même image en niveaux de gris : le mode teinté d'iOS 18 l'attend."""
    teinte = source.convert("RGB").convert("L").convert("RGB").convert("RGBA")
    teinte.putalpha(source.getchannel("A"))
    return teinte


def ecrire(source, chemin, cote, opaque):
    chemin.parent.mkdir(parents=True, exist_ok=True)
    image = source.resize((cote, cote), Image.LANCZOS)
    image.convert("RGB" if opaque else "RGBA").save(chemin)


def sources():
    """Les cinq images de `assets/icon/`, dont tout le reste dérive."""
    pleine = poser(LARGEUR_PLEINE, HAUT_PLEINE, BLANC)
    detouree = poser(LARGEUR_PLEINE, HAUT_PLEINE, TRANSPARENT)
    adaptative = poser(LARGEUR_ADAPTATIVE, HAUT_CENTRE, TRANSPARENT)
    return {
        # Sans alpha : l'App Store refuse une icône transparente.
        "icon.png": (pleine, True),
        "icon_dark.png": (pleine, True),
        # Fond transparent à la taille d'iOS : le système pose lui-même le
        # fond sombre du mode nuit et la teinte du mode teinté.
        "icon_ios_foreground.png": (detouree, False),
        "icon_foreground.png": (adaptative, False),
        "icon_monochrome.png": (silhouette(adaptative), False),
    }


def ios(pleine, detouree):
    """Le jeu d'icônes d'iOS, piloté par Contents.json."""
    teintee = gris(detouree)
    variantes = {"": (pleine, True), "Dark-": (detouree, False), "Tinted-": (teintee, False)}
    manifeste = json.loads((APPICONSET / "Contents.json").read_text())
    for entree in manifeste["images"]:
        nom = entree.get("filename")
        if not nom:
            continue
        cote = round(float(entree["size"].split("x")[0]) * int(entree["scale"].rstrip("x")))
        prefixe = next(p for p in ("Dark-", "Tinted-", "") if nom.startswith(f"Icon-App-{p}"))
        source, opaque = variantes[prefixe]
        ecrire(source, APPICONSET / nom, cote, opaque)
    for cote in IOS_HERITE:
        ecrire(pleine, APPICONSET / f"Icon-App-{cote}x{cote}@1x.png", cote, True)


def android(pleine, adaptative):
    for suffixe, echelle in ANDROID_DENSITES.items():
        ecrire(pleine, ANDROID_RES / f"mipmap-{suffixe}/ic_launcher.png", round(48 * echelle), True)
        dossier = ANDROID_RES / f"drawable-{suffixe}"
        ecrire(adaptative, dossier / "ic_launcher_foreground.png", round(108 * echelle), False)
        ecrire(silhouette(adaptative), dossier / "ic_launcher_monochrome.png", round(108 * echelle), False)


def web(pleine):
    masquable = poser(LARGEUR_MASQUABLE, HAUT_PLEINE, BLANC)
    for cote in (192, 512):
        ecrire(pleine, WEB / f"icons/Icon-{cote}.png", cote, True)
        ecrire(masquable, WEB / f"icons/Icon-maskable-{cote}.png", cote, True)
    ecrire(pleine, WEB / "favicon.png", 16, True)


def main():
    images = sources()
    for nom, (image, opaque) in images.items():
        image.convert("RGB" if opaque else "RGBA").save(ICONES / nom)
    pleine = images["icon.png"][0]
    ios(pleine, images["icon_ios_foreground.png"][0])
    android(pleine, images["icon_foreground.png"][0])
    web(pleine)
    print(f"Icônes régénérées depuis {MASTER.relative_to(RACINE)}")


if __name__ == "__main__":
    main()
