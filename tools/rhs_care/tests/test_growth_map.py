import unittest

from extract_growth import patch_inner
from growth_map import apply_growth, parse_maturity
from sourcing import dart_comment, dart_map, ensure_constants, fields_of, name_of


ALOE = (
    "Size Time to Maturity 5-10 years Max Spread 0.5-1 metres "
    "Max Height 0.5-1 metres Growing Conditions Loam"
)
BASIL = (
    "Size Time to Maturity 1-2 years Max Spread 0.1-0.5 metres "
    "Max Height 0.1-0.5 metres Growing Conditions Loam Sand"
)
TOMATO = (
    "Size Time to Maturity 1 year Max Spread 0.5-1 metres "
    "Max Height 1.5-2.5 metres Growing Conditions Clay Loam Sand"
)
OAK = (
    "Size Time to Maturity 20-50 years Max Spread wider than 8 metres "
    "Max Height Higher than 12 metres Growing Conditions"
)
PINUS = "Size Time to Maturity more than 50 years Max Spread 2.5-4 metres"
EMPTY = "Growing Conditions Loam Moisture Well-drained Position Full sun"


class ParseTest(unittest.TestCase):
    def test_aloe_five_to_ten(self):
        self.assertEqual(parse_maturity(ALOE), "5-10 years")

    def test_basil_one_to_two(self):
        self.assertEqual(parse_maturity(BASIL), "1-2 years")

    def test_tomato_one_year(self):
        self.assertEqual(parse_maturity(TOMATO), "1 year")

    def test_oak_twenty_to_fifty(self):
        self.assertEqual(parse_maturity(OAK), "20-50 years")

    def test_pinus_more_than_fifty(self):
        self.assertEqual(parse_maturity(PINUS), "more than 50 years")

    def test_en_dash(self):
        self.assertEqual(
            parse_maturity("Size Time to Maturity 2–5 years Max Spread"),
            "2-5 years",
        )

    def test_missing(self):
        self.assertIsNone(parse_maturity(EMPTY))


class ApplyTest(unittest.TestCase):
    def test_aloe_cactus_slow(self):
        out = apply_growth(
            soil="cactus",
            pot="snug",
            tips=["drySoilFirst"],
            issues=[],
            fertilizer=None,
            repot_months=30,
            damage_below_c=5,
            maturity="5-10 years",
        )
        self.assertEqual(out["fertilizingDays"], 60)
        self.assertEqual(out["repotEveryMonths"], 30)

    def test_basil_annual_keeps_no_repot(self):
        out = apply_growth(
            soil="draining",
            pot=None,
            tips=["pinchFlowers"],
            issues=[],
            fertilizer=None,
            repot_months=None,
            damage_below_c=10,
            maturity="1-2 years",
        )
        self.assertEqual(out["fertilizingDays"], 21)
        self.assertIsNone(out["repotEveryMonths"])
        self.assertTrue(out["repotting"])

    def test_tomato_vegetable_is_hungry(self):
        out = apply_growth(
            soil="rich",
            pot=None,
            tips=[],
            issues=["blossomEndRot"],
            fertilizer=None,
            repot_months=None,
            damage_below_c=8,
            maturity="1 year",
        )
        self.assertEqual(out["fertilizingDays"], 14)
        self.assertIsNone(out["repotEveryMonths"])

    def test_lavender_no_fertilizer(self):
        out = apply_growth(
            soil="draining",
            pot=None,
            tips=["noFertilizer", "drySoilFirst"],
            issues=[],
            fertilizer=None,
            repot_months=36,
            damage_below_c=-12,
            maturity="2-5 years",
        )
        self.assertIsNone(out["fertilizingDays"])
        self.assertTrue(out["feeding"])
        self.assertEqual(out["repotEveryMonths"], 24)

    def test_lithops_keeps_long_snug_repot(self):
        out = apply_growth(
            soil="cactus",
            pot="snug",
            tips=["noFertilizer"],
            issues=[],
            fertilizer=None,
            repot_months=48,
            damage_below_c=5,
            maturity="2-5 years",
        )
        self.assertIsNone(out["fertilizingDays"])
        self.assertEqual(out["repotEveryMonths"], 48)

    def test_orchid_stays_frequent(self):
        out = apply_growth(
            soil="orchid",
            pot="snug",
            tips=[],
            issues=[],
            fertilizer=None,
            repot_months=24,
            damage_below_c=15,
            maturity="5-10 years",
        )
        self.assertEqual(out["fertilizingDays"], 30)
        self.assertEqual(out["repotEveryMonths"], 24)

    def test_carnivore_without_page(self):
        out = apply_growth(
            soil="acidic",
            pot=None,
            tips=["feedsOnInsects", "neverDryOut"],
            issues=[],
            fertilizer=None,
            repot_months=24,
            damage_below_c=10,
            maturity=None,
        )
        self.assertIsNone(out["fertilizingDays"])
        self.assertTrue(out["feeding"])
        self.assertNotIn("repotting", out)

    def test_houseplant_does_not_starve_on_garden_maturity(self):
        out = apply_growth(
            soil="rich",
            pot="roomy",
            tips=[],
            issues=[],
            fertilizer=None,
            repot_months=24,
            damage_below_c=12,
            maturity="10-20 years",
        )
        self.assertEqual(out["fertilizingDays"], 30)
        self.assertEqual(out["repotEveryMonths"], 36)

    def test_hardy_garden_keeps_slow_feed(self):
        out = apply_growth(
            soil="draining",
            pot=None,
            tips=[],
            issues=[],
            fertilizer=None,
            repot_months=36,
            damage_below_c=-8,
            maturity="10-20 years",
        )
        self.assertEqual(out["fertilizingDays"], 60)
        self.assertEqual(out["repotEveryMonths"], 36)

    def test_no_signal_is_not_sourced(self):
        self.assertIsNone(
            apply_growth(
                soil="standard",
                pot=None,
                tips=[],
                issues=[],
                fertilizer=None,
                repot_months=24,
                damage_below_c=10,
                maturity=None,
            )
        )


