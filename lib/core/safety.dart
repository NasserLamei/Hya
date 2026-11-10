String normalizeArabic(String input) {
  return input
      .toLowerCase()
      .replaceAll(RegExp(r'[\u064B-\u0652\u0640]'), '')
      .replaceAll('أ', 'ا')
      .replaceAll('إ', 'ا')
      .replaceAll('آ', 'ا')
      .replaceAll('ة', 'ه')
      .replaceAll('ى', 'ي')
      .replaceAll('ؤ', 'و')
      .replaceAll('ئ', 'ي');
}

const redFlagNeedles = [
  'نزيف',
  'ينزف',
  'دم غزير',
  'نقط دم',
  'مش بيتحرك',
  'ما بيتحركش',
  'مش بيتحركش',
  'حركته قلت',
  'الحركه قلت',
  'حركة قلت',
  'صداع شديد',
  'زغلله',
  'زغللة',
  'تورم مفاجئ',
  'وشي ورم',
  'ضيق تنفس',
  'مش قادره اتنفس',
  'اغماء',
  'إغماء',
  'غبت عن الوعي',
  'ماء نازل',
  'الميه نازله',
  'المية نازلة',
  'طلق منتظم',
  'الم شديد',
  'ألم شديد',
  'حراره عاليه',
  'حرارة عالية',
  'سخونيه',
  'سخونية',
];

bool isRedFlag(String text) {
  final normalized = normalizeArabic(text);
  return redFlagNeedles.any((needle) => normalized.contains(normalizeArabic(needle)));
}

class MythEntry {
  const MythEntry({
    required this.id,
    required this.claim,
    required this.verdict,
    required this.truth,
    required this.keywords,
    this.audience = MythAudience.all,
  });

  final String id;
  final String claim;
  final String verdict;
  final String truth;
  final List<String> keywords;
  final MythAudience audience;
}

enum MythAudience { all, ttc, pregnant }

MythEntry? matchMyth(String text, List<MythEntry> myths) {
  final normalized = normalizeArabic(text);
  if (normalized.trim().length < 2) return null;

  MythEntry? best;
  var bestScore = 0;
  for (final myth in myths) {
    var score = 0;
    for (final keyword in myth.keywords) {
      if (normalized.contains(normalizeArabic(keyword))) score += keyword.length;
    }
    if (score > bestScore) {
      best = myth;
      bestScore = score;
    }
  }
  if (bestScore < 4) return null;
  return best;
}
