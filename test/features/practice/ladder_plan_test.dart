import 'package:drum_coach/features/practice/ladder_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LadderPlan', () {
    test('vier Stufen führen von −8 zum Gate-Tempo +4', () {
      final plan = buildLadderPlan(startBpm: 80, totalSeconds: 240);
      expect(plan.bpms, [72, 76, 80, 84]);
    });

    test('Stufen teilen die Dauer gleichmäßig, Rest geht an die letzte', () {
      final plan = buildLadderPlan(startBpm: 80, totalSeconds: 240);
      expect(plan.stepIndexAt(0), 0);
      expect(plan.stepIndexAt(59), 0);
      expect(plan.stepIndexAt(60), 1);
      expect(plan.stepIndexAt(179), 2);
      expect(plan.stepIndexAt(180), 3);
      expect(plan.stepIndexAt(239), 3);
    });

    test('bpmAt klemmt auf die letzte Stufe, auch über die Dauer hinaus', () {
      final plan = buildLadderPlan(startBpm: 100, totalSeconds: 200);
      expect(plan.bpmAt(0), 92);
      expect(plan.bpmAt(1000), 104);
    });

    test('Klemmen am unteren Rand dedupliziert Stufen', () {
      final plan = buildLadderPlan(startBpm: 42, totalSeconds: 180);
      expect(plan.bpms, [40, 42, 46]);
      expect(plan.stepIndexAt(179), 2);
    });

    test('krumme Dauer: letzte Stufe bekommt den Rest', () {
      final plan = buildLadderPlan(startBpm: 80, totalSeconds: 250);
      // 250 ~/ 4 = 62 → Wechsel bei 62/124/186, letzte Stufe 64 s lang.
      expect(plan.stepIndexAt(61), 0);
      expect(plan.stepIndexAt(62), 1);
      expect(plan.stepIndexAt(249), 3);
    });
  });
}
