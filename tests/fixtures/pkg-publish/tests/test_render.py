import sys
import unittest

sys.path.insert(0, "src")
from tabulate_lite import render  # noqa: E402


class RenderTest(unittest.TestCase):
    def test_aligns(self):
        self.assertEqual(render([["a", "bb"], ["ccc", "d"]]), "a    bb\nccc  d")
