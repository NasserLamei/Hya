import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app.dart';
import '../../core/cycle_math.dart';
import '../../core/format.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../../widgets/ui.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> with TickerProviderStateMixin {
  final _babyName = TextEditingController();
  final _page = PageController();

  late final AnimationController _pulse;
  late final AnimationController _enter;

  var _step = 0;
  var _mode = LifeMode.pregnant;
  var _useDueDate = false;
  DateTime? _lmp;
  DateTime? _due;
  DateTime? _birth;
  var _cycleLength = 28;
  var _delivery = DeliveryType.natural;
  var _accepted = false;
  var _error = '';
  var _forward = true;

  static const _stepIcons = [
    Icons.favorite_rounded,
    Icons.spa_rounded,
    Icons.calendar_month_rounded,
    Icons.verified_user_rounded,
  ];

  static const _stepAccents = [
    HyaColors.rose,
    HyaColors.sage,
    HyaColors.gold,
    HyaColors.rose,
  ];

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat();
    _enter = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();
  }

  @override
  void dispose() {
    _babyName.dispose();
    _page.dispose();
    _pulse.dispose();
    _enter.dispose();
    super.dispose();
  }

  Future<void> _goTo(int step) async {
    _forward = step > _step;
    setState(() {
      _step = step;
      _error = '';
    });
    _enter
      ..reset()
      ..forward();
    await _page.animateToPage(
      step,
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = _stepAccents[_step];

    return HyaBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    if (_step > 0)
                      IconButton(
                        onPressed: () => _goTo(_step - 1),
                        icon: const Icon(Icons.arrow_back_rounded),
                      )
                    else
                      const SizedBox(width: 48),
                    Expanded(child: _ProgressDots(step: _step, total: 4, accent: accent)),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 6),
                AnimatedBuilder(
                  animation: Listenable.merge([_pulse, _enter]),
                  builder: (context, _) {
                    final appear = Curves.easeOutBack.transform(_enter.value.clamp(0.0, 1.0));
                    final beat = 1 + (0.5 - (0.5 - _pulse.value).abs()) * 0.05;
                    return Transform.translate(
                      offset: Offset((1 - appear.clamp(0.0, 1.0)) * (_forward ? 28 : -28), 0),
                      child: Opacity(
                        opacity: appear.clamp(0.0, 1.0),
                        child: Transform.scale(
                          scale: beat,
                          child: _step == 0
                              ? _BrandHero(pulse: _pulse.value, accent: accent)
                              : _HeroIcon(
                                  icon: _stepIcons[_step],
                                  accent: accent,
                                  pulse: _pulse.value,
                                ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: PageView(
                    controller: _page,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _WelcomeStep(enter: _enter),
                      _ModeStep(
                        mode: _mode,
                        enter: _enter,
                        onChanged: (mode) => setState(() => _mode = mode),
                      ),
                      _DetailsStep(
                        mode: _mode,
                        useDueDate: _useDueDate,
                        lmp: _lmp,
                        due: _due,
                        birth: _birth,
                        cycleLength: _cycleLength,
                        delivery: _delivery,
                        babyName: _babyName,
                        enter: _enter,
                        onUseDueDate: (value) => setState(() => _useDueDate = value),
                        onLmp: (value) => setState(() => _lmp = value),
                        onDue: (value) => setState(() => _due = value),
                        onBirth: (value) => setState(() => _birth = value),
                        onCycle: (value) => setState(() => _cycleLength = value),
                        onDelivery: (value) => setState(() => _delivery = value),
                      ),
                      _ConsentStep(
                        accepted: _accepted,
                        enter: _enter,
                        onChanged: (value) => setState(() => _accepted = value),
                      ),
                    ],
                  ),
                ),
                if (_error.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  HyaText(_error, size: 13, weight: 600, color: HyaColors.red, align: TextAlign.center),
                ],
                const SizedBox(height: 10),
                _NextButton(
                  label: _step == 3 ? 'كمّلي للحساب' : 'كمّلي',
                  accent: accent,
                  onTap: _next,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _next() async {
    final problem = _validate();
    if (problem != null) {
      HapticFeedback.lightImpact();
      setState(() => _error = problem);
      return;
    }
    if (_step < 3) {
      HapticFeedback.selectionClick();
      await _goTo(_step + 1);
      return;
    }

    final lmp = _mode == LifeMode.pregnant && _useDueDate && _due != null ? CycleMath.lmpFromDueDate(_due!) : _lmp;
    final due = _mode == LifeMode.pregnant
        ? (_useDueDate ? _due : (_lmp == null ? null : CycleMath.dueDateFromLmp(_lmp!)))
        : null;
    await StoreScope.of(context).finishOnboarding(
      OnboardingDraft(
        mode: _mode,
        lastPeriodDate: _mode == LifeMode.postpartum ? null : lmp,
        cycleLength: _cycleLength,
        expectedDueDate: due,
        babyName: _babyName.text.trim().isEmpty ? null : _babyName.text.trim(),
        babyBirthDate: _birth,
        deliveryType: _mode == LifeMode.postpartum ? _delivery : null,
      ),
    );
  }

  String? _validate() {
    if (_step == 2) {
      if (_mode == LifeMode.postpartum && _birth == null) return 'محتاجين تاريخ الولادة.';
      if (_mode == LifeMode.ttc && _lmp == null) return 'اختاري أول يوم في آخر دورة.';
      if (_mode == LifeMode.pregnant && _useDueDate && _due == null) return 'اختاري ميعاد الولادة.';
      if (_mode == LifeMode.pregnant && !_useDueDate && _lmp == null) return 'اختاري أول يوم في آخر دورة.';
    }
    if (_step == 3 && !_accepted) return 'محتاجين موافقتك على إن التطبيق مش بديل عن الطبيب.';
    return null;
  }
}

class _ProgressDots extends StatelessWidget {
  const _ProgressDots({required this.step, required this.total, required this.accent});

  final int step;
  final int total;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            width: i == step ? 26 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i <= step ? accent : HyaColors.line,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ],
      ],
    );
  }
}

class _BrandHero extends StatelessWidget {
  const _BrandHero({required this.pulse, required this.accent});

  final double pulse;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132,
      height: 132,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (final lag in [0.0, 0.45])
            Transform.scale(
              scale: 0.72 + ((pulse + lag) % 1) * 0.42,
              child: Opacity(
                opacity: (1 - ((pulse + lag) % 1)) * 0.28,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: accent, width: 1.5),
                  ),
                ),
              ),
            ),
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: accent.withValues(alpha: 0.28), blurRadius: 18, offset: const Offset(0, 8)),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/icon/app_icon.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroIcon extends StatelessWidget {
  const _HeroIcon({required this.icon, required this.accent, required this.pulse});

  final IconData icon;
  final Color accent;
  final double pulse;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 118,
      height: 118,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (final lag in [0.0, 0.45])
            Transform.scale(
              scale: 0.72 + ((pulse + lag) % 1) * 0.42,
              child: Opacity(
                opacity: (1 - ((pulse + lag) % 1)) * 0.28,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: accent, width: 1.5),
                  ),
                ),
              ),
            ),
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [accent, Color.lerp(accent, Colors.white, 0.28)!],
              ),
              boxShadow: [
                BoxShadow(color: accent.withValues(alpha: 0.28), blurRadius: 18, offset: const Offset(0, 8)),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 36),
          ),
        ],
      ),
    );
  }
}

