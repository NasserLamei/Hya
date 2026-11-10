import 'models.dart';

DateTime dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);

int daysBetween(DateTime from, DateTime to) {
  final start = DateTime.utc(from.year, from.month, from.day);
  final end = DateTime.utc(to.year, to.month, to.day);
  return end.difference(start).inDays;
}

DateTime addDays(DateTime day, int days) {
  final shifted = DateTime.utc(day.year, day.month, day.day).add(Duration(days: days));
  return DateTime(shifted.year, shifted.month, shifted.day);
}

String isoDate(DateTime value) {
  final day = dateOnly(value);
  final month = day.month.toString().padLeft(2, '0');
  final dayText = day.day.toString().padLeft(2, '0');
  return '${day.year}-$month-$dayText';
}

DateTime? parseIsoDate(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return null;
  return dateOnly(parsed);
}

class GestationalAge {
  const GestationalAge({required this.week, required this.day, required this.totalDays});

  final int week;
  final int day;
  final int totalDays;

  int get contentWeek => week.clamp(1, 40);
}

class CycleSnapshot {
  const CycleSnapshot({
    required this.cycleDay,
    required this.cycleLength,
    required this.ovulationDay,
    required this.phase,
    required this.nextPeriod,
    required this.daysUntilPeriod,
  });

  final int cycleDay;
  final int cycleLength;
  final int ovulationDay;
  final CyclePhase phase;
  final DateTime nextPeriod;
  final int daysUntilPeriod;

  bool get periodLate => daysUntilPeriod < 0;
  int get lateDays => periodLate ? -daysUntilPeriod : 0;
}

enum CyclePhase { period, fertile, ovulation, luteal }

class CycleMath {
  static const pregnancyLength = 280;

  static DateTime dueDateFromLmp(DateTime lmp) => addDays(lmp, pregnancyLength);

  static DateTime lmpFromDueDate(DateTime due) => addDays(due, -pregnancyLength);

  static DateTime lmpFromPregnancyWeek(int week, [DateTime? today]) {
    final safeWeek = week.clamp(1, 45);
    return addDays(dateOnly(today ?? DateTime.now()), -(safeWeek * 7));
  }

  static GestationalAge gestationalAge(DateTime lmp, DateTime today) {
    final totalDays = daysBetween(lmp, today);
    if (totalDays < 0) {
      return const GestationalAge(week: 0, day: 0, totalDays: 0);
    }
    return GestationalAge(week: totalDays ~/ 7, day: totalDays % 7, totalDays: totalDays);
  }

  static CycleSnapshot cycleSnapshot({
    required DateTime lastPeriod,
    required int cycleLength,
    required DateTime today,
  }) {
    final length = cycleLength.clamp(20, 45);
    final start = dateOnly(lastPeriod);
    final now = dateOnly(today);
    var elapsed = daysBetween(start, now);
    if (elapsed < 0) elapsed = 0;
    final cycleDay = (elapsed % length) + 1;
    final ovulationDay = (length - 14).clamp(8, length - 2);
    final fertileStart = ovulationDay - 5;
    final fertileEnd = ovulationDay + 1;

    final CyclePhase phase;
    if (cycleDay <= 5) {
      phase = CyclePhase.period;
    } else if (cycleDay == ovulationDay) {
      phase = CyclePhase.ovulation;
    } else if (cycleDay >= fertileStart && cycleDay <= fertileEnd) {
      phase = CyclePhase.fertile;
    } else {
      phase = CyclePhase.luteal;
    }

    final cyclesPassed = elapsed ~/ length;
    final nextPeriod = addDays(start, (cyclesPassed + 1) * length);
    final daysUntilPeriod = daysBetween(now, nextPeriod);

    return CycleSnapshot(
      cycleDay: cycleDay,
      cycleLength: length,
      ovulationDay: ovulationDay,
      phase: phase,
      nextPeriod: nextPeriod,
      daysUntilPeriod: daysUntilPeriod,
    );
  }

  static DateTime? estimatedDueDate(Profile profile) {
    if (profile.expectedDueDate != null) return dateOnly(profile.expectedDueDate!);
    if (profile.lastPeriodDate != null) return dueDateFromLmp(profile.lastPeriodDate!);
    return null;
  }

  static DateTime? estimatedLmp(Profile profile) {
    if (profile.lastPeriodDate != null) return dateOnly(profile.lastPeriodDate!);
    if (profile.expectedDueDate != null) return lmpFromDueDate(profile.expectedDueDate!);
    return null;
  }
}
