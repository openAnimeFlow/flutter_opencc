import 'package:flutter/material.dart';
import 'package:flutter_opencc/flutter_opencc.dart';

void main() {
  runApp(const OpenCCExampleApp());
}

class OpenCCExampleApp extends StatelessWidget {
  const OpenCCExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'flutter_opencc example',
      home: Scaffold(body: Center(child: Text('$packageName example app'))),
    );
  }
}