class _StepShell extends StatelessWidget {
  const _StepShell({required this.enter, required this.child});

  final AnimationController enter;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: enter,
      builder: (context, _) {
        final t = Curves.easeOutCubic.transform(enter.value.clamp(0.0, 1.0));
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 18),
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 4, bottom: 12),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({required this.enter});

  final AnimationController enter;

  @override
  Widget build(BuildContext context) {
    return _StepShell(
      enter: enter,
      child: const Column(
        children: [
          SizedBox(height: 4),
          HyaText(
            'هي.. معكِ في كل نبضة.',
            align: TextAlign.center,
            size: 17,
            weight: 680,
            color: HyaColors.roseDeep,
          ),
          SizedBox(height: 14),
          HyaText(
            'رفيقة التخطيط للحمل، وشهور الحمل، وأول أيام الأمومة. الواجهة بتتغير حسب المرحلة اللي أنتِ فيها.',
            align: TextAlign.center,
            color: HyaColors.muted,
            height: 1.7,
          ),
          SizedBox(height: 22),
          _FeatureRow(icon: Icons.auto_awesome_rounded, text: 'رحلة أسبوع بأسبوع'),
          SizedBox(height: 10),
          _FeatureRow(icon: Icons.health_and_safety_rounded, text: 'دليلي للأكل والدوا'),
          SizedBox(height: 10),
          _FeatureRow(icon: Icons.forum_rounded, text: 'حكاوي وخرافات بهدوء'),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: HyaColors.line.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: HyaColors.blush, shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: HyaColors.roseDeep),
          ),
          const SizedBox(width: 10),
          HyaText(text, weight: 650),
        ],
      ),
    );
  }
}

class _ModeStep extends StatelessWidget {
  const _ModeStep({
    required this.mode,
    required this.enter,
    required this.onChanged,
  });

