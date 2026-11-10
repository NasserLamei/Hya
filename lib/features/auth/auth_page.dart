import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../app.dart';
import '../../core/models.dart';
import '../../core/remote.dart';
import '../../core/theme.dart';
import '../../widgets/ui.dart';

class AuthGatePage extends StatelessWidget {
  const AuthGatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return HyaBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 18),
                Center(
                  child: ClipOval(
                    child: Image.asset(
                      'assets/icon/app_icon.png',
                      width: 88,
                      height: 88,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                const HyaText('أهلاً بيكي في هي', size: 30, weight: 780, align: TextAlign.center),
                const SizedBox(height: 10),
                const HyaText(
                  'اعملي حساب جديد أو دخّلي بحسابك عشان نحفظ رحلتك ونزامن البيانات.',
                  align: TextAlign.center,
                  color: HyaColors.muted,
                  height: 1.65,
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SignupPage()),
                    );
                  },
                  child: const Text('حساب جديد'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    );
                  },
                  child: const Text('تسجيل الدخول'),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _name = TextEditingController();
  final _age = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _week = TextEditingController();
  var _obscure = true;
  var _busy = false;
  var _weekReady = false;
  String? _photoPath;
  String? _message;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_weekReady) return;
    final draft = StoreScope.of(context).draft;
    final week = draft?.estimatedPregnancyWeek();
    if (week != null) _week.text = '$week';
    _weekReady = true;
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
    final draft = StoreScope.of(context).draft;
    final pregnant = draft?.mode == LifeMode.pregnant;

    return HyaBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          title: const HyaText('حساب جديد', weight: 720, size: 18),
        ),
        body: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            const HyaText(
              'اكتبي بياناتك. هنتأكد إن الإيميل مش متسجل قبل كده.',
              color: HyaColors.muted,
            ),
            const SizedBox(height: 18),
            Center(
              child: GestureDetector(
                onTap: () async {
                  final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 72);
                  if (picked == null) return;
                  setState(() => _photoPath = picked.path);
                },
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: HyaColors.blush,
                  backgroundImage: _photoPath != null ? FileImage(File(_photoPath!)) : null,
                  child: _photoPath == null
                      ? const Icon(Icons.add_a_photo_rounded, color: HyaColors.roseDeep, size: 28)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const HyaText('صورة اختيارية', align: TextAlign.center, size: 12.5, color: HyaColors.muted),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                hintText: 'الاسم',
                prefixIcon: Icon(Icons.person_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _age,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                hintText: 'العمر',
                prefixIcon: Icon(Icons.cake_rounded),
              ),
            ),
            if (pregnant) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _week,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: 'أسبوع الحمل كام؟',
                  prefixIcon: Icon(Icons.pregnant_woman_rounded),
                ),
              ),
              const SizedBox(height: 6),
              const HyaText(
                'لو عدّلتي الأسبوع، هنظبط حساب الحمل والميعاد على أساسه.',
                size: 12.5,
                color: HyaColors.muted,
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                hintText: 'الإيميل',
                prefixIcon: Icon(Icons.email_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                FocusManager.instance.primaryFocus?.unfocus();
                _submit();
              },
              decoration: InputDecoration(
                hintText: 'كلمة السر',
                prefixIcon: const Icon(Icons.lock_rounded),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(_obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                ),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy ? const HyaButtonLoader() : const Text('اعملِ الحساب'),
            ),
            if (_message != null) ...[
              const SizedBox(height: 14),
              DisclaimerNote(text: _message!),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final age = int.tryParse(_age.text.trim());
    final week = int.tryParse(_week.text.trim());
    final draft = StoreScope.of(context).draft;
    final pregnant = draft?.mode == LifeMode.pregnant;

    if (_name.text.trim().length < 2) {
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
    if (!_email.text.contains('@') || _password.text.length < 6) {
      setState(() => _message = 'اكتبي إيميل صحيح، وكلمة سر من ٦ حروف على الأقل.');
      return;
    }

    setState(() {
      _busy = true;
      _message = null;
    });

    final store = StoreScope.of(context);
    if (await RemoteSync.emailIsRegistered(_email.text)) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _message = 'الإيميل ده متسجل قبل كده. دخّلي بيه أو جرّبي إيميل تاني.';
      });
      return;
    }

    final outcome = await store.signUp(
      email: _email.text,
      password: _password.text,
      name: _name.text,
      motherAge: age,
      photoPath: _photoPath,
      pregnancyWeek: pregnant ? week : null,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _message = outcome.message;
    });
    if (outcome.ok && store.profile != null) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _obscure = true;
  var _busy = false;
  String? _message;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HyaBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          title: const HyaText('تسجيل الدخول', weight: 720, size: 18),
        ),
        body: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            const HyaText(
              'دخّلي بالإيميل وكلمة السر اللي عملتي بيهم الحساب.',
              color: HyaColors.muted,
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                hintText: 'الإيميل',
                prefixIcon: Icon(Icons.email_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: 'كلمة السر',
                prefixIcon: const Icon(Icons.lock_rounded),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(_obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                ),
              ),
            ),
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
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy ? const HyaButtonLoader() : const Text('دخّلي'),
            ),
            if (_message != null) ...[
              const SizedBox(height: 14),
              DisclaimerNote(text: _message!),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_email.text.contains('@') || _password.text.length < 6) {
      setState(() => _message = 'اكتبي إيميل صحيح، وكلمة سر من ٦ حروف على الأقل.');
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    final store = StoreScope.of(context);
    final outcome = await store.signIn(_email.text, _password.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _message = outcome.message;
    });
    if (outcome.ok && store.profile != null) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }
}

