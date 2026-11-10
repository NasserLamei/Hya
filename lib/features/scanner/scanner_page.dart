import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/scan_match.dart';
import '../../core/theme.dart';
import '../../data/guides.dart';
import '../../data/scan_catalog.dart';
import '../../widgets/ui.dart';
import 'label_reader.dart';

void openScanner(BuildContext context) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ScannerPage()));
}

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> with TickerProviderStateMixin {
  final _picker = ImagePicker();
  final _name = TextEditingController();
  late final AnimationController _scan;
  late final AnimationController _reveal;
  late final AnimationController _pulse;

  XFile? _photo;
  ScanVerdict? _verdict;
  String _read = '';
  var _busy = false;
  var _food = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scan = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
    _reveal = AnimationController(vsync: this, duration: const Duration(milliseconds: 820));
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1700))..repeat();
  }

  @override
  void dispose() {
    _scan.dispose();
    _reveal.dispose();
    _pulse.dispose();
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final level = _verdict?.primary?.item.level;
    final wash = _verdict == null
        ? HyaColors.ivory
        : switch (level) {
            SafetyLevel.green => HyaColors.greenSoft,
            SafetyLevel.amber => HyaColors.amberSoft,
            SafetyLevel.red => HyaColors.redSoft,
            null => HyaColors.amberSoft,
          };
    final suggestions = _food ? foodSuggestions : medicineSuggestions;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      color: wash.withValues(alpha: 0.42),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          title: const HyaText('الأكل والدوا', weight: 720, size: 18),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: _KindTabs(
                food: _food,
                onPick: (food) {
                  if (food == _food) return;
                  setState(() => _food = food);
                  final text = _read.trim().isNotEmpty ? _read : _name.text;
                  if (_verdict != null && text.trim().length >= 2) {
                    _present(text, lockTab: true);
                  }
                },
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                children: [
                  TextField(
                    controller: _name,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: _food ? 'اكتبي الأكل، زي كبدة أو مانجا' : 'اكتبي الدواء، زي بنادول أو بروفين',
                    ),
                    onSubmitted: _judgeTyped,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _busy ? null : () => _judgeTyped(_name.text),
                          icon: const Icon(Icons.search_rounded),
                          label: const Text('افحصي'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _busy ? null : () => _capture(ImageSource.camera),
                          icon: const Icon(Icons.photo_camera_rounded),
                          label: const Text('الكاميرا'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.center,
                    child: TextButton(
                      onPressed: _busy ? null : () => _capture(ImageSource.gallery),
                      child: const Text('أو من الألبوم'),
                    ),
                  ),
                  if (_photo != null) ...[
                    const SizedBox(height: 4),
                    _photoCard(),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    HyaText(_error!, size: 13, weight: 650, color: HyaColors.red),
                  ],
                  if (_busy) ...[
                    const SizedBox(height: 12),
                    const _ReadingLine(),
                  ],
                  if (_verdict != null && !_busy) ...[
                    const SizedBox(height: 8),
                    _result(_verdict!),
                  ],
                  const SizedBox(height: 8),
                  HyaText(_food ? 'أكل بيتسأل عليه كتير' : 'أدوية بيتسأل عليها كتير', size: 13, weight: 700, color: HyaColors.muted),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final name in suggestions)
                        ActionChip(
                          label: Text(name),
                          onPressed: _busy ? null : () => _judgeTyped(name),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const DisclaimerNote(
                    text: 'النتيجة من دليل هي، مش من تشخيص صورة. مش إذن تاخدي الدواء، والجرعة والقرار عند الطبيب أو الصيدلي.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        height: 168,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(File(_photo!.path), fit: BoxFit.cover),
            if (_busy)
              AnimatedBuilder(
                animation: _scan,
                builder: (context, _) {
                  return CustomPaint(painter: _ScanPainter(t: _scan.value));
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _result(ScanVerdict verdict) {
    final item = verdict.primary?.item;
    if (item == null) return _unknown();

    final tone = _tone(item.level);
    return Column(
      children: [
        SizedBox(
          height: 150,
          child: AnimatedBuilder(
            animation: Listenable.merge([_reveal, _pulse]),
            builder: (context, child) {
              final scale = Tween<double>(begin: 0.55, end: 1).transform(Curves.elasticOut.transform(_reveal.value));
              return Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(220, 150),
                    painter: _BurstPainter(t: _pulse.value, color: tone.color, alpha: _reveal.value),
                  ),
                  Transform.scale(scale: scale, child: child),
                ],
              );
            },
            child: Container(
              width: 92,
              height: 92,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tone.color,
                boxShadow: [BoxShadow(color: tone.color.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 10))],
              ),
              child: Icon(tone.icon, color: Colors.white, size: 44),
            ),
          ),
        ),
        FadeTransition(
          opacity: CurvedAnimation(parent: _reveal, curve: Curves.easeOut),
          child: Column(
            children: [
              HyaText(tone.title, size: 30, weight: 780, height: 1.1, color: tone.color),
              const SizedBox(height: 6),
              HyaText(item.name, size: 18, weight: 700, align: TextAlign.center),
              const SizedBox(height: 4),
              HyaText('${kindLabel(item.kind)} · ${levelLabel(item.level)}', size: 13, color: HyaColors.muted),
              const SizedBox(height: 12),
              HyaCard(
                color: Colors.white,
                child: HyaText(item.note, height: 1.65),
              ),
              if (verdict.also.isNotEmpty) ...[
                const SizedBox(height: 10),
                for (final extra in verdict.also)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: HyaText(
                      'كمان ظاهر: ${extra.item.name} · ${_tone(extra.item.level).title}',
                      size: 13,
                      color: HyaColors.muted,
                      align: TextAlign.center,
                    ),
                  ),
              ],
              if (_read.trim().isNotEmpty && _photo != null) ...[
                const SizedBox(height: 6),
                HyaText('اتقرأ: ${_flat(_read)}', size: 12, color: HyaColors.muted, align: TextAlign.center, maxLines: 2),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _unknown() {
    return HyaCard(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.help_outline_rounded, color: HyaColors.amber),
              SizedBox(width: 8),
              HyaText('محتاجة تأكيد', weight: 760, size: 18, color: HyaColors.amber),
            ],
          ),
          const SizedBox(height: 8),
          HyaText(
            _food
                ? 'الاسم مش في الدليل. الاتجاه الأأمن: أكل مستوي ومتغسل، من غير كحول أو نيء أو كبدة. لو العلبة مش مكتوب عليها مبستر، سيبيها لحد ما تتأكدي.'
                : 'الاسم مش في الدليل. متبدئيش دواء في الحمل من غير الطبيب أو الصيدلي، حتى لو كنتي بتاخديه قبل كده أو حد قالكِ إنه عادي.',
            height: 1.6,
          ),
        ],
      ),
    );
  }

  Future<void> _capture(ImageSource source) async {
    setState(() => _error = null);
    try {
      final shot = await _picker.pickImage(source: source, imageQuality: 75, maxWidth: 1600);
      if (shot == null || !mounted) return;
      setState(() {
        _photo = shot;
        _busy = true;
        _verdict = null;
        _read = '';
      });
      _reveal.value = 0;
      final text = await readProductPhoto(shot.path);
      if (!mounted) return;
      _name.text = _flat(text);
      _present(text);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = source == ImageSource.camera
            ? 'الكاميرا مش متاحة هنا. جرّبي من الألبوم، أو اكتبي الاسم.'
            : 'ما قدرتش أفتح الصورة. اكتبي الاسم فوق.';
      });
    }
  }

  void _judgeTyped(String value) {
    final text = value.trim();
    if (text.length < 2) return;
    _name.value = TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
    _present(text);
  }

  void _present(String text, {bool lockTab = false}) {
    var food = _food;
    var verdict = judgeText(text, kinds: food ? foodScanKinds : medicineScanKinds);
    if (!verdict.found && !lockTab) {
      final otherFood = !food;
      final other = judgeText(text, kinds: otherFood ? foodScanKinds : medicineScanKinds);
      if (other.found) {
        food = otherFood;
        verdict = other;
      }
    }
    setState(() {
      _food = food;
      _verdict = verdict;
      _read = text;
      _busy = false;
      _error = null;
    });
    _reveal.forward(from: 0);
    final level = verdict.primary?.item.level;
    if (level == SafetyLevel.red) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  String _flat(String text) {
    final flat = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (flat.length <= 90) return flat;
    return '${flat.substring(0, 90)}…';
  }
}

class _KindTabs extends StatelessWidget {
  const _KindTabs({required this.food, required this.onPick});

  final bool food;
  final ValueChanged<bool> onPick;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: HyaColors.line),
      ),
      child: Row(
        children: [
          _segment('الأكل', Icons.restaurant_rounded, food, () => onPick(true)),
          _segment('الأدوية', Icons.medication_rounded, !food, () => onPick(false)),
        ],
      ),
    );
  }

  Widget _segment(String label, IconData icon, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? HyaColors.rose : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: selected ? Colors.white : HyaColors.roseDeep),
              const SizedBox(width: 6),
              HyaText(label, weight: 740, color: selected ? Colors.white : HyaColors.roseDeep),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tone {
  const _Tone(this.color, this.icon, this.title);

  final Color color;
  final IconData icon;
  final String title;
}

