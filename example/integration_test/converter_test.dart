import 'package:flutter_opencc_plus/flutter_opencc_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('converts simplified Chinese on a device', (tester) async {
    final converter = await ZhConverter.create(OpenCCConfig.s2t);
    addTearDown(converter.dispose);

    expect(converter.convert('开放中文转换 OpenCC'), '開放中文轉換 OpenCC');
  });

  testWidgets('converts traditional Chinese on a device', (tester) async {
    final converter = await ZhConverter.create(OpenCCConfig.t2s);
    addTearDown(converter.dispose);

    expect(converter.convert('鼠標與軟件 OpenCC'), '鼠标与软件 OpenCC');
  });
}
