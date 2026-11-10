import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';

class HyaText extends StatelessWidget {
  const HyaText(
    this.data, {
    super.key,
    this.size = 15,
    this.weight = 450,
    this.color = HyaColors.ink,
    this.height = 1.45,
    this.align,
    this.maxLines,
  });

  final String data;
  final double size;
  final double weight;
  final Color color;
  final double height;
  final TextAlign? align;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return Text(
      data,
      textAlign: align,
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
      style: HyaType.style(size: size, weight: weight, color: color, height: height),
    );
  }
}

class HyaBackground extends StatelessWidget {
  const HyaBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Opaque wallpaper so a pushed route never flashes the previous screen
    // through a transparent scaffold during the page transition.
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFFFFF4F6)),
        const Image(
          image: AssetImage('assets/art/hya_background.jpg'),
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
        child,
      ],
    );
  }
}

class HyaCard extends StatelessWidget {
  const HyaCard({
    super.key,
    required this.child,
    this.color = HyaColors.card,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
  });

  final Widget child;
  final Color color;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: HyaColors.line.withValues(alpha: 0.7)),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: card,
      ),
    );
  }
}

/// سهم التقدّم في واجهة عربية (RTL): دايمًا ناحية الشمال.
class HyaForwardArrow extends StatelessWidget {
  const HyaForwardArrow({super.key, this.size = 16, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.arrow_forward_ios_rounded,
      size: size,
      color: color,
      textDirection: TextDirection.rtl,
    );
  }
}

/// شيفرون فتح الصفوف في الواجهة العربية.
class HyaTrailingChevron extends StatelessWidget {
  const HyaTrailingChevron({super.key, this.size = 22, this.color = HyaColors.muted});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.chevron_left_rounded, size: size, color: color);
  }
}

class HyaMark extends StatelessWidget {
  const HyaMark({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFFE8B7B4), HyaColors.rose],
        ),
      ),
      child: Text('هي', style: HyaType.style(size: size * 0.38, weight: 700, color: Colors.white, height: 1)),
    );
  }
}

/// لودر بهوية هي: أيقونة + نبض وردي زي السبلاش.
class HyaLoader extends StatefulWidget {
  const HyaLoader({
    super.key,
    this.size = 56,
    this.label,
    this.color = HyaColors.rose,
  });

  final double size;
  final String? label;
  final Color color;

  @override
  State<HyaLoader> createState() => _HyaLoaderState();
}

class _HyaLoaderState extends State<HyaLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _beat;

  @override
  void initState() {
    super.initState();
    _beat = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
  }

  @override
  void dispose() {
    _beat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconSize = widget.size * 0.62;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size * 1.55,
          height: widget.size * 1.55,
          child: AnimatedBuilder(
            animation: _beat,
            builder: (context, child) {
              final t = _beat.value;
              final scale = 1 + _pulse(t, 0.02, 0.22, 0.05) + _pulse(t, 0.30, 0.18, 0.03);
              return Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: Size(widget.size * 1.55, widget.size * 1.55),
                    painter: _HyaLoaderPulsePainter(t: t, color: widget.color),
                  ),
                  Transform.scale(scale: scale, child: child),
                ],
              );
            },
            child: Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.22),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const ClipOval(
                child: Image(
                  image: AssetImage('assets/icon/app_icon.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
        if (widget.label != null) ...[
          const SizedBox(height: 6),
          HyaText(
            widget.label!,
            size: 13,
            weight: 650,
            color: HyaColors.muted,
            align: TextAlign.center,
          ),
        ],
      ],
    );
  }

  double _pulse(double t, double start, double width, double amount) {
    if (t < start || t > start + width) return 0;
    final x = (t - start) / width;
    return math.sin(x * math.pi) * amount;
  }
}

class _HyaLoaderPulsePainter extends CustomPainter {
  const _HyaLoaderPulsePainter({required this.t, required this.color});

  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final base = size.shortestSide * 0.28;
    for (var i = 0; i < 2; i++) {
      final progress = (t + i * 0.5) % 1;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = color.withValues(alpha: (1 - progress) * 0.4);
      canvas.drawCircle(center, base + progress * (size.shortestSide * 0.22), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _HyaLoaderPulsePainter oldDelegate) {
    return oldDelegate.t != t || oldDelegate.color != color;
  }
}

/// لودر صغير جوّه الأزرار بدل نص «لحظة...».
class HyaButtonLoader extends StatelessWidget {
  const HyaButtonLoader({super.key, this.color = Colors.white});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CircularProgressIndicator(
        strokeWidth: 2.2,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}

/// طبقة تحميل فوق الشاشة بنفس هوية هي.
class HyaLoadingOverlay extends StatelessWidget {
  const HyaLoadingOverlay({super.key, this.label = 'لحظة...'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFFFF4F6).withValues(alpha: 0.72),
      child: Center(
        child: HyaLoader(size: 72, label: label),
      ),
    );
  }
}

class WeekRing extends StatelessWidget {
  const WeekRing({
    super.key,
    required this.progress,
    required this.color,
    required this.child,
  });