_Tone _tone(SafetyLevel level) {
  return switch (level) {
    SafetyLevel.green => const _Tone(HyaColors.green, Icons.check_rounded, 'مسموح'),
    SafetyLevel.amber => const _Tone(HyaColors.amber, Icons.priority_high_rounded, 'بحذر'),
    SafetyLevel.red => const _Tone(HyaColors.red, Icons.close_rounded, 'ممنوع'),
  };
}

class _ReadingLine extends StatelessWidget {
  const _ReadingLine();

  @override
  Widget build(BuildContext context) {
    return const HyaText('بقرأ الاسم على الصورة...', align: TextAlign.center, weight: 700, color: HyaColors.roseDeep);
  }
}

class _ScanPainter extends CustomPainter {
  const _ScanPainter({required this.t});

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * t;
    final shade = Paint()..color = const Color(0x55C56B76);
    canvas.drawRect(Rect.fromLTWH(0, y - 18, size.width, 36), shade);
    final line = Paint()
      ..color = const Color(0xFFFFF7F4)
      ..strokeWidth = 3;
    canvas.drawLine(Offset(16, y), Offset(size.width - 16, y), line);
  }

  @override
  bool shouldRepaint(covariant _ScanPainter oldDelegate) => oldDelegate.t != t;
}

class _BurstPainter extends CustomPainter {
  const _BurstPainter({required this.t, required this.color, required this.alpha});

  final double t;
  final Color color;
  final double alpha;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    for (var i = 0; i < 3; i++) {
      final progress = (t + i * 0.22) % 1;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = color.withValues(alpha: (1 - progress) * 0.55 * alpha);
      canvas.drawCircle(center, 36 + progress * 78, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter oldDelegate) {
    return oldDelegate.t != t || oldDelegate.alpha != alpha || oldDelegate.color != color;
  }
}
