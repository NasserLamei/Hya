import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hya/app.dart';
import 'package:hya/core/models.dart';
import 'package:hya/core/store.dart';
import 'package:hya/core/theme.dart';
import 'package:hya/features/pregnant/pregnant_pages.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpHome(WidgetTester tester, {required int daysPregnant}) async {
    final store = AppStore()
      ..profile = Profile(
        name: 'جوليا',
        mode: LifeMode.pregnant,
        lastPeriodDate: DateTime.now().subtract(Duration(days: daysPregnant)),
        updatedAt: DateTime.now(),
      )
      ..ready = true;
    await tester.pumpWidget(
      StoreScope(
        store: store,
        child: MaterialApp(
          theme: buildHyaTheme(),
          home: const Directionality(textDirection: TextDirection.rtl, child: PregnantHomePage()),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> reveal(WidgetTester tester, Finder finder) async {
    for (var i = 0; i < 14 && finder.evaluate().isEmpty; i++) {
      await tester.drag(find.byType(ListView), const Offset(0, -450));
      await tester.pump();
    }
    expect(finder, findsWidgets);
  }

  testWidgets('early pregnancy explains the log and hides the kick counter', (tester) async {
    await pumpHome(tester, daysPregnant: 40);

    await reveal(tester, find.text('مزاجك النهاردة'));
    await reveal(tester, find.text('حسيتي إيه في جسمك؟'));
    await reveal(tester, find.textContaining('لسه بدري على عدّ الحركات'));
    expect(find.text('حسيت حركة'), findsNothing);
    expect(find.text('حركات اتسجلت النهاردة'), findsNothing);

    await reveal(tester, find.text('مبسوطة'));
    await tester.tap(find.text('مبسوطة'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.textContaining('اتسجل اليوم ده'), findsOneWidget);

    await reveal(tester, find.text('غثيان'));
    await tester.tap(find.text('غثيان'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.textContaining('الشهور الأولى'), findsOneWidget);
  });

  testWidgets('from week 28 the counter is a personal note', (tester) async {
    await pumpHome(tester, daysPregnant: 30 * 7);

    await reveal(tester, find.text('حسيت حركة'));
    expect(find.textContaining('لسه بدري'), findsNothing);
    expect(find.text('حركة حسيتيها النهاردة'), findsOneWidget);
    await tester.ensureVisible(find.text('حسيت حركة'));
    await tester.pump();
    await tester.tap(find.text('حسيت حركة'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('1'), findsOneWidget);
    expect(find.text('اضغطت بالغلط'), findsOneWidget);
  });
}
