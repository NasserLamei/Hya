import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/store.dart';
import 'core/theme.dart';
import 'features/auth/auth_page.dart';
import 'features/onboarding/onboarding_page.dart';
import 'features/shell/shell_page.dart';
import 'features/splash/splash_page.dart';

class StoreScope extends InheritedNotifier<AppStore> {
  const StoreScope({super.key, required AppStore store, required super.child}) : super(notifier: store);

  static AppStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<StoreScope>();
    assert(scope != null, 'StoreScope missing');
    return scope!.notifier!;
  }
}

class HyaApp extends StatelessWidget {
  const HyaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'هي',
      debugShowCheckedModeBanner: false,
      theme: buildHyaTheme(),
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          behavior: HitTestBehavior.translucent,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: Color(0xFFFFF4F6)),
                const Image(
                  image: AssetImage('assets/art/hya_background.jpg'),
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
                child ?? const SizedBox.shrink(),
              ],
            ),
          ),
        );
      },
      home: const _Opening(),
    );
  }
}

class _Opening extends StatefulWidget {
  const _Opening();

  @override
  State<_Opening> createState() => _OpeningState();
}

class _OpeningState extends State<_Opening> {
  var _held = true;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _held = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    if (_held || !store.ready) return const SplashPage();
    if (store.passwordRecovery) return const SetNewPasswordPage();
    if (store.profile != null) return ShellPage(key: ValueKey(store.profile!.mode));
    if (!store.onboardingDone) return const OnboardingPage();
    return const AuthGatePage();
  }
}
