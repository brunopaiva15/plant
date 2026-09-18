import unittest

from soil_map import apply_soil, drainage_from_moisture, is_ericaceous, parse_growing


CAMELLIA = (
    "Growing Conditions Clay Loam Sand Moisture Moist but well-drained or Well-drained "
    "pH Acid or Neutral Position Full shade Partial shade"
)
ALOE = (
    "Growing Conditions Loam Moisture Well-drained pH Acid or Alkaline or Neutral "
    "Position Full sun Aspect West-facing"
)
GARDENIA = (
    "Growing Conditions Clay Loam Sand Moisture Moist but well-drained "
    "pH Acid or Neutral Position Partial shade"
)
VACCINIUM = (
    "Growing Conditions Loam Sand Moisture Moist but well-drained pH Acid "
    "Position Full sun Partial shade"
)
LAVENDER = (
    "Growing Conditions Chalk Loam Sand Moisture Well-drained "
    "pH Acid or Alkaline or Neutral Position Full sun"
)
PHALAENOPSIS = (
    "Growing Conditions Loam Moisture Well-drained pH Neutral Position Partial shade"
)
NYMPHAEA = (
    "Growing Conditions Clay Loam Moisture Poorly-drained "
    "pH Acid or Alkaline or Neutral Position Full sun"
)
ZZ = (
    "Growing Conditions Loam Sand Moisture Well-drained "
    "pH Acid or Alkaline or Neutral Position Full shade Partial shade"
)
MONSTERA = (
    "Growing Conditions Loam Moisture Moist but well-drained "
    "pH Acid or Alkaline or Neutral Position Partial shade"
)
TOMATO = (
    "Growing Conditions Loam Moisture Moist but well-drained "
    "pH Acid or Neutral Position Full sun"
)


class ParseGrowingTest(unittest.TestCase):
    def test_camellia(self):
        g = parse_growing(CAMELLIA)
        self.assertEqual(g["types"], frozenset({"clay", "loam", "sand"}))
        self.assertEqual(g["moisture"], frozenset({"moist_well", "well_drained"}))
        self.assertEqual(g["ph"], frozenset({"acid", "neutral"}))
        self.assertFalse(is_ericaceous(g["ph"]))

    def test_vaccinium_acid_only(self):
        g = parse_growing(VACCINIUM)
        self.assertEqual(g["ph"], frozenset({"acid"}))
        self.assertTrue(is_ericaceous(g["ph"]))

    def test_aloe_all_ph(self):
        g = parse_growing(ALOE)
        self.assertFalse(is_ericaceous(g["ph"]))
        self.assertEqual(drainage_from_moisture(g["moisture"]), "dry")

    def test_empty(self):
        g = parse_growing("Hardiness Close modal Growing conditions unless otherwise stated")
        self.assertEqual(g["types"], frozenset())
        self.assertIsNone(g["raw"])


class ApplySoilTest(unittest.TestCase):
    def test_camellia_already_acidic_is_confirmed(self):
        g = parse_growing(CAMELLIA)
        self.assertEqual(
            apply_soil("acidic", "strict", g["types"], g["moisture"], g["ph"]),
            ("acidic", "strict"),
        )

    def test_gardenia_already_acidic(self):
        g = parse_growing(GARDENIA)
        self.assertEqual(
            apply_soil("acidic", "strict", g["types"], g["moisture"], g["ph"]),
            ("acidic", "strict"),
        )

    def test_vaccinium_acid_only_makes_ericaceous(self):
        g = parse_growing(VACCINIUM)
        self.assertEqual(
            apply_soil("standard", "tolerant", g["types"], g["moisture"], g["ph"]),
            ("acidic", "strict"),
        )

    def test_tomato_acid_or_neutral_is_not_ericaceous(self):
        g = parse_growing(TOMATO)
        soil, water = apply_soil("rich", "tolerant", g["types"], g["moisture"], g["ph"])
        self.assertIsNone(soil)
        self.assertEqual(water, "tolerant")

    def test_aloe_keeps_cactus(self):
        g = parse_growing(ALOE)
        self.assertEqual(
            apply_soil("cactus", "tolerant", g["types"], g["moisture"], g["ph"]),
            ("cactus", "tolerant"),
        )

    def test_lavender_well_drained(self):
        g = parse_growing(LAVENDER)
        self.assertEqual(
            apply_soil("draining", "tolerant", g["types"], g["moisture"], g["ph"]),
            ("draining", "tolerant"),
        )

    def test_orchid_is_not_garden_loam(self):
        g = parse_growing(PHALAENOPSIS)
        self.assertEqual(
            apply_soil("orchid", "sensitive", g["types"], g["moisture"], g["ph"]),
            (None, None),
        )

    def test_aquatic_none_is_not_clay(self):
        g = parse_growing(NYMPHAEA)
        self.assertEqual(
            apply_soil("none", "tolerant", g["types"], g["moisture"], g["ph"]),
            (None, None),
        )

    def test_zz_well_drained(self):
        g = parse_growing(ZZ)
        self.assertEqual(
            apply_soil("draining", "tolerant", g["types"], g["moisture"], g["ph"]),
            ("draining", "tolerant"),
        )

    def test_standard_to_draining_when_rhs_is_dry(self):
        g = parse_growing(ZZ)
        self.assertEqual(
            apply_soil("standard", "tolerant", g["types"], g["moisture"], g["ph"]),
            ("draining", "tolerant"),
        )

    def test_rich_mesic_is_kept_unsourced(self):
        g = parse_growing(MONSTERA)
        soil, water = apply_soil("rich", "tolerant", g["types"], g["moisture"], g["ph"])
        self.assertIsNone(soil)
        self.assertEqual(water, "tolerant")

    def test_standard_mesic_is_standard(self):
        g = parse_growing(MONSTERA)
        self.assertEqual(
            apply_soil("standard", "tolerant", g["types"], g["moisture"], g["ph"]),
            ("standard", "tolerant"),
        )

    def test_sensitive_water_is_not_loosened(self):
        g = parse_growing(ZZ)
        soil, water = apply_soil("draining", "sensitive", g["types"], g["moisture"], g["ph"])
        self.assertEqual(soil, "draining")
        self.assertIsNone(water)

    def test_poorly_drained_to_rich(self):
        g = parse_growing(NYMPHAEA)
        self.assertEqual(
            apply_soil("standard", "tolerant", g["types"], g["moisture"], g["ph"]),
            ("rich", "tolerant"),
        )


if __name__ == "__main__":
    unittest.main()
