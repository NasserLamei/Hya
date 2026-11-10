import 'package:flutter_test/flutter_test.dart';

import 'package:hya/core/cycle_math.dart';
import 'package:hya/core/safety.dart';
import 'package:hya/data/myths.dart';

void main() {
  test('due date is 280 days after the last period', () {
    final due = CycleMath.dueDateFromLmp(DateTime(2025, 1, 1));
    expect(due, DateTime(2025, 10, 8));
    expect(CycleMath.lmpFromDueDate(due), DateTime(2025, 1, 1));
  });

  test('gestational age counts completed weeks and days', () {
    final age = CycleMath.gestationalAge(DateTime(2025, 1, 1), DateTime(2025, 4, 16));
    expect(age.totalDays, 105);
    expect(age.week, 15);
    expect(age.day, 0);
  });

  test('fertile window follows a regular cycle estimate', () {
    final snapshot = CycleMath.cycleSnapshot(
      lastPeriod: DateTime(2026, 3, 1),
      cycleLength: 28,
      today: DateTime(2026, 3, 14),
    );
    expect(snapshot.cycleDay, 14);
    expect(snapshot.ovulationDay, 14);
    expect(snapshot.phase, CyclePhase.ovulation);
  });

  test('bleeding language is treated as urgent, not a myth', () {
    expect(isRedFlag('في نقط دم خفيفة النهاردة'), isTrue);
    expect(matchMyth('المانجا بتعمل تشوهات', mythLibrary)?.id, 'mango');
  });
}
