import unittest

from hardiness_map import (
    apply_hardiness,
    band_holds,
    parse_hardiness,
    parse_hardiness_html,
    temperature_for,
)

# La page RHS porte d'abord la légende des neuf cotes, puis celle de la
# plante. Le texte est celui d'une fiche réelle, raccourci.
PAGE = (
    "Exposure Sheltered Hardiness Close modal Hardiness Ratings All ratings refer to the "
    "UK growing conditions unless otherwise stated. Minimum temperature ranges (in degrees C) "
    "are shown in brackets H1A: under glass all year (>15C) H1B: can be grown outside in the "
    "summer (10 - 15) H1C: can be grown outside in the summer (5 - 10) H2: tolerant of low "
    "temperatures, but not surviving being frozen (1 to 5) H3: hardy in coastal and relatively "
    "mild parts of the UK (-5 to 1) H4: hardy through most of the UK (-10 to -5) H5: hardy in "
    "most places throughout the UK even in severe winters (-15 to -10) H6: hardy in all of UK "
    "and northern Europe (-20 to -15) H7: hardy in the severest European continental climates "
    "(< -20) H1B Colour & Scent Season Stem"
)


class ParseTest(unittest.TestCase):
    def test_reads_the_plant_rating_not_the_legend(self):
        self.assertEqual(parse_hardiness(PAGE), "H1B")

    def test_reads_the_definition_on_raw_html(self):
        html = '<dt>Hardiness</dt> <dd data-astro-cid-2tv5ctmt> H1A </dd>'
        self.assertEqual(parse_hardiness_html(html), "H1A")

    def test_a_page_without_rating_says_nothing(self):
        self.assertIsNone(parse_hardiness("Growing Conditions Loam Moisture Moist"))
        self.assertIsNone(parse_hardiness(""))


class BandTest(unittest.TestCase):
    def test_a_value_inside_the_band_holds(self):
        self.assertTrue(band_holds(12, "H1B"))
        self.assertTrue(band_holds(10, "H1B"))
        self.assertTrue(band_holds(15, "H1B"))

    def test_a_value_outside_the_band_does_not(self):
        self.assertFalse(band_holds(5, "H1B"))
        self.assertFalse(band_holds(18, "H1B"))
        self.assertFalse(band_holds(None, "H1B"))

    def test_open_bands_have_one_side_only(self):
        # « Sous verre toute l'année » : au-dessus de 15, rien ne dépasse.
        self.assertTrue(band_holds(20, "H1A"))
        self.assertFalse(band_holds(14, "H1A"))
        self.assertTrue(band_holds(-30, "H7"))
        self.assertFalse(band_holds(-18, "H7"))

    def test_the_middle_is_rounded_to_the_warm_side(self):
        self.assertEqual(temperature_for("H1B"), 13)
        self.assertEqual(temperature_for("H1C"), 8)
        self.assertEqual(temperature_for("H2"), 3)
        self.assertEqual(temperature_for("H4"), -7)
        self.assertEqual(temperature_for("H6"), -17)

    def test_open_bands_take_their_edge(self):
        self.assertEqual(temperature_for("H1A"), 15)
        self.assertEqual(temperature_for("H7"), -25)


class ApplyTest(unittest.TestCase):
    def test_a_value_that_holds_is_confirmed_not_moved(self):
        self.assertEqual(apply_hardiness(12, "H1B"), 12)

    def test_a_value_that_contradicts_the_band_is_corrected(self):
        self.assertEqual(apply_hardiness(-8, "H1B"), 13)

    def test_a_fiche_without_value_takes_the_band(self):
        self.assertEqual(apply_hardiness(None, "H3"), -2)

    def test_no_rating_is_not_a_source(self):
        self.assertIsNone(apply_hardiness(12, None))
        self.assertIsNone(apply_hardiness(12, "H9"))


if __name__ == "__main__":
    unittest.main()
