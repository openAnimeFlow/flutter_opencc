import 'package:flutter_opencc/flutter_opencc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('converts Chinese text on a device', (tester) async {
    final converter = await ZhConverter.create('s2t');
    addTearDown(converter.dispose);

    expect(converter.convert('开放中文转换 OpenCC'), '開放中文轉換 OpenCC');
  });
}
