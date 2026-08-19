import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_opencc_example/main.dart';

void main() {
  testWidgets('renders the example app', (WidgetTester tester) async {
    await tester.pumpWidget(const OpenCCExampleApp());

    expect(find.text('flutter_opencc example'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('简 → 繁（标准）'), findsOneWidget);
    expect(find.text('直接'), findsOneWidget);
    expect(find.text('流式'), findsOneWidget);
  });

  testWidgets('converts text through the UI', (WidgetTester tester) async {
    await tester.pumpWidget(const OpenCCExampleApp());

    await tester.runAsync(() async {
      await tester.tap(find.text('转换'));
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();

    expect(find.text('開放中文轉換 OpenCC'), findsOneWidget);
  });

  testWidgets('converts text through streaming mode', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const OpenCCExampleApp());
    await tester.tap(find.text('流式'));
    await tester.pumpAndSettle();

    await tester.runAsync(() async {
      await tester.tap(find.text('转换'));
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();

    expect(find.text('開放中文轉換 OpenCC'), findsOneWidget);
    expect(find.text('1 个分块'), findsOneWidget);
  });

  testWidgets('sample switches config and converts', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const OpenCCExampleApp());
    await tester.tap(find.widgetWithText(ActionChip, '繁体'));
    await tester.pumpAndSettle();

    expect(find.text('繁 → 简（标准）'), findsOneWidget);

    await tester.runAsync(() async {
      await tester.tap(find.text('转换'));
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();

    expect(find.text('开放中文转换 OpenCC'), findsOneWidget);
  });
}
