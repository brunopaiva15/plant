# ============================================================
# L'en-tête animé de la fiche App Store, et la ressource des résultats de
# recherche : le pot de l'icône, sur le vert de la marque, qui vit — la
# pousse ondule, le pot cligne des yeux, saute, et fait son clin d'œil
# d'ouverture (`LaunchSplash`).
#
#   python3 store/entete.py SORTIE [--blender CHEMIN] [--seulement header search]
#
# Le pot n'est pas animé dans Blender : 720 images en Cycles prendraient des
# heures. Blender rend une fois des calques au cadrage du lancement
# (tool/app_icon_scene.py, 2400 px) — le pot sans sa pousse mais avec son
# ombre, la pousse seule découpée par le pot et la terre, et chaque œil à
# trois moments de sa fermeture —, puis ce script les anime en 2D : la pousse
# se courbe depuis la terre, le pot s'écrase et s'étire sur sa base, les
# yeux se posent comme dans l'ouverture de l'app. Les calques se rangent
# dans SORTIE/calques et ne se rendent qu'une fois (environ 25 min sur
# quatre cœurs).
#
# Produit, aux formats d'App Store Connect :
#   header_21x9_3840x1646.mp4   en-tête : vidéo en boucle, 60 i/s, 12 s
#   header_21x9_3840x1646.png   en-tête : image fixe 21:9
#   header_16x9_5244x2950.png   en-tête ou recherche : image fixe 16:9
#   search_3x2_3840x2560.mp4    recherche : vidéo 3:2
#   search_3x2_1920x1280.mp4    recherche : la même, si la première est refusée
#
# Aucun texte : rien à traduire, les quatre fiches prennent les mêmes
# fichiers. Dépendances : pillow, numpy, scipy, ffmpeg ; Blender (ou le
# module bpy) pour les calques.
# ============================================================
import argparse
import math
import os
import shutil
import subprocess
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from scipy.ndimage import map_coordinates

RACINE = Path(__file__).resolve().parent.parent
SCENE = RACINE / "tool" / "app_icon_scene.py"

# --- calques ----------------------------------------------------------------

# Le cadrage du lancement (tool/render_app_icon.py, LANCEMENT), plus grand.
COTE = 2400
LANCEMENT = {"YEUX": "1", "FOND": "0", "POT_BAS": "-0.6", "CADRE": "0.84", "CIBLE_Z": "0.8", "RES": str(COTE)}
ECHANTILLONS = 128
# Les zones des yeux, de OEIL (tool/build_app_icon.py, 1024 px) mises à
# l'échelle ; celle de gauche est son miroir.
_k = COTE / 1024
OEIL_D = tuple(round(v * _k) for v in (497, 614, 673, 790))
OEIL_G = (COTE - OEIL_D[2], OEIL_D[1], COTE - OEIL_D[0], OEIL_D[3])
# Dans sa zone, l'image d'un œil est pleine jusqu'à ce rayon puis se fond
# dans le pot jusqu'au bord, comme OEIL_PLEIN.
OEIL_PLEIN = 56 / 176
FERMETURES = (50, 85, 100)

CALQUES = {
    "pot": {"CALQUE": "pot"},
    "pousse": {"CALQUE": "pousse"},
}
for _f in FERMETURES:
    CALQUES[f"oeil_d_{_f}"] = {"CALQUE": "pot", "CLIN": str(_f / 100), "ZONE": ",".join(map(str, OEIL_D))}
    CALQUES[f"oeil_g_{_f}"] = {"CALQUE": "pot", "CLIN_G": str(_f / 100), "ZONE": ",".join(map(str, OEIL_G))}


def rendre_calques(dossier, blender):
    dossier.mkdir(parents=True, exist_ok=True)
    for nom, variables in CALQUES.items():
        sortie = dossier / f"{nom}.png"
        if sortie.exists():
            continue
        print(f"Rendu de {nom}…", flush=True)
        env = {**os.environ, **LANCEMENT, **variables}
        subprocess.run([*blender, "-b", "--python", str(SCENE), "--", str(ECHANTILLONS), str(sortie)],
                       env=env, check=True, stdout=subprocess.DEVNULL)


def premult(img):
    a = np.asarray(img, dtype=np.float32) / 255
    a[..., :3] *= a[..., 3:4]
    return a


