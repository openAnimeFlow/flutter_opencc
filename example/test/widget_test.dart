import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_opencc_example/main.dart';

void main() {
  testWidgets('renders the example app', (WidgetTester tester) async {
    await tester.pumpWidget(const OpenCCExampleApp());

    expect(find.text('flutter_opencc example'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });
}
