import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/theme.dart';
import '../../data/care.dart';
import '../../widgets/ui.dart';

class HospitalPage extends StatelessWidget {
  const HospitalPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final done = hospitalBag.where((item) => store.hospitalChecks.contains(item.id)).length;
    final sections = <String>[];
    for (final item in hospitalBag) {
      if (!sections.contains(item.section)) sections.add(item.section);
    }

    return SoftPage(
      children: [
        const PageHeader(kicker: 'من غير ما النسيان يوسوسك', title: 'الحقيبة'),
        const SizedBox(height: 8),
        HyaCard(
          color: HyaColors.blush,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HyaText('$done من ${hospitalBag.length}', size: 28, weight: 760),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  minHeight: 8,
                  value: hospitalBag.isEmpty ? 0 : done / hospitalBag.length,
                  backgroundColor: Colors.white,
                  color: HyaColors.rose,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const HyaText(
          'القائمة اقتراح. المستشفى أحيانًا بتطلب حاجات زيادة أو بتوفّر حاجات. اتبعي الورقة بتاعتهم لو اختلفت.',
          size: 13,
          color: HyaColors.muted,
        ),
        const SizedBox(height: 14),
        for (final section in sections) ...[
          SectionLabel(section),
          const SizedBox(height: 8),
          for (final item in hospitalBag.where((entry) => entry.section == section))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: HyaCard(
                onTap: () => store.toggleHospital(item.id),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      store.hospitalChecks.contains(item.id) ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                      color: HyaColors.rose,
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: HyaText(item.label, weight: 620)),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
