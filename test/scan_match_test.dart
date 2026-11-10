import 'package:flutter_test/flutter_test.dart';
import 'package:hya/core/scan_match.dart';
import 'package:hya/data/guides.dart';
import 'package:hya/data/scan_catalog.dart';

void main() {
  test('a painkiller box is caution, not a free pass', () {
    final verdict = judgeText('PANADOL 500 mg');
    expect(verdict.primary?.item.name, 'الباراسيتامول');
    expect(verdict.primary?.item.level, SafetyLevel.amber);
  });

  test('ibuprofen outranks a safer word on the same label', () {
    final verdict = judgeText('BRUFEN and folic acid');
    expect(verdict.primary?.item.level, SafetyLevel.red);
  });

  test('a mango photo is allowed fruit, not a deformity', () {
    final verdict = judgeText('Mango');
    expect(verdict.primary?.item.name, 'فاكهة مغسولة');
    expect(verdict.primary?.item.level, SafetyLevel.green);
  });

  test('alcohol wins when the picture also contains fruit', () {
    final verdict = judgeText('mango wine');
    expect(verdict.primary?.item.level, SafetyLevel.red);
    expect(verdict.primary?.item.name, 'الكحول');
  });

  test('raw egg wording is forbidden rather than ordinary egg', () {
    final verdict = judgeText('بيض نيء');
    expect(verdict.primary?.item.name, 'اللحوم والبيض النيء');
  });

  test('unknown packaging is not guessed', () {
    expect(judgeText('xyzq brand 9').found, isFalse);
  });

  test('liver is avoided in pregnancy', () {
    final verdict = judgeText('كبده');
    expect(verdict.primary?.item.name, 'الكبدة');
    expect(verdict.primary?.item.level, SafetyLevel.red);
  });

  test('chicken liver stays forbidden, not plain chicken', () {
    final verdict = judgeText('كبدة فراخ');
    expect(verdict.primary?.item.name, 'الكبدة');
    expect(verdict.primary?.item.level, SafetyLevel.red);
  });

  test('food and medicine tabs search their own lists', () {
    expect(judgeText('بنادول', kinds: foodScanKinds).found, isFalse);
    expect(judgeText('بنادول', kinds: medicineScanKinds).primary?.item.name, 'الباراسيتامول');
    expect(judgeText('كبدة', kinds: foodScanKinds).primary?.item.level, SafetyLevel.red);
  });
}
