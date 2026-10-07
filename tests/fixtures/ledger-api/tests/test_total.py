import unittest

from ledger import total


class TotalTest(unittest.TestCase):
    def test_total(self):
        self.assertEqual(total([{"amount": 2}, {"amount": 3}]), 5)
