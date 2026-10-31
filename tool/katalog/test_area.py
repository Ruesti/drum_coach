"""Bereich + Songhinweis am Blatt und im Seed. Aufruf: cd tool/katalog && python3 -m unittest -v test_area"""
import pathlib
import tempfile
import unittest

import patch_seed
from blatt import Sheet


def _sheet(**kw):
    base = dict(id='x_test', name='X', min_bpm=60, target_bpm=100, difficulty='beginner',
                skills=['control'], genres=[], description='d', pattern='R8', lines=['R8'] * 8, lesson={})
    base.update(kw)
    return Sheet(**base)


class Area(unittest.TestCase):
    def test_defaults(self):
        s = _sheet()
        self.assertIsNone(s.area)
        self.assertIsNone(s.song)

    def test_unknown_area_rejected(self):
        with self.assertRaises(ValueError):
            _sheet(area='nonsense')

    def test_known_area_ok(self):
        self.assertEqual(_sheet(area='handTechnique').area, 'handTechnique')

    def test_patch_seed_writes_area(self):
        e = patch_seed._entry(_sheet(area='metal', song='Like in: X'))
        self.assertIn('area: TrainingArea.metal,', e)
        self.assertIn('songHint: "Like in: X",', e)
        e = patch_seed._entry(_sheet())
        self.assertNotIn('area:', e)
        self.assertNotIn('songHint:', e)

    def test_update_existing_adds_and_replaces(self):
        src = "  Rudiment(\n    id: 'x_test',\n    name: 'X',\n    sticking: a,\n  ),\n];\n"
        at = src.index("    id: 'x_test',")
        s = _sheet(area='feet', song='Like in: A')
        out = patch_seed._update(src, at, 'xTest', s)
        self.assertEqual(out.count('area: TrainingArea.feet,'), 1)
        s2 = _sheet(area='fills', song='Like in: B')
        out2 = patch_seed._update(out, out.index("    id: 'x_test',"), 'xTest', s2)
        self.assertEqual(out2.count('area:'), 1)
        self.assertIn('TrainingArea.fills', out2)
        self.assertNotIn('TrainingArea.feet', out2)
        self.assertIn('songHint: "Like in: B",', out2)
        self.assertEqual(out2.count('songHint:'), 1)


if __name__ == '__main__':
    unittest.main()
