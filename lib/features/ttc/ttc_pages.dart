import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/cycle_math.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/care.dart';
import '../../features/scanner/scanner_page.dart';
import '../../features/shell/shell_page.dart';
import '../../widgets/ui.dart';

class TtcHomePage extends StatelessWidget {
  const TtcHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final profile = store.profile!;
    final today = DateTime.now();
    final lmp = profile.lastPeriodDate;
    final snapshot = lmp == null
        ? null
        : CycleMath.cycleSnapshot(lastPeriod: lmp, cycleLength: profile.cycleLength, today: today);
    final log = store.logFor(today);

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
          color: HyaColors.sageSoft,
          child: Column(
            children: [
              WeekRing(
                progress: snapshot == null ? 0 : snapshot.cycleDay / snapshot.cycleLength,
                color: HyaColors.sage,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HyaText('${snapshot?.cycleDay ?? '—'}', size: 40, weight: 760, height: 1),
                    const HyaText('يوم في الدورة', size: 12.5, weight: 600, color: HyaColors.sageDeep),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              HyaText(_phaseTitle(snapshot), align: TextAlign.center, size: 18, weight: 720),
              const SizedBox(height: 4),
              HyaText(_phaseBody(snapshot), align: TextAlign.center, color: HyaColors.sageDeep, size: 13.5),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (snapshot != null)
          HyaCard(
            child: Row(
              children: [
                Expanded(child: _Stat('التبويض التقريبي', 'يوم ${snapshot.ovulationDay}')),
                Expanded(
                  child: _Stat(
                    snapshot.periodLate ? 'الدورة متأخرة' : 'الدورة الجاية',
                    snapshot.periodLate ? pluralDays(snapshot.lateDays) : formatDate(snapshot.nextPeriod),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        const SectionLabel('مزاج النهاردة'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final mood in ttcMoods)
              HyaChip(
                label: mood,
                color: HyaColors.sage,
                selected: log?.mood == mood,
                onTap: () => store.setMood(mood),
              ),
          ],
        ),
        const SizedBox(height: 14),
        const SectionLabel('علامات بتلاحظيها'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final symptom in prepSymptoms)
              HyaChip(
                label: symptom,
                color: HyaColors.sage,
                selected: log?.symptoms.contains(symptom) ?? false,
                onTap: () => store.toggleSymptom(symptom),
              ),
          ],
        ),
        const SizedBox(height: 16),
        const DisclaimerNote(
          text: 'نافذة الخصوبة تقدير من طول الدورة، مش تحليل تبويض. تأخر الدورة مش إثبات حمل. اختبار الحمل والطبيب أوضح من الحدس.',
        ),
      ],
    );
  }

  String _phaseTitle(CycleSnapshot? snapshot) {
    if (snapshot == null) return 'أضيفي تاريخ آخر دورة';
    return switch (snapshot.phase) {
      CyclePhase.period => 'أيام الدورة',
      CyclePhase.fertile => 'نافذة الخصوبة مفتوحة',
      CyclePhase.ovulation => 'يوم التبويض التقريبي',
      CyclePhase.luteal => 'بعد التبويض',
    };
  }

  String _phaseBody(CycleSnapshot? snapshot) {
    if (snapshot == null) return 'من الإعدادات، عشان الحساب يشتغل.';
    if (snapshot.periodLate) {
      return 'التقدير بيقول إن الدورة اتأخرت. لو ده مش معتاد، اختبار الحمل قرار هادي، والتشخيص مش من التطبيق.';
    }
    return switch (snapshot.phase) {
      CyclePhase.period => 'سجّلي أول يوم لو الدورة بدأت فعلاً النهاردة، من صفحة الدورة.',
      CyclePhase.fertile => 'الأيام دي هي الأعلى فرصة في الحساب التقريبي. مفيش وضعية بتضمن النتيجة.',
      CyclePhase.ovulation => 'ده تقدير يوم ${snapshot.ovulationDay} في دورة ${snapshot.cycleLength} يوم، مش تحليل معمل.',
      CyclePhase.luteal => 'الجسم في انتظار الدورة الجاية. الأعراض دي مش بتفرّق لوحدها بين دورة وحمل.',
    };
  }
}

class TtcPrepPage extends StatelessWidget {
  const TtcPrepPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SoftPage(
      children: [
        const PageHeader(kicker: 'قبل الحمل', title: 'الاستعداد'),
        const SizedBox(height: 8),
        const HyaText(
          'الصفحة دي بتهيّأ الجسم والسؤال الصح للطبيب. مش برنامج خصوبة ومش بتحسب جرعات.',
          color: HyaColors.muted,
        ),
        const SizedBox(height: 14),
        for (final card in ttcPrep) ...[
          HyaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HyaText(card.title, weight: 720, size: 16),
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

class CyclePage extends StatelessWidget {
  const CyclePage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final profile = store.profile!;
    final today = dateOnly(DateTime.now());
    final lmp = profile.lastPeriodDate;
    final snapshot = lmp == null
        ? null
        : CycleMath.cycleSnapshot(lastPeriod: lmp, cycleLength: profile.cycleLength, today: today);
    final log = store.logFor(today);

    return SoftPage(
      children: [
        const PageHeader(kicker: 'متابعة هادية', title: 'الدورة'),
        const SizedBox(height: 12),
        if (snapshot == null)
          const HyaCard(child: HyaText('تاريخ آخر دورة ناقص. زوديه من الإعدادات.'))
        else
          HyaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HyaText('دورة ${snapshot.cycleLength} يوم', weight: 720),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (var day = 1; day <= snapshot.cycleLength; day++)
                      _DayDot(
                        day: day,
                        today: day == snapshot.cycleDay,
                        period: day <= 5,
                        fertile: day >= snapshot.ovulationDay - 5 && day <= snapshot.ovulationDay + 1,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                const HyaText('النقطة الغامقة يومك. الأخضر أيام الخصوبة التقديرية، والوردي أيام الدورة.', size: 12.5, color: HyaColors.muted),
              ],
            ),
          ),
        const SizedBox(height: 12),
        HyaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const HyaText('حرارة الصبح', weight: 720),
              const SizedBox(height: 6),
              const HyaText(
                'اختياري. بعض البنات بتسجل حرارة الجسم قبل ما تقوم من السرير. الرقم مش تشخيص، ولو هتستخدميه خلّصي الطريقة مع طبيب.',
                size: 13,
                color: HyaColors.muted,
              ),
              const SizedBox(height: 10),
              TextField(
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: log?.temperature == null ? 'مثلًا ٣٦.٦' : log!.temperature!.toStringAsFixed(1),
                ),
                onSubmitted: (value) {
                  final parsed = double.tryParse(value.replaceAll(',', '.'));
                  if (parsed == null || parsed < 35 || parsed > 41) return;
                  store.setTemperature(parsed);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: HyaColors.sage),
          onPressed: () async {
            await store.saveProfile(profile.copyWith(lastPeriodDate: today));
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اتسجل إن الدورة بدأت النهاردة')));
          },
          child: const Text('الدورة بدأت النهاردة'),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HyaText(label, size: 12, weight: 600, color: HyaColors.muted),
        const SizedBox(height: 2),
        HyaText(value, weight: 720, size: 15),
      ],
    );
  }
}

class _DayDot extends StatelessWidget {
  const _DayDot({
    required this.day,
    required this.today,
    required this.period,
    required this.fertile,
  });

  final int day;
  final bool today;
  final bool period;
  final bool fertile;

  @override
  Widget build(BuildContext context) {
    final color = today
        ? HyaColors.ink
        : period
            ? const Color(0xFFE7B7BE)
            : fertile
                ? HyaColors.sageSoft
                : Colors.white;
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: today ? HyaColors.ink : HyaColors.line),
      ),
      child: Text(
        '$day',
        style: HyaType.style(size: 11, weight: 650, color: today ? Colors.white : HyaColors.ink, height: 1),
      ),
    );
  }
}
