import unittest

from extract_humidity import patch_inner, taxon_query
from humidity_map import (
    apply_humidity,
    classify_habitat,
    harvest_corpus,
    keep_description,
)
from sourcing import dart_comment, dart_map, fields_of, name_of


MONSTERA = (
    "Monstera deliciosa is known in Southern Mexico and Guatemala, "
    "in Premontane rain forest, Tropical moist forest and Tropical wet forest life zones."
)
ALOE = "Native range: Arabian Peninsula"
LAVENDER = "Lavandula angustifolia is a flowering plant native to the Mediterranean basin."
SCHLUMBERGERA = (
    "It is endemic to a small area of the coastal mountains of south-eastern Brazil "
    "where its natural habitats are subtropical or tropical moist forests."
)
DRY_FOREST = "Seasonally dry tropical forest of western Mexico."
CONFLICT = "Grows in desert washes and in tropical rainforest understory."
EMPTY = "A succulent houseplant widely cultivated."
PORTUGAL = "Habitat: Maritime rocks. First mention of the species as naturalised in Portugal."


class HarvestTest(unittest.TestCase):
    def test_drops_native_range_lists(self):
        d = {
            "type": "native range",
            "language": "eng",
            "source": "Checklist of introduced taxa in Cyprus",
            "description": "Arabian Peninsula",
        }
        self.assertFalse(keep_description(d))

    def test_drops_continent_laundry_list(self):
        d = {
            "type": "native range",
            "language": "eng",
            "source": "Manual of the Alien Plants of Belgium",
            "description": "Africa Arabian Peninsula Asia-Temperate Europe",
        }
        self.assertFalse(keep_description(d))

    def test_drops_naturalised_ecology(self):
        d = {
            "type": "biology_ecology",
            "language": "eng",
            "source": "An annotated catalogue of Aloe naturalised and escaped in continental Portugal",
            "description": PORTUGAL,
        }
        self.assertFalse(keep_description(d))

    def test_drops_morphology(self):
        d = {
            "type": "description",
            "language": "eng",
            "source": "Revision of Monstera",
            "description": "Robust to massive herb, terrestrial or nomadic vine.",
        }
        self.assertFalse(keep_description(d))

    def test_joins_wiki(self):
        text = harvest_corpus(
            [
                {
                    "type": "distribution",
                    "language": "eng",
                    "source": "Revision of Monstera",
                    "description": MONSTERA,
                }
            ],
            "Swiss cheese plant.",
        )
        self.assertIn("rain forest", text)
        self.assertIn("Swiss cheese", text)

    def test_drops_other_genus_notice(self):
        text = harvest_corpus(
            [
                {
                    "type": "distribution",
                    "language": "eng",
                    "source": "Asteraceae of Mexico",
                    "description": "<em>Montanoa hibiscifolia</em> was introduced onto Oahu, in cloud forests of Chiapas.",
                }
            ],
            None,
            genus="Achillea",
        )
        self.assertNotIn("cloud forests", text)

    def test_keeps_vegetation_genus_in_habitat(self):
        text = harvest_corpus(
            [
                {
                    "type": "habitat",
                    "language": "eng",
                    "source": "Flora of Tropical East Africa",
                    "description": "<p>Humid to dry evergreen forest, <i>Brachystegia</i> woodland, dry wooded grassland</p>",
                }
            ],
            None,
            genus="Zamioculcas",
        )
        self.assertIn("woodland", text)

    def test_focuses_bloated_gbif_dump(self):
        dump = [
            {
                "type": "distribution",
                "language": "eng",
                "source": "Asteraceae of Mexico",
                "description": f"Record {i}. Cloud forests of Chiapas.",
            }
            for i in range(13)
        ]
        dump.append(
            {
                "type": "distribution",
                "language": "eng",
                "source": "Flora of North America",
                "description": "Achillea millefolium spans the continental U.S.",
            }
        )
        text = harvest_corpus(dump, None, genus="Achillea")
        self.assertNotIn("Cloud forests", text)
        self.assertIn("millefolium", text)
        text = harvest_corpus(
            [
                {
                    "type": "habitat",
                    "language": "eng",
                    "source": "Flora of Tropical East Africa",
                    "description": "<p>Humid to dry evergreen forest, <i>Brachystegia</i> woodland, dry wooded grassland</p>",
                }
            ],
            None,
            genus="Zamioculcas",
        )
        self.assertIn("woodland", text)
        text = harvest_corpus(
            [
                {
                    "type": "distribution",
                    "language": "eng",
                    "source": "Revision of Monstera",
                    "description": "<em>Monstera</em> in tropical moist forest.",
                }
            ],
            None,
            genus="Monstera",
        )
        self.assertIn("moist forest", text)


