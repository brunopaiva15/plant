#!/usr/bin/env python3
"""Applique les trois petites intégrations de la scène aux fichiers existants.

Ce script n'est utilisé que par le bootstrap de la branche de fonctionnalité :
les fichiers créés pour la fonctionnalité vivent déjà dans le dépôt. Il évite
de recopier à la main les gros fichiers existants via l'API GitHub.
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def replace(path: str, old: str, new: str) -> None:
    target = ROOT / path
    text = target.read_text(encoding="utf-8")
    if new in text:
        return
    if old not in text:
        raise SystemExit(f"Point d'insertion introuvable dans {path}")
    target.write_text(text.replace(old, new, 1), encoding="utf-8")


replace(
    "lib/features/species/presentation/care_guide_screen.dart",
    "import 'care_guide_copy.dart';\n",
    "import 'care_environment_hero.dart';\nimport 'care_guide_copy.dart';\n",
)

replace(
    "lib/features/species/presentation/care_guide_screen.dart",
    "        ?header,\n\n        SectionHeader(title: l10n.needsSection, padding: const EdgeInsets.only(bottom: Space.sm)),",
    "        ?header,\n\n        // Le diorama encode l'emplacement conseillé avant que la fiche ne\n        // détaille chacun de ses besoins. Il ne reflète jamais les mesures\n        // réelles de l'emplacement ou de la maison.\n        CareEnvironmentHero(profile: p, speciesName: speciesName),\n        const SizedBox(height: Space.lg),\n\n        SectionHeader(title: l10n.needsSection, padding: const EdgeInsets.only(bottom: Space.sm)),",
)

replace(
    "pubspec.yaml",
    "    - assets/cutting/succulent_segment/\n",
    "    - assets/cutting/succulent_segment/\n    # Dioramas isométriques des fiches d'entretien : décors lumineux indoor /\n    # outdoor et silhouettes clay, générés par tool/build_care_scene_assets.py.\n    - assets/care_scene/indoor/\n    - assets/care_scene/outdoor/\n    - assets/care_scene/plants/\n",
)

replace(
    "README.md",
    "| [docs/12-guides-de-multiplication.md](docs/12-guides-de-multiplication.md) | Guides de multiplication : archétypes de gestes, choix du guide, rendus Blender |\n",
    "| [docs/12-guides-de-multiplication.md](docs/12-guides-de-multiplication.md) | Guides de multiplication : archétypes de gestes, choix du guide, rendus Blender |\n| [docs/13-care-environment-scenes.md](docs/13-care-environment-scenes.md) | Dioramas isométriques des fiches d'entretien : mapping des besoins, Blender headless, assets |\n",
)

print("Intégration care environment appliquée.")
