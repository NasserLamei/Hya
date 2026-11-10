import 'package:flutter/material.dart';

import '../../core/safety.dart';
import '../../core/theme.dart';
import '../../data/guides.dart';
import '../../data/scan_catalog.dart';
import '../../widgets/ui.dart';

class MedicalPage extends StatefulWidget {
  const MedicalPage({super.key});

  @override
  State<MedicalPage> createState() => _MedicalPageState();
}

class _MedicalPageState extends State<MedicalPage> {
  final _search = TextEditingController();
  final _report = TextEditingController();
  var _segment = 0;
  GuideKind? _kind;
  SafetyLevel? _level;

  @override
  void dispose() {
    _search.dispose();
    _report.dispose();
    super.dispose();
  }

  List<GuideItem> get _items {
    final query = normalizeArabic(_search.text.trim());
    return [
      for (final item in scanPool)
        if ((_kind == null || item.kind == _kind) &&
            (_level == null || item.level == _level) &&
            (query.isEmpty ||
                normalizeArabic('${item.name} ${item.aliases.join(' ')}').contains(query)))
          item,
    ];
  }

  int _countFor(SafetyLevel? level) {
    return scanPool.where((item) {
      if (level != null && item.level != level) return false;
      if (_kind != null && item.kind != _kind) return false;
      return true;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;

    return SoftPage(
      children: [
        const PageHeader(kicker: 'معرفة عامة', title: 'دليلي'),
        const SizedBox(height: 8),
        const DisclaimerNote(text: safetyDisclaimer),
        const SizedBox(height: 16),
        _SegmentSwitch(
          index: _segment,
          onChanged: (value) => setState(() => _segment = value),
        ),
        const SizedBox(height: 16),
        if (_segment == 0) ...[
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'ابحثي باسم الدواء أو الأكل',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 14),
          const HyaText('الإشارة باللون', size: 13, weight: 700, color: HyaColors.muted),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _SignalFilter(
                  label: 'الكل',
                  selected: _level == null,
                  soft: const Color(0xFFF3ECE8),
                  count: _countFor(null),
                  band: const [HyaColors.green, HyaColors.amber, HyaColors.red],
                  onTap: () => setState(() => _level = null),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SignalFilter(
                  label: 'مناسب',
                  selected: _level == SafetyLevel.green,
                  soft: HyaColors.greenSoft,
                  count: _countFor(SafetyLevel.green),
                  band: const [HyaColors.green],
                  onTap: () => setState(() {
                    _level = _level == SafetyLevel.green ? null : SafetyLevel.green;
                  }),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SignalFilter(
                  label: 'بحذر',
                  selected: _level == SafetyLevel.amber,
                  soft: HyaColors.amberSoft,
                  count: _countFor(SafetyLevel.amber),
                  band: const [HyaColors.amber],
                  onTap: () => setState(() {
                    _level = _level == SafetyLevel.amber ? null : SafetyLevel.amber;
                  }),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SignalFilter(
                  label: 'تجنبي',
                  selected: _level == SafetyLevel.red,
                  soft: HyaColors.redSoft,
                  count: _countFor(SafetyLevel.red),
                  band: const [HyaColors.red],
                  onTap: () => setState(() {
                    _level = _level == SafetyLevel.red ? null : SafetyLevel.red;
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _KindFilter(
                  label: 'الكل',
                  icon: Icons.apps_rounded,
                  selected: _kind == null,
                  onTap: () => setState(() => _kind = null),
                ),
                for (final kind in GuideKind.values) ...[
                  const SizedBox(width: 8),
                  _KindFilter(
                    label: kindLabel(kind),
                    icon: _kindIcon(kind),
                    selected: _kind == kind,
                    onTap: () => setState(() => _kind = _kind == kind ? null : kind),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            const HyaEmptyView(
              icon: Icons.health_and_safety_outlined,
              title: 'مش موجود في دليل هي',
              body: 'ما تاخديش قرار من النت. اسألي الطبيب أو الصيدلي، وقوليلهم أنتِ في أنهي أسبوع. دليلي معرفة عامة بس.',
            )
          else ...[
            HyaText(
              '${items.length} نتيجة',
              size: 12.5,
              weight: 650,
              color: HyaColors.muted,
            ),
            const SizedBox(height: 10),
            for (final item in items) ...[
              _GuideCard(item: item),
              const SizedBox(height: 10),
            ],
          ],
        ] else ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F0F2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const HyaText(
              'الصقي نص التقرير هنا. هي بتشرح الاختصارات اللي تعرفها بلغة بسيطة، ومش بتقرا صورة الأشعة ومش بتقول إن المقاس طبيعي.',
              color: HyaColors.muted,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _report,
            minLines: 4,
            maxLines: 8,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: 'مثلًا: BPD 48 mm, FHR 148, placenta anterior'),
          ),
          const SizedBox(height: 12),
          ..._termCards(),
        ],
      ],
    );
  }

  List<Widget> _termCards() {
    final text = _report.text.trim();
    if (text.isEmpty) {
      return [
        for (final term in reportTerms) ...[
          _TermCard(term: term),
          const SizedBox(height: 8),
        ],
      ];
    }
    final found = termsInText(text);
    if (found.isEmpty) {
      return const [
        HyaCard(
          child: HyaText('ما لقيتش اختصار معروف في النص. ابعتي الورقة لطبيبك يشرحها. التطبيق مش هيخمّن الأرقام.'),
        ),
      ];
    }
    return [
      for (final term in found) ...[
        _TermCard(term: term),
        const SizedBox(height: 8),
      ],
      const DisclaimerNote(text: 'وجود المصطلح في الورقة مش نتيجة. الطبيعي يتقال في العيادة على عمر الحمل والفحص كامل.'),
    ];
  }
}

IconData _kindIcon(GuideKind kind) {
  return switch (kind) {
    GuideKind.medicine => Icons.medication_rounded,
    GuideKind.food => Icons.restaurant_rounded,
    GuideKind.herb => Icons.spa_rounded,
    GuideKind.vitamin => Icons.science_rounded,
  };
}

String _shortLevel(SafetyLevel level) {
  return switch (level) {
    SafetyLevel.green => 'مناسب',
    SafetyLevel.amber => 'بحذر',
    SafetyLevel.red => 'تجنبي',
  };
}

(Color, Color, IconData) _levelTone(SafetyLevel level) {
  return switch (level) {
    SafetyLevel.green => (HyaColors.green, HyaColors.greenSoft, Icons.check_circle_rounded),
    SafetyLevel.amber => (HyaColors.amber, HyaColors.amberSoft, Icons.error_outline_rounded),
    SafetyLevel.red => (HyaColors.red, HyaColors.redSoft, Icons.block_rounded),
  };
}

class _SegmentSwitch extends StatelessWidget {
  const _SegmentSwitch({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: HyaColors.line.withValues(alpha: 0.85)),
      ),
      child: Row(
        children: [
          Expanded(child: _seg('دليل', Icons.menu_book_rounded, 0)),
          Expanded(child: _seg('مصطلحات التقرير', Icons.description_outlined, 1)),
        ],
      ),
    );
  }

  Widget _seg(String label, IconData icon, int value) {
    final selected = index == value;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: selected ? HyaColors.roseDeep : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => onChanged(value),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: selected ? Colors.white : HyaColors.muted),
                const SizedBox(width: 6),
                Flexible(
                  child: HyaText(
                    label,
                    size: 13,
                    weight: 700,
                    color: selected ? Colors.white : HyaColors.ink,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SignalFilter extends StatelessWidget {
  const _SignalFilter({
    required this.label,
    required this.selected,
    required this.soft,
    required this.count,
    required this.band,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color soft;
  final int count;
  final List<Color> band;
  final VoidCallback onTap;

  Color get _accent => band.length == 1 ? band.first : HyaColors.ink;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: selected ? soft : Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? _accent.withValues(alpha: band.length == 1 ? 0.55 : 0.22) : HyaColors.line.withValues(alpha: 0.75),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              SizedBox(
                height: 7,
                child: Row(
                  children: [
                    for (final color in band) Expanded(child: ColoredBox(color: color)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 10, 6, 11),
                child: Column(
                  children: [
                    HyaText(
                      '$count',
                      size: 18,
                      weight: 780,
                      color: selected ? _accent : HyaColors.ink,
                      align: TextAlign.center,
                      height: 1.1,
                    ),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: soft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: HyaText(
                        label,
                        size: 11,
                        weight: 740,
                        color: _accent,
                        align: TextAlign.center,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KindFilter extends StatelessWidget {
  const _KindFilter({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? HyaColors.roseDeep : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? HyaColors.roseDeep : HyaColors.line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: selected ? Colors.white : HyaColors.roseDeep),
              const SizedBox(width: 6),
              HyaText(label, size: 13, weight: 650, color: selected ? Colors.white : HyaColors.ink),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({required this.item});

  final GuideItem item;

  @override
  Widget build(BuildContext context) {
    final (color, soft, icon) = _levelTone(item.level);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: HyaColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: soft),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 6, color: color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(color: soft, borderRadius: BorderRadius.circular(12)),
                          child: Icon(icon, size: 18, color: color),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              HyaText(item.name, weight: 740, size: 15.5, height: 1.3),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  _MiniTag(
                                    text: _shortLevel(item.level),
                                    color: color,
                                    soft: soft,
                                  ),
                                  _MiniTag(
                                    text: kindLabel(item.kind),
                                    color: HyaColors.muted,
                                    soft: const Color(0xFFF3ECE8),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    HyaText(item.note, size: 13.5, height: 1.55, color: HyaColors.ink),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag({required this.text, required this.color, required this.soft});

  final String text;
  final Color color;
  final Color soft;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: soft, borderRadius: BorderRadius.circular(8)),
      child: HyaText(text, size: 11.5, weight: 700, color: color),
    );
  }
}

class _TermCard extends StatelessWidget {
  const _TermCard({required this.term});

  final ReportTerm term;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HyaColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: HyaColors.line.withValues(alpha: 0.75)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F0F2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: HyaText(term.code, size: 12, weight: 740, color: HyaColors.roseDeep),
          ),
          const SizedBox(height: 8),
          HyaText(term.title, weight: 720),
          const SizedBox(height: 6),
          HyaText(term.plain, height: 1.6, size: 13.5),
        ],
      ),
    );
  }
}
