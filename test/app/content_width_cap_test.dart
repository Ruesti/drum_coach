import 'package:drum_coach/app/design_tokens.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maxContentWidth is a sane desktop cap', () {
    expect(AppLayout.maxContentWidth, greaterThan(400));
    expect(AppLayout.maxContentWidth, lessThanOrEqualTo(700));
  });
}