class Personnage:
    """Les calques du pot, prêts à composer : tableaux prémultipliés de 0 à 1."""

    def __init__(self, dossier):
        ouvrir = lambda nom: Image.open(dossier / f"{nom}.png").convert("RGBA")
        pot, pousse = ouvrir("pot"), ouvrir("pousse")
        # Tout se joue dans la boîte du pot et de sa pousse, élargie de quoi
        # laisser la pousse se courber et s'étirer : on y recadre les calques.
        a_pot = np.asarray(pot.getchannel("A")) > 128
        a_pousse = np.asarray(pousse.getchannel("A")) > 128
        ys, xs = np.nonzero(a_pot | a_pousse)
        m = 260
        self.zone = (max(xs.min() - m, 0), max(ys.min() - m, 0), min(xs.max() + m, COTE), min(ys.max() + 40, COTE))
        zx, zy = self.zone[:2]
        self.pot = premult(pot.crop(self.zone))
        self.cadre = (xs.min() - zx, ys.min() - zy, xs.max() - zx, ys.max() - zy)
        # La pousse, dans sa propre boîte : seule celle-ci se déforme.
        ys, xs = np.nonzero(a_pousse)
        bas = ys.max()
        self.boite = (max(xs.min() - m, 0), max(ys.min() - m, 0), min(xs.max() + m, COTE), bas + 2)
        bx, by = self.boite[:2]
        self.pousse = premult(pousse.crop(self.boite))
        self.boite_zone = (bx - zx, by - zy)
        # Le pied de la tige, là où elle sort de terre : le pivot de la courbure.
        self.pied = (xs[ys >= bas - 8].mean() - bx, float(bas - by))
        self.haut = float(ys.min() - zy)
        self.haut_pousse = float(bas - ys.min())
        # La base du pot : son point d'appui et sa largeur, pour l'ombre et
        # l'écrasement.
        ys, xs = np.nonzero(a_pot)
        self.bas = float(ys.max() - zy)
        ligne = xs[ys >= ys.max() - 12]
        self.base_x = float((ligne.min() + ligne.max()) / 2 - zx)
        self.base_l = float(ligne.max() - ligne.min())
        self.yeux = {}
        for cote, (x0, y0, x1, y1) in (("d", OEIL_D), ("g", OEIL_G)):
            zone = (x0 - zx, y0 - zy, x1 - zx, y1 - zy)
            masque = self._masque(zone)
            for f in FERMETURES:
                oeil = premult(ouvrir(f"oeil_{cote}_{f}").resize((x1 - x0, y1 - y0), Image.LANCZOS))
                self.yeux[(cote, f)] = (zone, oeil, masque)

    @staticmethod
    def _masque(zone):
        l, h = zone[2] - zone[0], zone[3] - zone[1]
        y, x = np.mgrid[0:h, 0:l]
        r = np.hypot(x - (l - 1) / 2, y - (h - 1) / 2)
        plein, bord = OEIL_PLEIN * l, l / 2
        m = np.clip((bord - r) / (bord - plein), 0, 1)
        return (m * m * (3 - 2 * m))[..., None].astype(np.float32)

    def image(self, etat):
        """Le pot à l'état [etat], dans sa zone des calques."""
        img = self.pot.copy()
        for cote in ("d", "g"):
            f = etat["yeux"][cote]
            if not f:
                continue
            (x0, y0, x1, y1), oeil, m = self.yeux[(cote, f)]
            img[y0:y1, x0:x1] = img[y0:y1, x0:x1] * (1 - m) + oeil * m
        pousse = self._courber(etat["courbure"], etat["pousse_y"])
        x, y = self.boite_zone
        h, l = pousse.shape[:2]
        zone = img[y:y + h, x:x + l]
        zone[:] = pousse + zone * (1 - pousse[..., 3:4])
        return img

    def _courber(self, angle, etirement):
        """La pousse courbée de [angle] degrés à la pointe, depuis la terre :
        chaque hauteur tourne autour du pied, d'autant plus qu'elle est haute ;
        [etirement] l'allonge ou la tasse verticalement depuis le pied."""
        h, l = self.pousse.shape[:2]
        px, py = self.pied
        hauteur = self.haut_pousse
        y, x = np.mgrid[0:h, 0:l].astype(np.float32)
        dy = (py - y) / etirement
        u = np.clip(dy / hauteur, 0, None)
        phi = np.radians(angle) * u ** 1.4
        c, s = np.cos(phi), np.sin(phi)
        dx = x - px
        # rotation inverse autour du pied (y vers le haut)
        sx = px + dx * c - dy * s
        sy = py - (dx * s + dy * c)
        sortie = np.empty_like(self.pousse)
        for k in range(4):
            sortie[..., k] = map_coordinates(self.pousse[..., k], [sy, sx], order=1, mode="constant", cval=0)
        return sortie


