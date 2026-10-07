import unittest

from convert import km_to_miles


class ConvertTest(unittest.TestCase):
    def test_km(self):
        self.assertAlmostEqual(km_to_miles(10), 6.21371)
