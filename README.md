# flutter_opencc_plus

[![Pub Version](https://img.shields.io/pub/v/flutter_opencc_plus.svg)](https://pub.dev/packages/flutter_opencc_plus)
[![License](https://img.shields.io/github/license/openAnimeFlow/flutter_opencc_plus.svg)](LICENSE)
[![Native Assets](https://img.shields.io/github/actions/workflow/status/openAnimeFlow/flutter_opencc_plus/asset_build.yml?branch=main&label=native%20assets)](https://github.com/openAnimeFlow/flutter_opencc_plus/actions/workflows/asset_build.yml)
[![Example Build](https://img.shields.io/github/actions/workflow/status/openAnimeFlow/flutter_opencc_plus/example_build.yml?branch=main&label=example%20build)](https://github.com/openAnimeFlow/flutter_opencc_plus/actions/workflows/example_build.yml)

一个跨平台的 [OpenCC](https://github.com/BYVoid/OpenCC) Dart/Flutter 封装，用于简体中文、
繁体中文、台湾/香港字形和常用词、日文新旧字体之间的转换。

原生共享库由 GitHub Actions 预编译并通过 GitHub Release 分发。应用构建时由 build hook
自动下载对应平台产物，使用者不需要安装 C++ 工具链、NDK 或 Xcode。

## Features

- 支持全部 16 个 OpenCC 1.4.1 配置。
- 提供同步 `ZhConverter`、流式 `ZhTransformer` 和批量 `convertAll` API。
- 支持 Android、iOS、macOS、Windows、Linux。
- 词库资源随 Flutter package assets 打包，运行时自动解析。
- 不依赖 `OPENCC_SHARED_DIR` 等环境变量。
- 内置 CLI，支持文本参数、文件、标准输入输出和原地替换。
- 非汉字内容会原样保留，包括标点、英文、数字、换行和 Emoji。

## Requirements

| 组件 | 版本 |
| --- | --- |
| Dart SDK | `>=3.10.0 <4.0.0` |
| Flutter | `>=3.35.0` |

build hook 使用 Dart/Flutter native asset bundling，从 Flutter 3.44 起该功能已稳定。

## Installation

包正式发布到 pub.dev 后，在项目中执行：

```bash
flutter pub add flutter_opencc_plus
```

也可以直接添加到 `pubspec.yaml`：

```yaml
dependencies:
  flutter_opencc_plus: ^0.1.0
```

当前开发阶段可以使用 Git 依赖：

```yaml
dependencies:
  flutter_opencc_plus:
    git:
      url: https://github.com/openAnimeFlow/flutter_opencc_plus.git
      ref: main
```

## Usage

### 基础转换

```dart
import 'package:flutter_opencc_plus/flutter_opencc_plus.dart';

void main() {
  final converter = ZhConverter(OpenCCConfig.s2t);
  try {
    print(converter.convert('开放中文转换')); // 開放中文轉換
  } finally {
    converter.dispose();
  }
}
```

### 作用域自动释放

一次性转换可以使用 `run`，转换完成后会自动释放原生 handle，不需要手动调用
`dispose()`：

```dart
final output = await ZhConverter.run(
  OpenCCConfig.s2t,
  (converter) => converter.convert('开放中文转换'),
);
print(output); // 開放中文轉換
```

`ZhConverter.runFromConfigName` 和 `ZhTransformer.run` / `runFromConfigName`
使用同样的作用域自动释放方式。

### Flutter

在 Flutter 应用中使用 package assets 时，优先使用异步创建方式：

```dart
import 'package:flutter_opencc_plus/flutter_opencc_plus.dart';

final converter = await ZhConverter.create(OpenCCConfig.s2t);
final output = converter.convert('鼠标与软件');
converter.dispose();
```

### 流式转换

```dart
final transformer = ZhTransformer(OpenCCConfig.t2s);
final chunks = Stream<String>.fromIterable(['開放中文', '轉換']);

await for (final chunk in chunks.transform(transformer)) {
  print(chunk);
}
transformer.dispose();
```

### 批量转换

```dart
final converter = ZhConverter(OpenCCConfig.s2t);
try {
  final outputs = converter.convertAll([
    '开放中文转换',
    '鼠标与软件',
    'OpenCC 2026!',
  ]);
  print(outputs); // [開放中文轉換, 鼠標與軟件, OpenCC 2026!]
} finally {
  converter.dispose();
}
```

`convertAll` 会优先选择一个输入中不存在的控制字符作为分隔符，合并后只调用一次底层
OpenCC API；如果所有候选分隔符都出现在输入中，会自动回退为逐条转换。

### 自定义配置

内置配置通过 `OpenCCConfig` 枚举选择。需要加载自定义配置文件时，可以使用：

```dart
final converter = ZhConverter.fromConfigName('my_config');
```

异步场景使用 `ZhConverter.createFromConfigName('my_config')`。

注意：一个转换实例不应跨 isolate 共享，每个 isolate 应创建自己的 `ZhConverter`。

## Supported Configurations

| 配置 | 说明 |
| --- | --- |
| `s2t` | 简体转繁体（OpenCC 标准） |
| `t2s` | 繁体转简体（OpenCC 标准） |
| `s2tw` | 简体转台湾繁体 |
| `tw2s` | 台湾繁体转简体 |
| `s2hk` | 简体转香港繁体 |
| `hk2s` | 香港繁体转简体 |
| `s2hkp` | 简体转香港繁体并替换香港常用词 |
| `hk2sp` | 香港繁体转大陆简体词 |
| `s2twp` | 简体转台湾繁体并替换台湾常用词 |
| `tw2sp` | 台湾繁体转大陆简体词 |
| `t2tw` | 标准繁体转台湾繁体 |
| `tw2t` | 台湾繁体转标准繁体 |
| `t2hk` | 标准繁体转香港繁体 |
| `hk2t` | 香港繁体转标准繁体 |
| `t2jp` | 旧日文汉字转新字体 |
| `jp2t` | 新字体转旧日文汉字 |

## API

### `OpenCCConfig`

内置配置枚举，包含上述 16 个配置。每个枚举值通过 `configName` 获取不带 `.json`
后缀的配置文件名。

### `ZhConverter`

同步转换器。

```dart
String convert(String text);
List<String> convertAll(Iterable<String> texts);
```

### `ZhTransformer`

流式转换器，继承自 `StreamTransformerBase<String, String>`，按换行边界拆分并转换
输入流。

## CLI

```bash
# 文本参数
dart run flutter_opencc_plus -c s2t "开放中文转换"

# 文件参数，输出到 stdout
dart run flutter_opencc_plus -c t2s input.txt

# 原地替换
dart run flutter_opencc_plus -c s2t -i notes.txt

# 标准输入
echo "开放中文转换" | dart run flutter_opencc_plus -c s2t

# 查看帮助
dart run flutter_opencc_plus -h
```

如果资源目录无法自动解析，可以显式指定：

```bash
dart run flutter_opencc_plus -c s2t --data-dir assets/opencc "开放中文转换"
```

## Platform Support

| 平台 | 架构 |
| --- | --- |
| Android | `arm64-v8a`、`armeabi-v7a`、`x86_64`、`x86` |
| iOS | `arm64` 真机、`arm64`/`x64` 模拟器 |
| macOS | `arm64`、`x64` |
| Windows | `x64`、`arm64` |
| Linux | `x64`、`arm64` |

## Native Assets

每次 OpenCC 版本更新时，维护者推送 `opencc-v<版本>` tag，GitHub Actions 会构建并发布：

```text
opencc-android-arm64.zip
opencc-android-arm.zip
opencc-android-x64.zip
opencc-android-x86.zip
opencc-ios-iphoneos-arm64.zip
opencc-ios-iphonesimulator-arm64.zip
opencc-ios-iphonesimulator-x64.zip
opencc-macos-arm64.zip
opencc-macos-x64.zip
opencc-windows-x64.zip
opencc-windows-arm64.zip
opencc-linux-x64.zip
opencc-linux-arm64.zip
```

每个 zip 都附带 `.sha256` 文件。build hook 会下载对应平台产物、校验 SHA-256、
解压共享库并注册为 native code asset。

开发时可以通过 `hooks.user_defines` 覆盖默认行为：

```yaml
hooks:
  user_defines:
    flutter_opencc_plus:
      base_url: https://example.com/releases
      local_dir: path/to/prebuilt/library
```

## Example

完整演示应用位于 [example](example/)，采用 OpenCC 官网转换器布局，支持来源/目标语言、
地域常用词、16 个配置档、差异高亮和 `convertAll` 批量转换：

```bash
cd example
flutter pub get
flutter run
```

## Additional Information

- [IMPLEMENTATION.md](IMPLEMENTATION.md)：实现说明。
- [CONTRIBUTING.md](CONTRIBUTING.md)：贡献指南。
- [TASKS.md](docs/TASKS.md)：发布前任务清单（已归档）。
- [LICENSE](LICENSE) 和 [NOTICE](NOTICE)：许可证与 OpenCC 归属信息。