# --- l'animation ------------------------------------------------------------

BOUCLE = 12.0
FPS = 60
# Les moments, en secondes.
CLIGNEMENTS = (2.0, 10.1)
SAUT = 3.7
CLIN = 6.7


def adouci(u):
    u = min(max(u, 0.0), 1.0)
    return u * u * (3 - 2 * u)


def phase(t, de, a):
    return min(max((t - de) / (a - de), 0.0), 1.0)


def ease_out_cubic(u):
    return 1 - (1 - u) ** 3


def elastic_out(u, periode=0.4):
    # Curves.elasticOut de Flutter
    if u <= 0:
        return 0.0
    if u >= 1:
        return 1.0
    s = periode / 4
    return 2 ** (-10 * u) * math.sin((u - s) * 2 * math.pi / periode) + 1


def pas_a(u, pas, fin):
    """L'image de l'œil [u] secondes après le début d'un geste, ou None."""
    if u < 0 or u >= fin:
        return None
    image = None
    for debut, f in pas:
        if u >= debut:
            image = f
    return image


def yeux(t):
    """La fermeture de chaque œil (None : ouvert), en pas de 40 ms comme
    l'ouverture de l'app."""
    etat = {"d": None, "g": None}
    for debut in CLIGNEMENTS:
        # clignement : les deux yeux, vite, fermés 80 ms
        f = pas_a(t - debut, ((0, 50), (0.04, 100), (0.12, 50)), 0.16)
        if f:
            etat = {"d": f, "g": f}
    # clin d'œil : l'œil de droite, fermé 160 ms (les pas de `LaunchSplash`)
    f = pas_a(t - CLIN, ((0, 50), (0.04, 85), (0.08, 100), (0.24, 85), (0.28, 50)), 0.32)
    if f:
        etat["d"] = f
    return etat


def saut(t):
    """Le saut : (hauteur en fraction de la hauteur du pot, écrasement).
    L'écrasement est positif quand le pot se tasse, négatif quand il s'étire."""
    u = t - SAUT
    if u < 0 or u > 1.5:
        return 0.0, 0.0
    # 0–0,22 : il se ramasse ; 0,22–0,62 : en l'air ; puis il retombe et rebondit
    if u < 0.22:
        return 0.0, 0.10 * adouci(u / 0.22)
    if u < 0.62:
        v = (u - 0.22) / 0.40
        haut = SAUT_HAUT * 4 * v * (1 - v)
        etire = -0.07 * math.sin(math.pi * min(v * 1.6, 1)) * (1 - v)
        return haut, etire
    v = (u - 0.62) / 0.88
    return 0.0, 0.11 * (1 - elastic_out(v, 0.35))


def clin_ecrase(t):
    # celui de `LaunchSplash` : il s'écrase en fermant l'œil, tient, se relève
    ms = (t - CLIN) * 1000 + 200
    presse = ease_out_cubic(phase(ms, 200, 290)) * (1 - elastic_out(phase(ms, 440, 640)))
    return presse if 0 <= t - CLIN < 1 else 0.0


def etat(t):
    t %= BOUCLE
    w = 2 * math.pi / BOUCLE
    souffle = 0.006 * math.sin(3 * w * t)
    haut, ecrase = saut(t)
    presse = clin_ecrase(t)
    sy = (1 + souffle) * (1 - ecrase) * (1 - 0.05 * presse)
    sx = (1 - souffle * 0.5) * (1 + ecrase * 0.6) * (1 + 0.035 * presse)
    # La pousse : une brise lente, un frémissement, et le contrecoup du saut,
    # en retard sur le pot.
    _, ecrase_tard = saut(t - 0.07)
    courbure = 3.2 * math.sin(4 * w * t + 0.6) + 1.1 * math.sin(9 * w * t + 1.9)
    courbure += 7 * ecrase_tard * math.sin(4 * w * t + 2.2)
    pousse_y = 1 - 1.4 * ecrase_tard + 0.004 * math.sin(3 * w * t - 0.5)
    return {"yeux": yeux(t), "sx": sx, "sy": sy, "haut": haut, "courbure": courbure, "pousse_y": pousse_y}


