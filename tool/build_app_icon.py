# ============================================================
# Les icônes de l'application et l'écran de lancement, composés à partir
# des rendus 3D.
#
#   python3 tool/build_app_icon.py
#
# Les masters sont les calques de assets/icon/rendu/, rendus par
# tool/render_app_icon.py dans Blender : le pot d'argile et sa pousse, sur
# un fond sauge. Tout le reste en dérive — les sources de `assets/icon/`,
# les déclinaisons d'iOS, d'Android et du web (ce que produit
# `dart run flutter_launcher_icons`, reproduit ici pour que l'icône se
# régénère sans chaîne Flutter installée), le logo des écrans de lancement
# natifs et les images de l'animation d'ouverture (`LaunchSplash`).
#
# Ce que le script ne touche pas : les manifestes (Contents.json,
# ic_launcher.xml, manifest.json, LaunchScreen.storyboard). Ils ne dépendent
# pas du dessin.
# ============================================================
import json
import math
from pathlib import Path

from PIL import Image, ImageDraw

RACINE = Path(__file__).resolve().parent.parent
ICONES = RACINE / "assets" / "icon"
RENDUS = ICONES / "rendu"
SPLASH = RACINE / "assets" / "splash"
COTE = 1024

# La zone de l'œil de droite dans l'icône de 1024 px (gauche, haut, droite,
# bas) : les images du clin d'œil y sont découpées, et `LaunchSplash` les y
# repose. Même valeur que `LaunchSplash.eyeRect`.
OEIL = (488, 760, 712, 984)
# Dans cette zone, l'image du clin d'œil est pleine jusqu'à ce rayon, puis
# se fond dans le logo jusqu'au bord : le raccord ne se voit pas.
OEIL_PLEIN = 76

# Côté du logo sur l'écran de lancement, en points (iOS) ou en dp (Android).
# Même valeur que `LaunchSplash.logoSize`.
LOGO = 128
# Android 12 pose l'icône de lancement dans un cadre de 288 dp dont seul un
# disque de 192 dp se voit. Le squircle de 128 dp y tient entier.
CADRE_ANDROID_12 = 288

APPICONSET = RACINE / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
LAUNCHIMAGE = RACINE / "ios/Runner/Assets.xcassets/LaunchImage.imageset"
# Tailles absentes de Contents.json qu'Xcode ignore, mais que le générateur
# Flutter écrit tout de même : on les tient à jour pour ne pas laisser
# traîner une vieille icône dans le dépôt.
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

TRANSPARENT = (0, 0, 0, 0)
# Qualité des images de l'ouverture.
WEBP = 90


def rendu(nom):
    return Image.open(RENDUS / f"{nom}.png").convert("RGBA")


def masque_squircle(cote):
    """La forme des icônes d'iOS, une superellipse d'exposant 5, adoucie."""
    grand = cote * 4
    r = grand / 2
    points = []
    for i in range(720):
        t = i / 720 * 2 * math.pi
        c, s = math.cos(t), math.sin(t)
        points.append((r + r * math.copysign(abs(c) ** 0.4, c), r + r * math.copysign(abs(s) ** 0.4, s)))
    masque = Image.new("L", (grand, grand), 0)
    ImageDraw.Draw(masque).polygon(points, fill=255)
    return masque.resize((cote, cote), Image.LANCZOS)


def detourer(image):
    """L'icône découpée en squircle, coins transparents : le logo de lancement."""
    logo = image.copy()
    logo.putalpha(masque_squircle(image.width))
    return logo


def plumer(image):
    """Un disque plein de rayon OEIL_PLEIN, fondu jusqu'au bord de l'image."""
    cote = image.width
    masque = Image.new("L", (cote, cote), 0)
    centre = cote / 2
    pixels = masque.load()
    for y in range(cote):
        for x in range(cote):
            d = ((x + 0.5 - centre) ** 2 + (y + 0.5 - centre) ** 2) ** 0.5
            t = min(max((centre - d) / (centre - OEIL_PLEIN), 0), 1)
            pixels[x, y] = round(255 * t * t * (3 - 2 * t))
    plume = image.copy()
    plume.putalpha(masque)
    return plume


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
    image = source if source.width == cote else source.resize((cote, cote), Image.LANCZOS)
    image.convert("RGB" if opaque else "RGBA").save(chemin)


