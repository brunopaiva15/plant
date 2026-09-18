import unittest

from extract_family import patch_inner
from family_map import (
    filter_family_bloom,
    filter_family_growth,
    filter_family_humidity,
    filter_family_prop,
    months_overlap,
)
from prop_map import apply_prop
from watering_map import apply_watering


class PropTest(unittest.TestCase):
    def test_orchid_drops_keiki(self):
        mapped = apply_prop(
            ["division", "offsets"],
            {"raw": "Keikis and division of clumps."},
        )
        self.assertIn("offsets", mapped)
        out = filter_family_prop("Orchidaceae", mapped)
        self.assertEqual(out, ["division"])

    def test_bromeliad_keeps_offsets(self):
        mapped = apply_prop(["offsets"], {"raw": "Offsets and seed."})
        out = filter_family_prop("Bromeliaceae", mapped)
        self.assertEqual(out, ["offsets", "seed"])

    def test_empty_after_filter_is_not_sourced(self):
        self.assertIsNone(filter_family_prop("Orchidaceae", ["offsets"]))


class BloomTest(unittest.TestCase):
    def test_does_not_invent_a_window(self):
        applied = {"from": 6, "to": 8, "triggers": [], "indoors": True}
        self.assertIsNone(filter_family_bloom(None, applied))

    def test_christmas_cactus_does_not_steal_spring(self):
        current = {"from": 4, "to": 6, "triggers": ["coolRest"], "indoors": True}
        winter = {"from": 9, "to": 2, "triggers": ["coolRest"], "indoors": True}
        self.assertFalse(months_overlap(4, 6, 9, 2))
        self.assertIsNone(filter_family_bloom(current, winter))

    def test_overlapping_window_is_kept(self):
        current = {"from": 12, "to": 5, "triggers": ["coolNights"], "indoors": True}
        applied = {"from": 1, "to": 12, "triggers": ["coolNights"], "indoors": True}
        out = filter_family_bloom(current, applied)
        self.assertEqual(out["from"], 1)
        self.assertEqual(out["triggers"], ["coolNights"])


class HumidityTest(unittest.TestCase):
    def test_cactus_soil_rejects_forest_air(self):
        self.assertIsNone(filter_family_humidity("cactus", "high"))

    def test_aroid_accepts_rainforest(self):
        self.assertEqual(filter_family_humidity("rich", "high"), "high")


class GrowthTest(unittest.TestCase):
    def test_hardy_family_does_not_become_an_annual(self):
        applied = {
            "fertilizingDays": 21,
            "feeding": True,
            "repotEveryMonths": None,
            "repotting": True,
        }
        out = filter_family_growth(-12, "1-2 years", applied)
        self.assertTrue(out["feeding"])
        self.assertNotIn("repotting", out)
        self.assertNotIn("repotEveryMonths", out)

    def test_poinsettia_family_may_keep_repot(self):
        applied = {
            "fertilizingDays": 60,
            "feeding": True,
            "repotEveryMonths": 12,
            "repotting": True,
        }
        out = filter_family_growth(10, "1-2 years", applied)
        self.assertEqual(out["repotEveryMonths"], 12)


class WateringTest(unittest.TestCase):
    def test_cactus_family_dries_fully_from_soil(self):
        out = apply_watering("cactus", "terrestrial", 14, 45)
        self.assertEqual(out["dryDown"], "fullyDry")
        self.assertEqual(out["wateringSummerDays"], 30)


class PatchTest(unittest.TestCase):
    def test_keeps_orchid_triggers_and_range(self):
        inner = (
            "      humidity: HumidityNeed.high,\n"
            "      humidityIdealMin: 50,\n"
            "      fertilizingDays: 21,\n"
            "      propagation: [Propagation.division, Propagation.offsets],\n"
            "      bloom: Bloom(window: MonthWindow(12, 5), triggers: [BloomTrigger.coolNights]),\n"
            "      sourcing: _rhsLightIssues,\n"
        )
        out = patch_inner(
            inner,
            {
                "current_sourcing": "_rhsLightIssues",
                "propagation": ["division"],
                "bloom": {
                    "from": 1,
                    "to": 12,
                    "triggers": ["coolNights"],
                    "indoors": True,
                },
                "humidity": "high",
                "feeding": True,
                "fertilizingDays": 21,
            },
        )
        self.assertIn("propagation: _division,", out)
        self.assertNotIn("offsets", out)
        self.assertIn("BloomTrigger.coolNights", out)
        self.assertIn("humidityIdealMin: 50", out)
        self.assertIn("Propagation", out.split("sourcing:")[1])