# --- la composition ---------------------------------------------------------

BRAND = (53, 131, 84)
OMBRE = (18, 60, 36)


def fond(W, H):
    """Le vert de la marque et les deux disques pâles des têtes vertes, en
    haut à droite (store/compose.py, `background`), à l'échelle de la
    hauteur : sur un cadre large, la largeur les rendrait démesurés."""
    img = Image.new("RGBA", (W, H), BRAND + (255,))
    disques = Image.new("RGBA", (W, H), (255, 255, 255, 0))
    d = ImageDraw.Draw(disques)
    ref = min(W, H * 1.25)
    big, small = ref * 0.54, ref * 0.33
    d.ellipse((W + big * 0.12 - big, big * 0.2 - big, W + big * 0.12 + big, big * 0.2 + big), fill=(255, 255, 255, 18))
    d.ellipse((W - small * 0.15 - small, small * 0.55 - small, W - small * 0.15 + small, small * 0.55 + small), fill=(255, 255, 255, 14))
    img.alpha_composite(disques)
    return img


# L'App Store recadre fortement ces ressources : sur iPhone, il ne montre que
# le centre de l'en-tête et pose par-dessus la barre d'état, la Dynamic
# Island et les boutons retour, son et partage. Le pot tient donc dans la
# zone sûre du gabarit d'Apple (mesurée sur sa version Sketch, Apple ne
# publie pas de chiffres) : x, y, largeur, hauteur, pour chaque format.
ZONES_SURES = {
    (3840, 1646): (1097, 493, 1646, 661),   # en-tête 21:9
    (3840, 2560): (836, 765, 2168, 1030),   # recherche 3:2
    (5244, 2950): (1921, 660, 1402, 962),   # image 16:9, centrée plus haut
}
# La hauteur du saut, en fraction de celle du pot et de sa pousse (`saut`).
SAUT_HAUT = 0.13


class Cadre:
    def __init__(self, W, H, perso):
        self.W, self.H, self.p = W, H, perso
        x0, y0, x1, y1 = perso.cadre
        k = H / 1646
        zx, zy, zl, zh = ZONES_SURES.get((W, H), (W / 2 - 823 * k, 493 * k, 1646 * k, 661 * k))
        # Le pot et sa pousse, saut compris, remplissent la zone sûre ; au
        # repos, le pot se pose en bas de la zone, le saut monte dans le haut.
        haut = (y1 - y0) * (1 + SAUT_HAUT)
        self.echelle = float(0.96 * min(zl / (x1 - x0), zh / haut))
        self.ox = float(zx + zl / 2 - perso.base_x * self.echelle)
        bas = zy + zh - (zh - haut * self.echelle) / 2
        self.oy = float(bas - perso.bas * self.echelle)
        self.fond = fond(W, H)

    def image(self, t):
        p, e = self.p, etat(t)
        img = self.fond.copy()
        k = self.echelle
        bx, by = p.base_x * k + self.ox, p.bas * k + self.oy
        hauteur_pot = (p.bas - p.haut) * k
        # L'ombre de contact, qui rétrécit et pâlit quand le pot s'élève.
        lev = e["haut"] / SAUT_HAUT
        rx = p.base_l * k * 0.62 * e["sx"] * (1 - 0.35 * lev)
        ry = p.base_l * k * 0.07 * (1 - 0.35 * lev)
        flou = p.base_l * k * 0.05
        m = int(rx + 3 * flou)
        ombre = Image.new("RGBA", (2 * m, 2 * m), OMBRE + (0,))
        ImageDraw.Draw(ombre).ellipse((m - rx, m - ry * 1.2, m + rx, m + ry * 0.8),
                                       fill=OMBRE + (int(120 * (1 - 0.6 * lev)),))
        img.alpha_composite(ombre.filter(ImageFilter.GaussianBlur(flou)), (round(bx) - m, round(by) - m))
        # Le pot : écrasé ou étiré sur sa base, soulevé du saut. On ne
        # transforme que le rectangle qu'il occupe dans le cadre.
        perso = p.image(e)
        rgba = Image.fromarray(np.clip(perso * 255 + 0.5, 0, 255).astype(np.uint8), "RGBa")
        sx, sy = k * e["sx"], k * e["sy"]
        tx = bx - p.base_x * sx
        ty = by - e["haut"] * hauteur_pot - p.bas * sy
        x0, y0 = math.floor(tx), math.floor(ty)
        l, h = math.ceil(rgba.width * sx) + 2, math.ceil(rgba.height * sy) + 2
        # transformation inverse : du rectangle vers le calque
        inv = (1 / sx, 0, (x0 - tx) / sx, 0, 1 / sy, (y0 - ty) / sy)
        pose = rgba.transform((l, h), Image.Transform.AFFINE, inv, resample=Image.Resampling.BICUBIC)
        img.alpha_composite(pose.convert("RGBA"), (x0, y0))
        return img.convert("RGB")


