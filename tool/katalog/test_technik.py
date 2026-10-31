"""Satz `technik` (Trainingsraum, Hände-Technik). Aufruf: cd tool/katalog && python3 -m unittest -v test_technik"""
import unittest

import katalog
import technik

BEGINNER = ['tech_grip_rebound', 'tech_full_stroke_tap', 'tech_even_singles', 'tech_accent_basics',
            'tech_single_hand_control']
INTERMEDIATE = ['tech_down_up_strokes', 'tech_moving_accents', 'tech_doubles_control',
                'tech_ghost_accent_contrast', 'tech_speed_bursts']


class Technik(unittest.TestCase):
    def test_technik_set_has_5_beginner_and_5_intermediate_sheets(self):
        by = {d: [s.id for s in technik.SHEETS if s.difficulty == d] for d in ('beginner', 'intermediate')}
        self.assertEqual(by['beginner'], BEGINNER)
        self.assertEqual(by['intermediate'], INTERMEDIATE)
        self.assertEqual(len(technik.SHEETS), 10)

    def test_every_technik_sheet_has_area_hand_technique_8_lines_of_4_bars_and_a_lesson(self):
        for s in technik.SHEETS:
            with self.subTest(s.id):
                self.assertEqual(s.area, 'handTechnique')
                self.assertTrue(s.new_seed)
                self.assertEqual(s.line_bars, 4)
                self.assertFalse(s.fill_bar)
                lines = s.parsed()
                self.assertEqual(len(lines), 8)
                self.assertTrue(all(ln.bars == 4 for ln in lines))
                s.pattern_line()
                self.assertEqual(list(s.lesson), ['Why', 'How', 'Tips', 'Song examples'])
                self.assertTrue(all(len(v) > 60 for v in s.lesson.values()))
                self.assertTrue(40 <= s.min_bpm < s.target_bpm <= 240)

    def test_lines_are_written_out(self):
        """Keine Zeile ist viermal derselbe Takt."""
        for s in technik.SHEETS:
            for i, text in enumerate(s.lines):
                bars = [b.strip() for b in text.split('|')]
                self.assertGreater(len(set(bars)), 1, f'{s.id} line {i + 1}')

    def test_registered_in_katalog(self):
        st = katalog.select('technik')[0]
        self.assertIs(st.sheets, technik.SHEETS)
        self.assertTrue(st.seed_marker)

    def test_voice_how_covers_every_sheet_in_40_ascii_words(self):
        self.assertEqual(sorted(technik.VOICE_HOW), sorted(s.id for s in technik.SHEETS))
        for sid, text in technik.VOICE_HOW.items():
            with self.subTest(sid):
                self.assertLessEqual(len(text.split()), 40)
                self.assertTrue(text.isascii())

    def test_gen_raum_voice_writes_h_clips_deterministically(self):
        import pathlib
        import tempfile

        import gen_raum_voice
        with tempfile.TemporaryDirectory() as d:
            root = pathlib.Path(d)
            (root / 'tool/stimme').mkdir(parents=True)
            p = gen_raum_voice.generate(root, technik.SHEETS, technik.VOICE_HOW)
            first = p.read_bytes()
            gen_raum_voice.generate(root, technik.SHEETS, technik.VOICE_HOW)
            self.assertEqual(first, p.read_bytes())
            ns: dict = {}
            exec(first.decode(), ns)
            self.assertEqual(sorted(ns['RAUM']), sorted(f'h_{i}' for i in technik.VOICE_HOW))


if __name__ == '__main__':
    unittest.main()