class ClassifyTest(unittest.TestCase):
    def test_monstera_rainforest(self):
        self.assertEqual(classify_habitat(MONSTERA), "high")

    def test_aloe_arabia(self):
        self.assertEqual(classify_habitat(ALOE), "low")

    def test_lavender_mediterranean(self):
        self.assertEqual(classify_habitat(LAVENDER), "low")

    def test_schlumbergera_moist_forest(self):
        self.assertEqual(classify_habitat(SCHLUMBERGERA), "high")

    def test_seasonally_dry_is_average(self):
        self.assertEqual(classify_habitat(DRY_FOREST), "average")

    def test_conflict_is_unreadable(self):
        self.assertIsNone(classify_habitat(CONFLICT))

    def test_no_habitat_words(self):
        self.assertIsNone(classify_habitat(EMPTY))

    def test_moist_woodland_is_high_not_just_woodland(self):
        self.assertEqual(classify_habitat("Damp woodland and wet woodland of Atlantic Europe."), "high")

    def test_arabia_felici_is_not_a_desert(self):
        self.assertIsNone(classify_habitat('Habitat in Arabia felici. Coffea arabica, also known as the Arabica coffee.'))

    def test_bog_pine_is_not_a_marsh(self):
        self.assertIsNone(classify_habitat("Pinus mugo, known as dwarf mountain pine, Swiss mountain pine, bog pine, creeping pine."))

    def test_mediterranean_region_is_not_maquis(self):
        self.assertIsNone(
            classify_habitat(
                "Native to western and southern Europe, with diversity in the Mediterranean region."
            )
        )

    def test_mediterranean_climate_cultivation_is_not_habitat(self):
        self.assertIsNone(
            classify_habitat(
                "Basil is native to tropical regions from Central Africa to Southeast Asia. "
                "In temperate climates basil is treated as an annual and grows in a mediterranean climate."
            )
        )


class ApplyTest(unittest.TestCase):
    def test_confirms_current(self):
        self.assertEqual(apply_humidity("high", "high"), "high")

    def test_corrects_cactus_from_moist_forest(self):
        self.assertEqual(apply_humidity("average", "high"), "high")

    def test_unreadable_is_not_sourced(self):
        self.assertIsNone(apply_humidity("low", None))


class SourcingTest(unittest.TestCase):
    def test_humidity_suffix_is_habitat(self):
        name = name_of({"hardiness", "light", "humidity"})
        self.assertEqual(name, "_rhsHardinessLightHumidity")
        self.assertEqual(fields_of(name), {"hardiness", "light", "humidity"})
        rendered = dart_map({"hardiness", "light", "humidity"})
        self.assertIn("CareField.humidity: CareSource.habitat", rendered)
        self.assertIn("CareField.light: CareSource.rhs", rendered)
        self.assertNotIn("CareField.humidity: CareSource.rhs", rendered)

    def test_humidity_alone(self):
        self.assertEqual(name_of({"humidity"}), "_habitatHumidity")
        self.assertEqual(fields_of("_habitatHumidity"), {"humidity"})

    def test_comment_mixes_sources(self):
        text = dart_comment({"light", "humidity"})
        self.assertIn("RHS", text)
        self.assertIn("habitat", text)


class TaxonQueryTest(unittest.TestCase):
    def test_family_is_not_a_taxon(self):
        self.assertIsNone(taxon_query("byFamily", "Orchidaceae", {"query": "Phalaenopsis amabilis"}))

    def test_species_is_always_self(self):
        self.assertEqual(
            taxon_query(
                "bySpecies",
                "Euphorbia tirucalli",
                {"query": "Euphorbia pulcherrima", "slug": "euphorbia-pulcherrima"},
            ),
            "Euphorbia tirucalli",
        )

    def test_genus_uses_same_genus_rep(self):
        self.assertEqual(
            taxon_query(
                "byGenus",
                "Schlumbergera",
                {"query": "Schlumbergera truncata", "slug": "schlumbergera-truncata"},
            ),
            "Schlumbergera truncata",
        )

    def test_genus_rejects_another_genus(self):
        self.assertIsNone(
            taxon_query(
                "byGenus",
                "Dracaena",
                {"query": "Sansevieria trifasciata", "slug": "sansevieria-trifasciata"},
            )
        )


class PatchTest(unittest.TestCase):
    def test_keeps_percent_range(self):
        inner = (
            "      humidity: HumidityNeed.high,\n"
            "      humidityIdealMin: 55,\n"
            "      humidityIdealMax: 75,\n"
            "      sourcing: _rhsHardinessLightWaterIssuesPropagationBloom,\n"
        )
        rec = {
            "humidity": "high",
            "current_sourcing": "_rhsHardinessLightWaterIssuesPropagationBloom",
        }
        out = patch_inner(inner, rec)
        self.assertIn("humidityIdealMin: 55", out)
        self.assertIn("humidityIdealMax: 75", out)
        self.assertIn("humidity: HumidityNeed.high", out)
        self.assertIn("_rhsHardinessLightWaterHumidityIssuesPropagationBloom", out)


if __name__ == "__main__":
    unittest.main()
