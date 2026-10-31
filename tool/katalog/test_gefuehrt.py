"""Geführte Übungen: Notation + Prüfung. Aufruf: cd tool/katalog && python3 -m unittest test_gefuehrt -v"""
import dataclasses
import unittest

from gefuehrt_blatt import DIFFICULTIES, GuidedSheet, Variation, check_catalog

KIT_G = 'HH: R8 R8 R8 R8 R8 R8 R8 R8\nSN: -4 L4> -4 L4>\nBD: K4 -4 K4 -4'
KIT_V = 'HH: R8 R8 R8 R8 R8 R8 R8 R8\nSN: -4 L4> -4 L4>\nBD: K4 K4 K4 -4'
PAD_G = 'R8 L8 R8 L8 R8 L8 R8 L8'
PAD_V = 'R8 L8 L8 R8 R8 L8 L8 R8'


def V(line, text, after='after_good', title='Adds a note'):
    return Variation(line, text, after, title=title)


def mk(package='kit', **kw):
    g, v = (KIT_G, KIT_V) if package == 'kit' else (PAD_G, PAD_V)
    base = dict(
        id=f'guided_{package}_x', name='X', description='d', package=package,
        difficulty='beginner', default_bpm=80, min_bpm=60, max_bpm=100, grid='eighth',
        groove=g,
        variations=(V(v, 'Add a kick.'), V(v, 'Again.'),
                    V(v, 'Last one.', after=None)))
    base.update(kw)
    return GuidedSheet(**base)


class Guided(unittest.TestCase):
    def test_valid_kit_and_pad_sheet_parse(self):
        for p in ('kit', 'pad'):
            groove, vs = mk(p).parsed()
            self.assertEqual(groove.bars, 1)
            self.assertEqual(len(vs), 3)

    def test_rejects_two_variations_rule(self):
        vs = tuple(V(KIT_V, 'Ok.', after='after_good') for _ in range(4))
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
        vs = (V(KIT_V, ' '.join(['w'] * 17)), V(KIT_V, 'a.'),
              V(KIT_V, 'b.', after=None))
        with self.assertRaisesRegex(ValueError, 'text'):
            mk(variations=vs).parsed()

    def test_rejects_non_ascii_and_empty_text(self):
        for t in ('Nice — go', 'Hi \U0001F600', ' '):
            vs = (V(KIT_V, t), V(KIT_V, 'a.'), V(KIT_V, 'b.', after=None))
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
        two = PAD_V + ' | ' + PAD_V
        vs = (V(two, 'a.'), V(PAD_V, 'b.'), V(PAD_V, 'c.', after=None))
        self.assertEqual(mk('pad', variations=vs).parsed()[1][0].bars, 2)
        with self.assertRaises(ValueError):
            mk('pad', groove=' | '.join([PAD_G] * 3)).parsed()

    def test_two_bar_groove_accepted(self):
        self.assertEqual(mk('pad', groove=PAD_G + ' | ' + PAD_G).parsed()[0].bars, 2)

    def test_rejects_two_bar_variation_with_odd_bars(self):
        two = PAD_V + ' | ' + PAD_V
        vs = (V(two, 'a.'), V(PAD_V, 'b.'), V(PAD_V, 'c.', after=None))
        mk('pad', variations=vs).parsed()  # 24 bars: fine
        with self.assertRaisesRegex(ValueError, 'multiple of'):
            mk('pad', variations=vs, variation_bars=22).parsed()

    def test_variation_needs_title(self):
        for kw in ({}, {'title': ''}, {'title': '  '}):
            vs = (Variation(KIT_V, 'a.', **kw), V(KIT_V, 'b.'), V(KIT_V, 'c.', after=None))
            with self.assertRaisesRegex(ValueError, 'title'):
                mk(variations=vs).parsed()

    def test_title_word_limit(self):
        for title, ok in (('One', False), ('Two words', True), ('a b c d e', True),
                          ('a b c d e f', False), ('Caf\u00e9 au lait', False)):
            vs = (V(KIT_V, 'a.', title=title), V(KIT_V, 'b.'), V(KIT_V, 'c.', after=None))
            if ok:
                mk(variations=vs).parsed()
            else:
                with self.assertRaisesRegex(ValueError, 'title'):
                    mk(variations=vs).parsed()

    def test_section_bars_multiple_of_four(self):
        mk(variation_bars=20, groove_bars=8).parsed()
        with self.assertRaisesRegex(ValueError, 'multiple of 4'):
            mk(variation_bars=18).parsed()
        with self.assertRaisesRegex(ValueError, 'multiple of 4'):
            mk(groove_bars=10).parsed()

    def test_four_bar_line_accepted(self):
        four = ' | '.join([PAD_G] * 4)
        groove, _ = mk('pad', groove=four).parsed()
        self.assertEqual(groove.bars, 4)
        vs = (V(' | '.join([PAD_V] * 4), 'a.'), V(PAD_V, 'b.'), V(PAD_V, 'c.', after=None))
        self.assertEqual(mk('pad', variations=vs).parsed()[1][0].bars, 4)

    def test_three_bar_line_rejected(self):
        with self.assertRaisesRegex(ValueError, 'bars'):
            mk('pad', groove=' | '.join([PAD_G] * 3)).parsed()

    # bars(s) * 240 / default_bpm of the 8 exercises BEFORE the 4-bar rounding (seconds)
    OLD_SECONDS = {
        'guided_kit_backbeat_walk': 325.3, 'guided_kit_funk_sixteenths': 308.2,
        'guided_kit_halftime_shuffle': 318.0, 'guided_kit_linear_shift': 304.0,
        'guided_pad_accent_walk': 304.0, 'guided_pad_paradiddle_builder': 299.3,
        'guided_pad_triplet_flams': 306.0, 'guided_pad_fives_and_sixes': 318.0,
    }

    def test_catalog_durations_within_ten_percent(self):
        from gefuehrt import SHEETS, bars
        self.assertEqual({s.id for s in SHEETS}, set(self.OLD_SECONDS))
        for s in SHEETS:
            secs = bars(s) * 240 / s.default_bpm
            old = self.OLD_SECONDS[s.id]
            self.assertLessEqual(abs(secs - old) / old, 0.10, (s.id, secs, old))

    def test_check_catalog_rejects_duplicate_ids(self):
        check_catalog([mk('kit'), mk('pad')])
        with self.assertRaisesRegex(ValueError, 'duplicate'):
            check_catalog([mk('kit'), mk('kit')])

    def test_clip_id(self):
        self.assertEqual(mk(id='guided_x').clip_id(2), 'g_guided_x_v2')


