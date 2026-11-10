import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../widgets/ui.dart';
import '../hospital/hospital_page.dart';
import '../settings/settings_page.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SoftPage(
      children: [
        const PageHeader(kicker: 'كل اللي محتاجاه في مكان', title: 'المزيد'),
        const SizedBox(height: 8),
        const HyaText(
          'الحقيبة والإعدادات من هنا، عشان الشاشة الرئيسية تفضل للرحلة.',
          color: HyaColors.muted,
        ),
        const SizedBox(height: 18),
        _MoreTile(
          icon: Icons.luggage_rounded,
          title: 'الحقيبة',
          body: 'قائمة مستشفى الولادة، علشان النسيان ما يوسوسكيش.',
          accent: HyaColors.rose,
          soft: HyaColors.blush,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HospitalPage()),
            );
          },
        ),
        const SizedBox(height: 10),
        _MoreTile(
          icon: Icons.tune_rounded,
          title: 'الإعدادات',
          body: 'الحساب، البيانات، وتغيير مرحلة الرحلة.',
          accent: HyaColors.roseDeep,
          soft: const Color(0xFFF3E6EC),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            );
          },
        ),
      ],
    );
  }
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({
    required this.icon,
    required this.title,
    required this.body,
    required this.accent,
    required this.soft,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color accent;
  final Color soft;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: HyaColors.card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: HyaColors.line.withValues(alpha: 0.8)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: soft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HyaText(title, weight: 740, size: 16),
                    const SizedBox(height: 4),
                    HyaText(body, size: 13, color: HyaColors.muted, height: 1.45),
                  ],
                ),
              ),
              HyaTrailingChevron(color: accent.withValues(alpha: 0.75), size: 14),
            ],
          ),
        ),
      ),
    );
  }
}
