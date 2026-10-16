"""Spuren-Notenschrift (Phase B.1): Parser, Dart- und ABC-Ausgabe. Aufruf: cd tool/katalog && python3 -m unittest -v"""
import unittest

from sheetlang import (KitLine, is_kit_text, kit_line_to_abc, kit_line_to_dart, note_to_dart,
                       parse_kit_line, parse_line)

ROCK8 = '''
HH: R8 R8 R8 R8 R8 R8 R8 R8
SN: -4 L4> -4 L4>
BD: K4 -4 K4 -4
'''


class ParseKitLine(unittest.TestCase):
    def test_tracks_instruments_bars(self):
        kl = parse_kit_line(ROCK8)
        self.assertIsInstance(kl, KitLine)
        self.assertEqual([t.key for t in kl.tracks], ['HH', 'SN', 'BD'])
        self.assertEqual([t.instrument for t in kl.tracks], ['hiHatClosed', 'snare', 'kick'])
        self.assertEqual([t.foot for t in kl.tracks], [False, False, True])
        self.assertEqual(kl.bars, 1)
        self.assertTrue(kl.repeat)
        self.assertIsNone(kl.tracks[0].accepts)

    def test_class_suffix(self):
        kl = parse_kit_line('T1~: R16 L16 R16 L16 -4 -2\nC1~: -2. R4>')
        self.assertEqual(kl.tracks[0].accepts, 'anyTom')
        self.assertEqual(kl.tracks[1].accepts, 'anyCrash')
        with self.assertRaises(ValueError):
            parse_kit_line('SN~: R4 L4 R4 L4')  # snare has no class

    def test_feet_and_hands_are_checked(self):
        with self.assertRaises(ValueError):
            parse_kit_line('BD: R4 -4 R4 -4')  # a foot track with hand letters
        with self.assertRaises(ValueError):
            parse_kit_line('SN: K4 -4 K4 -4')  # a hand track with foot letters
        with self.assertRaises(ValueError):
            parse_kit_line('BD: K4f -4 K4 -4')  # no graces on a foot

    def test_lengths_must_agree(self):
        with self.assertRaises(ValueError):
            parse_kit_line('HH: R8 R8 R8 R8 R8 R8 R8 R8 | R8 R8 R8 R8 R8 R8 R8 R8\nBD: K4 -4 K4 -4')
        with self.assertRaises(ValueError):
            parse_kit_line('HH: R4 R4 R4 R4\nHH: R4 R4 R4 R4')  # track twice
        with self.assertRaises(ValueError):
            parse_kit_line('XX: R4 R4 R4 R4')  # unknown track
        with self.assertRaises(ValueError):
            parse_kit_line('')

    def test_is_kit_text(self):
        self.assertTrue(is_kit_text(ROCK8))
        self.assertFalse(is_kit_text('R8 L8 R8 L8 R8 L8 R8 L8'))


class DartOutput(unittest.TestCase):
    def test_foot_note(self):
        self.assertEqual(note_to_dart(parse_line('K4 -2.').notes[0]), 'foot(NoteValue.quarter)')
        self.assertEqual(note_to_dart(parse_line('K8>g -8 -4 -2').notes[0]),
                         'foot(NoteValue.eighth, accent: true, ghost: true)')
        self.assertEqual(note_to_dart(parse_line('3(K8 -8 -8) -2.').notes[0]),
                         'foot(NoteValue.eighth, tuplet: Tuplet.triplet)')

    def test_kit_line(self):
        out = kit_line_to_dart(parse_kit_line('T1~: R16 L16 R16 L16 -4 -2\nBD: K4 -4 K4 -4', counts=True, title='Fill'))
        self.assertTrue(out.startswith('  kitLine([\n'))
        self.assertIn('voice(KitInstrument.tom1, [', out)
        self.assertIn('], accepts: InstrumentClass.anyTom),', out)
        self.assertIn('voice(KitInstrument.kick, [', out)
        self.assertIn('foot(NoteValue.quarter),', out)
        self.assertIn('note(R, NoteValue.sixteenth),', out)
        self.assertTrue(out.rstrip().endswith("], title: 'Fill', counts: true),"))


class AbcOutput(unittest.TestCase):
    def test_two_voices_chords_and_rests(self):
        abc = kit_line_to_abc(parse_kit_line(ROCK8))
        self.assertIn('[V:H]', abc)
        self.assertIn('[V:F]', abc)
        hands = abc.split('[V:H]')[1].split('[V:F]')[0]
        feet = abc.split('[V:F]')[1]
        # Hands: hi-hat eighths, snare joins on 2 and 4 as a chord.
        self.assertEqual(hands.count('['), 2)
        self.assertIn('[cg]', hands)
        # Feet: kick on 1 and 3, invisible rests between.
        self.assertEqual(feet.count('F'), 2)
        self.assertIn('x', feet)
        self.assertTrue(abc.strip().endswith(':|') or abc.strip().endswith('|'))


if __name__ == '__main__':
    unittest.main()
