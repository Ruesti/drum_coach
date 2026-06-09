import '../models/rudiment.dart';

const rudimentsSeedData = <Rudiment>[
  // ─── ROLLS ────────────────────────────────────────────────────────────────

  Rudiment(
    id: 'single_stroke_roll',
    name: 'Single Stroke Roll',
    category: 'Rolls',
    description:
        'The most fundamental rudiment. Alternate single strokes between hands '
        'as fast and evenly as possible. Focus on equal pressure and rebound.',
    minBpm: 60,
    targetBpm: 200,
    difficulty: Difficulty.beginner,
    sticking: [
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
    ],
    technique: [
      TechniqueSection(
        title: 'Bewegung',
        body:
            'Lass den Stock nach dem Aufprall natürlich zurückfedern — kein aktives Hochziehen. '
            'Die Bewegung kommt aus dem Handgelenk, der Arm bleibt entspannt. '
            'Beide Hände sollten identisch aussehen und klingen.',
      ),
      TechniqueSection(
        title: 'Häufige Fehler',
        body:
            '• Zu festes Greifen beim Rebound — der Stock braucht Spielraum\n'
            '• Ungleiche Lautstärke zwischen rechts und links\n'
            '• Schultern hochziehen bei höherem Tempo',
      ),
      TechniqueSection(
        title: 'Übungsplan',
        body:
            'Beginne mit 60 BPM als Achtelnoten. Steigere erst wenn beide Hände '
            'klingen wie eine. Nutze ein Metronom und höre auf Lücken oder Rushes. '
            'Übe vor einem Spiegel um die Handhaltung zu vergleichen.',
      ),
      TechniqueSection(
        title: 'Musikalische Anwendung',
        body:
            'Grundlage für alles — Fills, Hi-Hat-Patterns, Ghostnote-Grooves. '
            'Ohne einen soliden Single Stroke Roll funktioniert kein anderes Rudiment.',
      ),
    ],
  ),

  Rudiment(
    id: 'double_stroke_roll',
    name: 'Double Stroke Roll',
    category: 'Rolls',
    description:
        'Two consecutive strokes per hand. The second stroke uses the natural '
        'rebound of the stick. Keep both strokes even in volume and timing.',
    minBpm: 60,
    targetBpm: 180,
    difficulty: Difficulty.beginner,
    sticking: [
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat(hand: Hand.left),
    ],
    technique: [
      TechniqueSection(
        title: 'Bewegung',
        body:
            'Erster Schlag: volle Stockhöhe, aktiver Handgelenksschwung. '
            'Zweiter Schlag: kontrollierter Rebound — der Stock "fällt" zurück. '
            'Bei langsamem Tempo: zwei bewusste Schläge. Bei Geschwindigkeit: '
            'Rebound übernimmt den zweiten Schlag automatisch.',
      ),
      TechniqueSection(
        title: 'Häufige Fehler',
        body:
            '• Zweiter Schlag leiser als der erste\n'
            '• Zu wenig Fingerkontrolle — Finger helfen dem Rebound\n'
            '• Beide Schläge gleich weit auseinander statt eng beieinander',
      ),
      TechniqueSection(
        title: 'Übungsplan',
        body:
            'Übe zunächst jeden Doppelschlag extrem langsam als zwei separate, '
            'bewusste Bewegungen. Steigere das Tempo schrittweise. '
            'Das "Klick-Klick" muss sich wie ein "Klack" anfühlen.',
      ),
      TechniqueSection(
        title: 'Musikalische Anwendung',
        body:
            'Kern des Buzz Rolls bei Höchstgeschwindigkeit. '
            'Doppelschläge auf Snare und Toms für Fills. '
            'Wichtig in Latin-Rhythmen (Conga-Transfers).',
      ),
    ],
  ),

  Rudiment(
    id: 'multiple_bounce_roll',
    name: 'Multiple Bounce Roll',
    category: 'Rolls',
    description:
        'Also called buzz roll. Press the stick into the drum head to create '
        'multiple uncontrolled bounces per stroke. Creates a sustained roll sound.',
    minBpm: 40,
    targetBpm: 100,
    difficulty: Difficulty.intermediate,
    sticking: [
      StrokeBeat(hand: Hand.right, isGhost: true),
      StrokeBeat(hand: Hand.left, isGhost: true),
      StrokeBeat(hand: Hand.right, isGhost: true),
      StrokeBeat(hand: Hand.left, isGhost: true),
    ],
    technique: [
      TechniqueSection(
        title: 'Bewegung',
        body:
            'Drücke den Stock leicht in das Fell — nicht festhalten, sondern '
            'geführt drücken. Der Stock bounced mehrfach unkontrolliert. '
            'Der Druck bestimmt die Dichte der Bounces. '
            'Wechsle beide Hände so, dass kein Unterbruch hörbar ist.',
      ),
      TechniqueSection(
        title: 'Häufige Fehler',
        body:
            '• Stock zwischen den Schlägen anheben (hörbare Lücken)\n'
            '• Zu viel oder zu wenig Druck\n'
            '• Hände nicht gleichmäßig wechseln',
      ),
      TechniqueSection(
        title: 'Übungsplan',
        body:
            'Finde zunächst mit einer Hand die richtige Druckstärke. '
            'Dann übe beide Hände einzeln. Erst wenn jede Hand allein '
            'einen gleichmäßigen Buzz erzeugt, kombiniere sie.',
      ),
      TechniqueSection(
        title: 'Musikalische Anwendung',
        body:
            'Crescendo-Rolls und Fermatenschläge. Unverzichtbar im Orchester '
            'und Marching Band. Gibt Snare-Solos dramatischen Ausdruck.',
      ),
    ],
  ),

  // ─── PARADIDDLES ──────────────────────────────────────────────────────────

  Rudiment(
    id: 'single_paradiddle',
    name: 'Single Paradiddle',
    category: 'Paradiddles',
    description:
        'RLRR LRLL. One of the most important rudiments. The double stroke at '
        'the end shifts the leading hand on each repetition. Great for fills and grooves.',
    minBpm: 60,
    targetBpm: 120,
    difficulty: Difficulty.beginner,
    sticking: [
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.left),
    ],
    technique: [
      TechniqueSection(
        title: 'Bewegung',
        body:
            'Akzent auf Schlag 1 jeder Gruppe (R und L abwechselnd). '
            'Die Doppelschläge am Ende jeder Gruppe (RR / LL) wechseln '
            'automatisch die führende Hand beim nächsten Durchgang. '
            'Sprich das Pattern laut: "Para-did-dle, para-did-dle".',
      ),
      TechniqueSection(
        title: 'Häufige Fehler',
        body:
            '• Akzent nur auf der rechten Hand\n'
            '• Doppelschläge ungleichmäßig (zweiter Schlag zu leise)\n'
            '• Tempo beim Wechsel der führenden Hand instabil',
      ),
      TechniqueSection(
        title: 'Übungsplan',
        body:
            'Übe zunächst nur R–L–R–R, dann nur L–R–L–L. '
            'Dann verbinde beide. Variante: Akzente auf den Doubles (RL**RR** / LR**LL**) '
            'für einen anderen Groove-Charakter.',
      ),
      TechniqueSection(
        title: 'Musikalische Anwendung',
        body:
            'Eines der vielseitigsten Rudiments. Fills, Grooves, Solo-Patterns. '
            'Über das Drumset verteilt ergibt jeder Schlag einen anderen Klang. '
            'Eines der 40 PAS-Rudiments die jeder Schlagzeuger kennen muss.',
      ),
    ],
  ),

  Rudiment(
    id: 'double_paradiddle',
    name: 'Double Paradiddle',
    category: 'Paradiddles',
    description:
        'RLRLRR LRLRLL. Extends the paradiddle concept with two extra single '
        'strokes. Creates a 12-note phrase that works well over triplet-feel rhythms.',
    minBpm: 50,
    targetBpm: 100,
    difficulty: Difficulty.intermediate,
    sticking: [
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.left),
    ],
    technique: [
      TechniqueSection(
        title: 'Bewegung',
        body:
            '12 Noten pro Zyklus: RLRLRR / LRLRLL. '
            'Vier Einzelschläge, dann ein Doppelschlag. '
            'Akzent auf Note 1 wechselt automatisch zwischen R und L. '
            'Denke: "Para-para-diddle".',
      ),
      TechniqueSection(
        title: 'Häufige Fehler',
        body:
            '• Den Überblick verlieren welche Hand führt\n'
            '• Ungleichmäßige Unterteilungen\n'
            '• Doppelschlag bricht das Groove-Gefühl',
      ),
      TechniqueSection(
        title: 'Übungsplan',
        body:
            'Zähle "1-e-+-a-2-+" um die 12er-Gruppe in 12/8-Feeling einzubetten. '
            'Übe zunächst extrem langsam mit Akzenten, dann steigere das Tempo.',
      ),
      TechniqueSection(
        title: 'Musikalische Anwendung',
        body:
            'Funktioniert natürlich über Triolen-Rhythmen (12/8, Shuffle). '
            'Häufig in Jazz und Fusion. Gut für Fills über drei Beats.',
      ),
    ],
  ),

  Rudiment(
    id: 'paradiddle_diddle',
    name: 'Paradiddle-Diddle',
    category: 'Paradiddles',
    description:
        'RLRRLL LRLLRR. A 6-note phrase built from the paradiddle with a trailing '
        'double stroke. Creates a feeling of three over two when played at speed.',
    minBpm: 60,
    targetBpm: 100,
    difficulty: Difficulty.intermediate,
    sticking: [
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.right),
    ],
    technique: [
      TechniqueSection(
        title: 'Bewegung',
        body:
            '6 Noten: R-L-RR-LL. Denke: "Para-did-dle-did-dle". '
            'Das Pattern teilt sich in drei 2er-Gruppen, was bei '
            'Wiederholung einen 3-gegen-2 Polyrhythmus erzeugt.',
      ),
      TechniqueSection(
        title: 'Häufige Fehler',
        body:
            '• Doppelschläge in unterschiedlichen Lautstärken\n'
            '• Zweiter Doppelschlag (LL) wird hastig gespielt\n'
            '• Akzent geht verloren bei höherem Tempo',
      ),
      TechniqueSection(
        title: 'Übungsplan',
        body:
            'Denke in 6er-Gruppen. Übe als Triolen (3+3 über 4/4) '
            'um das Polyrhythmus-Gefühl zu entwickeln.',
      ),
      TechniqueSection(
        title: 'Musikalische Anwendung',
        body:
            'Erzeugt bei Geschwindigkeit ein polyrhythmisches Gefühl. '
            'Sehr effektiv in Drum-Solos und für komplexe Fills.',
      ),
    ],
  ),

  // ─── FLAMS ────────────────────────────────────────────────────────────────

  Rudiment(
    id: 'flam',
    name: 'Flam',
    category: 'Flams',
    description:
        'A grace note played just before the main stroke, creating a thicker '
        'sound. The grace note (shown smaller) is barely audible — keep it tight.',
    minBpm: 60,
    targetBpm: 120,
    difficulty: Difficulty.intermediate,
    sticking: [
      StrokeBeat(hand: Hand.left, isGhost: true),
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.right, isGhost: true),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat(hand: Hand.left, isGhost: true),
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.right, isGhost: true),
      StrokeBeat(hand: Hand.left, isAccent: true),
    ],
    technique: [
      TechniqueSection(
        title: 'Stockhaltung',
        body:
            'Grace-Note-Hand: Stock 2–3 cm über dem Fell halten. '
            'Hauptschlag-Hand: Stock 20–25 cm hoch. '
            'Beide Stöcke landen fast gleichzeitig — Grace Note knapp vorher. '
            'Nach dem Flam wechseln die Hände die Höhe.',
      ),
      TechniqueSection(
        title: 'Häufige Fehler',
        body:
            '• Grace Note zu laut — klingt wie zwei separate Schläge\n'
            '• Beide Hände auf gleicher Höhe\n'
            '• Flam zu "offen" (zu viel Zeit zwischen Grace Note und Hauptschlag)',
      ),
      TechniqueSection(
        title: 'Übungsplan',
        body:
            'Übe extrem langsam. Halte die Grace-Note-Hand dicht am Fell '
            'und bewege nur die Hauptschlag-Hand. '
            'Akzeptiere anfangs einen "offenen" Flam und schließe ihn schrittweise.',
      ),
      TechniqueSection(
        title: 'Musikalische Anwendung',
        body:
            'Fügt Snare-Akzenten Gewicht und Textur hinzu. '
            'Klassisch in Rock, Rudimental- und Marching-Drumming. '
            'Macht Fills dramatischer und "fetter".',
      ),
    ],
  ),

  Rudiment(
    id: 'flam_accent',
    name: 'Flam Accent',
    category: 'Flams',
    description:
        'A flam followed by two taps: lR L R / rL R L. Each group of three '
        'starts with a flam accent. Common in rudimental and orchestral drumming.',
    minBpm: 50,
    targetBpm: 100,
    difficulty: Difficulty.intermediate,
    sticking: [
      StrokeBeat(hand: Hand.left, isGhost: true),
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.right, isGhost: true),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
    ],
    technique: [
      TechniqueSection(
        title: 'Bewegung',
        body:
            'Jede Gruppe: Flam (lR oder rL) gefolgt von zwei Taps. '
            'Der Flam ist der Akzent, die zwei Taps sind leise. '
            'Sprich: "FLAM-tap-tap, FLAM-tap-tap".',
      ),
      TechniqueSection(
        title: 'Häufige Fehler',
        body:
            '• Taps nach dem Flam zu laut\n'
            '• Flam nicht eng genug\n'
            '• Tempo bricht nach dem Flam ein',
      ),
      TechniqueSection(
        title: 'Übungsplan',
        body:
            'Übe zunächst jede Gruppe einzeln: Flam, Tap, Tap — Pause. '
            'Dann verbinde. Akzentiere den Flam stark, spiele die Taps sehr leise.',
      ),
      TechniqueSection(
        title: 'Musikalische Anwendung',
        body:
            'Klassisches Rudimental-Pattern. Ideal für Snare-Solos und Fills. '
            'In der Marching-Percussion allgegenwärtig.',
      ),
    ],
  ),

  Rudiment(
    id: 'flam_paradiddle',
    name: 'Flam Paradiddle',
    category: 'Flams',
    description:
        'lRLRR / rLRLL. A paradiddle with a flam on the leading stroke. '
        'The grace note adds texture and challenges your stick control significantly.',
    minBpm: 40,
    targetBpm: 90,
    difficulty: Difficulty.advanced,
    sticking: [
      StrokeBeat(hand: Hand.left, isGhost: true),
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.right, isGhost: true),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.left),
    ],
    technique: [
      TechniqueSection(
        title: 'Bewegung',
        body:
            'Ein Paradiddle mit Flam auf dem ersten Schlag jeder Gruppe. '
            'lRLRR: Grace Note links, Hauptschlag rechts, dann L-R-R weiter. '
            'Die Grace Note muss trotz nachfolgender Schläge eng am Flam bleiben.',
      ),
      TechniqueSection(
        title: 'Häufige Fehler',
        body:
            '• Grace Note geht im Rest des Patterns unter\n'
            '• Tempo nach dem Flam instabil\n'
            '• Doppelschlag am Ende verliert Kontrolle',
      ),
      TechniqueSection(
        title: 'Übungsplan',
        body:
            'Beherrsche zuerst den Single Paradiddle ohne Flam. '
            'Füge dann langsam die Grace Note hinzu. '
            'Sehr langsames Üben (40 BPM) ist hier essenziell.',
      ),
      TechniqueSection(
        title: 'Musikalische Anwendung',
        body:
            'Hohes Niveau der Stockkontrolle. Eindrucksvolle Textur für '
            'Drum-Solos und komplexe Fills. Setzt Paradiddle und Flam-Kontrolle voraus.',
      ),
    ],
  ),

  // ─── RUFFS / DRAGS ────────────────────────────────────────────────────────

  Rudiment(
    id: 'single_drag',
    name: 'Single Drag',
    category: 'Ruffs',
    description:
        'Two grace notes preceding the main stroke: llR rRL. The drag (two ghost '
        'notes) sounds like a rapid roll before the accent. Keep the drags light.',
    minBpm: 50,
    targetBpm: 100,
    difficulty: Difficulty.intermediate,
    sticking: [
      StrokeBeat(hand: Hand.left, isGhost: true),
      StrokeBeat(hand: Hand.left, isGhost: true),
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.right, isGhost: true),
      StrokeBeat(hand: Hand.right, isGhost: true),
      StrokeBeat(hand: Hand.left, isAccent: true),
    ],
    technique: [
      TechniqueSection(
        title: 'Was ist ein Drag?',
        body:
            'Ein Drag besteht aus zwei Ghost Notes (ll oder rr) direkt vor '
            'dem Hauptschlag. Sie klingen wie ein miniatur Doppelschlag. '
            'Der Drag soll sich wie ein einzelnes Ereignis anfühlen, nicht drei.',
      ),
      TechniqueSection(
        title: 'Bewegung',
        body:
            'Die zwei Ghost Notes sehr eng und leise, fast gleichzeitig. '
            'Dann der Hauptschlag mit voller Lautstärke. '
            'Denke: "drr-SCHLAG, drr-SCHLAG" nicht "l-l-R".',
      ),
      TechniqueSection(
        title: 'Häufige Fehler',
        body:
            '• Drag-Noten zu laut oder zu weit auseinander\n'
            '• Drag klingt wie drei separate Schläge\n'
            '• Timing des Hauptschlags durch den Drag versetzt',
      ),
      TechniqueSection(
        title: 'Übungsplan',
        body:
            'Übe zunächst nur den Drag (ll) ohne Hauptschlag. '
            'Dann füge den Hauptschlag hinzu. Der Drag muss "zerquetscht" '
            'klingen — dicht vor dem Akzent.',
      ),
    ],
  ),

  Rudiment(
    id: 'double_drag',
    name: 'Double Drag',
    category: 'Ruffs',
    description:
        'Two drag taps followed by an accent: llR L llR L / rrL R rrL R. '
        'Requires independent control of both hands to execute the drags cleanly.',
    minBpm: 40,
    targetBpm: 80,
    difficulty: Difficulty.advanced,
    sticking: [
      StrokeBeat(hand: Hand.left, isGhost: true),
      StrokeBeat(hand: Hand.left, isGhost: true),
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.left, isGhost: true),
      StrokeBeat(hand: Hand.left, isGhost: true),
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.left),
    ],
    technique: [
      TechniqueSection(
        title: 'Aufbau',
        body:
            'Drag + Akzent + Tap, dann wiederholen: llR L / llR L. '
            'Insgesamt vier Schläge pro Gruppe: zwei Ghost-Noten, ein Akzent, ein Tap. '
            'Der Tap nach dem Akzent ist mittelstark.',
      ),
      TechniqueSection(
        title: 'Häufige Fehler',
        body:
            '• Hetzen nach dem Drag\n'
            '• Tap nach dem Akzent zu laut oder zu leise\n'
            '• Drags werden breiter bei höherem Tempo',
      ),
      TechniqueSection(
        title: 'Übungsplan',
        body:
            'Zähle in 4er-Gruppen. Der Drag nimmt fast keine Zeit ein — '
            'er wird direkt vor Beat 1 "gequetscht". '
            'Übe den Drag separat bis er automatisch sitzt.',
      ),
      TechniqueSection(
        title: 'Musikalische Anwendung',
        body:
            'Komplexes Rudimental-Pattern. Taucht in Snare-Drum-Etüden '
            'und Drum-Corps-Musik auf.',
      ),
    ],
  ),

  Rudiment(
    id: 'lesson_25',
    name: 'Lesson 25',
    category: 'Ruffs',
    description:
        'Also called the double drag tap. Two sets of drag taps ending with a '
        'double stroke: llR llR R / rrL rrL L. A classic rudimental pattern.',
    minBpm: 40,
    targetBpm: 80,
    difficulty: Difficulty.advanced,
    sticking: [
      StrokeBeat(hand: Hand.left, isGhost: true),
      StrokeBeat(hand: Hand.left, isGhost: true),
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.left, isGhost: true),
      StrokeBeat(hand: Hand.left, isGhost: true),
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.right, isGhost: true),
      StrokeBeat(hand: Hand.right, isGhost: true),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat(hand: Hand.right, isGhost: true),
      StrokeBeat(hand: Hand.right, isGhost: true),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat(hand: Hand.left),
    ],
    technique: [
      TechniqueSection(
        title: 'Herkunft',
        body:
            '"Lesson 25" stammt aus dem traditionellen Drum-Corps-Unterricht. '
            'Zwei Drags gefolgt von einem Doppelschlag: llR llR R. '
            'Der Name kommt von der Lektion Nr. 25 in klassischen Unterrichtswerken.',
      ),
      TechniqueSection(
        title: 'Bewegung',
        body:
            'Erster Drag + Akzent, zweiter Drag + Akzent, dann Doppelschlag. '
            'Alle Drags bleiben eng und leise. Der abschließende Doppelschlag '
            'hat dieselbe Lautstärke wie die Akzente.',
      ),
      TechniqueSection(
        title: 'Häufige Fehler',
        body:
            '• Doppelschlag am Ende zu laut oder zu leise\n'
            '• Drags werden breiter und lauter unter Druck\n'
            '• Timing driftet im zweiten Drag',
      ),
      TechniqueSection(
        title: 'Übungsplan',
        body:
            'Dieses Pattern braucht viel Zeit. '
            'Beginne bei 40 BPM und steigere erst nach Wochen. '
            'Übe jeden Drag separat bis er sitzt.',
      ),
    ],
  ),

  // ─── GHOST NOTES ──────────────────────────────────────────────────────────

  Rudiment(
    id: 'ghost_note_groove',
    name: 'Ghost Note Groove',
    category: 'Ghost Notes',
    description:
        'A groove built around accent and ghost note contrast. The accented '
        'strokes cut through while ghost notes fill the space between beats. '
        'Focus on a dramatic dynamic difference between the two.',
    minBpm: 60,
    targetBpm: 120,
    difficulty: Difficulty.intermediate,
    sticking: [
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.left, isGhost: true),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left, isGhost: true),
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.left, isGhost: true),
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.left, isGhost: true),
    ],
    technique: [
      TechniqueSection(
        title: 'Das Konzept',
        body:
            'Ghost Notes sind so leise, dass sie kaum hörbar sind — '
            'sie "fühlen" den Groove, anstatt ihn zu bestimmen. '
            'Die Dynamikdifferenz zwischen Akzent und Ghost Note '
            'muss dramatisch sein: Akzente 20–25 cm Stockhöhe, '
            'Ghost Notes 1–2 cm.',
      ),
      TechniqueSection(
        title: 'Bewegung',
        body:
            'Akzent-Hand: Handgelenk schnappt nach unten aus voller Höhe. '
            'Ghost-Note-Hand: Stock liegt fast auf dem Fell, '
            'minimale Bewegung, kein Handgelenkschwung.',
      ),
      TechniqueSection(
        title: 'Häufige Fehler',
        body:
            '• Ghost Notes zu laut — dominieren den Groove\n'
            '• Stockhöhe bei Akzenten zu niedrig\n'
            '• Timing der Ghost Notes ungenau',
      ),
      TechniqueSection(
        title: 'Musikalische Anwendung',
        body:
            'Grundlage von Funk und R&B-Drumming. '
            'Ghost Notes geben dem Groove Tiefe und "Feel". '
            'Denk an Steve Gadd, Vinnie Colaiuta, Questlove.',
      ),
    ],
  ),

  Rudiment(
    id: 'dynamics_control',
    name: 'Dynamics Control',
    category: 'Ghost Notes',
    description:
        'Systematic practice of forte and piano strokes in alternation. '
        'The goal is a clean, consistent contrast — not just louder and quieter, '
        'but a completely different stroke height and feel.',
    minBpm: 40,
    targetBpm: 80,
    difficulty: Difficulty.beginner,
    sticking: [
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.left, isGhost: true),
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.left, isGhost: true),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat(hand: Hand.right, isGhost: true),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat(hand: Hand.right, isGhost: true),
    ],
    technique: [
      TechniqueSection(
        title: 'Grundprinzip',
        body:
            'Lautstärke kommt aus der Stockhöhe, nicht aus der Kraft. '
            'Forte = hoher Stock (20–25 cm), lockeres Handgelenk, '
            'schneller Schwung. Piano = niedriger Stock (2–3 cm), '
            'kontrollierte, kleine Bewegung.',
      ),
      TechniqueSection(
        title: 'Häufige Fehler',
        body:
            '• Lautstärke durch Griffdruck steuern (falsch!)\n'
            '• Forte-Schläge zu verkrampft\n'
            '• Piano-Schläge zittern oder sind ungleichmäßig',
      ),
      TechniqueSection(
        title: 'Übungsplan',
        body:
            'Übe beide Schlagtypen separat bis jede Höhe konsistent ist. '
            'Dann wechsle zwischen beiden. Aufnehmen und zurückhören '
            'hilft extrem um den Dynamikunterschied objektiv zu beurteilen.',
      ),
      TechniqueSection(
        title: 'Warum ist das wichtig?',
        body:
            'Dynamikkontrolle ist Musikalität. Wer Lautstärke kontrollieren kann, '
            'kann jeden Stil bedienen — von leisem Jazz bis hartem Rock. '
            'Es ist die grundlegendste Ausdrucksmöglichkeit am Schlagzeug.',
      ),
    ],
  ),

  // ─── LINEAR PATTERNS ──────────────────────────────────────────────────────

  Rudiment(
    id: 'linear_beat_1',
    name: 'Linear Beat 1',
    category: 'Linear Patterns',
    description:
        'A linear pattern where only one hand plays at a time. No simultaneous '
        'strokes. Builds independence and creates a flowing, open texture. '
        'Common in funk and fusion drumming.',
    minBpm: 60,
    targetBpm: 120,
    difficulty: Difficulty.intermediate,
    sticking: [
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left, isGhost: true),
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left, isGhost: true),
      StrokeBeat(hand: Hand.left),
    ],
    technique: [
      TechniqueSection(
        title: 'Was ist Linear?',
        body:
            'Linear bedeutet: es schlägt immer nur eine Hand gleichzeitig. '
            'Keine Unisono-Hits. Die Hände füllen gegenseitig die Lücken '
            'und erzeugen so einen fließenden, gleichmäßigen Strom von Noten.',
      ),
      TechniqueSection(
        title: 'Bewegung',
        body:
            'Akzente von 20 cm Höhe, Taps von 10 cm, Ghost Notes von 2 cm. '
            'Die verschiedenen Höhen innerhalb des Patterns geben ihm '
            'Tiefe und Groove. Kein Schlag gleicht dem anderen.',
      ),
      TechniqueSection(
        title: 'Häufige Fehler',
        body:
            '• Zögern zwischen den Noten — das Pattern muss fließen\n'
            '• Alle Noten auf gleicher Lautstärke\n'
            '• Tempo bricht bei Handwechsel von R zu R oder L zu L',
      ),
      TechniqueSection(
        title: 'Übungsplan',
        body:
            'Beginne bei 50 BPM und spiele das Pattern bis es sich automatisch '
            'anfühlt. Dann steigere. Übertragen auf das Drumset: '
            'jede Hand auf ein anderes Instrument verteilen.',
      ),
    ],
  ),

  Rudiment(
    id: 'linear_beat_2',
    name: 'Linear Beat 2',
    category: 'Linear Patterns',
    description:
        'A second linear combination exploring a different grouping. '
        'Practice slowly to internalize the pattern before building speed. '
        'Ghost notes add texture without disturbing the groove.',
    minBpm: 60,
    targetBpm: 100,
    difficulty: Difficulty.intermediate,
    sticking: [
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.left, isGhost: true),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat(hand: Hand.right, isGhost: true),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.left, isGhost: true),
    ],
    technique: [
      TechniqueSection(
        title: 'Aufbau',
        body:
            'Eine andere Gruppierung als Linear Beat 1. '
            'Doppelschläge derselben Hand (RR, LL) sind erlaubt — '
            'das unterscheidet es vom reinen Alternating-Linear-Pattern. '
            'Akzente auf Positionen 1, 5, 9 erzeugen eine 10-Noten-Phrase.',
      ),
      TechniqueSection(
        title: 'Häufige Fehler',
        body:
            '• Doppelschläge (RR, LL) zu laut oder ungleich\n'
            '• Akzentmuster geht verloren\n'
            '• Ghost Notes fehlen oder sind zu laut',
      ),
      TechniqueSection(
        title: 'Übungsplan',
        body:
            'Lerne zunächst das Akzentmuster allein. '
            'Dann füge die Ghost Notes und Taps hinzu. '
            'Zähle die 10-Noten-Gruppe bewusst, um den Einstiegspunkt '
            'beim Loop zu finden.',
      ),
      TechniqueSection(
        title: 'Musikalische Anwendung',
        body:
            'Funk- und Fusion-Grooves. Erzeugt Komplexität ohne Schwere. '
            'Inspirationsquellen: Tony Williams, Vinnie Colaiuta.',
      ),
    ],
  ),

  // ─── ÜBUNGEN ──────────────────────────────────────────────────────────────

  Rudiment(
    id: 'akzent_alle_viertel',
    name: 'Akzent auf allen Vierteln',
    category: 'Akzente',
    level: 1,
    description:
        'Jeder Schlag wird akzentuiert. Gleiche Lautstärke und Rebound beider '
        'Hände trainieren. Ideal zum Aufwärmen.',
    minBpm: 50,
    targetBpm: 160,
    difficulty: Difficulty.beginner,
    sticking: [
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.left, isAccent: true),
    ],
    technique: [
      TechniqueSection(
        title: 'Ziel',
        body:
            'Beide Hände sollen identisch klingen. Höre auf Lautstärkenunterschiede '
            'zwischen rechts und links und gleiche sie aktiv aus.',
      ),
      TechniqueSection(
        title: 'Übungsplan',
        body:
            'Starte bei 50–60 BPM. Erhöhe erst, wenn beide Hände wirklich '
            'gleich klingen. Übe auch mit geschlossenen Augen.',
      ),
    ],
  ),

  Rudiment(
    id: 'akzent_zwei_vier',
    name: 'Akzent auf 2 und 4',
    category: 'Akzente',
    level: 2,
    description:
        'Backbeat-Training: Schläge auf Zählzeit 2 und 4 werden akzentuiert, '
        '1 und 3 bleiben leise. Grundlage für Snare-Backbeats.',
    minBpm: 50,
    targetBpm: 160,
    difficulty: Difficulty.beginner,
    sticking: [
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left, isAccent: true),
    ],
    technique: [
      TechniqueSection(
        title: 'Ziel',
        body:
            'Den Backbeat internalisieren. Der Akzent auf 2 und 4 muss automatisch '
            'sitzen, ohne nachzudenken. Das ist die Basis aller Rock- und Pop-Grooves.',
      ),
      TechniqueSection(
        title: 'Übungsplan',
        body:
            'Zähle laut "1-2-3-4" mit, während du spielst. Fühle den Puls auf '
            '2 und 4. Viele Schlagzeugschüler trainieren dies täglich.',
      ),
    ],
  ),

  Rudiment(
    id: 'akzent_wandernd',
    name: 'Wandernder Akzent',
    category: 'Akzente',
    level: 4,
    description:
        'Der Akzent wandert von Schlag zu Schlag durch alle acht Positionen. '
        'Fördert das Denken in Grooves und Phrasierungen.',
    minBpm: 50,
    targetBpm: 130,
    difficulty: Difficulty.intermediate,
    sticking: [
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
    ],
    technique: [
      TechniqueSection(
        title: 'Ziel',
        body:
            'Übe dasselbe Muster mit dem Akzent auf 1, dann auf 2, dann auf 3 usw. '
            'Jede Position fühlt sich anders an — das trainiert Flexibilität.',
      ),
      TechniqueSection(
        title: 'Übungsplan',
        body:
            'Spiele 4 Takte mit Akzent auf Position 1, dann 4 Takte auf Position 2 '
            'usw., ohne anzuhalten. Metronom läuft durch.',
      ),
    ],
  ),

  Rudiment(
    id: 'ghostnote_training',
    name: 'Ghostnote-Training',
    category: 'Dynamik & Ghost Notes',
    level: 2,
    description:
        'Wechsel zwischen lauten Akzentschlägen und sehr leisen Ghostnotes. '
        'Dynamik-Kontrolle ist das Kernziel.',
    minBpm: 50,
    targetBpm: 140,
    difficulty: Difficulty.intermediate,
    sticking: [
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.left, isGhost: true),
      StrokeBeat(hand: Hand.right, isGhost: true),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat(hand: Hand.right, isGhost: true),
      StrokeBeat(hand: Hand.left, isGhost: true),
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.left, isGhost: true),
    ],
    technique: [
      TechniqueSection(
        title: 'Bewegung',
        body:
            'Akzente: Stock hoch, volles Handgelenk. Ghostnotes: Stock bleibt '
            'nah am Fell, ca. 2–3 cm Stockhöhe. Der Kontrast macht den Groove.',
      ),
      TechniqueSection(
        title: 'Häufige Fehler',
        body:
            '• Ghostnotes zu laut (unkontrollierter Rebound)\n'
            '• Akzente zu leise (Angst den Rhythmus zu verlieren)\n'
            '• Tempo schwankt bei Wechseln zwischen Ghost und Akzent',
      ),
      TechniqueSection(
        title: 'Übungsplan',
        body:
            'Erst nur Akzente, dann nur Ghostnotes üben. Dann kombinieren. '
            'Ziel: der Hörer soll nur die Akzente klar hören, Ghostnotes im '
            'Hintergrund fühlen.',
      ),
    ],
  ),

  Rudiment(
    id: 'paradiddle_diddle',
    name: 'Paradiddle-Diddle',
    category: 'Stockkontrolle',
    level: 3,
    description:
        'Erweiterung des Paradiddles: RLRRLL LRLLRR. Sechs Noten pro Gruppe — '
        'ideal für Triolen und 6/8-Anwendungen.',
    minBpm: 50,
    targetBpm: 150,
    difficulty: Difficulty.intermediate,
    sticking: [
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.right),
    ],
    technique: [
      TechniqueSection(
        title: 'Bewegung',
        body:
            'Die Doppelschläge am Ende (RRLL) nutzen Rebound. Der erste der '
            'Doppelschläge ist aktiv, der zweite "fällt" zurück.',
      ),
      TechniqueSection(
        title: 'Musikalische Anwendung',
        body:
            'Perfekt für Triolen-Fills. Aus RLRRLL entsteht über drei Toms '
            'eine aufsteigende Phrasen. Beliebt in Fusion und Latin.',
      ),
    ],
  ),

  Rudiment(
    id: 'six_stroke_roll',
    name: 'Six Stroke Roll',
    category: 'Stockkontrolle',
    level: 2,
    description:
        'RLLRRL — sechs Schläge mit zwei Doppelschlägen in der Mitte. '
        'Verbindet Einzel- und Doppelschläge zu einem fließenden Muster.',
    minBpm: 50,
    targetBpm: 160,
    difficulty: Difficulty.intermediate,
    sticking: [
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left, isAccent: true),
    ],
    technique: [
      TechniqueSection(
        title: 'Bewegung',
        body:
            'Erster und letzter Schlag sind Akzente mit vollem Schwung. '
            'Die vier mittleren Schläge (LLRR) nutzen Rebound und bleiben leiser.',
      ),
      TechniqueSection(
        title: 'Übungsplan',
        body:
            'Langsam starten: Akzent — Double — Double — Akzent. '
            'Dann Tempo erhöhen bis der Übergang nahtlos wirkt.',
      ),
    ],
  ),

  Rudiment(
    id: 'gleichmaessigkeit_16tel',
    name: 'Gleichmäßigkeit — Sechzehntel',
    category: 'Timing & Gleichmäßigkeit',
    level: 1,
    description:
        'Sechzehntel-Noten in strenger Alternation, ohne Akzente. '
        'Reines Kontroll- und Ausdauertraining für beide Hände.',
    minBpm: 60,
    targetBpm: 200,
    difficulty: Difficulty.beginner,
    sticking: [
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
    ],
    technique: [
      TechniqueSection(
        title: 'Ziel',
        body:
            'Perfekte zeitliche Gleichmäßigkeit. Metronom genau in der Mitte '
            'zwischen zwei Schlägen. Höre auf Lücken oder Rushes.',
      ),
      TechniqueSection(
        title: 'Übungsplan',
        body:
            'Aufnahme mit Handy machen und zurückhören. Übe Abschnitte von '
            '2–5 Minuten ohne Unterbrechung. Ausdauer ist das Ziel.',
      ),
    ],
  ),

  Rudiment(
    id: 'moeller_motion',
    name: 'Moeller-Bewegung',
    category: 'Dynamik & Ghost Notes',
    level: 4,
    description:
        'Arm-Peitschenbewegung für effizienten Energiefluss. Erzeugt mehrere '
        'Schläge aus einer Armbewegung: Akzent — Tap — Tap.',
    minBpm: 40,
    targetBpm: 120,
    difficulty: Difficulty.advanced,
    sticking: [
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.right, isGhost: true),
      StrokeBeat(hand: Hand.right, isGhost: true),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat(hand: Hand.left, isGhost: true),
      StrokeBeat(hand: Hand.left, isGhost: true),
    ],
    technique: [
      TechniqueSection(
        title: 'Bewegung',
        body:
            'Arm hebt sich für den Akzent (Down Stroke). Der Arm fällt und '
            'erzeugt automatisch zwei weitere leise Schläge (Tap + Up). '
            'Keine Muskelkraft — Schwerkraft und Rebound machen die Arbeit.',
      ),
      TechniqueSection(
        title: 'Häufige Fehler',
        body:
            '• Arm aktiv anheben statt fallen lassen\n'
            '• Taps zu laut (kein Unterschied zur Akzent-Lautstärke)\n'
            '• Tempo zu hoch am Anfang — langsam ist hier schwerer',
      ),
      TechniqueSection(
        title: 'Übungsplan',
        body:
            'Extrem langsam beginnen (40 BPM). Erst wenn die Bewegung sich '
            '"von selbst" anfühlt, Tempo erhöhen. Täglich 5 Minuten.',
      ),
    ],
  ),

  Rudiment(
    id: 'doppelschlag_basis',
    name: 'Doppelschläge (Basis)',
    category: 'Stockkontrolle',
    level: 1,
    description:
        'RRLL im gemächlichen Tempo. Grundlage jeder Stockkontrolle: zwei '
        'kontrollierte Schläge pro Hand, der zweite aus dem Rebound.',
    minBpm: 50,
    targetBpm: 140,
    difficulty: Difficulty.beginner,
    sticking: [
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat(hand: Hand.left),
    ],
    technique: [
      TechniqueSection(
        title: 'Bewegung',
        body:
            'Der erste Schlag jeder Hand ist aktiv aus dem Handgelenk, der zweite '
            '"fällt" aus dem Rebound nach. Beide sollen gleich laut klingen.',
      ),
      TechniqueSection(
        title: 'Übungsplan',
        body:
            'Langsam beginnen (50 BPM) und auf einen sauberen zweiten Schlag '
            'achten. Erst erhöhen, wenn beide Schläge gleichmäßig klingen.',
      ),
    ],
  ),

  Rudiment(
    id: 'speed_singles_basis',
    name: 'Single-Stroke-Tempo (Basis)',
    category: 'Geschwindigkeit',
    level: 1,
    description:
        'Gleichmäßige Sechzehntel-Einzelschläge zum schrittweisen Tempoaufbau. '
        'Locker bleiben — Geschwindigkeit kommt aus Entspannung, nicht aus Kraft.',
    minBpm: 60,
    targetBpm: 200,
    difficulty: Difficulty.beginner,
    gridUnit: NoteGrid.sixteenth,
    sticking: [
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
    ],
    technique: [
      TechniqueSection(
        title: 'Ziel',
        body:
            'Das höchste Tempo finden, bei dem du noch entspannt und gleichmäßig '
            'spielst. Sobald es verkrampft, einen Schritt zurück.',
      ),
      TechniqueSection(
        title: 'Übungsplan',
        body:
            'In 5-BPM-Schritten steigern. Jede Stufe 1 Minute halten. Notiere '
            'dir dein aktuelles Maximaltempo und vergleiche über Wochen.',
      ),
    ],
  ),

  Rudiment(
    id: 'speed_bursts',
    name: 'Speed Bursts',
    category: 'Geschwindigkeit',
    level: 3,
    description:
        'Vier schnelle Sechzehntel, dann Pause. Trainiert kurze Schnelligkeits-'
        'spitzen mit Entspannung dazwischen.',
    minBpm: 70,
    targetBpm: 180,
    difficulty: Difficulty.intermediate,
    gridUnit: NoteGrid.sixteenth,
    sticking: [
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat.rest(),
      StrokeBeat.rest(),
      StrokeBeat.rest(),
      StrokeBeat.rest(),
    ],
    technique: [
      TechniqueSection(
        title: 'Bewegung',
        body:
            'Den Burst bewusst locker explodieren lassen und in der Pause '
            'komplett entspannen. Die Pause ist Teil der Übung.',
      ),
      TechniqueSection(
        title: 'Häufige Fehler',
        body:
            '• In der Pause angespannt bleiben\n'
            '• Den Burst überhasten und ungleichmäßig spielen',
      ),
    ],
  ),

  Rudiment(
    id: 'speed_doubles',
    name: 'Double-Stroke-Tempo',
    category: 'Geschwindigkeit',
    level: 4,
    description:
        'Schnelle Doppelschläge (RRLL) als Sechzehntel. Tempo basiert auf '
        'sauberem Rebound — nicht auf Kraft.',
    minBpm: 60,
    targetBpm: 170,
    difficulty: Difficulty.advanced,
    gridUnit: NoteGrid.sixteenth,
    sticking: [
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat(hand: Hand.left),
    ],
    technique: [
      TechniqueSection(
        title: 'Bewegung',
        body:
            'Bei hohem Tempo wird der zweite Schlag fast nur durch den Rebound '
            'erzeugt. Druck mit den Fingern statt Armkraft.',
      ),
      TechniqueSection(
        title: 'Übungsplan',
        body:
            'Erst langsam mit gleich lauten Schlägen. Tempo nur erhöhen, wenn '
            'der zweite Schlag nicht in der Lautstärke abfällt.',
      ),
    ],
  ),

  Rudiment(
    id: 'ausdauer_dauerlauf',
    name: 'Sechzehntel-Dauerlauf',
    category: 'Ausdauer',
    level: 2,
    description:
        'Durchgehende Sechzehntel über mehrere Minuten ohne Pause. '
        'Baut Kondition und gleichbleibende Klangqualität auf.',
    minBpm: 70,
    targetBpm: 150,
    difficulty: Difficulty.beginner,
    gridUnit: NoteGrid.sixteenth,
    sticking: [
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
    ],
    technique: [
      TechniqueSection(
        title: 'Ziel',
        body:
            'Über die gesamte Dauer gleich laut und gleichmäßig bleiben. '
            'Achte auf den Moment, in dem die Hände müde werden.',
      ),
      TechniqueSection(
        title: 'Übungsplan',
        body:
            'Mit 2 Minuten starten und wöchentlich verlängern. Bei nachlassender '
            'Qualität bewusst entspannen statt aufzuhören.',
      ),
    ],
  ),

  Rudiment(
    id: 'ausdauer_doubles',
    name: 'Doppelschlag-Ausdauer',
    category: 'Ausdauer',
    level: 3,
    description:
        'Durchgehende Doppelschläge (RRLL) zum Aufbau von Unterarm- und '
        'Fingerausdauer bei gleichbleibendem Klang.',
    minBpm: 60,
    targetBpm: 140,
    difficulty: Difficulty.intermediate,
    gridUnit: NoteGrid.sixteenth,
    sticking: [
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.left),
    ],
    technique: [
      TechniqueSection(
        title: 'Häufige Fehler',
        body:
            '• Der zweite Schlag wird mit zunehmender Müdigkeit leiser\n'
            '• Verkrampfen im Unterarm — Schultern locker lassen',
      ),
      TechniqueSection(
        title: 'Übungsplan',
        body:
            'Moderate 2–3 Minuten am Stück. Lieber sauber und kürzer als lang '
            'und ungleichmäßig.',
      ),
    ],
  ),

  Rudiment(
    id: 'akzent_offbeat',
    name: 'Akzent auf dem Offbeat',
    category: 'Akzente',
    level: 3,
    description:
        'Achtel mit Akzent auf dem "und" (Offbeat). Trainiert das Gefühl für '
        'Synkopen und gegen-den-Puls-Phrasierung.',
    minBpm: 50,
    targetBpm: 150,
    difficulty: Difficulty.intermediate,
    sticking: [
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left, isAccent: true),
    ],
    technique: [
      TechniqueSection(
        title: 'Ziel',
        body:
            'Der Akzent liegt zwischen den Zählzeiten ("und"). Zähle "1-und-2-und" '
            'und betone konsequent das "und".',
      ),
      TechniqueSection(
        title: 'Übungsplan',
        body:
            'Erst laut mitzählen, dann nur denken. Das Offbeat-Gefühl ist die '
            'Grundlage für Funk- und Reggae-Phrasierung.',
      ),
    ],
  ),

  Rudiment(
    id: 'ghost_um_akzent',
    name: 'Ghostnotes um den Akzent',
    category: 'Dynamik & Ghost Notes',
    level: 3,
    description:
        'Ein lauter Akzent eingebettet in leise Ghostnotes. Maximaler Dynamik-'
        'kontrast auf engem Raum.',
    minBpm: 50,
    targetBpm: 130,
    difficulty: Difficulty.intermediate,
    gridUnit: NoteGrid.sixteenth,
    sticking: [
      StrokeBeat(hand: Hand.left, isGhost: true),
      StrokeBeat(hand: Hand.right, isGhost: true),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat(hand: Hand.right, isGhost: true),
      StrokeBeat(hand: Hand.left, isGhost: true),
      StrokeBeat(hand: Hand.right, isGhost: true),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat(hand: Hand.right, isGhost: true),
      StrokeBeat(hand: Hand.left, isGhost: true),
      StrokeBeat(hand: Hand.right, isGhost: true),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat(hand: Hand.right, isGhost: true),
      StrokeBeat(hand: Hand.left, isGhost: true),
      StrokeBeat(hand: Hand.right, isGhost: true),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat(hand: Hand.right, isGhost: true),
    ],
    technique: [
      TechniqueSection(
        title: 'Bewegung',
        body:
            'Ghostnotes bleiben 2–3 cm über dem Fell, der Akzent kommt von oben. '
            'Der Höhenunterschied der Stöcke erzeugt die Dynamik automatisch.',
      ),
      TechniqueSection(
        title: 'Ziel',
        body:
            'Der Hörer soll nur den Akzent klar wahrnehmen, die Ghostnotes als '
            'leises Brodeln im Hintergrund.',
      ),
    ],
  ),

  Rudiment(
    id: 'timing_achtel_triolen',
    name: 'Achtel-Triolen gleichmäßig',
    category: 'Timing & Gleichmäßigkeit',
    level: 2,
    description:
        'Triolen mit Akzent auf jeder Zählzeit. Schult das gleichmäßige Dritteln '
        'des Pulses — Grundlage für Shuffle und Swing.',
    minBpm: 50,
    targetBpm: 150,
    difficulty: Difficulty.intermediate,
    gridUnit: NoteGrid.triplet,
    sticking: [
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
    ],
    technique: [
      TechniqueSection(
        title: 'Ziel',
        body:
            'Alle drei Triolen-Noten exakt gleich weit auseinander. Zähle '
            '"1-trio-le, 2-trio-le" und lege den Akzent genau auf die Zählzeit.',
      ),
      TechniqueSection(
        title: 'Übungsplan',
        body:
            'Mit dem Metronom auf die Viertel spielen und prüfen, ob die '
            'mittlere Triolennote sauber in der Mitte sitzt.',
      ),
    ],
  ),

  Rudiment(
    id: 'timing_galopp',
    name: 'Galopp-Rhythmus',
    category: 'Timing & Gleichmäßigkeit',
    level: 3,
    description:
        'Achtel gefolgt von zwei Sechzehnteln pro Zählzeit ("Galopp"). '
        'Schult präzise Subdivision innerhalb des Beats.',
    minBpm: 50,
    targetBpm: 140,
    difficulty: Difficulty.intermediate,
    gridUnit: NoteGrid.sixteenth,
    sticking: [
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat.rest(),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat.rest(),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat.rest(),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat.rest(),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
    ],
    technique: [
      TechniqueSection(
        title: 'Ziel',
        body:
            'Der erste Schlag ist lang (Achtel), darauf folgen zwei schnelle '
            'Sechzehntel. Das "da-da-dim"-Gefühl muss gleichmäßig bleiben.',
      ),
      TechniqueSection(
        title: 'Häufige Fehler',
        body:
            '• Die beiden Sechzehntel werden zu früh gespielt (Triole statt Galopp)\n'
            '• Ungleiche Pause nach dem ersten Schlag',
      ),
    ],
  ),

  // ─── MARCHING SNARE ─────────────────────────────────────────────────────────

  Rudiment(
    id: 'eight_on_a_hand',
    name: 'Eight on a Hand',
    category: 'Marching Snare',
    description:
        'Acht Sechzehntel pro Hand mit Akzent auf jeder Zählzeit. '
        'Grundlegendes Marching-Warm-up für Kontrolle und gleichmäßigen Anschlag.',
    minBpm: 60,
    targetBpm: 160,
    difficulty: Difficulty.beginner,
    gridUnit: NoteGrid.sixteenth,
    beatsPerBar: 4,
    sticking: [
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.left),
    ],
    technique: [
      TechniqueSection(
        title: 'Ziel',
        body:
            'Gleichmäßige Sechzehntel mit klarem Akzent auf 1, 2, 3, 4. '
            'Die unbetonten Noten bleiben tief und locker.',
      ),
      TechniqueSection(
        title: 'Tipp',
        body:
            'Handgelenk führt die Akzente, Finger kontrollieren die tiefen Töne. '
            'Beide Hände sollen identisch klingen.',
      ),
    ],
  ),

  Rudiment(
    id: 'flam_accent',
    name: 'Flam Accent',
    category: 'Marching Snare',
    description:
        'Flam auf der betonten Zählzeit, gefolgt von zwei Tap-Noten — '
        'im Triolen-Feel. Ein Eckpfeiler der Marching-Rudiments.',
    minBpm: 50,
    targetBpm: 140,
    difficulty: Difficulty.intermediate,
    gridUnit: NoteGrid.triplet,
    beatsPerBar: 2,
    sticking: [
      StrokeBeat(hand: Hand.right, isAccent: true, graces: [Hand.left]),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left, isAccent: true, graces: [Hand.right]),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
    ],
    technique: [
      TechniqueSection(
        title: 'Bewegung',
        body:
            'Der Flam landet als kräftiger Akzent, die beiden folgenden Taps '
            'bleiben tief. Hände wechseln nach jeder Triole.',
      ),
    ],
  ),

  Rudiment(
    id: 'flam_tap',
    name: 'Flam Tap',
    category: 'Marching Snare',
    description:
        'Flam gefolgt von einem Tap derselben Hand: lR-R rL-L. '
        'Trainiert den Down-Up-Stroke und Doppelschläge mit Flam.',
    minBpm: 50,
    targetBpm: 150,
    difficulty: Difficulty.intermediate,
    gridUnit: NoteGrid.eighth,
    beatsPerBar: 4,
    sticking: [
      StrokeBeat(hand: Hand.right, isAccent: true, graces: [Hand.left]),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left, isAccent: true, graces: [Hand.right]),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right, isAccent: true, graces: [Hand.left]),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left, isAccent: true, graces: [Hand.right]),
      StrokeBeat(hand: Hand.left),
    ],
    technique: [
      TechniqueSection(
        title: 'Down-Up',
        body:
            'Der Flam ist ein Down-Stroke (laut, bleibt unten), der Tap ein '
            'tiefer Up-Stroke, der die nächste Hand vorbereitet.',
      ),
    ],
  ),

  Rudiment(
    id: 'flamacue',
    name: 'Flamacue',
    category: 'Marching Snare',
    description:
        'Flam, danach ein Akzent auf der zweiten Note, zwei Taps und ein '
        'abschließender Flam. Klassisches, ausdrucksstarkes Rudiment.',
    minBpm: 50,
    targetBpm: 130,
    difficulty: Difficulty.advanced,
    gridUnit: NoteGrid.sixteenth,
    beatsPerBar: 2,
    sticking: [
      StrokeBeat(hand: Hand.right, graces: [Hand.left]),
      StrokeBeat(hand: Hand.left, isAccent: true),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.left, graces: [Hand.right]),
      StrokeBeat(hand: Hand.right, isAccent: true),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
    ],
    technique: [
      TechniqueSection(
        title: 'Akzent',
        body:
            'Der Akzent liegt nicht auf dem Flam, sondern auf der Note direkt '
            'danach. Genau diese Verschiebung macht den Flamacue aus.',
      ),
    ],
  ),

  Rudiment(
    id: 'flam_paradiddle',
    name: 'Flam Paradiddle',
    category: 'Marching Snare',
    description:
        'Ein Paradiddle, dessen erste Note ein Flam mit Akzent ist: '
        'lR-L-R-R rL-R-L-L. Verbindet Flam-Kontrolle mit Doppelschlägen.',
    minBpm: 50,
    targetBpm: 140,
    difficulty: Difficulty.advanced,
    gridUnit: NoteGrid.sixteenth,
    beatsPerBar: 2,
    sticking: [
      StrokeBeat(hand: Hand.right, isAccent: true, graces: [Hand.left]),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left, isAccent: true, graces: [Hand.right]),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.left),
    ],
    technique: [
      TechniqueSection(
        title: 'Tipp',
        body:
            'Der Flam-Akzent eröffnet jeden Paradiddle, der abschließende '
            'Diddle (RR bzw. LL) bleibt tief und kontrolliert.',
      ),
    ],
  ),

  Rudiment(
    id: 'cheese',
    name: 'Cheese (Flam Diddle)',
    category: 'Marching Snare',
    description:
        'Ein Flam direkt gefolgt von einem Diddle: lR-R rL-L. '
        'Hybrid-Rudiment, das Flam und Doppelschlag in einer Bewegung verbindet.',
    minBpm: 50,
    targetBpm: 130,
    difficulty: Difficulty.advanced,
    gridUnit: NoteGrid.sixteenth,
    beatsPerBar: 2,
    sticking: [
      StrokeBeat(hand: Hand.right, graces: [Hand.left]),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left, graces: [Hand.right]),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.right, graces: [Hand.left]),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.left, graces: [Hand.right]),
      StrokeBeat(hand: Hand.left),
    ],
    technique: [
      TechniqueSection(
        title: 'Idee',
        body:
            'Der Flam und der erste Diddle-Schlag verschmelzen fast zu einem '
            'Klang. Locker bleiben, der Diddle kommt aus den Fingern.',
      ),
    ],
  ),

  Rudiment(
    id: 'inverted_flam_tap',
    name: 'Inverted Flam Tap',
    category: 'Marching Snare',
    description:
        'Flam Tap, bei dem der Flam auf den Off-Beat fällt: R lR L rL. '
        'Anspruchsvolle Variante für Timing und Handabwechslung.',
    minBpm: 50,
    targetBpm: 130,
    difficulty: Difficulty.professional,
    gridUnit: NoteGrid.eighth,
    beatsPerBar: 4,
    sticking: [
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.right, isAccent: true, graces: [Hand.left]),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.left, isAccent: true, graces: [Hand.right]),
      StrokeBeat(hand: Hand.right),
      StrokeBeat(hand: Hand.right, isAccent: true, graces: [Hand.left]),
      StrokeBeat(hand: Hand.left),
      StrokeBeat(hand: Hand.left, isAccent: true, graces: [Hand.right]),
    ],
    technique: [
      TechniqueSection(
        title: 'Achtung',
        body:
            'Der Flam liegt auf dem "und" der Zählzeit. Erst sehr langsam üben, '
            'damit der versetzte Akzent sauber sitzt.',
      ),
    ],
  ),
];

/// Ordered list of all categories for consistent display.
/// Focus areas for the free practice exercises ("Übungen"), ordered as the
/// guided practice plan presents them.
const exerciseCategories = [
  'Geschwindigkeit',
  'Stockkontrolle',
  'Ausdauer',
  'Akzente',
  'Dynamik & Ghost Notes',
  'Timing & Gleichmäßigkeit',
];

const rudimentCategories = [
  'Rolls',
  'Paradiddles',
  'Flams',
  'Ruffs',
  'Ghost Notes',
  'Linear Patterns',
  'Marching Snare',
  ...exerciseCategories,
];
