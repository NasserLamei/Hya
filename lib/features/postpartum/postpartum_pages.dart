import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/cycle_math.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/care.dart';
import '../../features/scanner/scanner_page.dart';
import '../../features/shell/shell_page.dart';
import '../../widgets/ui.dart';

class PostpartumHomePage extends StatelessWidget {
  const PostpartumHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final profile = store.profile!;
    final today = DateTime.now();
    final birth = profile.babyBirthDate;
    final baby = (profile.babyName == null || profile.babyName!.isEmpty) ? 'البيبي' : profile.babyName!;
    final age = birth == null ? 'أضيفي تاريخ الولادة' : formatBabyAge(birth, today);
    final side = store.lastFeedSide();
    final log = store.logFor(today);
    final openCapsules = store.capsules.where((note) => note.isOpenOn(today)).length;

    return SoftPage(
      children: [
        HomeGreeting(
          greeting: greetingFor(today),
          name: profile.name,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              HyaCameraButton(onPressed: () => openScanner(context)),
              IconButton(onPressed: () => openSettings(context), icon: const Icon(Icons.tune_rounded)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        HyaCard(
          color: HyaColors.goldSoft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HyaText(baby, size: 14, weight: 700, color: HyaColors.goldDeep),
              const SizedBox(height: 4),
              HyaText(age, size: 28, weight: 760, height: 1.25),
              const SizedBox(height: 6),
              HyaText(
                side == null
                    ? 'لسه ما اتسجلتش رضاعة. الزرار الكبير تحت عشان الناحيتين.'
                    : 'آخر رضاعة كانت من ${side == 'feed_right' ? 'اليمين' : 'الشمال'}.',
                size: 13.5,
                color: HyaColors.goldDeep,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _FeedButton(label: 'يمين', onTap: () => store.addBabyLog('feed_right'))),
            const SizedBox(width: 8),
            Expanded(child: _FeedButton(label: 'شمال', onTap: () => store.addBabyLog('feed_left'))),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _SmallLog(label: 'حفاض', onTap: () => store.addBabyLog('diaper'))),
            const SizedBox(width: 8),
            Expanded(child: _SmallLog(label: 'نوم', onTap: () => store.addBabyLog('sleep'))),
            const SizedBox(width: 8),
            Expanded(child: _SmallLog(label: 'شفط', onTap: () => store.addBabyLog('pump'))),
          ],
        ),
        const SizedBox(height: 16),
        const SectionLabel('أنتِ النهاردة'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final mood in postpartumMoods)
              HyaChip(
                label: mood,
                color: HyaColors.gold,
                selected: log?.mood == mood,
                onTap: () => store.setMood(mood),
              ),
          ],
        ),
        if (log?.mood == 'حزينة شوية' || log?.mood == 'متوترة') ...[
          const SizedBox(height: 10),
          const DisclaimerNote(
            text: 'الحزن والتوتر بعد الولادة شائعين، ومش ضعف. لو الإحساس تقيل، أو مش قادره تهتمي بنفسك أو بالبيبي، أو فيه أفكار تخوّف: كلّمي الطبيب وحد قريب النهاردة. لو في خطر فوري، الإسعاف ١٢٣.',
          ),
        ],
        const SizedBox(height: 12),
        HyaCard(
          onTap: () => openCapsule(context),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HyaText('كبسولة الزمن', weight: 720),
                    SizedBox(height: 4),
                    HyaText('الرسائل اللي اتقفلت وأنتِ حامل تتفتح هنا لما معادها ييجي.', size: 13, color: HyaColors.muted),
                  ],
                ),
              ),
              HyaText('$openCapsules', size: 22, weight: 760, color: HyaColors.goldDeep),
            ],
          ),
        ),
      ],
    );
  }
}

class BabyLogPage extends StatelessWidget {
  const BabyLogPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final today = dateOnly(DateTime.now());
    final entries = store.babyLogs.where((entry) => dateOnly(entry.at) == today).toList();

