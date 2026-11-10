import 'package:flutter/material.dart';

import '../../core/safety.dart';
import '../../core/theme.dart';
import '../../data/guides.dart';
import '../../data/scan_catalog.dart';
import '../../widgets/ui.dart';
import '../scanner/scanner_page.dart';

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

  @override
  void dispose() {
    _search.dispose();
    _report.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = normalizeArabic(_search.text.trim());
    final items = scanPool.where((item) {
      if (_kind != null && item.kind != _kind) return false;
      if (query.isEmpty) return true;
      final haystack = normalizeArabic('${item.name} ${item.aliases.join(' ')}');
      return haystack.contains(query);
    }).toList();

    return SoftPage(
      children: [
        const PageHeader(kicker: 'معرفة عامة', title: 'الدرع'),
        const SizedBox(height: 8),
        const DisclaimerNote(text: safetyDisclaimer),
        const SizedBox(height: 14),
        HyaCard(
          color: HyaColors.blush,
          onTap: () => openScanner(context),
          child: const Row(
            children: [
              Icon(Icons.photo_camera_rounded, color: HyaColors.roseDeep),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HyaText('صوّري الأكل أو الدواء', weight: 740, size: 16),
                    SizedBox(height: 3),
                    HyaText('هقولك مسموح ولا ممنوع، وباللون', size: 13, color: HyaColors.muted),
                  ],
                ),
              ),
              HyaTrailingChevron(color: HyaColors.rose),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            HyaChip(label: 'دليل', selected: _segment == 0, onTap: () => setState(() => _segment = 0)),
            const SizedBox(width: 8),
            HyaChip(label: 'مصطلحات التقرير', selected: _segment == 1, onTap: () => setState(() => _segment = 1)),
          ],
        ),
        const SizedBox(height: 14),
        if (_segment == 0) ...[
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: 'ابحثي باسم الدواء أو الأكل'),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              HyaChip(label: 'الكل', selected: _kind == null, onTap: () => setState(() => _kind = null)),
              for (final kind in GuideKind.values)
                HyaChip(
                  label: kindLabel(kind),
                  selected: _kind == kind,
                  onTap: () => setState(() => _kind = kind),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const HyaCard(
              child: HyaText(
                'مش موجود في دليل هي. ما تاخديش قرار من النت: اسألي الطبيب أو الصيدلي، وقوليلهم أنتِ في أنهي أسبوع.',
              ),
            )
          else
            for (final item in items) ...[
              _GuideCard(item: item),
              const SizedBox(height: 10),
            ],
        ] else ...[
          const HyaText(
            'الصقي نص التقرير هنا. هي بتشرح الاختصارات اللي تعرفها بلغة بسيطة، ومش بتقرا صورة الأشعة ومش بتقول إن المقاس طبيعي.',
            color: HyaColors.muted,
          ),
          const SizedBox(height: 10),
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

class _GuideCard extends StatelessWidget {
  const _GuideCard({required this.item});

  final GuideItem item;

  @override
  Widget build(BuildContext context) {
    final (color, soft) = switch (item.level) {
      SafetyLevel.green => (HyaColors.green, HyaColors.greenSoft),
      SafetyLevel.amber => (HyaColors.amber, HyaColors.amberSoft),
      SafetyLevel.red => (HyaColors.red, HyaColors.redSoft),
    };
    return HyaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(child: HyaText(item.name, weight: 720, size: 16)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: soft, borderRadius: BorderRadius.circular(999)),
            child: HyaText('${kindLabel(item.kind)} · ${levelLabel(item.level)}', size: 12, weight: 650, color: color),
          ),
          const SizedBox(height: 8),
          HyaText(item.note, height: 1.6),
        ],
      ),
    );
  }
}

class _TermCard extends StatelessWidget {
  const _TermCard({required this.term});

  final ReportTerm term;

  @override
  Widget build(BuildContext context) {
    return HyaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HyaText(term.code, size: 13, weight: 700, color: HyaColors.roseDeep),
          const SizedBox(height: 2),
          HyaText(term.title, weight: 720),
          const SizedBox(height: 6),
          HyaText(term.plain, height: 1.6),
        ],
      ),
    );
  }
}
