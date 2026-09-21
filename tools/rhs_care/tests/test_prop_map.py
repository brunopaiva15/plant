import unittest

from extract_prop import page_fits
from prop_map import apply_prop, methods_from_rhs, parse_propagation
from sourcing import dart_map, fields_of, name_of


ALOE = (
    "Propagation Propagate by seed as soon as ripe, or propagate by "
    "separating offsets in spring or early summer. Root offsets in cactus "
    "potting compost Pruning No pruning required"
)
MONSTERA = (
    "Propagation Propagate by seed, root tip or stem cuttings "
    "Suggested planting locations and garden types"
)
TOMATO = (
    "Propagation Propagate by seed. See sowing vegetable seeds or sowing "
    "seeds indoors for further advice Pruning Remove sideshoots"
)
PHALAENOPSIS = (
    "Propagation Cuttings or offshoots (keikis) may root successfully when "
    "roots are 2cm long Suggested planting locations"
)
SANSEVIERIA = (
    "Propagation Propagate by leaf cuttings, suckers or division "
    "Suggested planting locations"
)
ZZ = "Propagation Propagate by leaf cuttings, using single leaflets Pruning "
CAMELLIA = "Propagation Propagate by semi- hardwood cuttings Pruning "
LAVENDER = (
    "Propagation Propagate by seed sown in a cold frame in spring, or by "
    "semi- hardwood cuttings in summer. See our video how to take lavender "
    "cuttings for more advice Pests May be susceptible"
)
CRASSULA = (
    "Propagation Propagate by seed sown as soon as ripe or by offsets or by "
    "root, stem or leaf cuttings in spring Suggested planting"
)
NOTES = "Propagation See cultivation notes Pests See cultivation notes "
ADANSONII = (
    "Propagation Propagate by sowing seed at 18-24°C as soon as ripe, take "
    "tip or leaf cuttings with bottom heat in summer, layer in autumn "
    "Suggested planting locations"
)
GRAFT = "Propagation Propagate by grafting Pruning pruning group 1 Pests "
NAV = (
    "How to propagate Beginners' guide Propagation Propagate by seed "
    "Pruning No pruning required"
)


class ParseTest(unittest.TestCase):
    def test_skips_nav(self):
        p = parse_propagation(NAV)
        self.assertIsNotNone(p)
        self.assertIn("propagate by seed", p["raw"].lower())

    def test_stops_before_pruning(self):
        p = parse_propagation(ALOE)
        self.assertNotIn("pruning", p["raw"].lower())

    def test_cultivation_notes_unread(self):
        self.assertIsNone(parse_propagation(NOTES))

    def test_empty_page(self):
        self.assertIsNone(parse_propagation("Hardiness Close modal Growing conditions"))


class MapTest(unittest.TestCase):
    def test_aloe_seed_and_offsets(self):
        p = parse_propagation(ALOE)
        self.assertEqual(methods_from_rhs(p["raw"]), ["offsets", "seed"])

    def test_monstera_seed_and_stem(self):
        p = parse_propagation(MONSTERA)
        self.assertEqual(methods_from_rhs(p["raw"]), ["stemCutting", "seed"])

    def test_tip_cutting_is_a_stem_cutting(self):
        # « take tip or leaf cuttings » : la bouture de tête compte, sans
        # quoi le monstera adansonii ne se multiplierait que par la feuille.
        p = parse_propagation(ADANSONII)
        self.assertEqual(
            methods_from_rhs(p["raw"]),
            ["stemCutting", "leafCutting", "seed"],
        )

    def test_tomato_seed_only(self):
        p = parse_propagation(TOMATO)
        self.assertEqual(methods_from_rhs(p["raw"]), ["seed"])

    def test_phalaenopsis_keiki_not_stem(self):
        p = parse_propagation(PHALAENOPSIS)
        self.assertEqual(methods_from_rhs(p["raw"]), ["offsets"])

    def test_sansevieria_leaf_sucker_division(self):
        p = parse_propagation(SANSEVIERIA)
        self.assertEqual(methods_from_rhs(p["raw"]), ["leafCutting", "division", "offsets"])

    def test_zz_leaflets(self):
        p = parse_propagation(ZZ)
        self.assertEqual(methods_from_rhs(p["raw"]), ["leafCutting"])

    def test_camellia_semi_hardwood(self):
        p = parse_propagation(CAMELLIA)
        self.assertEqual(methods_from_rhs(p["raw"]), ["stemCutting"])

    def test_lavender_seed_and_cuttings(self):
        p = parse_propagation(LAVENDER)
        self.assertEqual(methods_from_rhs(p["raw"]), ["stemCutting", "seed"])

    def test_crassula_root_stem_leaf(self):
        p = parse_propagation(CRASSULA)
        self.assertEqual(
            methods_from_rhs(p["raw"]),
            ["stemCutting", "leafCutting", "offsets", "seed"],
        )

    def test_grafting_only_is_empty(self):
        p = parse_propagation(GRAFT)
        self.assertEqual(methods_from_rhs(p["raw"]), [])


class ApplyTest(unittest.TestCase):
    def test_keeps_water_on_monstera(self):
        p = parse_propagation(MONSTERA)
        self.assertEqual(
            apply_prop(["stemCutting", "water"], p),
            ["stemCutting", "seed", "water"],
        )

    def test_does_not_invent_water(self):
        p = parse_propagation(MONSTERA)
        self.assertEqual(apply_prop(["stemCutting"], p), ["stemCutting", "seed"])

    def test_keeps_advised_order_then_adds(self):
        p = parse_propagation(SANSEVIERIA)
        self.assertEqual(
            apply_prop(["division", "leafCutting"], p),
            ["division", "leafCutting", "offsets"],
        )

    def test_drops_methods_rhs_does_not_name(self):
        p = parse_propagation(TOMATO)
        self.assertEqual(apply_prop(["seed", "stemCutting"], p), ["seed"])

    def test_grafting_is_not_sourced(self):
        self.assertIsNone(apply_prop(["stemCutting"], parse_propagation(GRAFT)))

    def test_unreadable_page_is_not_sourced(self):
        self.assertIsNone(apply_prop(["offsets"], None))


class PageFitsTest(unittest.TestCase):
    def test_family_is_not_a_taxon(self):
        self.assertFalse(page_fits("byFamily", "Orchidaceae", {"slug": "phalaenopsis-amabilis"}))

    def test_genus_rejects_another_genus_page(self):
        self.assertFalse(page_fits("byGenus", "Dracaena", {"slug": "sansevieria-trifasciata"}))

    def test_genus_accepts_own_species(self):
        self.assertTrue(page_fits("byGenus", "Mentha", {"slug": "mentha-spicata"}))

    def test_species_rejects_another_species(self):
        self.assertFalse(
            page_fits(
                "bySpecies",
                "Euphorbia tirucalli",
                {"query": "Euphorbia pulcherrima", "slug": "euphorbia-pulcherrima"},
            )
        )


class SourcingTest(unittest.TestCase):
    def test_propagation_suffix(self):
        name = name_of({"hardiness", "light", "issues", "propagation"})
        self.assertEqual(name, "_rhsHardinessLightIssuesPropagation")
        self.assertEqual(fields_of(name), {"hardiness", "light", "issues", "propagation"})
        self.assertIn("CareField.propagation", dart_map({"issues", "propagation"}))


if __name__ == "__main__":
    unittest.main()