  final double progress;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 168,
      height: 168,
      child: CustomPaint(
        painter: _RingPainter(progress: progress.clamp(0, 1), color: color),
        child: Center(child: child),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = 12.0;
    final rect = Offset.zero & size;
    final inset = rect.deflate(stroke);
    final base = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final value = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(inset, 0, 6.28318, false, base);
    canvas.drawArc(inset, -1.5708, 6.28318 * progress, false, value);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class HyaChip extends StatelessWidget {
  const HyaChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.color = HyaColors.rose,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color : Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: selected ? color : HyaColors.line),
          ),
          child: HyaText(
            label,
            size: 13.5,
            weight: 620,
            color: selected ? Colors.white : HyaColors.ink,
          ),
        ),
      ),
    );
  }
}

class DisclaimerNote extends StatelessWidget {
  const DisclaimerNote({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HyaColors.goldSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: HyaText(text, size: 12.5, weight: 450, color: HyaColors.goldDeep, height: 1.5),
    );
  }
}

class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.kicker,
    required this.title,
    this.trailing,
  });

  final String kicker;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HyaText(kicker, size: 13, weight: 600, color: HyaColors.muted),
              const SizedBox(height: 2),
              HyaText(title, size: 28, weight: 720, height: 1.25),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// زرار الكاميرا مع أنيميشن فوكس/فلاش فوقه.
class HyaCameraButton extends StatefulWidget {
  const HyaCameraButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<HyaCameraButton> createState() => _HyaCameraButtonState();
}

class _HyaCameraButtonState extends State<HyaCameraButton> with TickerProviderStateMixin {
  late final AnimationController _focus;
  late final AnimationController _shutter;

  @override
  void initState() {
    super.initState();
    _focus = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat();
    _shutter = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200))..repeat();
  }

  @override
  void dispose() {
    _focus.dispose();
    _shutter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          AnimatedBuilder(
            animation: _focus,
            builder: (context, _) {
              final t = _focus.value;
              return CustomPaint(
                size: const Size(48, 48),
                painter: _CameraFocusPainter(t: t),
              );
            },
          ),
          AnimatedBuilder(
            animation: Listenable.merge([_focus, _shutter]),
            builder: (context, child) {
              final flash = _shutterFlash(_shutter.value);
              return Stack(
                alignment: Alignment.center,
                children: [
                  if (flash > 0)
                    Opacity(
                      opacity: flash,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.85),
                          boxShadow: [
                            BoxShadow(
                              color: HyaColors.rose.withValues(alpha: 0.35 * flash),
                              blurRadius: 14,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  Transform.scale(
                    scale: 1 + (_focusPulse(_focus.value) * 0.06),
                    child: child,
                  ),
                ],
              );
            },
            child: IconButton(
              onPressed: widget.onPressed,
              tooltip: 'صوّري الأكل أو الدواء',
              icon: const Icon(Icons.photo_camera_rounded, color: HyaColors.roseDeep),
            ),
          ),
        ],
      ),
    );
  }

  double _focusPulse(double t) {
    final x = (t % 1);
    return (0.5 - (0.5 - x).abs()) * 2;
  }

  double _shutterFlash(double t) {
    // فلاش سريع كل دورة
    if (t > 0.72 && t < 0.82) {
      final x = (t - 0.72) / 0.1;
      return (1 - (2 * x - 1).abs()).clamp(0.0, 1.0);
    }
    return 0;
  }
}

class _CameraFocusPainter extends CustomPainter {
  const _CameraFocusPainter({required this.t});

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    for (var i = 0; i < 2; i++) {
      final progress = (t + i * 0.5) % 1;
      final radius = 12 + progress * 14;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = HyaColors.rose.withValues(alpha: (1 - progress) * 0.45);
      canvas.drawCircle(center, radius, paint);

      // زوايا فوكس الكاميرا
      final cornerPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = HyaColors.roseDeep.withValues(alpha: (1 - progress) * 0.55);
      final r = radius * 0.72;
      const tick = 5.0;
      // top-right
      canvas.drawLine(center + Offset(r, -r), center + Offset(r - tick, -r), cornerPaint);
      canvas.drawLine(center + Offset(r, -r), center + Offset(r, -r + tick), cornerPaint);
      // top-left
      canvas.drawLine(center + Offset(-r, -r), center + Offset(-r + tick, -r), cornerPaint);
      canvas.drawLine(center + Offset(-r, -r), center + Offset(-r, -r + tick), cornerPaint);
      // bottom-right
      canvas.drawLine(center + Offset(r, r), center + Offset(r - tick, r), cornerPaint);
      canvas.drawLine(center + Offset(r, r), center + Offset(r, r - tick), cornerPaint);
      // bottom-left
      canvas.drawLine(center + Offset(-r, r), center + Offset(-r + tick, r), cornerPaint);
      canvas.drawLine(center + Offset(-r, r), center + Offset(-r, r - tick), cornerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CameraFocusPainter oldDelegate) => oldDelegate.t != t;
}

/// تحية الصفحة الرئيسية: مثل «صباح الخير يا ناصر» — مضغوطة ومحاذاة مع أزرار الكاميرا.
class HomeGreeting extends StatefulWidget {
  const HomeGreeting({
    super.key,
    required this.greeting,
    required this.name,
    this.trailing,
  });

