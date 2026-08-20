import 'dart:io';

import 'package:flutter_opencc_plus/flutter_opencc_plus.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'support/native_build.dart';

void main() {
  final dataDir = localOpenCCDataDir();
  final skip = hasLocalOpenCCBuild ? false : nativeBuildSkipReason;

  group('ZhConverter', () {
    test('converts simplified Chinese to traditional Chinese', () {
      final converter = ZhConverter(OpenCCConfig.s2t, dataDir: dataDir);
      addTearDown(converter.dispose);

      expect(converter.convert('开放中文转换 OpenCC'), '開放中文轉換 OpenCC');
    }, skip: skip);

    test('converts traditional Chinese to simplified Chinese', () {
      final converter = ZhConverter(OpenCCConfig.t2s, dataDir: dataDir);
      addTearDown(converter.dispose);

      expect(converter.convert('鼠標與軟件 OpenCC'), '鼠标与软件 OpenCC');
    }, skip: skip);

    test('supports every OpenCC config name', () {
      for (final config in OpenCCConfig.values) {
        final converter = ZhConverter(config, dataDir: dataDir);
        addTearDown(converter.dispose);

        expect(converter.convert('开放中文转换'), isNotEmpty);
      }
    }, skip: skip);

    test('supports Taiwan and Hong Kong phrase configs', () {
      final s2twp = ZhConverter(OpenCCConfig.s2twp, dataDir: dataDir);
      final tw2sp = ZhConverter(OpenCCConfig.tw2sp, dataDir: dataDir);
      final s2hk = ZhConverter(OpenCCConfig.s2hk, dataDir: dataDir);
      final hk2s = ZhConverter(OpenCCConfig.hk2s, dataDir: dataDir);
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
      final converter = ZhConverter(OpenCCConfig.s2t, dataDir: dataDir);
      addTearDown(converter.dispose);

      for (final input in ['', ' ', '\t', '\n', ' \t\n ']) {
        expect(converter.convert(input), input);
      }
    }, skip: skip);

    test('handles mixed Chinese, English, digits, and punctuation', () {
      final converter = ZhConverter(OpenCCConfig.s2t, dataDir: dataDir);
      addTearDown(converter.dispose);

      expect(converter.convert('OpenCC 开放中文转换 2026!'), 'OpenCC 開放中文轉換 2026!');
    }, skip: skip);

    test('handles multibyte UTF-8 including emoji', () {
      final converter = ZhConverter(OpenCCConfig.s2t, dataDir: dataDir);
      addTearDown(converter.dispose);

      expect(converter.convert('Hello 🙂 开放中文转换 🌏'), 'Hello 🙂 開放中文轉換 🌏');
    }, skip: skip);

    test('converts long multi-line text', () {
      final converter = ZhConverter(OpenCCConfig.s2t, dataDir: dataDir);
      addTearDown(converter.dispose);

      const line = '开放中文转换 OpenCC';
      const convertedLine = '開放中文轉換 OpenCC';
      final input = List.filled(4096, line).join('\n');
      final expected = List.filled(4096, convertedLine).join('\n');

      expect(converter.convert(input), expected);
    }, skip: skip);

    group('convertAll', () {
      test('converts multiple simplified texts to traditional Chinese', () {
        final converter = ZhConverter(OpenCCConfig.s2t, dataDir: dataDir);
        addTearDown(converter.dispose);

        expect(
          converter.convertAll(['开放中文转换', '鼠标', '软件', 'OpenCC 2026!', '']),
          ['開放中文轉換', '鼠標', '軟件', 'OpenCC 2026!', ''],
        );
      }, skip: skip);

      test('converts multiple traditional texts to simplified Chinese', () {
        final converter = ZhConverter(OpenCCConfig.t2s, dataDir: dataDir);
        addTearDown(converter.dispose);

        expect(converter.convertAll(['開放中文轉換', '鼠標', '軟件']), [
          '开放中文转换',
          '鼠标',
          '软件',
        ]);
      }, skip: skip);

      test('handles empty, single-item, and mixed multiline inputs', () {
        final converter = ZhConverter(OpenCCConfig.s2t, dataDir: dataDir);
        addTearDown(converter.dispose);

        expect(converter.convertAll([]), isEmpty);
        expect(converter.convertAll(['开放中文转换']), ['開放中文轉換']);
        expect(converter.convertAll(['开放中文转换\nOpenCC', '你好 🙂', '']), [
          '開放中文轉換\nOpenCC',
          '你好 🙂',
          '',
        ]);
      }, skip: skip);

      test('falls back per item when every separator is used', () {
        const separators = [
          '\u0001',
          '\u0002',
          '\u0003',
          '\u0004',
          '\u0005',
          '\u0006',
          '\u0007',
          '\u0008',
          '\u000B',
          '\u000C',
          '\u000E',
          '\u000F',
          '\u0010',
          '\u0011',
          '\u0012',
          '\u0013',
          '\u0014',
          '\u0015',
          '\u0016',
          '\u0017',
          '\u0018',
          '\u0019',
          '\u001A',
          '\u001B',
          '\u001C',
          '\u001D',
          '\u001E',
          '\u001F',
          '\u007F',
          '\u2028',
          '\u2029',
          '\uFEFF',
        ];
        final separatorText = separators.join();
        final converter = ZhConverter(OpenCCConfig.s2t, dataDir: dataDir);
        addTearDown(converter.dispose);

        expect(
          converter.convertAll(['开放中文转换$separatorText', '鼠标$separatorText软件']),
          ['開放中文轉換$separatorText', '鼠標$separatorText軟件'],
        );
      }, skip: skip);
    });

    test('resolves built-in config names and json suffixes', () {
      expect(OpenCCConfig.fromConfigName('s2t'), OpenCCConfig.s2t);
      expect(OpenCCConfig.fromConfigName('s2t.json'), OpenCCConfig.s2t);
      expect(OpenCCConfig.fromConfigName('custom'), isNull);
    });

    test('rejects an unknown config', () {
      final resourcesDir = p.join('assets', 'opencc');

      expect(
        () =>
            ZhConverter.fromConfigName('no_such_config', dataDir: resourcesDir),
        throwsArgumentError,
      );
    });

    test('create rejects an unknown config', () async {
      final resourcesDir = p.join('assets', 'opencc');

      await expectLater(
        ZhConverter.createFromConfigName(
          'no_such_config',
          dataDir: resourcesDir,
        ),
        throwsArgumentError,
      );
    });

    test('throws StateError for an invalid config file', () {
      final tempDir = Directory.systemTemp.createTempSync(
        'flutter_opencc_plus_invalid_config_',
      );
      addTearDown(() => tempDir.deleteSync(recursive: true));
      File(p.join(tempDir.path, 's2t.json')).writeAsStringSync('{}');
      File(p.join(tempDir.path, 'bad.json')).writeAsStringSync('not json');

      expect(
        () => ZhConverter.fromConfigName('bad', dataDir: tempDir.path),
        throwsStateError,
      );
    }, skip: skip);

    test('dispose is idempotent and convert fails after dispose', () {
      final converter = ZhConverter(OpenCCConfig.s2t, dataDir: dataDir);

      expect(converter.convert('开放中文转换'), '開放中文轉換');
      converter.dispose();
      converter.dispose();
      expect(() => converter.convert('开放中文转换'), throwsStateError);
    }, skip: skip);

    test('run disposes the converter automatically', () async {
      ZhConverter? captured;
      final output = await ZhConverter.run(OpenCCConfig.s2t, (converter) {
        captured = converter;
        return converter.convert('开放中文转换');
      }, dataDir: dataDir);

      expect(output, '開放中文轉換');
      expect(() => captured!.convert('开放中文转换'), throwsStateError);
    }, skip: skip);

    test('run disposes the converter when action throws', () async {
      ZhConverter? captured;

      await expectLater(
        ZhConverter.run(OpenCCConfig.s2t, (converter) {
          captured = converter;
          throw StateError('boom');
        }, dataDir: dataDir),
        throwsStateError,
      );

      expect(() => captured!.convert('开放中文转换'), throwsStateError);
    }, skip: skip);

    test('runFromConfigName disposes the converter automatically', () async {
      ZhConverter? captured;
      final output = await ZhConverter.runFromConfigName('s2t', (converter) {
        captured = converter;
        return converter.convert('开放中文转换');
      }, dataDir: dataDir);

      expect(output, '開放中文轉換');
      expect(() => captured!.convert('开放中文转换'), throwsStateError);
    }, skip: skip);

    test('create resolves resources without an explicit dataDir', () async {
      final converter = await ZhConverter.create(OpenCCConfig.s2t);
      addTearDown(converter.dispose);

      expect(converter.convert('开放中文转换'), '開放中文轉換');
    }, skip: skip);

    test('constructor resolves filesystem resources without dataDir', () {
      final converter = ZhConverter(OpenCCConfig.s2t);
      addTearDown(converter.dispose);

      expect(converter.convert('开放中文转换'), '開放中文轉換');
    }, skip: skip);
  });
}
