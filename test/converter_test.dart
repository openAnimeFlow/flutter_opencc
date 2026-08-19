import 'dart:io';

import 'package:flutter_opencc/flutter_opencc.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'support/native_build.dart';

void main() {
  final dataDir = localOpenCCDataDir();
  final skip = hasLocalOpenCCBuild ? false : nativeBuildSkipReason;

  group('ZhConverter', () {
    test('converts simplified Chinese to traditional Chinese', () {
      final converter = ZhConverter('s2t', dataDir: dataDir);
      addTearDown(converter.dispose);

      expect(converter.convert('开放中文转换 OpenCC'), '開放中文轉換 OpenCC');
    }, skip: skip);

    test('converts traditional Chinese to simplified Chinese', () {
      final converter = ZhConverter('t2s', dataDir: dataDir);
      addTearDown(converter.dispose);

      expect(converter.convert('鼠標與軟件 OpenCC'), '鼠标与软件 OpenCC');
    }, skip: skip);

    test('supports every OpenCC config name', () {
      const configs = [
        's2t',
        't2s',
        's2tw',
        'tw2s',
        's2hk',
        'hk2s',
        's2twp',
        'tw2sp',
        't2tw',
        'tw2t',
        't2hk',
        'hk2t',
        't2jp',
        'jp2t',
      ];

      for (final config in configs) {
        final converter = ZhConverter(config, dataDir: dataDir);
        addTearDown(converter.dispose);

        expect(converter.convert('开放中文转换'), isNotEmpty);
      }
    }, skip: skip);

    test('supports Taiwan and Hong Kong phrase configs', () {
      final s2twp = ZhConverter('s2twp', dataDir: dataDir);
      final tw2sp = ZhConverter('tw2sp', dataDir: dataDir);
      final s2hk = ZhConverter('s2hk', dataDir: dataDir);
      final hk2s = ZhConverter('hk2s', dataDir: dataDir);
      addTearDown(s2twp.dispose);
      addTearDown(tw2sp.dispose);
      addTearDown(s2hk.dispose);
      addTearDown(hk2s.dispose);

      expect(s2twp.convert('鼠标 内存 硬盘 网络'), '滑鼠 記憶體 硬碟 網路');
      expect(tw2sp.convert('滑鼠 記憶體 硬碟 網路'), '鼠标 内存 硬盘 网络');
      expect(s2hk.convert('软件'), '軟件');
      expect(hk2s.convert('軟件'), '软件');
    }, skip: skip);

    test('preserves empty and whitespace-only input', () {
      final converter = ZhConverter('s2t', dataDir: dataDir);
      addTearDown(converter.dispose);

      for (final input in ['', ' ', '\t', '\n', ' \t\n ']) {
        expect(converter.convert(input), input);
      }
    }, skip: skip);

    test('handles mixed Chinese, English, digits, and punctuation', () {
      final converter = ZhConverter('s2t', dataDir: dataDir);
      addTearDown(converter.dispose);

      expect(converter.convert('OpenCC 开放中文转换 2026!'), 'OpenCC 開放中文轉換 2026!');
    }, skip: skip);

    test('handles multibyte UTF-8 including emoji', () {
      final converter = ZhConverter('s2t', dataDir: dataDir);
      addTearDown(converter.dispose);

      expect(converter.convert('Hello 🙂 开放中文转换 🌏'), 'Hello 🙂 開放中文轉換 🌏');
    }, skip: skip);

    test('converts long multi-line text', () {
      final converter = ZhConverter('s2t', dataDir: dataDir);
      addTearDown(converter.dispose);

      const line = '开放中文转换 OpenCC';
      const convertedLine = '開放中文轉換 OpenCC';
      final input = List.filled(4096, line).join('\n');
      final expected = List.filled(4096, convertedLine).join('\n');

      expect(converter.convert(input), expected);
    }, skip: skip);

    test('rejects an unknown config', () {
      final resourcesDir = p.join('assets', 'opencc');

      expect(
        () => ZhConverter('no_such_config', dataDir: resourcesDir),
        throwsArgumentError,
      );
    });

    test('create rejects an unknown config', () async {
      final resourcesDir = p.join('assets', 'opencc');

      await expectLater(
        ZhConverter.create('no_such_config', dataDir: resourcesDir),
        throwsArgumentError,
      );
    });

    test('throws StateError for an invalid config file', () {
      final tempDir = Directory.systemTemp.createTempSync(
        'flutter_opencc_invalid_config_',
      );
      addTearDown(() => tempDir.deleteSync(recursive: true));
      File(p.join(tempDir.path, 's2t.json')).writeAsStringSync('{}');
      File(p.join(tempDir.path, 'bad.json')).writeAsStringSync('not json');

      expect(() => ZhConverter('bad', dataDir: tempDir.path), throwsStateError);
    }, skip: skip);

    test('dispose is idempotent and convert fails after dispose', () {
      final converter = ZhConverter('s2t', dataDir: dataDir);

      expect(converter.convert('开放中文转换'), '開放中文轉換');
      converter.dispose();
      converter.dispose();
      expect(() => converter.convert('开放中文转换'), throwsStateError);
    }, skip: skip);

    test('create resolves resources without an explicit dataDir', () async {
      final converter = await ZhConverter.create('s2t');
      addTearDown(converter.dispose);

      expect(converter.convert('开放中文转换'), '開放中文轉換');
    }, skip: skip);

    test('constructor resolves filesystem resources without dataDir', () {
      final converter = ZhConverter('s2t');
      addTearDown(converter.dispose);

      expect(converter.convert('开放中文转换'), '開放中文轉換');
    }, skip: skip);
  });
}