class SourcingTest(unittest.TestCase):
    def test_feeding_and_repotting_are_derived(self):
        name = name_of({"hardiness", "light", "watering", "feeding", "repotting"})
        self.assertEqual(name, "_rhsHardinessLightWateringFeedingRepotting")
        self.assertEqual(
            fields_of(name),
            {"hardiness", "light", "watering", "feeding", "repotting"},
        )
        rendered = dart_map({"light", "feeding", "repotting"})
        self.assertIn("CareField.feeding: CareSource.derived", rendered)
        self.assertIn("CareField.repotting: CareSource.derived", rendered)
        self.assertNotIn("CareField.feeding: CareSource.rhs", rendered)

    def test_derived_trio(self):
        self.assertEqual(
            name_of({"watering", "feeding", "repotting"}),
            "_derivedWateringFeedingRepotting",
        )
        self.assertEqual(
            fields_of("_derivedWateringFeedingRepotting"),
            {"watering", "feeding", "repotting"},
        )

    def test_water_is_not_watering_or_feeding(self):
        self.assertEqual(
            fields_of("_rhsHardinessLightWaterFeeding"),
            {"hardiness", "light", "water", "feeding"},
        )

    def test_comment(self):
        text = dart_comment({"light", "watering", "feeding", "repotting"})
        self.assertIn("RHS", text)
        self.assertIn("séchage", text)
        self.assertIn("maturité", text)

    def test_ensure_does_not_skip_a_prefix_of_a_longer_name(self):
        text = (
            "  static const _rhsLight = {CareField.light: CareSource.rhs};\n"
            "  static const _rhsLightWateringFeedingRepottingIssuesPropagationBloom"
            " = {CareField.light: CareSource.rhs};\n"
        )
        out = ensure_constants(
            text,
            {"_rhsLightWateringFeedingRepottingIssuesPropagation"},
        )
        self.assertIn(
            "static const _rhsLightWateringFeedingRepottingIssuesPropagation =",
            out,
        )


class PatchTest(unittest.TestCase):
    def test_rewrites_days_keeps_window_and_kind(self):
        inner = (
            "      fertilizingDays: 45,\n"
            "      fertilizingWindow: MonthWindow(3, 8),\n"
            "      fertilizer: FertilizerKind.flowering,\n"
            "      repotEveryMonths: 36,\n"
            "      sourcing: _rhsHardinessLightSoilWaterWateringIssuesPropagationBloom,\n"
        )
        rec = {
            "feeding": True,
            "fertilizingDays": 30,
            "repotting": True,
            "repotEveryMonths": 24,
            "current_sourcing": "_rhsHardinessLightSoilWaterWateringIssuesPropagationBloom",
        }
        out = patch_inner(inner, rec)
        self.assertIn("fertilizingDays: 30,", out)
        self.assertIn("fertilizingWindow: MonthWindow(3, 8),", out)
        self.assertIn("fertilizer: FertilizerKind.flowering,", out)
        self.assertIn("repotEveryMonths: 24,", out)
        self.assertIn("FeedingRepotting", out)


if __name__ == "__main__":
    unittest.main()