class Generator(unittest.TestCase):
    def _run(self, root):
        import gen_gefuehrt
        from gefuehrt import SHEETS
        gen_gefuehrt.generate(root, SHEETS)
        dart = root / 'lib/features/guided/data/guided_catalog.dart'
        py = root / 'tool/stimme/saetze_gefuehrt.py'
        return dart, py, SHEETS

    def test_generate_writes_catalog_and_sentences(self):
        import pathlib
        import tempfile
        with tempfile.TemporaryDirectory() as d:
            dart, py, sheets = self._run(pathlib.Path(d))
            self.assertTrue(dart.exists() and py.exists())
            text = dart.read_text()
            self.assertIn('final List<GuidedExercise> guidedCatalog = [', text)
            self.assertIn("'g_guided_kit_backbeat_walk_v1'", text)
            self.assertIn('do not edit', text.splitlines()[0])
            ns: dict = {}
            exec(py.read_text(), ns)
            sentences = ns['GEFUEHRT']
            self.assertEqual(len(sentences), sum(len(s.variations) for s in sheets))
            for s in sheets:
                for i, v in enumerate(s.variations, 1):
                    self.assertEqual(sentences[s.clip_id(i)], v.text)

    def test_second_run_writes_identical_files(self):
        import pathlib
        import tempfile
        with tempfile.TemporaryDirectory() as d:
            dart, py, _ = self._run(pathlib.Path(d))
            first = dart.read_bytes(), py.read_bytes()
            self._run(pathlib.Path(d))
            self.assertEqual((dart.read_bytes(), py.read_bytes()), first)

    def test_committed_generated_files_are_current(self):
        import pathlib
        import re
        import tempfile
        repo = pathlib.Path(__file__).resolve().parents[2]

        def norm(t):
            t = re.sub(r'\s+', ' ', t)
            t = re.sub(r',\s*([)\]])', r'\1', t)
            return re.sub(r'\s*([()\[\],])\s*', r'\1', t).strip()  # dart format moves breaks

        with tempfile.TemporaryDirectory() as d:
            dart, py, _ = self._run(pathlib.Path(d))
            self.assertEqual(py.read_bytes(),
                             (repo / 'tool/stimme/saetze_gefuehrt.py').read_bytes())
            committed = repo / 'lib/features/guided/data/guided_catalog.dart'
            self.assertEqual(norm(dart.read_text()), norm(committed.read_text()))

    def test_round1_has_eight_exercises(self):
        from gefuehrt import SHEETS
        check_catalog(SHEETS)
        self.assertEqual(len(SHEETS), 8)
        self.assertEqual(len({s.id for s in SHEETS}), 8)
        for pkg in ('kit', 'pad'):
            self.assertEqual(sorted(s.difficulty for s in SHEETS if s.package == pkg),
                             sorted(DIFFICULTIES), pkg)

    def test_groupings_close_on_the_line(self):
        from gefuehrt import FIVES_AND_SIXES
        from sheetlang import parse_line
        vs = FIVES_AND_SIXES.variations
        for i, v in ((1, vs[0]), (2, vs[1]), (4, vs[3])):  # V3 = flam taps, no grouping
            ln = parse_line(v.line)
            acc = [k for k, n in enumerate(ln.notes) if n.accent]
            gaps = [b - a for a, b in zip(acc, acc[1:] + [acc[0] + len(ln.notes)])]
            self.assertEqual(acc[0], 0, i)
            self.assertEqual(sum(gaps), len(ln.notes), i)
            self.assertTrue(all(g >= 4 for g in gaps), (i, gaps))  # no broken short group

    def test_linear_groove_is_linear(self):
        from gefuehrt import LINEAR_SHIFT, is_linear
        for line in [LINEAR_SHIFT.groove] + [v.line for v in LINEAR_SHIFT.variations]:
            self.assertTrue(is_linear(line), line)