  final LifeMode mode;
  final AnimationController enter;
  final ValueChanged<LifeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return _StepShell(
      enter: enter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HyaText('أنتِ في أنهي مرحلة؟', size: 28, weight: 760),
          const SizedBox(height: 8),
          const HyaText(
            'تقدري تغيّري الاختيار بعد كده من الإعدادات، والتطبيق هيبدّل الشاشة الرئيسية.',
            color: HyaColors.muted,
          ),
          const SizedBox(height: 16),
          _ModeCard(
            icon: Icons.favorite_outline_rounded,
            title: 'بخطّط للحمل',
            body: 'نافذة خصوبة تقديرية، واستعداد قبل ما يحصل حمل.',
            color: HyaColors.sageSoft,
            accent: HyaColors.sage,
            selected: mode == LifeMode.ttc,
            onTap: () => onChanged(LifeMode.ttc),
          ),
          const SizedBox(height: 10),
          _ModeCard(
            icon: Icons.pregnant_woman_rounded,
            title: 'أنا حامل',
            body: 'أسبوع الحمل، رسالة البيبي، دليلي، وحقيبة المستشفى.',
            color: HyaColors.blush,
            accent: HyaColors.rose,
            selected: mode == LifeMode.pregnant,
            onTap: () => onChanged(LifeMode.pregnant),
          ),
          const SizedBox(height: 10),
          _ModeCard(
            icon: Icons.child_care_rounded,
            title: 'بعد الولادة',
            body: 'عمر البيبي، الرضاعة، تعافي الأم، وتذكير التطعيم.',
            color: HyaColors.goldSoft,
            accent: HyaColors.gold,
            selected: mode == LifeMode.postpartum,
            onTap: () => onChanged(LifeMode.postpartum),
          ),
        ],
      ),
    );
  }
}

class _DetailsStep extends StatelessWidget {
  const _DetailsStep({
    required this.mode,
    required this.useDueDate,
    required this.lmp,
    required this.due,
    required this.birth,
    required this.cycleLength,
    required this.delivery,
    required this.babyName,
    required this.enter,
    required this.onUseDueDate,
    required this.onLmp,
    required this.onDue,
    required this.onBirth,
    required this.onCycle,
    required this.onDelivery,
  });

