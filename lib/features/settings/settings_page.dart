import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../app.dart';
import '../../core/cycle_math.dart';
import '../../core/format.dart';
import '../../core/models.dart';
import '../../core/remote.dart';
import '../../core/theme.dart';
import '../../widgets/ui.dart';
import '../auth/auth_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final profile = store.profile;
    if (profile == null) return const Scaffold(body: SizedBox.shrink());

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: const HyaText('الإعدادات', weight: 720, size: 18),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          HyaText(profile.name, size: 28, weight: 760),
          const SizedBox(height: 4),
          HyaText(_modeLabel(profile.mode), color: HyaColors.muted, weight: 650),
          const SizedBox(height: 16),
          _Tile(
            title: 'تعديل البيانات',
            body: 'الاسم، التواريخ، وطول الدورة',
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditProfilePage()));
            },
          ),
          const SizedBox(height: 8),
          _Tile(
            title: 'تغيير المرحلة',
            body: 'تخطيط، حمل، أو بعد الولادة. الشاشة الرئيسية بتتبدل.',
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ShiftModePage()));
            },
          ),
          const SizedBox(height: 8),
          _Tile(
            title: 'الحساب',
            body: store.signedIn ? (store.accountEmail ?? 'متصلة') : 'حساب جديد أو تسجيل دخول',
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AccountPage()));
            },
          ),
          if (store.signedIn) ...[
            const SizedBox(height: 8),
            _Tile(
              title: 'خروج من الحساب',
              body: 'هترجعي لشاشة الدخول. بيانات الرحلة المحلية بتفضل لحد ما تدخلي تاني.',
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const HyaText('تخرجي من الحساب؟', size: 18, weight: 740),
                    content: const HyaText('هترجعي لشاشة تسجيل الدخول.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('رجوع')),
                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('أخرجي')),
                    ],
                  ),
                );
                if (confirmed == true && context.mounted) {
                  await store.signOut();
                }
              },
            ),
          ],
          if (store.syncNote != null) ...[
            const SizedBox(height: 10),
            DisclaimerNote(text: store.syncNote!),
          ],
          const SizedBox(height: 16),
          const DisclaimerNote(
            text: 'هي مش جهاز طبي. دليل الأدوية ومصطلحات السونار ومصفاة الخرافات معرفة عامة، وأي قرار يخص جسمك أو البيبي يرجع للطبيب.',
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const HyaText('مسح البيانات من الموبايل؟', size: 18, weight: 740),
                  content: const HyaText('هيبدأ التطبيق من الأول على الجهاز ده. النسخة السحابية، لو فيه حساب، مش بتتمسح من هنا.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('رجوع')),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('امسحي')),
                  ],
                ),
              );
              if (confirmed == true && context.mounted) {
                await store.clearAll();
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('ابدئي من الأول على الجهاز'),
          ),
        ],
      ),
    );
  }

  String _modeLabel(LifeMode mode) {
    return switch (mode) {
      LifeMode.ttc => 'بتخططي للحمل',
      LifeMode.pregnant => 'حامل',
      LifeMode.postpartum => 'بعد الولادة',
    };
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.title, required this.body, required this.onTap});

  final String title;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return HyaCard(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HyaText(title, weight: 720),
                const SizedBox(height: 4),
                HyaText(body, size: 13, color: HyaColors.muted),
              ],
            ),
          ),
          const HyaTrailingChevron(),
        ],
      ),
    );
  }
}

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final TextEditingController _name;
  late final TextEditingController _baby;
  late final TextEditingController _age;
  var _ready = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    final profile = StoreScope.of(context).profile!;
    _name = TextEditingController(text: profile.name);
    _baby = TextEditingController(text: profile.babyName ?? '');
    _age = TextEditingController(text: profile.motherAge?.toString() ?? '');
    _ready = true;
  }

  @override
  void dispose() {
    if (_ready) {
      _name.dispose();
      _baby.dispose();
      _age.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const SizedBox.shrink();
    final store = StoreScope.of(context);
    final profile = store.profile!;
    final now = DateTime.now();
    final photo = profile.photoPath;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: const HyaText('بياناتك', weight: 720, size: 18),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Center(
            child: GestureDetector(
              onTap: () async {
                final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 72);
                if (picked == null) return;
                await store.saveProfile(profile.copyWith(photoPath: picked.path));
              },
              child: CircleAvatar(
                radius: 42,
                backgroundColor: HyaColors.blush,
                backgroundImage: photo != null && File(photo).existsSync() ? FileImage(File(photo)) : null,
                child: photo == null || !File(photo).existsSync()
                    ? const Icon(Icons.add_a_photo_rounded, color: HyaColors.roseDeep)
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 6),
          const HyaText('الصورة اختيارية', align: TextAlign.center, size: 12.5, color: HyaColors.muted),
          const SizedBox(height: 14),
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'الاسم')),
          const SizedBox(height: 12),
          TextField(
            controller: _age,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'سن الحامل'),
          ),
          const SizedBox(height: 12),
          if (profile.mode != LifeMode.postpartum)
            _DateRow(
              label: 'آخر دورة',
              value: profile.lastPeriodDate == null ? 'غير محدد' : formatDate(profile.lastPeriodDate!),
              onTap: () async {
                final picked = await pickDate(
                  context,
                  initial: profile.lastPeriodDate ?? now.subtract(const Duration(days: 28)),
                  first: now.subtract(const Duration(days: 400)),
                  last: now,
                );
                if (picked == null) return;
                final due = profile.mode == LifeMode.pregnant ? CycleMath.dueDateFromLmp(picked) : profile.expectedDueDate;
                await store.saveProfile(profile.copyWith(lastPeriodDate: dateOnly(picked), expectedDueDate: due));
              },
            ),
          if (profile.mode == LifeMode.pregnant && profile.expectedDueDate != null) ...[
            const SizedBox(height: 8),
            HyaText('الميعاد المتوقع ${formatDate(profile.expectedDueDate!)}', color: HyaColors.muted),
          ],
          if (profile.mode != LifeMode.postpartum) ...[
            const SizedBox(height: 8),
            HyaText('طول الدورة: ${profile.cycleLength} يوم', weight: 680),
            Slider(
              value: profile.cycleLength.toDouble(),
              min: 21,
              max: 40,
              divisions: 19,
              activeColor: HyaColors.rose,
              onChanged: (value) => store.saveProfile(profile.copyWith(cycleLength: value.round())),
            ),
          ],
          if (profile.mode == LifeMode.postpartum) ...[
            TextField(controller: _baby, decoration: const InputDecoration(labelText: 'اسم البيبي')),
            const SizedBox(height: 12),
            _DateRow(
              label: 'تاريخ الولادة',
              value: profile.babyBirthDate == null ? 'غير محدد' : formatDate(profile.babyBirthDate!),
              onTap: () async {
                final picked = await pickDate(
                  context,
                  initial: profile.babyBirthDate ?? now,
                  first: DateTime(now.year - 3),
                  last: now,
                  accent: HyaColors.gold,
                );
                if (picked != null) {
                  await store.saveProfile(profile.copyWith(babyBirthDate: dateOnly(picked)));
                }
              },
            ),
          ],
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () async {
              final age = int.tryParse(_age.text.trim());
              if (age != null && (age < 14 || age > 60)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('السن لازم بين ١٤ و ٦٠')),
                );
                return;
              }
              await store.saveProfile(
                profile.copyWith(
                  name: _name.text.trim().isEmpty ? profile.name : _name.text.trim(),
                  babyName: _baby.text.trim().isEmpty ? profile.babyName : _baby.text.trim(),
                  motherAge: age,
                  clearMotherAge: age == null && _age.text.trim().isEmpty,
                ),
              );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('احفظي'),
          ),
        ],
      ),
    );
  }
}