  final String greeting;
  final String name;
  final Widget? trailing;

  @override
  State<HomeGreeting> createState() => _HomeGreetingState();
}

class _HomeGreetingState extends State<HomeGreeting> with TickerProviderStateMixin {
  late final AnimationController _enter;
  late final AnimationController _beat;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();
    _beat = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat();
  }

  @override
  void dispose() {
    _enter.dispose();
    _beat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMorning = widget.greeting.contains('صباح');
    final cleanName = widget.name.trim().isEmpty ? 'ماما' : widget.name.trim();
    final line = '${widget.greeting} يا $cleanName';
    final accent = isMorning ? HyaColors.goldDeep : HyaColors.roseDeep;
    final soft = isMorning ? HyaColors.goldSoft : const Color(0xFFF3E6EC);
    final appear = CurvedAnimation(parent: _enter, curve: Curves.easeOutBack);

    // التحية يمين (في RTL)، والأيقونات شمال — من غير overflow.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Align(
                alignment: AlignmentDirectional.centerStart,
                child: FadeTransition(
                  opacity: CurvedAnimation(parent: _enter, curve: Curves.easeOut),
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0.12, 0), end: Offset.zero).animate(
                      CurvedAnimation(parent: _enter, curve: Curves.easeOutCubic),
                    ),
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.94, end: 1).animate(appear),
                      child: AnimatedBuilder(
                        animation: _beat,
                        builder: (context, child) {
                          final t = _beat.value;
                          final heart = 1 + (0.5 - (0.5 - t).abs()) * 0.18;
                          return ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: soft,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: accent.withValues(alpha: 0.14)),
                                boxShadow: [
                                  BoxShadow(
                                    color: accent.withValues(alpha: 0.08 + (heart - 1) * 0.2),
                                    blurRadius: 8 + (heart - 1) * 12,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isMorning ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded,
                                    size: 16,
                                    color: accent,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: HyaText(
                                      line,
                                      size: 14.5,
                                      weight: 740,
                                      height: 1.25,
                                      color: HyaColors.ink,
                                      maxLines: 2,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: Center(
                                      child: Transform.scale(
                                        scale: heart,
                                        child: const Icon(Icons.favorite_rounded, size: 14, color: HyaColors.rose),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.trailing != null) widget.trailing!,
      ],
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return HyaText(text, size: 16, weight: 700);
  }
}

/// Empty state موحّد بهوية هي: صورة + عنوان + تفاصيل.
class HyaEmptyView extends StatelessWidget {
  const HyaEmptyView({
    super.key,
    required this.title,
    required this.body,
    this.icon = Icons.favorite_rounded,
  });

  final String title;
  final String body;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return HyaCard(
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 26),
      child: Column(
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: HyaColors.rose.withValues(alpha: 0.22),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const ClipOval(
              child: Image(
                image: AssetImage('assets/icon/app_icon.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Icon(icon, color: HyaColors.rose, size: 22),
          const SizedBox(height: 10),
          HyaText(title, size: 18, weight: 760, align: TextAlign.center),
          const SizedBox(height: 8),
          HyaText(
            body,
            size: 13.5,
            color: HyaColors.muted,
            align: TextAlign.center,
            height: 1.55,
          ),
        ],
      ),
    );
  }
}

class HyaNavBar extends StatelessWidget {
  const HyaNavBar({
    super.key,
    required this.index,
    required this.items,
    required this.accent,
    required this.onChanged,
  });

  final int index;
  final List<(IconData, String)> items;
  final Color accent;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(8, 8, 8, bottom + 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: HyaColors.line)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++)
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => onChanged(i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(items[i].$1, size: 22, color: i == index ? accent : HyaColors.muted),
                      const SizedBox(height: 2),
                      HyaText(
                        items[i].$2,
                        size: 11,
                        weight: i == index ? 700 : 500,
                        color: i == index ? accent : HyaColors.muted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class SoftPage extends StatelessWidget {
  const SoftPage({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: children,
      ),
    );
  }
}

Future<DateTime?> pickDate(
  BuildContext context, {
  required DateTime initial,
  required DateTime first,
  required DateTime last,
  Color accent = HyaColors.rose,
}) {
  final clamped = initial.isBefore(first) ? first : (initial.isAfter(last) ? last : initial);
  return showDatePicker(
    context: context,
    initialDate: clamped,
    firstDate: first,
    lastDate: last,
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(primary: accent, onPrimary: Colors.white),
        ),
        child: child ?? const SizedBox.shrink(),
      );
    },
  );
}
