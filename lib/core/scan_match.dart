import '../data/guides.dart';
import '../data/scan_catalog.dart';
import 'safety.dart';

class ScanHit {
  const ScanHit({required this.item, required this.score});

  final GuideItem item;
  final int score;
}

class ScanVerdict {
  const ScanVerdict({required this.primary, this.also = const []});

  final ScanHit? primary;
  final List<ScanHit> also;

  bool get found => primary != null;
}

ScanVerdict judgeText(String raw, {Set<GuideKind>? kinds}) {
  final text = normalizeArabic(raw);
  if (text.trim().length < 2) {
    return const ScanVerdict(primary: null);
  }

  final pool = kinds == null ? scanPool : scanPool.where((item) => kinds.contains(item.kind));
  final hits = <ScanHit>[];
  for (final item in pool) {
    var best = 0;
    for (final alias in [item.name, ...item.aliases]) {
      if (!_aliasHits(text, alias)) continue;
      final length = normalizeArabic(alias).length;
      if (length > best) best = length;
    }
    if (best >= 3) hits.add(ScanHit(item: item, score: best));
  }

  if (hits.isEmpty) return const ScanVerdict(primary: null);
  hits.sort((a, b) {
    final severityGap = _severity(b.item.level).compareTo(_severity(a.item.level));
    if (severityGap != 0) return severityGap;
    return b.score.compareTo(a.score);
  });
  return ScanVerdict(primary: hits.first, also: hits.skip(1).take(2).toList());
}

int _severity(SafetyLevel level) {
  return switch (level) {
    SafetyLevel.red => 3,
    SafetyLevel.amber => 2,
    SafetyLevel.green => 1,
  };
}

bool _aliasHits(String text, String alias) {
  final needle = normalizeArabic(alias);
  if (needle.length < 3) return false;
  final arabic = RegExp(r'[\u0600-\u06FF]').hasMatch(needle);
  if (arabic) return text.contains(needle);
  final escaped = RegExp.escape(needle);
  return RegExp('(?:^|[^0-9a-z])$escaped(?:\$|[^0-9a-z])').hasMatch(text);
}
