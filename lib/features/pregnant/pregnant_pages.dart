import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/cycle_math.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/care.dart';
import '../../data/weeks.dart';
import '../../features/scanner/scanner_page.dart';
import '../../features/shell/shell_page.dart';
import '../../widgets/ui.dart';

class PregnantHomePage extends StatelessWidget {
  const PregnantHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final profile = store.profile!;
    final lmp = CycleMath.estimatedLmp(profile);
    final today = DateTime.now();
    final age = lmp == null ? null : CycleMath.gestationalAge(lmp, today);
    final week = age?.week ?? 0;
    final guide = guideForWeek(week == 0 ? 1 : week);
    final log = store.logFor(today);
    final due = CycleMath.estimatedDueDate(profile);

    return SoftPage(
      children: [
        HomeGreeting(
          greeting: greetingFor(today),
          name: profile.name,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              HyaCameraButton(onPressed: () => openScanner(context)),
              IconButton(
                onPressed: () => openSettings(context),
                icon: const Icon(Icons.tune_rounded),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _WeekJourney(
          week: week,
          day: age?.day,
          due: due,
          size: guide.size,
          known: age != null,
          onOpenDetails: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => WeekPage(week: guide.week)));
          },
        ),
        const SizedBox(height: 16),
        const SectionLabel('مزاجك النهاردة'),
        const SizedBox(height: 4),
        const HyaText(
          'اختياري. لما تختاري، الجملة تتسجل في يومك عشان ترجعي تفتكري اليوم كان عامل إزاي.',
          size: 12.5,
          color: HyaColors.muted,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final mood in pregnantMoods)
              HyaChip(
                label: mood.label,
                selected: log?.mood == mood.label,
                onTap: () => store.setMood(mood.label),
              ),
          ],
        ),
        if (feelMeaning(pregnantMoods, log?.mood) != null) ...[
          const SizedBox(height: 10),
          _MeaningCard(text: feelMeaning(pregnantMoods, log?.mood)!),
        ],
        const SizedBox(height: 16),
        const SectionLabel('حسيتي إيه في جسمك؟'),
        const SizedBox(height: 4),
        const HyaText(
          'اختاري اللي موجود. كل واحدة بتظهر جملتها: شائع ولا يستاهل اتصال بالطبيب.',
          size: 12.5,
          color: HyaColors.muted,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final symptom in pregnantSymptoms)
              HyaChip(
                label: symptom.label,
                selected: log?.symptoms.contains(symptom.label) ?? false,
                onTap: () => store.toggleSymptom(symptom.label),
              ),
          ],
        ),
        for (final symptom in pregnantSymptoms)
          if (log?.symptoms.contains(symptom.label) ?? false) ...[
            const SizedBox(height: 8),
            _MeaningCard(title: symptom.label, text: symptom.meaning),
          ],
        const SizedBox(height: 8),
        const HyaText(
          'الاختيار تسجيل ومعلومة عامة، مش تشخيص. النزيف، أو الصداع الشديد مع زغللة، أو ضيق النفس: طبيبك أو الإسعاف ١٢٣.',
          size: 12.5,
          color: HyaColors.muted,
        ),
        const SizedBox(height: 16),
        if (week < 28)
          const _MovementLater()
        else ...[
          HyaCard(
            child: Column(
              children: [
                HyaText('${log?.kicks ?? 0}', size: 32, weight: 760, height: 1),
                const SizedBox(height: 2),
                const HyaText('حركة حسيتيها النهاردة', size: 13, weight: 650),
                const SizedBox(height: 8),
                const HyaText(
                  'كل ضغطة حركة واحدة حسيتيها إنتي. الرقم مذكرتك، ومش حكم إن اليوم سليم.',
                  align: TextAlign.center,
                  size: 12.5,
                  color: HyaColors.muted,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => store.addKicks(1),
                  child: const Text('حسيت حركة'),
                ),
                if ((log?.kicks ?? 0) > 0)
                  TextButton(
                    onPressed: () => store.addKicks(-1),
                    child: const Text('اضغطت بالغلط'),
                  ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: TextButton(
              onPressed: () => _movementWarning(context),
              child: const Text('الحركة أقل من المعتاد'),
            ),
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _LinkCard(
                title: 'رسالة لبابا',
                body: 'نصيحة الأسبوع للي جنبك',
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => PartnerPage(week: guide.week)));
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _LinkCard(
                title: 'الكبسولة',
                body: 'رسالة تتفتح في المستقبل',
                onTap: () => openCapsule(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _movementWarning(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const HyaText('ما تستنيش التطبيق', size: 20, weight: 740),
        content: const HyaText(
          'لو حركة البيبي أقل من النمط اللي متعوداه، اتصلي بطبيب المتابعة. لو مش متاحة، الإسعاف ١٢٣. العداد هنا تسجيل بس، ومش بيقول إن الحركة كويسة.',
          size: 14.5,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('تمام')),
        ],
      ),
    );
  }
}

class WeekPage extends StatelessWidget {
  const WeekPage({super.key, required this.week});

  final int week;

  @override
  Widget build(BuildContext context) {
    final guide = guideForWeek(week);
    return HyaBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          title: HyaText('تفاصيل الأسبوع ${guide.week}', weight: 720, size: 18),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            HyaCard(
              color: HyaColors.blush,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const HyaText('البيبي دلوقتي قد', size: 12.5, weight: 700, color: HyaColors.roseDeep),
                  const SizedBox(height: 4),
                  HyaText(guide.size, size: 26, weight: 740),
                  const SizedBox(height: 8),
                  HyaText(guide.baby, size: 14.5, height: 1.55, color: HyaColors.ink),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _DetailBlock(
              icon: Icons.spa_rounded,
              tint: HyaColors.sage,
              soft: HyaColors.sageSoft,
              title: 'إيه اللي بيتكون؟',
              body: guide.forming,
            ),
            const SizedBox(height: 10),
            _DetailBlock(
              icon: Icons.lightbulb_rounded,
              tint: HyaColors.roseDeep,
              soft: const Color(0xFFFFF0ED),
              title: 'معلومة لازم تعرفها',
              body: guide.know,
            ),
            const SizedBox(height: 10),
            _DetailBlock(
              icon: Icons.priority_high_rounded,
              tint: HyaColors.amber,
              soft: HyaColors.amberSoft,
              title: 'تجنّبي إيه؟',
              body: guide.avoid,
            ),
            const SizedBox(height: 10),
            _DetailBlock(
              icon: Icons.favorite_rounded,
              tint: HyaColors.rose,
              soft: const Color(0xFFFFF6F4),
              title: 'جسمك الأسبوع ده',
              body: guide.mom,
            ),
            const SizedBox(height: 10),
            _Info(title: 'رسالة من البيبي', body: guide.letter),
            const SizedBox(height: 10),
            _Info(title: 'للي جنبك', body: guide.partner),
            const SizedBox(height: 14),
            const DisclaimerNote(
              text: 'الكلام عام ومبسّط بالعامية، مش تشخيص ولا بديل عن الدكتور. أي نزيف أو صداع شديد أو زغللة أو حركة أقل من المعتاد: طبيبك أو الإسعاف ١٢٣.',
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekDetailsButton extends StatefulWidget {
  const _WeekDetailsButton({
    required this.week,
    required this.size,
    required this.onTap,
  });

  final int week;
  final String size;
  final VoidCallback onTap;

  @override
  State<_WeekDetailsButton> createState() => _WeekDetailsButtonState();
}

class _WeekDetailsButtonState extends State<_WeekDetailsButton> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final glow = 0.12 + _pulse.value * 0.14;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: widget.onTap,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [Color(0xFFC56B76), Color(0xFF6E9178)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: HyaColors.rose.withValues(alpha: glow),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const HyaText(
                            'شوفي تفاصيل الأسبوع',
                            size: 16.5,
                            weight: 780,
                            color: Colors.white,
                            height: 1.15,
                          ),
                          const SizedBox(height: 3),
                          HyaText(
                            'إيه بيتكون · معلومة مهمة · إيه تتجنبيه',
                            size: 12,
                            weight: 520,
                            color: Colors.white.withValues(alpha: 0.92),
                            height: 1.3,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    const HyaForwardArrow(size: 15, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DetailBlock extends StatelessWidget {
  const _DetailBlock({
    required this.icon,
    required this.tint,
    required this.soft,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color tint;
  final Color soft;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return HyaCard(
      color: soft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: tint.withValues(alpha: 0.16), shape: BoxShape.circle),
            child: Icon(icon, color: tint, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HyaText(title, size: 14, weight: 740, color: tint),
                const SizedBox(height: 6),
                HyaText(body, height: 1.65),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PartnerPage extends StatelessWidget {
  const PartnerPage({super.key, required this.week});

  final int week;

  @override
  Widget build(BuildContext context) {
    final guide = guideForWeek(week);
    return HyaBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          title: const HyaText('رسالة لبابا', weight: 720, size: 18),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            const HyaText(
              'الصفحة دي تتبعتله أو تتقراله. حساب منفصل للأب محتاج دعوة سحابية، والنصيحة دي جاهزة من غير ما يستنى.',
              color: HyaColors.muted,
            ),
            const SizedBox(height: 14),
            HyaCard(
              color: const Color(0xFFF3F6F8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HyaText('الأسبوع $week', size: 13, weight: 700, color: HyaColors.roseDeep),
                  const SizedBox(height: 8),
                  HyaText(guide.partner, size: 18, weight: 600, height: 1.7),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _Info(title: 'هي حاسة بإيه تقريبًا', body: guide.mom),
            const SizedBox(height: 12),
            _Info(title: 'البيبي الأسبوع ده', body: guide.baby),
          ],
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return HyaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HyaText(title, size: 13, weight: 700, color: HyaColors.roseDeep),
          const SizedBox(height: 6),
          HyaText(body, height: 1.65),
        ],
      ),
    );
  }
}

class _LinkCard extends StatelessWidget {
  const _LinkCard({required this.title, required this.body, required this.onTap});

  final String title;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return HyaCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HyaText(title, weight: 720, size: 15),
          const SizedBox(height: 4),
          HyaText(body, size: 12.5, color: HyaColors.muted),
        ],
      ),
    );
  }
}

class _WeekJourney extends StatefulWidget {
  const _WeekJourney({
    required this.week,
    required this.day,
    required this.due,
    required this.size,
    required this.known,
    required this.onOpenDetails,
  });

  final int week;
  final int? day;
  final DateTime? due;
  final String size;
  final bool known;
  final VoidCallback onOpenDetails;

  @override
  State<_WeekJourney> createState() => _WeekJourneyState();
}

class _WeekJourneyState extends State<_WeekJourney> with TickerProviderStateMixin {
  late final AnimationController _enter;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(vsync: this, duration: const Duration(milliseconds: 1900))..forward();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat();
  }

  @override
  void dispose() {
    _enter.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final target = (widget.week / 40).clamp(0, 1).toDouble();
    final month = _pregnancyMonth(widget.week);
    final day = widget.day ?? 0;
    final weekValue = day == 0 ? 'الأسبوع ${widget.week}' : 'الأسبوع ${widget.week} واليوم $day';
    final facts = <(IconData, Color, String, String)>[
      (Icons.calendar_today_rounded, HyaColors.rose, 'فين إنتي؟', 'إنتي دلوقتي في $weekValue'),
      (Icons.nightlight_round, HyaColors.sage, 'الشهر كام؟', 'ده الشهر ${_monthName(month)}'),
      if (widget.due != null)
        (Icons.favorite_rounded, HyaColors.roseDeep, 'ميعاد الولادة', 'الميعاد المتوقع يوم ${formatDate(widget.due!)}'),
      (Icons.spa_rounded, HyaColors.sageDeep, 'حجم البيبي', 'البيبي دلوقتي قد ${widget.size}'),
    ];

    return AnimatedBuilder(
      animation: Listenable.merge([_enter, _pulse]),
      builder: (context, _) {
        final cardFade = Curves.easeOut.transform((_enter.value / 0.22).clamp(0.0, 1.0));
        final drawn = Curves.easeOutCubic.transform(((_enter.value - 0.08) / 0.55).clamp(0.0, 1.0));
        final beat = 1 + (0.5 - (0.5 - _pulse.value).abs()) * 0.035;
        final shownWeek = (widget.week * drawn).round().clamp(0, widget.week);
        final ringGlow = 0.18 + (0.5 - (0.5 - _pulse.value).abs()) * 0.16;

        return Opacity(
          opacity: cardFade,
          child: Transform.translate(
            offset: Offset(0, (1 - cardFade) * 18),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [Color(0xFFFFF8F6), Color(0xFFF3F8F4), Color(0xFFFFFCF9)],
                ),
                border: Border.all(color: HyaColors.line.withValues(alpha: 0.75)),
                boxShadow: [
                  BoxShadow(
                    color: HyaColors.rose.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: 156,
                    height: 156,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        for (final step in [0.0, 0.33, 0.66])
                          Transform.scale(
                            scale: 0.72 + ((_pulse.value + step) % 1) * 0.38,
                            child: Opacity(
                              opacity: (1 - ((_pulse.value + step) % 1)) * 0.22,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: step < 0.4 ? HyaColors.rose : HyaColors.sage,
                                    width: 1.4,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        Transform.scale(
                          scale: beat,
                          child: SizedBox(
                            width: 140,
                            height: 140,
                            child: CustomPaint(
                              painter: _JourneyRingPainter(
                                progress: drawn * target,
                                primary: HyaColors.rose,
                                accent: HyaColors.sage,
                                glow: ringGlow,
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    HyaText('$shownWeek', size: 36, weight: 780, height: 1, color: HyaColors.roseDeep),
                                    const HyaText('أسبوع', size: 12.5, weight: 650, color: HyaColors.sageDeep),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (!widget.known)
                    const HyaText('كمّلي تاريخ الحمل من الإعدادات', align: TextAlign.center, weight: 650)
                  else ...[
                    _WeekDetailsButton(
                      week: widget.week,
                      size: widget.size,
                      onTap: widget.onOpenDetails,
                    ),
                    const SizedBox(height: 12),
                    for (var i = 0; i < facts.length; i++) ...[
                      if (i > 0) const SizedBox(height: 8),
                      _factTile(
                        start: 0.38 + i * 0.12,
                        icon: facts[i].$1,
                        tint: facts[i].$2,
                        label: facts[i].$3,
                        value: facts[i].$4,
                      ),
                    ],
                    if (widget.week > 42) ...[
                      const SizedBox(height: 8),
                      const HyaText(
                        'عديتي الأسبوع ٤٢. الميعاد تقريبي، والدكتور يتابع الخطوة الجاية.',
                        align: TextAlign.center,
                        size: 13,
                        color: HyaColors.muted,
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _factTile({
    required double start,
    required IconData icon,
    required Color tint,
    required String label,
    required String value,
  }) {
    final end = (start + 0.22).clamp(0.0, 1.0);
    final t = Curves.easeOutBack.transform(((_enter.value - start) / (end - start)).clamp(0.0, 1.0));
    return Opacity(
      opacity: t.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset((1 - t) * 18, 0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: tint.withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: tint),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HyaText(label, size: 12, weight: 700, color: tint),
                    const SizedBox(height: 2),
                    HyaText(value, size: 14.5, weight: 650, height: 1.35),
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

class _JourneyRingPainter extends CustomPainter {
  const _JourneyRingPainter({
    required this.progress,
    required this.primary,
    required this.accent,
    required this.glow,
  });

  final double progress;
  final Color primary;
  final Color accent;
  final double glow;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = 13.0;
    final rect = (Offset.zero & size).deflate(stroke + 4);
    final track = Paint()
      ..color = const Color(0xFFE8EFEA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final soft = Paint()
      ..color = accent.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final value = Paint()
      ..shader = SweepGradient(
        startAngle: -1.5708,
        endAngle: -1.5708 + 6.28318,
        colors: [primary, accent, primary],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final halo = Paint()
      ..color = primary.withValues(alpha: glow)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    canvas.drawCircle(size.center(Offset.zero), rect.width / 2, halo);
    canvas.drawArc(rect, 0, 6.28318, false, track);
    canvas.drawArc(rect, -1.5708, 6.28318 * progress.clamp(0, 1), false, soft);
    canvas.drawArc(rect, -1.5708, 6.28318 * progress.clamp(0, 1), false, value);
  }

  @override
  bool shouldRepaint(covariant _JourneyRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.primary != primary ||
        oldDelegate.accent != accent ||
        oldDelegate.glow != glow;
  }
}

const _monthNames = ['الأول', 'التاني', 'التالت', 'الرابع', 'الخامس', 'السادس', 'السابع', 'التامن', 'التاسع', 'العاشر'];

int _pregnancyMonth(int week) {
  if (week < 1) return 1;
  return ((week - 1) ~/ 4 + 1).clamp(1, 10);
}

String _monthName(int month) => _monthNames[month.clamp(1, 10) - 1];

class _MeaningCard extends StatelessWidget {
  const _MeaningCard({this.title, required this.text});

  final String? title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return HyaCard(
      color: const Color(0xFFFFF6F4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            HyaText(title!, size: 13, weight: 720, color: HyaColors.roseDeep),
            const SizedBox(height: 4),
          ],
          HyaText(text, size: 13.5, height: 1.55),
        ],
      ),
    );
  }
}

class _MovementLater extends StatelessWidget {
  const _MovementLater();

  @override
  Widget build(BuildContext context) {
    return const HyaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HyaText('حركات البيبي', size: 16, weight: 720),
          SizedBox(height: 6),
          HyaText(
            'لسه بدري على عدّ الحركات. البيبي بيتحرك من غير ما تحسي، وأول إحساس غالبًا بين الأسبوع ١٦ و٢٥، وناس بتحس متأخر. العدّ اليومي بيبدأ من الأسبوع ٢٨، بالطريقة اللي يشرحها الطبيب. رقم صفر دلوقتي ملوش معنى.',
            size: 13.5,
            height: 1.6,
          ),
        ],
      ),
    );
  }
}
