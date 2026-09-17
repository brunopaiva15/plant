# ============================================================
# Les props de la scene « environnement ideal » : les petits objets qui
# disent le climat sans un mot, et le gueridon.
#
#   humidificateur  l'air humide — rendu seul au centre du monde, pose par
#                   l'application a cote de la plante (comme elle).
#   pedestal        le gueridon — rendu seul au centre du monde, pose par
#                   l'application sur l'emplacement lumineux ; la plante
#                   vient se poser sur son plateau. Comme la plante, il
#                   garde le meme eclat d'une variante a l'autre : c'est le
#                   decor qui porte la lumiere.
#
# L'air qui bouge n'a pas de prop : un courant d'air entre par la fenetre, il
# ne sort pas d'une machine. Ses lignes de flux, comme la vapeur de
# l'humidificateur, sont dessinees par l'application (reduced motion,
# contraste, et le flux doit passer a distance de la plante, qui bouge).
#
# Rien ne s'execute a l'import.
# ============================================================
from mathutils import Vector
import os, sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from clay_scene import revolve  # noqa: E402  — le chemin doit etre pose avant
from care_scene.common import materiau  # noqa: E402


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


def gueridon():
    """Le guéridon rond de la pièce : un plateau en bois clair sur un pied
    central. Rendu seul au centre du monde ; l'application pose sa base sur
    l'emplacement lumineux et la plante sur son plateau."""
    bois = materiau("MAT_Gueridon_Bois", "C99A6B", rough=0.60, relief=0.010)
    profil = [(0.0, 0.0), (0.30, 0.0), (0.325, 0.035), (0.11, 0.07),
              (0.085, 0.11), (0.085, 0.50), (0.29, 0.54), (0.315, 0.575),
              (0.30, 0.60), (0.0, 0.605)]
    return [revolve("Gueridon", profil, 64, [bois], 30.0)]


PROPS = {
    "humidifier": humidificateur,
    "pedestal": gueridon,
}