def centrer(source, cote_logo, cote_toile):
    """Le logo à `cote_logo`, au centre d'une toile transparente."""
    toile = Image.new("RGBA", (cote_toile, cote_toile), TRANSPARENT)
    logo = source.resize((cote_logo, cote_logo), Image.LANCZOS)
    coin = (cote_toile - cote_logo) // 2
    toile.paste(logo, (coin, coin))
    return toile


def sources():
    """Les sources de `assets/icon/`, dont tout le reste dérive."""
    icone = rendu("icone")
    adaptative = rendu("avant_plan_adaptatif")
    return {
        # Sans alpha : l'App Store refuse une icône transparente.
        "icon.png": (icone, True),
        "icon_dark.png": (icone, True),
        # Fond transparent au cadrage d'iOS : le système pose lui-même le
        # fond sombre du mode nuit et la teinte du mode teinté.
        "icon_ios_foreground.png": (rendu("avant_plan"), False),
        # Les deux calques de l'icône adaptative d'Android, pleins.
        "icon_foreground.png": (adaptative, False),
        "icon_background.png": (rendu("fond"), True),
        "icon_monochrome.png": (silhouette(adaptative), False),
    }


def ios(pleine, detouree, logo):
    """Le jeu d'icônes d'iOS, piloté par Contents.json, et le logo de lancement."""
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
    for suffixe, echelle in (("", 1), ("@2x", 2), ("@3x", 3)):
        ecrire(logo, LAUNCHIMAGE / f"LaunchImage{suffixe}.png", LOGO * echelle, False)


def android(pleine, avant_plan, fond, logo):
    for suffixe, echelle in ANDROID_DENSITES.items():
        ecrire(pleine, ANDROID_RES / f"mipmap-{suffixe}/ic_launcher.png", round(48 * echelle), True)
        dossier = ANDROID_RES / f"drawable-{suffixe}"
        cote = round(108 * echelle)
        ecrire(avant_plan, dossier / "ic_launcher_foreground.png", cote, False)
        ecrire(fond, dossier / "ic_launcher_background.png", cote, True)
        ecrire(silhouette(avant_plan), dossier / "ic_launcher_monochrome.png", cote, False)
        # L'écran de lancement : le logo seul jusqu'à Android 11, posé dans
        # son cadre de 288 dp à partir d'Android 12.
        ecrire(logo, dossier / "splash_logo.png", round(LOGO * echelle), False)
        cadre = centrer(logo, round(LOGO * echelle), round(CADRE_ANDROID_12 * echelle))
        ecrire(cadre, dossier / "splash_android12.png", cadre.width, False)


def web(pleine):
    # L'icône est pleine jusqu'aux bords : elle sert telle quelle de
    # « maskable », le pot et la pousse restant dans le disque de sûreté.
    for cote in (192, 512):
        ecrire(pleine, WEB / f"icons/Icon-{cote}.png", cote, True)
        ecrire(pleine, WEB / f"icons/Icon-maskable-{cote}.png", cote, True)
    ecrire(pleine, WEB / "favicon.png", 16, True)


def splash(logo):
    """Les images de `LaunchSplash` : le logo, puis l'œil qui se ferme.

    En WebP : le grain rend le PNG du logo presque deux fois plus lourd que
    tout le reste de l'ouverture. À cette qualité, l'écart avec l'écran natif
    reste sous le grain lui-même.
    """
    SPLASH.mkdir(parents=True, exist_ok=True)
    for ancien in SPLASH.glob("*.png"):
        ancien.unlink()
    logo.save(SPLASH / "logo.webp", quality=WEBP, method=6)
    for nom in ("clin_50", "clin_85", "clin_100"):
        plumer(rendu(nom)).save(SPLASH / f"{nom}.webp", quality=WEBP, method=6)


def main():
    images = sources()
    for nom, (image, opaque) in images.items():
        image.convert("RGB" if opaque else "RGBA").save(ICONES / nom)
    pleine = images["icon.png"][0]
    logo = detourer(pleine)
    ios(pleine, images["icon_ios_foreground.png"][0], logo)
    android(pleine, images["icon_foreground.png"][0], images["icon_background.png"][0], logo)
    web(pleine)
    splash(logo)
    print(f"Icônes régénérées depuis {RENDUS.relative_to(RACINE)}")


if __name__ == "__main__":
    main()