  final LifeMode mode;
  final bool useDueDate;
  final DateTime? lmp;
  final DateTime? due;
  final DateTime? birth;
  final int cycleLength;
  final DeliveryType delivery;
  final TextEditingController babyName;
  final AnimationController enter;
  final ValueChanged<bool> onUseDueDate;
  final ValueChanged<DateTime> onLmp;
  final ValueChanged<DateTime> onDue;
  final ValueChanged<DateTime> onBirth;
  final ValueChanged<int> onCycle;
  final ValueChanged<DeliveryType> onDelivery;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return _StepShell(
      enter: enter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HyaText(
            switch (mode) {
              LifeMode.ttc => 'آخر دورة',
              LifeMode.pregnant => 'نحسب الحمل إزاي؟',
              LifeMode.postpartum => 'بيانات البيبي',
            },
            size: 28,
            weight: 760,
          ),
          const SizedBox(height: 8),
          HyaText(
            switch (mode) {
              LifeMode.ttc => 'الحساب تقريبي على دورة منتظمة. لو الدورة اتغيرت، حدّثي التاريخ بعدين.',
              LifeMode.pregnant => 'إمّا أول يوم في آخر دورة، أو ميعاد الولادة اللي قاله الطبيب.',
              LifeMode.postpartum => 'عشان نحسب العمر ونرتب تذكير التطعيم.',
            },
            color: HyaColors.muted,
          ),
          const SizedBox(height: 16),
          if (mode == LifeMode.pregnant) ...[
            Row(
              children: [
                HyaChip(label: 'آخر دورة', selected: !useDueDate, onTap: () => onUseDueDate(false)),
                const SizedBox(width: 8),
                HyaChip(label: 'ميعاد الولادة', selected: useDueDate, onTap: () => onUseDueDate(true)),
              ],
            ),
            const SizedBox(height: 14),
          ],
          if (mode != LifeMode.postpartum && !(mode == LifeMode.pregnant && useDueDate))
            _DateTile(
              label: 'أول يوم في آخر دورة',
              value: lmp == null ? 'اختاري التاريخ' : formatDate(lmp!),
              onTap: () async {
                final picked = await pickDate(
                  context,
                  initial: lmp ?? now.subtract(const Duration(days: 28)),
                  first: now.subtract(const Duration(days: 320)),
                  last: now,
                );
                if (picked != null) onLmp(dateOnly(picked));
              },
            ),
          if (mode == LifeMode.pregnant && useDueDate)
            _DateTile(
              label: 'ميعاد الولادة المتوقع',
              value: due == null ? 'اختاري التاريخ' : formatDate(due!),
              onTap: () async {
                final picked = await pickDate(
                  context,
                  initial: due ?? now.add(const Duration(days: 180)),
                  first: now.subtract(const Duration(days: 30)),
                  last: now.add(const Duration(days: 300)),
                );
                if (picked != null) onDue(dateOnly(picked));
              },
            ),
          if (mode != LifeMode.postpartum) ...[
            const SizedBox(height: 16),
            HyaText('طول الدورة: $cycleLength يوم', weight: 680),
            Slider(
              value: cycleLength.toDouble(),
              min: 21,
              max: 40,
              divisions: 19,
              activeColor: mode == LifeMode.ttc ? HyaColors.sage : HyaColors.rose,
              label: '$cycleLength',
              onChanged: (value) => onCycle(value.round()),
            ),
          ],
          if (mode == LifeMode.postpartum) ...[
            TextField(
              controller: babyName,
              decoration: const InputDecoration(
                hintText: 'اسم البيبي، لو اخترتوه',
                prefixIcon: Icon(Icons.child_care_rounded),
              ),
            ),
            const SizedBox(height: 12),
            _DateTile(
              label: 'تاريخ الولادة',
              value: birth == null ? 'اختاري التاريخ' : formatDate(birth!),
              onTap: () async {
                final picked = await pickDate(
                  context,
                  initial: birth ?? now,
                  first: DateTime(now.year - 3, now.month, now.day),
                  last: now,
                  accent: HyaColors.gold,
                );
                if (picked != null) onBirth(dateOnly(picked));
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                HyaChip(
                  label: 'طبيعي',
                  selected: delivery == DeliveryType.natural,
                  color: HyaColors.gold,
                  onTap: () => onDelivery(DeliveryType.natural),
                ),
                const SizedBox(width: 8),
                HyaChip(
                  label: 'قيصري',
                  selected: delivery == DeliveryType.cesarean,
                  color: HyaColors.gold,
                  onTap: () => onDelivery(DeliveryType.cesarean),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ConsentStep extends StatelessWidget {
  const _ConsentStep({
    required this.accepted,
    required this.enter,
    required this.onChanged,
  });

  final bool accepted;
  final AnimationController enter;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _StepShell(
      enter: enter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HyaText('قبل ما نبدأ', size: 28, weight: 760),
          const SizedBox(height: 12),
          const DisclaimerNote(
            text:
                'هي مساحة معرفة ودعم، مش طبيبة ومش صيدلية. أدوية الحمل، وأعراض زي النزيف أو قلة الحركة، ترجع لطبيب المتابعة أو الإسعاف. مصفاة الخرافات بتشرح الشائعات المعروفة، ومش بتشخّص حالتك.',
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            value: accepted,
            contentPadding: EdgeInsets.zero,
            activeColor: HyaColors.rose,
            onChanged: (value) => onChanged(value ?? false),
            title: const HyaText('فهمت إن التطبيق استرشادي، والقرار الطبي عند الطبيب.', size: 14.5, weight: 600),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
    );
  }
}

class _NextButton extends StatelessWidget {
  const _NextButton({required this.label, required this.accent, required this.onTap});

  final String label;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        onPressed: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label),
            const SizedBox(width: 8),
            const HyaForwardArrow(size: 15, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color color;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: selected ? accent : HyaColors.line.withValues(alpha: 0.5), width: selected ? 2 : 1),
        boxShadow: selected
            ? [BoxShadow(color: accent.withValues(alpha: 0.18), blurRadius: 16, offset: const Offset(0, 8))]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: accent.withValues(alpha: 0.16), shape: BoxShape.circle),
                  child: Icon(icon, color: accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HyaText(title, size: 17, weight: 740),
                      const SizedBox(height: 4),
                      HyaText(body, size: 13, color: HyaColors.muted, height: 1.4),
                    ],
                  ),
                ),
                Icon(
                  selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                  color: selected ? accent : HyaColors.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({required this.label, required this.value, required this.onTap});

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return HyaCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(color: HyaColors.blush, shape: BoxShape.circle),
            child: const Icon(Icons.calendar_month_rounded, color: HyaColors.roseDeep),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HyaText(label, size: 12.5, weight: 600, color: HyaColors.muted),
                const SizedBox(height: 2),
                HyaText(value, size: 16, weight: 680),
              ],
            ),
          ),
          const HyaTrailingChevron(),
        ],
      ),
    );
  }
}
