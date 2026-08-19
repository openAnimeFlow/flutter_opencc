# flutter_opencc

`flutter_opencc` 是一个跨平台的 [OpenCC](https://github.com/BYVoid/OpenCC)
Dart/Flutter 封装，提供简体中文、繁体中文、台湾/香港字形和常用词、日文新旧字体
之间的转换能力。

原生共享库由维护者在 GitHub Actions 中预编译，并通过 GitHub Release 分发。应用
构建时由 build hook 自动下载对应平台的 zip，因此使用者不需要安装 C++ 工具链、
NDK 或 Xcode。

## 特性

- 支持 16 个 OpenCC 1.4.1 配置。
- 提供同步 `ZhConverter` 和流式 `ZhTransformer` 两个 API。
- 支持 Android、iOS、macOS、Windows、Linux。
- 词库资源随 Flutter package assets 打包，运行时自动解析。
- 不依赖 `OPENCC_SHARED_DIR` 等环境变量。
- 内置 CLI，支持文本、文件、标准输入输出和原地替换。

## 环境要求

| 组件 | 版本 |
| --- | --- |
| Dart SDK | `>=3.10.0 <4.0.0` |
| Flutter | `>=3.35.0`，建议使用最新 stable |

构建 hook 使用 Dart/Flutter native asset bundling，从 3.44 起该功能已经稳定。

## 安装

发布到 pub.dev 后，在项目中执行：

```bash
flutter pub add flutter_opencc
```

当前开发阶段也可以使用 Git 依赖：

```yaml
dependencies:
  flutter_opencc:
    git:
      url: https://github.com/openAnimeFlow/flutter_opencc.git
      ref: main
```

## 快速开始

### Dart

```dart
import 'package:flutter_opencc/flutter_opencc.dart';

void main() {
  final converter = ZhConverter('s2t');
  try {
    print(converter.convert('开放中文转换')); // 開放中文轉換
  } finally {
    converter.dispose();
  }
}
```

### Flutter

在 Flutter 应用中使用 package assets 时，优先使用异步创建方式：

```dart
import 'package:flutter_opencc/flutter_opencc.dart';

final converter = await ZhConverter.create('s2t');
final output = converter.convert('鼠标与软件');
converter.dispose();
```

### 流式转换

```dart
final transformer = ZhTransformer('t2s');
final chunks = Stream<String>.fromIterable(['開放中文', '轉換']);
await for (final chunk in chunks.transform(transformer)) {
  print(chunk);
}
transformer.dispose();
```

一个转换实例不应跨 isolate 共享；每个 isolate 创建自己的 `ZhConverter`。

## 支持配置

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

## CLI

```bash
# 文本参数
dart run flutter_opencc -c s2t "开放中文转换"

# 文件参数，输出到 stdout
dart run flutter_opencc -c t2s input.txt

# 原地替换
dart run flutter_opencc -c s2t -i notes.txt

# 标准输入
echo "开放中文转换" | dart run flutter_opencc -c s2t

# 查看帮助
dart run flutter_opencc -h
```

如果资源目录无法自动解析，可以显式指定：

```bash
dart run flutter_opencc -c s2t --data-dir assets/opencc "开放中文转换"
```

## 平台支持

| 平台 | 架构 |
| --- | --- |
| Android | `arm64-v8a`、`armeabi-v7a`、`x86_64`、`x86` |
| iOS | `arm64` 真机、`arm64`/`x64` 模拟器 |
| macOS | `arm64`、`x64` |
| Windows | `x64`、`arm64` |
| Linux | `x64`、`arm64` |

## 原生库与 Release

每次 OpenCC 版本更新时，维护者推送 `opencc-v<版本>` tag，GitHub Actions 会构建并
发布以下产物：

```text
opencc-android-arm64.zip
opencc-android-arm.zip
opencc-android-x64.zip
opencc-android-x86.zip
opencc-ios-iphoneos-arm64.zip
opencc-ios-iphonesimulator-arm64.zip
opencc-macos-arm64.zip
opencc-macos-x64.zip
opencc-windows-x64.zip
opencc-windows-arm64.zip
opencc-linux-x64.zip
opencc-linux-arm64.zip
```

每个 zip 都附带 `.sha256` 文件。build hook 会下载对应平台的 zip、校验 SHA-256、
解压共享库并注册为 native code asset。

开发时可以通过 `hooks.user_defines` 覆盖默认行为：

```yaml
hooks:
  user_defines:
    flutter_opencc:
      base_url: https://example.com/releases
      local_dir: path/to/prebuilt/library
```

## 示例工程

完整演示应用位于 [example](example/)，支持 16 个配置、直接/流式转换和快捷示例：

```bash
cd example
flutter pub get
flutter run
```

## 开发与维护

- [IMPLEMENTATION.md](IMPLEMENTATION.md)：完整实现说明。
- [TASKS.md](TASKS.md)：发布前任务清单。
- [CONTRIBUTING.md](CONTRIBUTING.md)：贡献指南。

## License

本项目使用 [Apache License 2.0](LICENSE)，其中包含 OpenCC 预编译库和词库资源，
OpenCC 的相关归属信息见 [NOTICE](NOTICE)。