class SetNewPasswordPage extends StatefulWidget {
  const SetNewPasswordPage({super.key});

  @override
  State<SetNewPasswordPage> createState() => _SetNewPasswordPageState();
}

class _SetNewPasswordPageState extends State<SetNewPasswordPage> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  var _obscure = true;
  var _busy = false;
  String? _message;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HyaBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          title: const HyaText('كلمة سر جديدة', weight: 720, size: 18),
        ),
        body: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            const HyaText(
              'اللينك اتفتح صح. عيّني كلمة السر الجديدة دلوقتي.',
              color: HyaColors.muted,
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _password,
              obscureText: _obscure,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                hintText: 'كلمة السر الجديدة',
                prefixIcon: const Icon(Icons.lock_rounded),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(_obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirm,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                hintText: 'تأكيد كلمة السر',
                prefixIcon: Icon(Icons.lock_outline_rounded),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy ? const HyaButtonLoader() : const Text('حفظ كلمة السر'),
            ),
            TextButton(
              onPressed: _busy ? null : () => StoreScope.of(context).dismissPasswordRecovery(),
              child: const Text('رجوع'),
            ),
            if (_message != null) ...[
              const SizedBox(height: 14),
              DisclaimerNote(text: _message!),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_password.text.length < 6) {
      setState(() => _message = 'كلمة السر لازم تبقى ٦ حروف على الأقل.');
      return;
    }
    if (_password.text != _confirm.text) {
      setState(() => _message = 'كلمة السر وتأكيدها مش زي بعض.');
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    final outcome = await StoreScope.of(context).updatePassword(_password.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _message = outcome.ok ? 'اتحفظت. دخّلي بالإيميل وكلمة السر الجديدة.' : outcome.message;
    });
  }
}

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  late final TextEditingController _email;
  var _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HyaBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          title: const HyaText('نسيت كلمة السر', weight: 720, size: 18),
        ),
        body: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            const HyaText(
              'اكتبي الإيميل، وهنبعتلكِ لينك. افتحيه من الموبايل وهيفتح تطبيق هي مباشرة.',
              color: HyaColors.muted,
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                hintText: 'الإيميل',
                prefixIcon: Icon(Icons.email_rounded),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy ? const HyaButtonLoader() : const Text('ابعتي لينك الاستعادة'),
            ),
            if (_message != null) ...[
              const SizedBox(height: 14),
              DisclaimerNote(text: _message!),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    final outcome = await StoreScope.of(context).sendResetLink(_email.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _message = outcome.message;
    });
  }
}
