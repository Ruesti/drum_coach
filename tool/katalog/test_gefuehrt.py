"""Geführte Übungen: Notation + Prüfung. Aufruf: cd tool/katalog && python3 -m unittest test_gefuehrt -v"""
import dataclasses
import unittest

from gefuehrt_blatt import GuidedSheet, Variation, check_catalog

KIT_G = 'HH: R8 R8 R8 R8 R8 R8 R8 R8\nSN: -4 L4> -4 L4>\nBD: K4 -4 K4 -4'
KIT_V = 'HH: R8 R8 R8 R8 R8 R8 R8 R8\nSN: -4 L4> -4 L4>\nBD: K4 K4 K4 -4'
PAD_G = 'R8 L8 R8 L8 R8 L8 R8 L8'
PAD_V = 'R8 L8 L8 R8 R8 L8 L8 R8'


def mk(package='kit', **kw):
    g, v = (KIT_G, KIT_V) if package == 'kit' else (PAD_G, PAD_V)
    base = dict(
        id=f'guided_{package}_x', name='X', description='d', package=package,
        difficulty='beginner', default_bpm=80, min_bpm=60, max_bpm=100, grid='eighth',
        groove=g,
        variations=(Variation(v, 'Add a kick.'), Variation(v, 'Again.'),
                    Variation(v, 'Last one.', after=None)))
    base.update(kw)
    return GuidedSheet(**base)


class Guided(unittest.TestCase):
    def test_valid_kit_and_pad_sheet_parse(self):
        for p in ('kit', 'pad'):
            groove, vs = mk(p).parsed()
            self.assertEqual(groove.bars, 1)
            self.assertEqual(len(vs), 3)

    def test_rejects_two_variations_rule(self):
        vs = tuple(Variation(KIT_V, 'Ok.', after='after_good') for _ in range(4))
        with self.assertRaisesRegex(ValueError, 'after'):
            mk(variations=vs).parsed()
        with self.assertRaises(ValueError):
            mk(variations=vs[:2]).parsed()

    def test_rejects_non_whole_bar_line(self):
        with self.assertRaises(ValueError):
            mk('pad', groove='R8 L8 R8').parsed()

    def test_rejects_hand_conflict_kit(self):
        bad = 'HH: R8 R8 R8 R8 R8 R8 R8 R8\nSN: R4 -4 -4 -4\nBD: K4 -4 K4 -4'
        with self.assertRaises(ValueError):
            mk(groove=bad).parsed()

    def test_rejects_long_text(self):
        vs = (Variation(KIT_V, ' '.join(['w'] * 17)), Variation(KIT_V, 'a.'),
              Variation(KIT_V, 'b.', after=None))
        with self.assertRaisesRegex(ValueError, 'text'):
            mk(variations=vs).parsed()

    def test_rejects_non_ascii_and_empty_text(self):
        for t in ('Nice — go', 'Hi \U0001F600', ' '):
            vs = (Variation(KIT_V, t), Variation(KIT_V, 'a.'), Variation(KIT_V, 'b.', after=None))
            with self.assertRaises(ValueError):
                mk(variations=vs).parsed()

    def test_rejects_bad_fields(self):
        for kw in (dict(package='x'), dict(difficulty='easy'), dict(min_bpm=30),
                   dict(max_bpm=241), dict(default_bpm=50), dict(id='demo_kit_rock8'),
                   dict(id='kit_x'), dict(id='guided_A')):
            with self.assertRaises(ValueError, msg=str(kw)):
                mk(**kw).parsed()

    def test_two_bar_line_ok_three_bar_not(self):
        two = KIT_G.replace('\n', ' | R8 R8 R8 R8 R8 R8 R8 R8\n', 1)  # only HH extended -> mismatch
        with self.assertRaises(ValueError):
            mk(groove=two).parsed()
        self.assertEqual(mk('pad', groove=PAD_G + ' | ' + PAD_G).parsed()[0].bars, 2)
        with self.assertRaises(ValueError):
            mk('pad', groove=' | '.join([PAD_G] * 3)).parsed()

    def test_check_catalog_rejects_duplicate_ids(self):
        check_catalog([mk('kit'), mk('pad')])
        with self.assertRaisesRegex(ValueError, 'duplicate'):
            check_catalog([mk('kit'), mk('kit')])

    def test_clip_id(self):
        self.assertEqual(mk(id='guided_x').clip_id(2), 'g_guided_x_v2')


if __name__ == '__main__':
    unittest.main()
