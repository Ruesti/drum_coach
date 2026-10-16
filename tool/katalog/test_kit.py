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


def _abc_ticks(bar: str) -> float:
    """Ticks eines ABC-Takts aus dem Text (L:1/8 = 12 Ticks); versteht `(3` und `(6:4:6`.

    Zählzeiten stehen ohne Leerzeichen (Balken), daher Token per Regex statt `split()`."""
    import re
    total, scale, left = 0.0, 1.0, 0
    tokens = re.findall(r'(\(\d(?::\d:\d)?)?(?:\{[^}]*\}|!.*?!|"[^"]*")*'
                        r'(?:\[[^\]]*\]|[_^]?[A-Ga-gzx])(\d+/\d+|\d+|/+)?', bar)
    for tup, ln in tokens:
        m = re.match(r'^\(([36])(?::(\d):\d)?', tup)
        if m:
            p = int(m.group(1))
            q = int(m.group(2)) if m.group(2) else 2
            scale, left = q / p, p
        units = {'': 1.0, '/': 0.5, '//': 0.25}.get(ln)
        if units is None:
            units = float(ln) if ln.isdigit() else eval(ln)
        total += units * 12 * (scale if left else 1.0)
        if left:
            left -= 1
    return total


class AbcTuplets(unittest.TestCase):
    def voices(self, text):
        abc = kit_line_to_abc(parse_kit_line(text))
        return abc.split('[V:H]')[1].split('[V:F]')[0], abc.split('[V:F]')[1]

    def test_triplet_hands(self):
        hands, _ = self.voices('HH: 3(R8 R8 R8) -4 -4 -4\nBD: K4 -4 -4 -4')
        self.assertIn('(3ggg', hands)
        self.assertEqual(_abc_ticks(hands.split('|:')[1].split(':|')[0]), 96)

    def test_sextuplet_feet(self):
        hands, feet = self.voices('HH: -1\nBD: 6(K16 K16 K16 K16 K16 K16) -4 -4 -4')
        self.assertIn('(6:4:6F/F/F/F/F/F/', feet)
        self.assertEqual(_abc_ticks(feet.split('|:')[1].split(':|')[0]), 96)

    def test_shuffle_hat(self):
        hands, _ = self.voices('HH: ' + ' '.join(['3(R8 -8 R8)'] * 4) + '\nBD: K4 -4 -4 -4')
        self.assertEqual(hands.count('(3'), 4)
        self.assertEqual(hands.count('z'), 4)
        self.assertEqual(_abc_ticks(hands.split('|:')[1].split(':|')[0]), 96)

    def test_foot_triplet_rest_is_visible(self):
        # abcjs 6.4.4 bricht bei einer unsichtbaren Pause `x` in einer Triole ab (TypeError …'top').
        _, feet = self.voices('HH: -1\nBD: 3(K8 -8 K8) -4 -4 -4')
        self.assertIn('(3FzF', feet)
        self.assertNotIn('(3Fx', feet)


class AbcReadability(unittest.TestCase):
    def voices(self, text):
        abc = kit_line_to_abc(parse_kit_line(text))
        return abc.split('[V:H]')[1].split('[V:F]')[0], abc.split('[V:F]')[1]

    def test_beat_groups_joined_without_spaces(self):
        # ABC bricht Balken an Leerzeichen: je Zählzeit ein Token-Block, Leerzeichen nur zwischen Zählzeiten.
        hands, _ = self.voices('HH: R8 R8 R8 R8 R16 R16 R16 R16 R8 R8\nBD: K4 -4 K4 -4')
        body = hands.split('|:')[1].split(':|')[0].split()
        self.assertEqual(body, ['gg', 'gg', 'g/g/g/g/', 'gg'])
        self.assertEqual(_abc_ticks(' '.join(body)), 96)

    def test_open_hat_has_open_decoration(self):
        hands, _ = self.voices('HH: R8 R8 R8 -8 -2\nHO: -4 -8 R8 -2\nBD: K4 -4 -2')
        self.assertIn('g!open!g', hands)
        self.assertEqual(hands.count('!open!'), 1)

    def test_ride_bell_own_pitch_with_diamond(self):
        from sheetlang import KIT_ABC_HEADER
        self.assertIn('%%percmap ^f 53 harmonic\n', KIT_ABC_HEADER)
        hands, _ = self.voices('RB: R4 -4 -2\nRD: -4 R4 -2\nSN: R4 -4 -2\nBD: K4 -4 -2')
        self.assertIn('[c^f]2', hands)
        self.assertIn(' f2', hands)


class Orchestrate(unittest.TestCase):
    def test_beats_go_to_their_drums_tuplets_stay_whole(self):
        from set_fills import orchestrate
        out = orchestrate('R16 L16 R16 L16 R8 L8 3(R8 L8 R8) R4>', ['SN', 'T1~', 'F1~', 'SN'])
        self.assertEqual(out['SN'], 'R16 L16 R16 L16 -4 -4 R4>')
        self.assertEqual(out['T1~'], '-4 R8 L8 -4 -4')
        self.assertEqual(out['F1~'], '-4 -4 3(R8 L8 R8) -4')
        self.assertEqual(set(out), {'SN', 'T1~', 'F1~'})

    def test_a_beat_split_across_tokens_is_refused(self):
        from set_fills import orchestrate
        plan = ['SN', 'T1~', 'F1~', 'SN']
        self.assertEqual(orchestrate('R8. L16 R8. L16 R4 R4', plan)['SN'], 'R8. L16 -4 -4 R4')
        with self.assertRaises(ValueError):
            orchestrate('R4. L8 R4 R4', plan)  # R4. crosses into beat 2
        with self.assertRaises(ValueError):
            orchestrate('R4 R4 R4', plan)  # three quarters, not a bar
        with self.assertRaisesRegex(ValueError, 'beat 2: plan entry is None'):
            orchestrate('R4 R4 R4 R4', ['SN', None, 'SN', 'SN'])