class Page(unittest.TestCase):
    def test_page_contains_every_exercise_and_audio(self):
        import pathlib
        import tempfile
        import build_gefuehrt_page
        from gefuehrt import SHEETS
        with tempfile.TemporaryDirectory() as d:
            out = pathlib.Path(d) / 'p.html'
            build_gefuehrt_page.main(out)
            page = out.read_text()
        for s in SHEETS:
            self.assertIn(f'id="{s.id}"', page)
            for i, v in enumerate(s.variations, 1):
                self.assertIn(s.clip_id(i), page)
        self.assertEqual(page.count('data:audio/wav;base64,'),
                         sum(len(s.variations) for s in SHEETS))
        self.assertIn('<script src="https://cdnjs.cloudflare.com/ajax/libs/abcjs/6.4.4/abcjs-basic-min.js">', page)

    def test_duration_at_default_bpm(self):
        import build_gefuehrt_page
        from gefuehrt import BACKBEAT_WALK
        # 1 count-in + 3 x (12 + 24) + 12 + 1 outro = 122 bars x 2.667 s = 325.3 s
        self.assertEqual(build_gefuehrt_page.duration_label(BACKBEAT_WALK), '~5:25')

    def test_duration_rounds_half_up(self):
        from unittest import mock
        import build_gefuehrt_page
        from gefuehrt import BACKBEAT_WALK
        s = dataclasses.replace(BACKBEAT_WALK, default_bpm=160, max_bpm=160)
        with mock.patch.object(build_gefuehrt_page, 'bars', lambda _s: 1):  # 1.5 s exactly
            self.assertEqual(build_gefuehrt_page.duration_label(s), '~0:02')


if __name__ == '__main__':
    unittest.main()
