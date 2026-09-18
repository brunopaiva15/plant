import unittest

from issue_map import apply_issues, issues_from_rhs, parse_pests_diseases
from sourcing import dart_map, fields_of, name_of


ALOE = (
    "Pests May be susceptible to scale insects and mealybugs "
    "Diseases Generally disease-free Grow The new app"
)
MONSTERA = (
    "Pests May be susceptible to scale insects and glasshouse red spider mite "
    "Diseases Generally disease-free Grow The new app"
)
ECHINACEA = (
    "Pests Generally pest-free Diseases Generally disease-free Grow The new app"
)
TOMATO = (
    "Pests May be susceptible to glasshouse whitefly and tomato moth "
    "Diseases May be susceptible to honey fungus (rarely), blossom end rot, "
    "magnesium deficiency, tomato spotted wilt virus and grey moulds under glass Grow"
)
CAMELLIA = (
    "Pests May be susceptible to aphids , scale insects and vine weevil "
    "Diseases May be susceptible to honey fungus (rarely), Phytophthora root rot, "
    "Camellia gall , camellia leaf blight Grow"
)
LAVENDER = (
    "Pests May be susceptible to rosemary beetle and cuckoo spit (froghoppers) "
    "Diseases high risk host for xylella fastidiosa . May be susceptible to "
    "grey moulds (Botrytis) and honey fungus (rarely) Grow"
)
NAV = "Pests & Diseases Beginners' guide Grow your own Pests May be susceptible to aphids Diseases Generally disease-free Grow The new app"


class ParseTest(unittest.TestCase):
    def test_skips_nav(self):
        p = parse_pests_diseases(NAV)
        self.assertIsNotNone(p)
        self.assertIn("aphids", p["pests_raw"].lower())

    def test_pest_free(self):
        p = parse_pests_diseases(ECHINACEA)
        self.assertTrue(p["pest_free"])
        self.assertTrue(p["disease_free"])
        self.assertEqual(issues_from_rhs(p["pests_raw"], p["diseases_raw"]), [])

    def test_aloe_scale_mealy(self):
        p = parse_pests_diseases(ALOE)
        self.assertCountEqual(issues_from_rhs(p["pests_raw"], p["diseases_raw"]), ["scale", "mealybugs"])

    def test_tomato(self):
        p = parse_pests_diseases(TOMATO)
        self.assertCountEqual(
            issues_from_rhs(p["pests_raw"], p["diseases_raw"]),
            ["whitefly", "blossomEndRot", "greyMould", "chlorosis"],
        )

    def test_camellia(self):
        p = parse_pests_diseases(CAMELLIA)
        self.assertCountEqual(
            issues_from_rhs(p["pests_raw"], p["diseases_raw"]),
            ["aphids", "scale", "rootRot", "blight"],
        )

    def test_lavender_froghoppers_and_botrytis(self):
        p = parse_pests_diseases(LAVENDER)
        self.assertEqual(issues_from_rhs(p["pests_raw"], p["diseases_raw"]), ["trueBugs", "greyMould"])

    def test_empty_page(self):
        self.assertIsNone(parse_pests_diseases("Hardiness Close modal Growing conditions"))


class ApplyTest(unittest.TestCase):
    def test_outdoor_smear_drops_when_pest_free(self):
        current = ["aphids", "trueBugs", "slugs", "powderyMildew", "greyMould"]
        p = parse_pests_diseases(ECHINACEA)
        self.assertEqual(apply_issues(current, p), [])

    def test_tropical_keeps_watering_troubles(self):
        current = [
            "overwatering",
            "rootRot",
            "spiderMites",
            "thrips",
            "mealybugs",
            "scale",
            "fungusGnats",
            "leafSpot",
            "dryTips",
        ]
        p = parse_pests_diseases(MONSTERA)
        self.assertEqual(
            apply_issues(current, p),
            ["overwatering", "rootRot", "spiderMites", "scale", "fungusGnats", "dryTips"],
        )

    def test_succulent_adds_scale_keeps_etiolation(self):
        current = ["overwatering", "rootRot", "etiolation", "mealybugs", "fungusGnats"]
        p = parse_pests_diseases(ALOE)
        self.assertEqual(
            apply_issues(current, p),
            ["overwatering", "rootRot", "mealybugs", "scale", "fungusGnats", "etiolation"],
        )

    def test_unreadable_page_is_not_sourced(self):
        self.assertIsNone(apply_issues(["aphids"], None))


class SourcingTest(unittest.TestCase):
    def test_historical_and_names(self):
        self.assertEqual(name_of({"hardiness", "light"}), "_rhsHardinessAndLight")
        self.assertEqual(name_of({"soil", "water"}), "_rhsSoilAndWater")
        self.assertEqual(fields_of("_rhsHardinessAndLight"), {"hardiness", "light"})
        self.assertEqual(fields_of("_rhsHardinessLightSoilWater"), {"hardiness", "light", "soil", "water"})

    def test_issues_suffix(self):
        name = name_of({"hardiness", "light", "issues"})
        self.assertEqual(name, "_rhsHardinessLightIssues")
        self.assertEqual(fields_of(name), {"hardiness", "light", "issues"})
        self.assertIn("CareField.issues", dart_map({"hardiness", "issues"}))


if __name__ == "__main__":
    unittest.main()
