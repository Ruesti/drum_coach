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
];

/// Ordered list of all categories for consistent display.
const rudimentCategories = [
  'Rolls',
  'Paradiddles',
  'Flams',
  'Ruffs',
  'Ghost Notes',
  'Linear Patterns',
];
