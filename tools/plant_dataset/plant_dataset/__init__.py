"""Construction du jeu d'images pour la reconnaissance de plantes.

Le paquet est indépendant de l'application : il lit la liste des plantes
(`plants.csv`, exportée du catalogue de l'app), va chercher des images dont la
licence permet un usage commercial, les vérifie, les déduplique, les répartit
en train / validation / test, et tient un manifeste où chaque image garde sa
source, son auteur et sa licence.
"""

__version__ = '0.1.0'