class ShiftModePage extends StatelessWidget {
  const ShiftModePage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final profile = store.profile!;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: const HyaText('المرحلة', weight: 720, size: 18),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          const HyaText('لما المرحلة تتغير، الشاشة الأولى والتابات بيتغيروا. بياناتك القديمة بتفضل محفوظة.', color: HyaColors.muted),
          const SizedBox(height: 14),
          if (profile.mode != LifeMode.ttc)
            _ShiftButton(
              title: 'أرجّع لمرحلة التخطيط',
              onTap: () => _shift(context, LifeMode.ttc),
            ),
          if (profile.mode != LifeMode.pregnant)
            _ShiftButton(
              title: 'أنا حامل',
              onTap: () => _shift(context, LifeMode.pregnant),
            ),
          if (profile.mode != LifeMode.postpartum)
            _ShiftButton(
              title: 'حصلت الولادة',
              onTap: () => _shift(context, LifeMode.postpartum),
            ),
        ],
      ),
    );
  }

  Future<void> _shift(BuildContext context, LifeMode mode) async {
    final store = StoreScope.of(context);
    final profile = store.profile!;
    final now = DateTime.now();

    if (mode == LifeMode.ttc || (mode == LifeMode.pregnant && profile.lastPeriodDate == null)) {
      final picked = await pickDate(
        context,
        initial: profile.lastPeriodDate ?? now.subtract(const Duration(days: 28)),
        first: now.subtract(const Duration(days: 400)),
        last: now,
      );
      if (picked == null || !context.mounted) return;
      await store.saveProfile(
        profile.copyWith(
          mode: mode,
          lastPeriodDate: dateOnly(picked),
          expectedDueDate: mode == LifeMode.pregnant ? CycleMath.dueDateFromLmp(picked) : profile.expectedDueDate,
          clearDueDate: mode == LifeMode.ttc,
        ),
      );
    } else if (mode == LifeMode.pregnant) {
      await store.saveProfile(
        profile.copyWith(
          mode: LifeMode.pregnant,
          expectedDueDate: profile.expectedDueDate ?? CycleMath.dueDateFromLmp(profile.lastPeriodDate!),
        ),
      );
    } else {
      final picked = await pickDate(
        context,
        initial: now,
        first: now.subtract(const Duration(days: 900)),
        last: now,
        accent: HyaColors.gold,
      );
      if (picked == null || !context.mounted) return;
      final natural = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const HyaText('الولادة كانت إزاي؟', size: 18, weight: 740),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('طبيعي')),
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('قيصري')),
          ],
        ),
      );
      if (natural == null || !context.mounted) return;
      await store.saveProfile(
        profile.copyWith(
          mode: LifeMode.postpartum,
          babyBirthDate: dateOnly(picked),
          deliveryType: natural ? DeliveryType.natural : DeliveryType.cesarean,
        ),
      );
    }
    if (context.mounted) Navigator.pop(context);
  }
}

