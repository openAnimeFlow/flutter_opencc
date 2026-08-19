import 'package:flutter_opencc/flutter_opencc.dart';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('package exposes its package name', () {
    expect(packageName, 'flutter_opencc');
  });

  final dataDir = p.join(
    'build',
    'opencc',
    'windows-x64',
    'install',
    'share',
    'opencc',
  );
  final localBuildAvailable =
      Platform.isWindows && Directory(dataDir).existsSync();

  group('ZhConverter', () {
    test('converts simplified Chinese to traditional Chinese', () {
      final converter = ZhConverter('s2t', dataDir: dataDir);
      addTearDown(converter.dispose);

      expect(converter.convert('开放中文转换 OpenCC'), '開放中文轉換 OpenCC');
    }, skip: localBuildAvailable ? false : 'local OpenCC build not found');

    test('converts traditional Chinese to simplified Chinese', () {
      final converter = ZhConverter('t2s', dataDir: dataDir);
      addTearDown(converter.dispose);

      expect(converter.convert('鼠標與軟件 OpenCC'), '鼠标与软件 OpenCC');
    }, skip: localBuildAvailable ? false : 'local OpenCC build not found');

    test('handles empty strings and repeated dispose', () {
      final converter = ZhConverter('s2t', dataDir: dataDir);

      expect(converter.convert(''), '');
      converter.dispose();
      converter.dispose();
    }, skip: localBuildAvailable ? false : 'local OpenCC build not found');

    test('transforms a stream line by line', () async {
      final transformer = ZhTransformer('s2t', dataDir: dataDir);
      addTearDown(transformer.dispose);

      final lines = Stream<String>.fromIterable([
        '开放\n中文',
      ]).transform(transformer);
      expect((await lines.toList()).join(), '開放\n中文');
    }, skip: localBuildAvailable ? false : 'local OpenCC build not found');
  });
}