class FootSide(unittest.TestCase):
    def test_side_flags_on_feet(self):
        notes = parse_line('K16r K16l K8 -4 -2').notes
        self.assertEqual([n.side for n in notes], ['R', 'L', None, None, None])
        self.assertEqual(note_to_dart(notes[0]), 'foot(NoteValue.sixteenth, side: R)')
        self.assertEqual(note_to_dart(notes[1]), 'foot(NoteValue.sixteenth, side: L)')
        self.assertEqual(note_to_dart(notes[2]), 'foot(NoteValue.eighth)')
        self.assertEqual(note_to_dart(parse_line('K8>r -8 -2.').notes[0]),
                         'foot(NoteValue.eighth, accent: true, side: R)')

    def test_side_only_on_feet_and_only_one(self):
        with self.assertRaises(ValueError):
            parse_line('R8r L8 R4 L4 R4')
        with self.assertRaises(ValueError):
            parse_line('K8rl -8 -4 -2')
        kl = parse_kit_line('HH: R4 R4 R4 R4\nBD: K16r K16l K16r K16l K4 -2')
        self.assertEqual([n.side for n in kl.tracks[1].notes][:4], ['R', 'L', 'R', 'L'])


class OrchestrateFeet(unittest.TestCase):
    def test_foot_tokens_go_to_bd(self):
        from set_fills import orchestrate
        out = orchestrate('R16 L16 K16 K16 R16 L16 K16 K16 R16 L16 K16 K16 R16 L16 K16 K16',
                          ['SN', 'T1~', 'F1~', 'SN'])
        self.assertEqual(out['BD'], '-8 K16 K16 -8 K16 K16 -8 K16 K16 -8 K16 K16')
        self.assertEqual(out['SN'], 'R16 L16 -8 -4 -4 R16 L16 -8')
        self.assertEqual(out['T1~'], '-4 R16 L16 -8 -4 -4')
        self.assertNotIn('HP', out)

    def test_sided_feet_keep_their_side(self):
        from set_fills import orchestrate
        out = orchestrate('R16 L16 R16 L16 R16 L16 R16 L16 K16r K16l K16r K16l K16r K16l K16r K16l',
                          ['SN', 'T1~', 'F1~', 'SN'])
        self.assertEqual(out['BD'], '-4 -4 K16r K16l K16r K16l K16r K16l K16r K16l')
        self.assertNotIn('F1~', out)  # no hand token on beats 3–4 → no F1 track

    def test_mixed_tuplet_group_is_split_with_rests(self):
        from set_fills import orchestrate
        out = orchestrate('6(R16 L16 K16 R16 L16 K16) R4 R4 R4', ['SN', 'SN', 'SN', 'SN'])
        self.assertEqual(out['SN'].split(' ', 2)[:2], ['6(R16', 'L16'])
        self.assertIn('6(-16 -16 K16 -16 -16 K16)', out['BD'])
        self.assertIn('6(R16 L16 -16 R16 L16 -16)', out['SN'])

    def test_linear_check(self):
        from set_more import is_linear
        self.assertTrue(is_linear(parse_kit_line('HH: R8 -8 R8 -8 R8 -8 R8 -8\nSN: -8 L8 -8 L8 -8 L8 -8 L8')))
        self.assertFalse(is_linear(parse_kit_line('HH: R8 R8 R8 R8 R8 R8 R8 R8\nSN: -4 L4 -4 L4')))


class CheckHands(unittest.TestCase):
    def test_one_hand_on_two_drums_raises(self):
        from sheetlang import check_hands
        with self.assertRaises(ValueError) as cm:
            check_hands(parse_kit_line('HH: R16 L16 R16 L16 -4 -2\nSN: -16 L16g -8 -4 -2'))
        self.assertIn('tick 6', str(cm.exception))

    def test_right_hat_and_left_snare_together_pass(self):
        from sheetlang import check_hands
        check_hands(parse_kit_line('HH: R8 R8 R8 R8 R8 R8 R8 R8\nSN: -4 L4> -4 L4>'))

    def test_flam_grace_is_the_other_hand(self):
        from sheetlang import check_hands
        with self.assertRaises(ValueError):
            check_hands(parse_kit_line('HH: R4 R4 R4 R4\nSN: -4 L4f> -4 L4>'))  # grace R on 2 meets the hat
        check_hands(parse_kit_line('HH: R4 -4 R4 R4\nSN: -4 L4f> -4 L4>'))

    def test_feet_never_collide(self):
        from sheetlang import check_hands
        check_hands(parse_kit_line('HH: R4 R4 R4 R4\nBD: K4r K4r K4l K4l\nHP: P4 P4 P4 P4'))

    def test_sheets_check_their_lines(self):
        from blatt import Sheet
        bad = 'HH: R16 L16 R16 L16 R16 L16 R16 L16 R16 L16 R16 L16 R16 L16 R16 L16\nSN: -16 L16g -8 -4 -2\nBD: K4 -2.'
        sh = Sheet(id='x', name='x', min_bpm=60, target_bpm=100, difficulty='beginner', skills=[], genres=[],
                   description='', pattern=bad, lines=[bad] * 8, challenge=bad, lesson={}, kit=True)
        with self.assertRaises(ValueError) as cm:
            sh.pattern_line()
        self.assertIn('x pattern', str(cm.exception))


if __name__ == '__main__':
    unittest.main()