class _ShiftButton extends StatelessWidget {
  const _ShiftButton({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: OutlinedButton(onPressed: onTap, child: Text(title)),
    );
  }
}

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final _name = TextEditingController();
  final _age = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _week = TextEditingController();
  var _creating = false;
  var _obscure = true;
  var _busy = false;
  String? _photoPath;
  String? _message;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final store = StoreScope.of(context);
    final profile = store.profile;
    if (_name.text.isEmpty && profile != null) {
      _name.text = profile.name;
      _age.text = profile.motherAge?.toString() ?? '';
      final week = store.draft?.estimatedPregnancyWeek() ??
          (profile.lastPeriodDate == null
              ? null
              : CycleMath.gestationalAge(profile.lastPeriodDate!, dateOnly(DateTime.now())).week);
      if (week != null && week > 0) _week.text = '$week';
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _email.dispose();
    _password.dispose();
    _week.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final pregnant = store.profile?.mode == LifeMode.pregnant || store.draft?.mode == LifeMode.pregnant;
    return HyaBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          title: const HyaText('الحساب', weight: 720, size: 18),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            HyaText(
              RemoteSync.configured
                  ? 'الحساب بيحفظ الاسم والسن والصورة واليوميات والتجارب على Supabase.'
                  : 'التطبيق شغال على الموبايل. عشان توصّلي Supabase، حطّي المفاتيح في env.json.',
              color: HyaColors.muted,
            ),
            const SizedBox(height: 12),
            if (store.signedIn) ...[
              HyaCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HyaText(store.profile?.name ?? 'متصلة', weight: 740, size: 18),
                    const SizedBox(height: 4),
                    HyaText(store.accountEmail ?? '', color: HyaColors.muted),
                    if (store.profile?.motherAge != null) ...[
                      const SizedBox(height: 4),
                      HyaText('السن: ${store.profile!.motherAge}', color: HyaColors.muted),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => store.signOut(),
                child: const Text('اخرجي من الحساب'),
              ),
            ] else ...[
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('دخولي')),
                  ButtonSegment(value: true, label: Text('حساب جديد')),
                ],
                selected: {_creating},
                onSelectionChanged: (value) => setState(() {
                  _creating = value.first;
                  _message = null;
                }),
              ),
              const SizedBox(height: 14),
              if (_creating) ...[
                Center(
                  child: GestureDetector(
                    onTap: () async {
                      final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 72);
                      if (picked == null) return;
                      setState(() => _photoPath = picked.path);
                    },
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: HyaColors.blush,
                      backgroundImage: _photoPath != null ? FileImage(File(_photoPath!)) : null,
                      child: _photoPath == null
                          ? const Icon(Icons.add_a_photo_rounded, color: HyaColors.roseDeep)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const HyaText('صورة اختيارية', align: TextAlign.center, size: 12.5, color: HyaColors.muted),
                const SizedBox(height: 12),
                TextField(
                  controller: _name,
                  decoration: const InputDecoration(hintText: 'الاسم'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _age,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: 'العمر'),
                ),
                if (pregnant) ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: _week,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'أسبوع الحمل كام؟'),
                  ),
                ],
                const SizedBox(height: 10),
              ],
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(hintText: 'الإيميل'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _password,
                obscureText: _obscure,
                decoration: InputDecoration(
                  hintText: 'كلمة السر',
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(_obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                  ),
                ),
              ),
              if (!_creating)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    onPressed: _busy
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ForgotPasswordPage(initialEmail: _email.text.trim()),
                              ),
                            );
                          },
                    child: const Text('نسيتِ كلمة السر؟'),
                  ),
                ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _busy ? null : () => _submit(),
                child: _busy
                    ? const HyaButtonLoader()
                    : Text(_creating ? 'اعملِ الحساب' : 'دخّلي'),
              ),
            ],
            if (_message != null) ...[
              const SizedBox(height: 12),
              DisclaimerNote(text: _message!),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_password.text.length < 6 || !_email.text.contains('@')) {
      setState(() => _message = 'اكتبي إيميل صحيح، وكلمة سر من ٦ حروف على الأقل.');
      return;
    }
    int? age;
    int? week;
    if (_creating) {
      age = int.tryParse(_age.text.trim());
      week = int.tryParse(_week.text.trim());
      final pregnant = StoreScope.of(context).profile?.mode == LifeMode.pregnant ||
          StoreScope.of(context).draft?.mode == LifeMode.pregnant;
      if (_name.text.trim().isEmpty) {
        setState(() => _message = 'اكتبي اسمكِ.');
        return;
      }
      if (age == null || age < 14 || age > 60) {
        setState(() => _message = 'اكتبي عمر صحيح (من ١٤ لـ ٦٠).');
        return;
      }
      if (pregnant && (week == null || week < 1 || week > 45)) {
        setState(() => _message = 'اكتبي أسبوع الحمل (من ١ لـ ٤٥).');
        return;
      }
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    final store = StoreScope.of(context);
    final outcome = _creating
        ? await store.signUp(
            email: _email.text,
            password: _password.text,
            name: _name.text,
            motherAge: age!,
            photoPath: _photoPath,
            pregnancyWeek: week,
          )
        : await store.signIn(_email.text, _password.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _message = outcome.message;
    });
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({required this.label, required this.value, required this.onTap});

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
          Expanded(child: HyaText(label, color: HyaColors.muted, size: 13)),
          HyaText(value, weight: 700),
        ],
      ),
    );
  }
}
