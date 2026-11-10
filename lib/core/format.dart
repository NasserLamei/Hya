import 'cycle_math.dart';

const arabicMonths = [
  'يناير',
  'فبراير',
  'مارس',
  'أبريل',
  'مايو',
  'يونيو',
  'يوليو',
  'أغسطس',
  'سبتمبر',
  'أكتوبر',
  'نوفمبر',
  'ديسمبر',
];

String formatDate(DateTime date) => '${date.day} ${arabicMonths[date.month - 1]} ${date.year}';

String greetingFor(DateTime now) {
  // صباح لحد قبل ٥ العصر، وبعدها مساء
  if (now.hour >= 5 && now.hour < 17) return 'صباح الخير';
  return 'مساء الخير';
}

String pluralDays(int count) {
  final value = count.abs();
  if (value == 0) return 'النهاردة';
  if (value == 1) return 'يوم واحد';
  if (value == 2) return 'يومين';
  if (value <= 10) return '$value أيام';
  return '$value يوم';
}

class CalendarAge {
  const CalendarAge({required this.months, required this.days, required this.totalDays});

  final int months;
  final int days;
  final int totalDays;
}

CalendarAge calendarAge(DateTime birth, DateTime today) {
  final start = dateOnly(birth);
  final end = dateOnly(today);
  final totalDays = daysBetween(start, end);
  if (totalDays < 0) {
    return CalendarAge(months: 0, days: 0, totalDays: totalDays);
  }

  var months = (end.year - start.year) * 12 + end.month - start.month;
  var anchor = DateTime(start.year, start.month + months, start.day);
  if (anchor.isAfter(end)) {
    months -= 1;
    anchor = DateTime(start.year, start.month + months, start.day);
  }
  final days = daysBetween(anchor, end);
  return CalendarAge(months: months, days: days, totalDays: totalDays);
}

String formatBabyAge(DateTime birth, DateTime today) {
  final age = calendarAge(birth, today);
  if (age.totalDays < 0) return 'لسه قبل معاد الولادة';
  if (age.totalDays == 0) return 'اتولد النهاردة';
  if (age.months <= 0) {
    final weeks = age.totalDays ~/ 7;
    final rest = age.totalDays % 7;
    if (weeks == 0) return pluralDays(age.totalDays);
    if (rest == 0) return weeks == 1 ? 'أسبوع' : '$weeks أسابيع';
    return '${weeks == 1 ? 'أسبوع' : '$weeks أسابيع'} و${pluralDays(rest)}';
  }
  final monthLabel = age.months == 1 ? 'شهر' : (age.months == 2 ? 'شهرين' : '${age.months} شهور');
  if (age.days == 0) return monthLabel;
  return '$monthLabel و${pluralDays(age.days)}';
}

String deliveryLabel(String? type) {
  return switch (type) {
    'natural' => 'ولادة طبيعية',
    'cesarean' => 'ولادة قيصرية',
    _ => 'الولادة',
  };
}