def video(perso, W, H, sorties, dossier):
    cadre = Cadre(W, H, perso)
    images = round(BOUCLE * FPS)
    split = "".join(f"[s{i}]" for i in range(len(sorties)))
    chaines = []
    for i, (_, taille) in enumerate(sorties):
        mise = f"scale={taille[0]}:{taille[1]}:flags=lanczos:" if taille else "scale="
        chaines.append(f"[s{i}]{mise}out_color_matrix=bt709:out_range=tv,format=yuv420p[o{i}]")
    args = ["ffmpeg", "-y", "-loglevel", "error", "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{W}x{H}",
            "-framerate", str(FPS), "-i", "-", "-filter_complex", ";".join([f"[0:v]split={len(sorties)}{split}", *chaines])]
    for i, (nom, _) in enumerate(sorties):
        args += ["-map", f"[o{i}]", "-c:v", "libx264", "-profile:v", "high", "-preset", "slow", "-crf", "14",
                 "-maxrate", "60M", "-bufsize", "120M", "-g", str(FPS), "-r", str(FPS),
                 "-colorspace", "bt709", "-color_primaries", "bt709", "-color_trc", "bt709", "-color_range", "tv",
                 "-movflags", "+faststart", "-an", str(dossier / nom)]
    ff = subprocess.Popen(args, stdin=subprocess.PIPE)
    for i in range(images):
        ff.stdin.write(cadre.image(i / FPS).tobytes())
        if i % 60 == 0:
            print(f"{sorties[0][0]} : image {i}/{images}", flush=True)
    ff.stdin.close()
    if ff.wait():
        sys.exit("ffmpeg a échoué")
    for nom, _ in sorties:
        print("Vidéo écrite :", dossier / nom)


def main():
    parser = argparse.ArgumentParser(description="En-tête animé de la fiche App Store.")
    parser.add_argument("sortie", type=Path)
    parser.add_argument("--blender", default=shutil.which("blender") or "blender",
                        help="Blender, ou « python » d'un environnement qui a le module bpy et "
                             "un lanceur compatible (voir store/README.md)")
    parser.add_argument("--seulement", nargs="*", choices=("header", "search"))
    args = parser.parse_args()
    dossier = args.sortie
    rendre_calques(dossier / "calques", args.blender.split())
    perso = Personnage(dossier / "calques")
    voulu = args.seulement or ("header", "search")
    if "header" in voulu:
        # t = 0 : le pot au repos, les yeux ouverts.
        Cadre(5244, 2950, perso).image(0).save(dossier / "header_16x9_5244x2950.png")
        Cadre(3840, 1646, perso).image(0).save(dossier / "header_21x9_3840x1646.png")
        video(perso, 3840, 1646, [("header_21x9_3840x1646.mp4", None)], dossier)
    if "search" in voulu:
        video(perso, 3840, 2560, [("search_3x2_3840x2560.mp4", None),
                                  ("search_3x2_1920x1280.mp4", (1920, 1280))], dossier)


if __name__ == "__main__":
    main()
