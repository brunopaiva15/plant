import unittest

from extract_watering import patch_inner
from sourcing import dart_comment, dart_map, fields_of, name_of
from watering_map import apply_watering, days_from_dry_down, dry_down_from_days, infer_dry_down


class InferTest(unittest.TestCase):
    def test_aquatic_stays_moist_even_without_soil(self):
        self.assertEqual(
            infer_dry_down("none", "aquatic", 1, 1),
            "alwaysMoist",
        )

    def test_semi_aquatic_stays_moist(self):
        self.assertEqual(
            infer_dry_down("acidic", "semiAquatic", 2, 6),
            "alwaysMoist",
        )

    def test_cactus_soil_dries_fully(self):
        self.assertEqual(
            infer_dry_down("cactus", "terrestrial", 14, 35),
            "fullyDry",
        )

    def test_epiphyte_without_soil_is_skipped(self):
        self.assertIsNone(infer_dry_down("none", "epiphytic", 5, 10))

    def test_draining_is_not_a_watering_rule(self):
        # Basilic : terre drainante, soif tous les deux jours.
        self.assertEqual(
            infer_dry_down("draining", "terrestrial", 2, 4),
            "alwaysMoist",
        )

    def test_days_bucket_from_active_season(self):
        self.assertEqual(
            infer_dry_down("rich", "terrestrial", 7, 14),
            "topQuarterDry",
        )

    def test_winter_active_uses_the_short_interval(self):
        self.assertEqual(
            infer_dry_down("draining", "terrestrial", 30, 10),
            "halfDry",
        )

    def test_explicit_rule_wins_absent_lock(self):
        self.assertEqual(
            infer_dry_down("standard", "terrestrial", 7, 14, explicit="halfDry"),
            "halfDry",
        )

    def test_cactus_lock_beats_explicit(self):
        self.assertEqual(
            infer_dry_down("cactus", "terrestrial", 7, 14, explicit="halfDry"),
            "fullyDry",
        )


class DaysTest(unittest.TestCase):
    def test_roundtrip_buckets(self):
        for rule in (
            "alwaysMoist",
            "surfaceDry",
            "topQuarterDry",
            "halfDry",
            "mostlyDry",
            "fullyDry",
        ):
            self.assertEqual(dry_down_from_days(days_from_dry_down(rule)), rule)

    def test_aloe_cactus_scales_winter(self):
        out = apply_watering("cactus", "terrestrial", 14, 35)
        self.assertEqual(out["dryDown"], "fullyDry")
        self.assertEqual(out["wateringSummerDays"], 30)
        self.assertEqual(out["wateringWinterDays"], 75)

    def test_hyacinth_keeps_winter_active(self):
        out = apply_watering("draining", "terrestrial", 30, 10)
        self.assertEqual(out["dryDown"], "halfDry")
        self.assertEqual(out["wateringSummerDays"], 30)
        self.assertEqual(out["wateringWinterDays"], 10)

    def test_monstera_canonical(self):
        out = apply_watering("rich", "terrestrial", 7, 14)
        self.assertEqual(out["dryDown"], "topQuarterDry")
        self.assertEqual(out["wateringSummerDays"], 7)
        self.assertEqual(out["wateringWinterDays"], 14)

    def test_basil_not_mostly_dry(self):
        out = apply_watering("draining", "terrestrial", 2, 4)
        self.assertEqual(out["dryDown"], "alwaysMoist")
        self.assertEqual(out["wateringSummerDays"], 2)
        self.assertEqual(out["wateringWinterDays"], 4)

    def test_tillandsia_unsourced(self):
        self.assertIsNone(apply_watering("none", "epiphytic", 5, 10))

    def test_idempotent(self):
        first = apply_watering("cactus", "terrestrial", 14, 35)
        again = apply_watering(
            "cactus",
            "terrestrial",
            first["wateringSummerDays"],
            first["wateringWinterDays"],
            explicit=first["dryDown"],
        )
        self.assertEqual(again, first)


class SourcingTest(unittest.TestCase):
    def test_water_is_not_watering(self):
        self.assertEqual(
            fields_of("_rhsHardinessLightWater"),
            {"hardiness", "light", "water"},
        )
        self.assertEqual(
            fields_of("_rhsHardinessLightWatering"),
            {"hardiness", "light", "watering"},
        )
        self.assertEqual(
            fields_of("_rhsHardinessLightWaterWatering"),
            {"hardiness", "light", "water", "watering"},
        )

    def test_watering_is_derived(self):
        name = name_of({"hardiness", "light", "water", "humidity", "watering"})
        self.assertEqual(name, "_rhsHardinessLightWaterHumidityWatering")
        self.assertEqual(
            fields_of(name),
            {"hardiness", "light", "water", "humidity", "watering"},
        )
        rendered = dart_map({"hardiness", "light", "watering"})
        self.assertIn("CareField.watering: CareSource.derived", rendered)
        self.assertIn("CareField.light: CareSource.rhs", rendered)
        self.assertNotIn("CareField.watering: CareSource.rhs", rendered)

    def test_watering_alone(self):
        self.assertEqual(name_of({"watering"}), "_derivedWatering")
        self.assertEqual(fields_of("_derivedWatering"), {"watering"})

    def test_humidity_and_watering(self):
        self.assertEqual(
            name_of({"humidity", "watering"}),
            "_habitatHumidityDerivedWatering",
        )
        self.assertEqual(
            fields_of("_habitatHumidityDerivedWatering"),
            {"humidity", "watering"},
        )

    def test_comment_mixes_sources(self):
        text = dart_comment({"light", "humidity", "watering"})
        self.assertIn("RHS", text)
        self.assertIn("habitat", text)
        self.assertIn("dérivé", text)


class PatchTest(unittest.TestCase):
    def test_inserts_dry_down_and_rewrites_days(self):
        inner = (
            "      wateringSummerDays: 14,\n"
            "      wateringWinterDays: 35,\n"
            "      light: LightNeed.fullSun,\n"
            "      sourcing: _rhsHardinessLightSoilWaterIssuesPropagationBloom,\n"
        )
        rec = {
            "dryDown": "fullyDry",
            "wateringSummerDays": 30,
            "wateringWinterDays": 75,
            "current_sourcing": "_rhsHardinessLightSoilWaterIssuesPropagationBloom",
        }
        out = patch_inner(inner, rec)
        self.assertIn("wateringSummerDays: 30,", out)
        self.assertIn("wateringWinterDays: 75,", out)
        self.assertIn("dryDown: DryDown.fullyDry,", out)
        self.assertIn("_rhsHardinessLightSoilWaterWateringIssuesPropagationBloom", out)


if __name__ == "__main__":
    unittest.main()
