import unittest

from light_map import apply_floor, ideal_from_positions, parse_positions


class LightMapTest(unittest.TestCase):
  def test_monstera_partial_only(self):
    pos = parse_positions("Partial shade")
    self.assertEqual(pos, frozenset({"partial"}))
    self.assertEqual(ideal_from_positions(pos), "brightIndirect")
    self.assertEqual(apply_floor("brightIndirect", "brightIndirect"), ("brightIndirect", None))

  def test_sansevieria_sun_and_partial(self):
    pos = parse_positions("Full sun, Partial shade")
    self.assertEqual(ideal_from_positions(pos), "someSun")
    self.assertEqual(apply_floor("someSun", "lowLight"), ("someSun", "lowLight"))

  def test_full_sun_only(self):
    self.assertEqual(ideal_from_positions(parse_positions("Full sun")), "fullSun")

  def test_shade_only(self):
    self.assertEqual(ideal_from_positions(parse_positions("Full shade")), "shade")

  def test_partial_and_shade(self):
    self.assertEqual(ideal_from_positions(parse_positions("Partial shade, Full shade")), "indirect")

  def test_overestimated_sun_is_lowered(self):
    self.assertEqual(apply_floor("brightIndirect", "fullSun"), ("brightIndirect", None))

  def test_empty_position(self):
    self.assertIsNone(ideal_from_positions(parse_positions("")))


if __name__ == "__main__":
  unittest.main()
