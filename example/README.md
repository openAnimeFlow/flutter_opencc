# flutter_opencc example

一个完整的 OpenCC 转换演示应用，展示 `flutter_opencc` 在 Flutter 中的用法。

## 演示内容

- 参考 [OpenCC 网页版转换工具](https://opencc.js.org/converter) 的来源/目标语言选择布局。
- 覆盖简体中文、台湾正体、香港繁体、OpenCC 标准繁体、日文新旧字体。
- 16 个 OpenCC 配置档选择弹窗，以及地域常用词转换开关。
- 输入后自动转换，也可点击转换按钮手动触发。
- 转换结果可复制，开启差异显示后高亮转换产生的文字变化。
- 批量转换区通过 `convertAll` 一次处理多行文本。

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
