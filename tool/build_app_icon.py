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
# régénère sans chaîne Flutter installée), le pot des écrans de lancement
# natifs et les images de l'animation d'ouverture (`LaunchSplash`).
#
# Ce que le script ne touche pas : les manifestes (Contents.json,
# ic_launcher.xml, manifest.json, LaunchScreen.storyboard). Ils ne dépendent
# pas du dessin.
# ============================================================
import json
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

RACINE = Path(__file__).resolve().parent.parent
ICONES = RACINE / "assets" / "icon"
RENDUS = ICONES / "rendu"
SPLASH = RACINE / "assets" / "splash"
DART_CONTOUR = RACINE / "lib" / "app" / "launch_silhouette.dart"
COTE = 1024

# La zone de l'œil de droite dans le rendu du lancement, de 1024 px (gauche,
# haut, droite, bas) : les images du clin d'œil y sont découpées, et
# `LaunchSplash` les y repose. Même valeur que `LaunchSplash.eyeRect`.
OEIL = (497, 614, 673, 790)
# Dans cette zone, l'image du clin d'œil est pleine jusqu'à ce rayon, puis
# se fond dans le logo jusqu'au bord : le raccord ne se voit pas.
OEIL_PLEIN = 56

# L'écran de lancement : le pot raccourci au centre, sur un sauge uni pris au
# milieu du dégradé de l'icône. Même valeurs que `LaunchSplash.logoSize` et
# `LaunchSplash.background`, et que les couleurs `splash_background`
# d'Android et `LaunchBackground` d'iOS.
LOGO = 160
SAUGE = "#459765"
# Android 12 pose l'icône de lancement dans un cadre de 288 dp dont seul un
# disque de 192 dp se voit. Le pot, feuilles comprises, tient dans le cercle
# inscrit de son image : à 160 dp, il reste loin du bord de ce disque.
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


def ombrer(pot):
    """Le pot posé sur une ombre de contact douce, sous sa base.

    Blender en rendrait une vraie, mais la lampe principale l'allonge hors du
    cadre, et une ombre coupée au bord de l'image se verrait sur le fond uni.
    """
    alpha = pot.getchannel("A").point(lambda v: 255 if v > 128 else 0)
    gauche, _, droite, bas = alpha.getbbox()
    # Largeur de la base : l'étendue opaque juste au-dessus du bas.
    ligne = alpha.crop((0, bas - 12, pot.width, bas - 11)).getbbox()
    base = (ligne[2] - ligne[0]) if ligne else (droite - gauche)
    centre = (ligne[0] + ligne[2]) / 2 if ligne else (gauche + droite) / 2
    ombre = Image.new("RGBA", pot.size, TRANSPARENT)
    rx, ry = base * 0.62, base * 0.07
    ImageDraw.Draw(ombre).ellipse((centre - rx, bas - ry * 1.2, centre + rx, bas + ry * 0.8), fill=(18, 60, 36, 120))
    ombre = ombre.filter(ImageFilter.GaussianBlur(base * 0.05))
    ombre.alpha_composite(pot)
    return ombre


def contour(image, cote=512, tolerance=0.6):
    """Le contour du pot, en polygone : la fenêtre de l'ouverture.

    `LaunchSplash` perce le fond de cette forme au lieu d'y découper l'image
    par un mode de fusion : sur l'iPhone, le moteur de rendu remplissait la
    découpe de noir. Un tracé, lui, se dessine partout pareil. Le pot, la
    tige et les feuilles se touchent : un seul contour extérieur les prend
    tous. On le suit pixel à pixel (voisinage de Moore) sur une version
    réduite de l'image, puis on le simplifie (Douglas-Peucker) à
    `tolerance` pixel près. Les points sont rendus entre 0 et 1.
    """
    alpha = image.getchannel("A").resize((cote, cote), Image.LANCZOS).point(lambda v: 255 if v > 128 else 0)
    px = alpha.load()

    def plein(x, y):
        return 0 <= x < cote and 0 <= y < cote and px[x, y] > 0

    depart = next((x, y) for y in range(cote) for x in range(cote) if plein(x, y))
    voisins = [(-1, 0), (-1, -1), (0, -1), (1, -1), (1, 0), (1, 1), (0, 1), (-1, 1)]
    p, arriere, trace = depart, (depart[0] - 1, depart[1]), [depart]
    while True:
        k = voisins.index((arriere[0] - p[0], arriere[1] - p[1]))
        for i in range(1, 9):
            d = voisins[(k + i) % 8]
            q = (p[0] + d[0], p[1] + d[1])
            if plein(*q):
                a = voisins[(k + i - 1) % 8]
                arriere, p = (p[0] + a[0], p[1] + a[1]), q
                break
        if p == depart:
            break
        trace.append(p)

    def simplifier(points):
        if len(points) < 3:
            return points
        (x1, y1), (x2, y2) = points[0], points[-1]
        longueur = math.hypot(x2 - x1, y2 - y1) or 1e-9
        ecarts = [abs((y2 - y1) * x - (x2 - x1) * y + x2 * y1 - y2 * x1) / longueur for x, y in points[1:-1]]
        i = max(range(len(ecarts)), key=ecarts.__getitem__)
        if ecarts[i] <= tolerance:
            return [points[0], points[-1]]
        return simplifier(points[: i + 2])[:-1] + simplifier(points[i + 1 :])

    # Le contour est fermé : on le coupe en deux au point le plus éloigné du
    # départ pour que la simplification ait deux extrémités fixes.
    loin = max(range(len(trace)), key=lambda i: math.dist(trace[i], depart))
    points = simplifier(trace[: loin + 1])[:-1] + simplifier(trace[loin:] + [depart])[:-1]
    return [((x + 0.5) / cote, (y + 0.5) / cote) for x, y in points]


