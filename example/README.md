# flutter_opencc example

一个完整的 OpenCC 转换演示应用，展示 `flutter_opencc` 在 Flutter 中的用法。

## 演示内容

- 16 个 OpenCC 配置，覆盖简繁互转、台湾/香港字形和常用词、日文新旧字体。
- `ZhConverter` 直接转换与 `ZhTransformer` 流式分块转换两种模式。
- 简体、繁体、台湾、香港、日文新字体/旧字体快捷示例文本。
- 转换结果可选中复制，异常会直接显示在输出区域。

## 运行

```bash
flutter pub get
flutter run
```

连接 Android 设备或模拟器后运行集成测试：

```bash
flutter test integration_test
```

## 测试

```bash
flutter test
```
