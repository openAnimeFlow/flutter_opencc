import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_opencc_example/main.dart';

void main() {
  testWidgets('renders the official-style converter', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const OpenCCExampleApp());

    expect(find.text('OpenCC'), findsOneWidget);
    expect(find.text('选择转换模式'), findsOneWidget);
    expect(find.text('输入原文'), findsOneWidget);
    expect(find.text('转换结果'), findsOneWidget);
    expect(find.text('简体中文 (s)'), findsOneWidget);
    expect(find.byKey(const ValueKey('来源 (Source)-s')), findsOneWidget);
    expect(find.byKey(const ValueKey('目标 (Target)-t')), findsOneWidget);
    expect(find.text('s2t.json'), findsOneWidget);
  });

  testWidgets('converts text through the UI', (WidgetTester tester) async {
    await tester.pumpWidget(const OpenCCExampleApp());

    await tester.enterText(find.byKey(const ValueKey('input-field')), '鼠标与软件');
    await tester.pump();
    await tester.ensureVisible(find.byKey(const ValueKey('convert-button')));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const ValueKey('convert-button')));
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 400));
    });
    await tester.pumpAndSettle();

    expect(find.text('鼠標與軟件'), findsOneWidget);
  });

  testWidgets('swaps source and target', (WidgetTester tester) async {
    await tester.pumpWidget(const OpenCCExampleApp());

    await tester.tap(find.byKey(const ValueKey('swap-button')));
    await tester.pump();

    expect(find.text('t2s.json'), findsOneWidget);
  });

  testWidgets('selects a target and enables phrase conversion', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const OpenCCExampleApp());

    await tester.tap(find.byKey(const ValueKey('目标 (Target)-tw')));
    await tester.pump();
    expect(find.text('s2tw.json'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('phrase-option')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('phrase-option')));
    await tester.pump();
    expect(find.text('s2twp.json'), findsOneWidget);
  });

  testWidgets('picks a config from the picker dialog', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const OpenCCExampleApp());

    await tester.tap(find.byKey(const ValueKey('config-picker')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('config-s2twp')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('config-s2twp')));
    await tester.pumpAndSettle();
    expect(find.text('s2twp.json'), findsOneWidget);
  });
}
