import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../widgets/ui.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late final AnimationController _enter;
  late final AnimationController _beat;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(vsync: this, duration: const Duration(milliseconds: 420))..forward();
    _beat = AnimationController(vsync: this, duration: const Duration(milliseconds: 1480))..repeat();
  }

  @override
  void dispose() {
    _enter.dispose();
    _beat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enter = CurvedAnimation(parent: _enter, curve: Curves.easeOutCubic);
    final slogan = CurvedAnimation(parent: _enter, curve: const Interval(0.2, 1, curve: Curves.easeOut));

    return HyaBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 280,
                  height: 250,
                  child: AnimatedBuilder(
                    animation: Listenable.merge([enter, _beat]),
                    builder: (context, child) {
                      final arrive = Tween<double>(begin: 0.94, end: 1).transform(enter.value);
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(280, 250),
                            painter: _PulsePainter(t: _beat.value, alpha: enter.value),
                          ),
                          Transform.scale(scale: arrive * _beatScale(_beat.value), child: child),
                        ],
                      );
                    },
                    child: const _AppIcon(),
                  ),
                ),
                const SizedBox(height: 6),
                FadeTransition(
                  opacity: slogan,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0, 0.35), end: Offset.zero).animate(slogan),
                    child: const HyaText(
                      'هي.. معكِ في كل نبضة.',
                      size: 22,
                      weight: 720,
                      color: HyaColors.roseDeep,
                      align: TextAlign.center,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }

  double _beatScale(double t) {
    return 1 + _pulse(t, 0.02, 0.22, 0.055) + _pulse(t, 0.30, 0.18, 0.032);
  }

  double _pulse(double t, double start, double width, double amount) {
    if (t < start || t > start + width) return 0;
    final x = (t - start) / width;
    return math.sin(x * math.pi) * amount;
  }
}

class _AppIcon extends StatelessWidget {
  const _AppIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 156,
      height: 156,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: HyaColors.rose.withValues(alpha: 0.28), blurRadius: 28, offset: const Offset(0, 16)),
        ],
      ),
      child: const ClipOval(
        child: Image(image: AssetImage('assets/icon/app_icon.png'), fit: BoxFit.cover),
      ),
    );
  }
}

class _PulsePainter extends CustomPainter {
  const _PulsePainter({required this.t, required this.alpha});

  final double t;
  final double alpha;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    for (var i = 0; i < 2; i++) {
      final progress = (t + i * 0.5) % 1;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..color = HyaColors.rose.withValues(alpha: (1 - progress) * 0.42 * alpha);
      canvas.drawCircle(center, 86 + progress * 56, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PulsePainter oldDelegate) {
    return oldDelegate.t != t || oldDelegate.alpha != alpha;
  }
}