    return SoftPage(
      children: [
        const PageHeader(kicker: 'النهاردة بس', title: 'السجل'),
        const SizedBox(height: 8),
        const HyaText('تسجيل سريع عشان الليل ما يبهدلش الذاكرة. مش جدول رضاعة إجباري.', color: HyaColors.muted),
        const SizedBox(height: 14),
        if (entries.isEmpty)
          const HyaCard(child: HyaText('لسه مفيش حاجة متسجلة النهاردة. الأزرار في الصفحة الأولى.'))
        else
          for (final entry in entries) ...[
            HyaCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(child: HyaText(_label(entry.type), weight: 680)),
                  HyaText(_time(entry.at), size: 13, color: HyaColors.muted),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
      ],
    );
  }

  String _label(String type) {
    return switch (type) {
      'feed_right' => 'رضاعة من اليمين',
      'feed_left' => 'رضاعة من الشمال',
      'diaper' => 'تغيير حفاض',
      'sleep' => 'نوم',
      'pump' => 'شفط',
      _ => type,
    };
  }

  String _time(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class VaccinesPage extends StatelessWidget {
  const VaccinesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final birth = store.profile?.babyBirthDate;

    return SoftPage(
      children: [
        const PageHeader(kicker: 'تذكير مش شهادة', title: 'التطعيم'),
        const SizedBox(height: 8),
        const DisclaimerNote(text: vaccineDisclaimer),
        const SizedBox(height: 14),
        if (birth == null)
          const HyaCard(child: HyaText('تاريخ الولادة ناقص. من غير ما يتسجل، المواعيد مش هتتحسب.'))
        else
          for (final dose in egyptVaccines) ...[
            _VaccineCard(
              title: dose.title,
              detail: dose.detail,
                when: formatDate(addDays(birth, dose.day)),
              done: store.vaccineChecks.contains(dose.id),
              onToggle: () => store.toggleVaccine(dose.id),
            ),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

class RecoveryPage extends StatelessWidget {
  const RecoveryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = StoreScope.of(context).profile!;
    final birth = profile.babyBirthDate;
    final days = birth == null ? 0 : dateOnly(DateTime.now()).difference(dateOnly(birth)).inDays;
    final cards = recoveryCards(days: days, cesarean: profile.deliveryType?.name == 'cesarean');

    return SoftPage(
      children: [
        const PageHeader(kicker: 'جسمك بعد الولادة', title: 'التعافي'),
        const SizedBox(height: 8),
        HyaText(
          birth == null ? 'أضيفي تاريخ الولادة عشان النصيحة تظبط على الأيام.' : 'عدى ${pluralDays(days)} من الولادة.',
          color: HyaColors.muted,
        ),
        const SizedBox(height: 14),
        for (final card in cards) ...[
          HyaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HyaText(card.title, weight: 720),
                const SizedBox(height: 6),
                HyaText(card.body, height: 1.65),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        const SectionLabel('لو بيبكي'),
        const SizedBox(height: 8),
        for (final card in soothingIdeas) ...[
          HyaCard(
            color: HyaColors.goldSoft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HyaText(card.title, weight: 720),
                const SizedBox(height: 6),
                HyaText(card.body, height: 1.65),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _FeedButton extends StatelessWidget {
  const _FeedButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(backgroundColor: HyaColors.goldDeep, minimumSize: const Size.fromHeight(64)),
      onPressed: onTap,
      child: Text('رضاعة $label'),
    );
  }
}

class _SmallLog extends StatelessWidget {
  const _SmallLog({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(onPressed: onTap, child: Text(label));
  }
}

class _VaccineCard extends StatelessWidget {
  const _VaccineCard({
    required this.title,
    required this.detail,
    required this.when,
    required this.done,
    required this.onToggle,
  });

  final String title;
  final String detail;
  final String when;
  final bool done;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return HyaCard(
      onTap: onToggle,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            done ? Icons.check_circle_rounded : Icons.circle_outlined,
            color: done ? HyaColors.green : HyaColors.gold,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HyaText(title, weight: 720),
                const SizedBox(height: 2),
                HyaText(when, size: 12.5, weight: 650, color: HyaColors.goldDeep),
                const SizedBox(height: 4),
                HyaText(detail, size: 13.5, color: HyaColors.muted, height: 1.55),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
