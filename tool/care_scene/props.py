# ============================================================
# Les props de la scene « environnement ideal » : les petits objets qui
# disent le climat sans un mot.
#
#   humidificateur  l'air humide — rendu seul au centre du monde, pose par
#                   l'application a cote de la plante (comme elle) ;
#   aeration        la grille qui souffle l'air a abriter — fixe, sur le mur
#                   du fond, rendue a sa place definitive dans le cadre.
#
# La vapeur de l'humidificateur et les lignes de flux ne sont PAS rendues :
# elles sont dessinees par l'application (reduced motion, contraste, et le
# flux doit passer a distance de la plante, qui bouge).
#
# Rien ne s'execute a l'import.
# ============================================================
from mathutils import Vector
import os, sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from clay_scene import revolve  # noqa: E402  — le chemin doit etre pose avant
from care_scene.common import PIECE_Y, boite, materiau  # noqa: E402

# La grille d'aération, sur le mur du fond : assez haute pour que le flux
# passe au-dessus de la plante, a droite pour ne pas concurrencer la fenetre.
AERATION = (1.20, PIECE_Y, 2.05)


def humidificateur():
    """Un petit humidificateur d'argile : corps creme, reservoir couleur
    d'eau, sortie sombre d'ou la vapeur s'echappe (dessinee par l'app)."""
    mats = {
        "corps": materiau("MAT_Humid_Corps", "F4EDE0", rough=0.60, relief=0.008),
        "eau": materiau("MAT_Humid_Eau", "9CC4DD", rough=0.42, relief=0.004),
        "encre": materiau("MAT_Humid_Encre", "4A3528", rough=0.60, relief=0.004),
    }
    objets = []
    # Le corps : un cylindre doux, un peu plus large a la base.
    corps_profil = [
        (0.0, 0.0), (0.185, 0.0), (0.215, 0.02), (0.235, 0.07),
        (0.240, 0.26), (0.225, 0.34), (0.185, 0.40), (0.10, 0.435), (0.0, 0.44),
    ]
    objets.append(revolve("Humid_Corps", corps_profil, 64, [mats["corps"]], 30.0))
    # Le reservoir : la bande couleur d'eau, legerement saillante.
    eau_profil = [(0.0, 0.105), (0.244, 0.105), (0.246, 0.215), (0.0, 0.215)]
    objets.append(revolve("Humid_Reservoir", eau_profil, 64, [mats["eau"]], 30.0))
    # La sortie de vapeur, au sommet.
    sortie_profil = [(0.0, 0.435), (0.052, 0.435), (0.058, 0.45), (0.052, 0.465), (0.0, 0.465)]
    objets.append(revolve("Humid_Sortie", sortie_profil, 32, [mats["encre"]], 24.0))
    return objets


def aeration():
    """La grille d'aération sur le mur du fond : un cadre creme et trois
    lamelles sombres. Fixe — rendue a sa place definitive."""
    mats = {
        "cadre": materiau("MAT_Aeration_Cadre", "FDFBF4", rough=0.55, relief=0.006),
        "lamelle": materiau("MAT_Aeration_Lamelle", "8A6B4F", rough=0.60, relief=0.006),
    }
    x, y, z = AERATION
    objets = [
        boite("Aeration_Cadre", (x, y - 0.03, z), (0.42, 0.07, 0.30), mats["cadre"], 0.03),
    ]
    for i in range(3):
        objets.append(
            boite("Aeration_Lamelle_%d" % (i + 1), (x, y - 0.065, z - 0.075 + i * 0.075),
                  (0.32, 0.025, 0.035), mats["lamelle"], 0.01),
        )
    return objets


PROPS = {
    "humidifier": humidificateur,
    "vent": aeration,
}
