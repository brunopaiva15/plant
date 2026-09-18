import unittest

from bloom_map import apply_bloom, parse_flower_seasons, window_from_seasons
from sourcing import dart_map, fields_of, name_of


def table(*rows: tuple[str, str]) -> str:
    body = []
    for season, flower in rows:
        body.append(
            f'<tr><th scope="row">{season}</th>'
            f'<td data-label="Stem"></td>'
            f'<td data-label="Flower">{flower}</td>'
            f'<td data-label="Foliage"></td></tr>'
        )
    return "<table><tbody>" + "".join(body) + "</tbody></table>"


PINK = '<svg aria-label="Pink"></svg>'
CAMELLIA = table(("Spring", PINK), ("Summer", " "), ("Autumn", ""), ("Winter", "  "))
LAVENDER = table(("Spring", ""), ("Summer", PINK), ("Autumn", ""), ("Winter", ""))
MONSTERA = table(("Spring", PINK), ("Summer", PINK), ("Autumn", ""), ("Winter", ""))
SCHLUMBERGERA = table(("Spring", ""), ("Summer", ""), ("Autumn", PINK), ("Winter", PINK))
PHALAENOPSIS = table(("Spring", PINK), ("Summer", PINK), ("Autumn", PINK), ("Winter", PINK))
SPLIT = table(("Spring", PINK), ("Summer", ""), ("Autumn", PINK), ("Winter", ""))
EMPTY = table(("Spring", " "), ("Summer", ""), ("Autumn", ""), ("Winter", ""))


class ParseTest(unittest.TestCase):
    def test_camellia_spring(self):
        self.assertEqual(parse_flower_seasons(CAMELLIA), ["Spring"])

    def test_lavender_summer(self):
        self.assertEqual(parse_flower_seasons(LAVENDER), ["Summer"])

    def test_year_round(self):
        self.assertEqual(
            parse_flower_seasons(PHALAENOPSIS),
            ["Spring", "Summer", "Autumn", "Winter"],
        )

    def test_no_table(self):
        self.assertIsNone(parse_flower_seasons("Hardiness Close modal Growing conditions"))


class WindowTest(unittest.TestCase):
    def test_single_season(self):
        self.assertEqual(window_from_seasons(["Summer"]), (6, 8))
        self.assertEqual(window_from_seasons(["Spring"]), (3, 5))
        self.assertEqual(window_from_seasons(["Winter"]), (12, 2))

    def test_contiguous(self):
        self.assertEqual(window_from_seasons(["Spring", "Summer"]), (3, 8))
        self.assertEqual(window_from_seasons(["Summer", "Autumn"]), (6, 11))
        self.assertEqual(window_from_seasons(["Autumn", "Winter"]), (9, 2))

    def test_wraps_winter_into_spring(self):
        self.assertEqual(window_from_seasons(["Spring", "Winter"]), (12, 5))

    def test_all_year(self):
        self.assertEqual(
            window_from_seasons(["Spring", "Summer", "Autumn", "Winter"]),
            (1, 12),
        )

    def test_gap_is_unreadable(self):
        self.assertIsNone(window_from_seasons(["Spring", "Autumn"]))


class ApplyTest(unittest.TestCase):
    def test_keeps_triggers_and_outdoors(self):
        seasons = parse_flower_seasons(MONSTERA)
        current = {"from": 5, "to": 8, "triggers": ["maturity"], "indoors": False}
        self.assertEqual(
            apply_bloom(current, seasons),
            {"from": 3, "to": 8, "triggers": ["maturity"], "indoors": False},
        )

    def test_adds_window_when_missing(self):
        seasons = parse_flower_seasons(LAVENDER)
        self.assertEqual(
            apply_bloom(None, seasons),
            {"from": 6, "to": 8, "triggers": [], "indoors": True},
        )

    def test_empty_flower_column_is_not_sourced(self):
        self.assertEqual(apply_bloom({"from": 6, "to": 8, "triggers": [], "indoors": True}, parse_flower_seasons(EMPTY)), None)

    def test_gap_is_not_sourced(self):
        self.assertIsNone(apply_bloom(None, parse_flower_seasons(SPLIT)))

    def test_unreadable_page_is_not_sourced(self):
        self.assertIsNone(apply_bloom({"from": 6, "to": 8, "triggers": [], "indoors": True}, None))


class SourcingTest(unittest.TestCase):
    def test_bloom_suffix(self):
        name = name_of({"hardiness", "light", "propagation", "bloom"})
        self.assertEqual(name, "_rhsHardinessLightPropagationBloom")
        self.assertEqual(fields_of(name), {"hardiness", "light", "propagation", "bloom"})
        self.assertIn("CareField.bloom", dart_map({"propagation", "bloom"}))


class PatchTest(unittest.TestCase):
    def test_does_not_split_on_month_window(self):
        from extract_bloom import patch_inner

        inner = (
            "      bloom: Bloom(window: MonthWindow(5, 8), "
            "triggers: [BloomTrigger.maturity], indoors: false),\n"
            "      sourcing: _rhsHardinessLightWaterIssuesPropagation,\n"
        )
        rec = {
            "bloom": {"from": 3, "to": 8, "triggers": ["maturity"], "indoors": False},
            "current_sourcing": "_rhsHardinessLightWaterIssuesPropagation",
        }
        out = patch_inner(inner, rec)
        self.assertEqual(out.count("triggers:"), 1)
        self.assertEqual(out.count("indoors: false"), 1)
        self.assertIn("MonthWindow(3, 8)", out)


if __name__ == "__main__":
    unittest.main()