def ecrire_contour(points):
    lignes = [f"  {x:.4f}, {y:.4f}," for x, y in points]
    DART_CONTOUR.write_text(
        "// Généré par tool/build_app_icon.py — ne pas modifier à la main.\n"
        "//\n"
        "// Le contour du pot de l'ouverture, en coordonnées de 0 à 1 dans son\n"
        "// image (x, y, x, y…) : la fenêtre que `LaunchSplash` perce dans le fond.\n"
        "\n"
        "const launchSilhouette = <double>[\n" + "\n".join(lignes) + "\n];\n"
    )


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
        # L'écran de lancement : le pot seul jusqu'à Android 11, posé dans
        # son cadre de 288 dp à partir d'Android 12.
        ecrire(logo, dossier / "splash_logo.png", round(LOGO * echelle), False)
        cadre = centrer(logo, round(LOGO * echelle), round(CADRE_ANDROID_12 * echelle))
        ecrire(cadre, dossier / "splash_android12.png", cadre.width, False)


def notification(lancement):
    """La petite icône de la barre d'état d'Android : 24 dp, blanche.

    Android n'en garde que l'alpha et la teinte lui-même. L'icône de
    l'application, en couleur, y deviendrait un carré blanc : c'est le pot
    raccourci de l'écran de lancement, en silhouette, qui s'y pose — entier,
    là où celui de l'icône adaptative continue sous le masque.
    """
    blanc = Image.new("RGBA", lancement.size, (255, 255, 255, 0))
    blanc.putalpha(lancement.getchannel("A"))
    forme = blanc.crop(blanc.getchannel("A").getbbox())
    for suffixe, echelle in ANDROID_DENSITES.items():
        # 24 dp, dont 2 de marge de chaque côté : la zone active que
        # préconisent les consignes d'Android pour les icônes de notification.
        cote, utile = round(24 * echelle), round(20 * echelle)
        rapport = utile / max(forme.size)
        dessin = forme.resize((max(1, round(forme.width * rapport)), max(1, round(forme.height * rapport))), Image.LANCZOS)
        toile = Image.new("RGBA", (cote, cote), (255, 255, 255, 0))
        toile.paste(dessin, ((cote - dessin.width) // 2, (cote - dessin.height) // 2))
        chemin = ANDROID_RES / f"drawable-{suffixe}/ic_stat_auxine.png"
        chemin.parent.mkdir(parents=True, exist_ok=True)
        toile.save(chemin)


def web(pleine):
    # L'icône est pleine jusqu'aux bords : elle sert telle quelle de
    # « maskable », le pot et la pousse restant dans le disque de sûreté.
    for cote in (192, 512):
        ecrire(pleine, WEB / f"icons/Icon-{cote}.png", cote, True)
        ecrire(pleine, WEB / f"icons/Icon-maskable-{cote}.png", cote, True)
    ecrire(pleine, WEB / "favicon.png", 16, True)


def splash(logo):
    """Les images de `LaunchSplash` : le pot, puis l'œil qui se ferme.

    En WebP : le grain rend le PNG du logo presque deux fois plus lourd que
    tout le reste de l'ouverture. À cette qualité, l'écart avec l'écran natif
    reste sous le grain lui-même.
    """
    SPLASH.mkdir(parents=True, exist_ok=True)
    for ancien in SPLASH.glob("*.png"):
        ancien.unlink()
    logo.save(SPLASH / "logo.webp", quality=WEBP, method=6)
    for clin in ("50", "85", "100"):
        plumer(rendu(f"lancement_clin_{clin}")).save(SPLASH / f"clin_{clin}.webp", quality=WEBP, method=6)


def main():
    images = sources()
    for nom, (image, opaque) in images.items():
        image.convert("RGB" if opaque else "RGBA").save(ICONES / nom)
    pleine = images["icon.png"][0]
    logo = ombrer(rendu("lancement"))
    ios(pleine, images["icon_ios_foreground.png"][0], logo)
    android(pleine, images["icon_foreground.png"][0], images["icon_background.png"][0], logo)
    notification(rendu("lancement"))
    web(pleine)
    splash(logo)
    ecrire_contour(contour(rendu("lancement")))
    print(f"Icônes régénérées depuis {RENDUS.relative_to(RACINE)}")


if __name__ == "__main__":
    main()
