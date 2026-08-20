import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_opencc_plus/flutter_opencc_plus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('converts s2t using bundled package assets', () async {
    final converter = await ZhConverter.create(OpenCCConfig.s2t);
    addTearDown(converter.dispose);

    expect(converter.convert('开放中文转换 OpenCC'), '開放中文轉換 OpenCC');
  });

  test('converts t2s using bundled package assets', () async {
    final converter = await ZhConverter.create(OpenCCConfig.t2s);
    addTearDown(converter.dispose);

    expect(converter.convert('鼠標與軟件 OpenCC'), '鼠标与软件 OpenCC');
  });

  test('converts Taiwan phrase config using bundled package assets', () async {
    final converter = await ZhConverter.create(OpenCCConfig.s2twp);
    addTearDown(converter.dispose);

    expect(converter.convert('鼠标 内存 硬盘 网络'), '滑鼠 記憶體 硬碟 網路');
  });

  test('converts long text using bundled package assets', () async {
    final converter = await ZhConverter.create(OpenCCConfig.s2t);
    addTearDown(converter.dispose);

    final input = List.filled(2048, '开放中文转换 OpenCC').join('\n');
    final expected = List.filled(2048, '開放中文轉換 OpenCC').join('\n');
    expect(converter.convert(input), expected);
  });
}
