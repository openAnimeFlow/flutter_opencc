import 'package:flutter_opencc_plus/flutter_opencc_plus.dart';
import 'package:test/test.dart';

import 'support/native_build.dart';

void main() {
  final dataDir = localOpenCCDataDir();
  final skip = hasLocalOpenCCBuild ? false : nativeBuildSkipReason;

  group('ZhTransformer', () {
    test('converts buffered chunks without a trailing newline', () async {
      final transformer = ZhTransformer(OpenCCConfig.s2t, dataDir: dataDir);
      addTearDown(transformer.dispose);

      final output = await Stream<String>.fromIterable([
        '开放',
        '中文转换',
      ]).transform(transformer).toList();

      expect(output, ['開放中文轉換']);
    }, skip: skip);

    test('handles a newline split across chunks', () async {
      final transformer = ZhTransformer(OpenCCConfig.s2t, dataDir: dataDir);
      addTearDown(transformer.dispose);

      final output = await Stream<String>.fromIterable([
        '开放中',
        '文\n转换',
        '\nOpenCC',
      ]).transform(transformer).toList();

      expect(output, ['開放中文', '\n', '轉換', '\n', 'OpenCC']);
    }, skip: skip);

    test('preserves empty lines and whitespace-only lines', () async {
      final transformer = ZhTransformer(OpenCCConfig.s2t, dataDir: dataDir);
      addTearDown(transformer.dispose);

      final output = await Stream<String>.fromIterable([
        '开放\n',
        '\n  \n',
        '转换',
      ]).transform(transformer).toList();

      expect(output.join(), '開放\n\n  \n轉換');
    }, skip: skip);

    test('handles CRLF line endings split across chunks', () async {
      final transformer = ZhTransformer(OpenCCConfig.s2t, dataDir: dataDir);
      addTearDown(transformer.dispose);

      final output = await Stream<String>.fromIterable([
        '开放\r',
        '\n中文\r\n',
      ]).transform(transformer).toList();

      expect(output.join(), '開放\r\n中文\r\n');
    }, skip: skip);

    test('ignores empty chunks', () async {
      final transformer = ZhTransformer(OpenCCConfig.s2t, dataDir: dataDir);
      addTearDown(transformer.dispose);

      final output = await Stream<String>.fromIterable([
        '',
        '',
        '开放',
        '',
      ]).transform(transformer).toList();

      expect(output, ['開放']);
    }, skip: skip);

    test('dispose is idempotent', () {
      final transformer = ZhTransformer(OpenCCConfig.s2t, dataDir: dataDir);

      transformer.dispose();
      transformer.dispose();
    }, skip: skip);
  });
}
