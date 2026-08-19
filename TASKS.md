# flutter_opencc 项目任务步骤清单

这份清单覆盖从项目初始化到发布维护的完整流程。每完成一项就勾选，并把每个阶段
的验收标准跑通后再进入下一阶段。

## 0. 项目初始化与决策

- [ ] 确定项目根目录，建议为 `C:\Coding\ProJect\flutter_opencc`。
- [ ] 确定包名 `flutter_opencc`、版本号和发布范围。
- [x] 固定 OpenCC 版本为 `ver.1.4.1`，不使用 `master`。
- [x] 确定发布策略：维护者/CI 构建预编译共享库，最终包只下载二进制。
- [x] 确定词库资源策略：方案 A，Flutter package assets 打包词库。
- [x] 确定支持平台和 ABI。
- [ ] 初始化 Git 仓库。
- [ ] 创建 `README.md`、`pubspec.yaml`、`.gitignore`。
- [ ] 确认 Dart SDK 和 Flutter 版本满足要求。

完成标准：

- 项目目录存在。
- `dart pub get` 成功。
- 平台和 OpenCC 版本已经写入文档。

## 1. OpenCC 源码与构建环境

- [x] 在维护构建目录 checkout OpenCC `ver.1.4.1`。
- [x] 确认源码包含 `deps/`，或准备好 FetchContent/子模块方式。
- [x] 确认 CMake、Python、词库生成工具可用。
- [x] 在宿主机跑通一次 `libopencc` 构建。
- [x] 跑通 `Dictionaries` 目标，生成 `.ocd2` 和 JSON 配置。
- [x] 用简单文本验证 `s2t`、`t2s` 转换结果。

完成标准：

- 本机能编译出 `libopencc.so`、`libopencc.dylib` 或 `opencc.dll`。
- 生成的词库和配置可以被 OpenCC 正常加载。

## 2. 原生库跨平台构建

- [ ] Linux x64 构建。
- [ ] Linux arm64 构建。
- [ ] Windows x64 构建。
- [ ] Windows arm64 构建。
- [ ] macOS arm64 构建。
- [ ] macOS x64 构建。
- [ ] iOS 真机 arm64 构建。
- [ ] iOS 模拟器 arm64 构建。
- [ ] Android `arm64-v8a` 构建。
- [ ] Android `armeabi-v7a` 构建。
- [ ] Android `x86_64` 构建。
- [ ] Android `x86` 构建，如需要。
- [ ] 关闭不需要的 Jieba 插件。
- [ ] 对每个产物检查动态库依赖和导出符号。
- [ ] 对每个平台执行一次原生冒烟转换。

完成标准：

- 每个目标平台都有独立构建脚本或 workflow。
- 每个动态库能单独加载并完成中文转换。
- 没有依赖不存在的系统库或路径。

## 3. 预编译产物打包与发布

- [ ] 确定 zip 命名规则。
- [ ] 将动态库和 `opencc/` 资源放入 zip。
- [ ] 为每个 zip 生成 SHA-256。
- [ ] 生成本地测试目录，模拟 hook 下载流程。
- [ ] 测试压缩包可以完整解压。
- [ ] 上传到 GitHub Release。
- [ ] 验证 Release 中的下载 URL。
- [ ] 验证代理或镜像下载方式。

建议命名：

```text
opencc-android-arm64.zip
opencc-ios-iphoneos-arm64.zip
opencc-ios-iphonesimulator-arm64.zip
opencc-macos-arm64.zip
opencc-macos-x64.zip
opencc-windows-x64.zip
opencc-windows-arm64.zip
opencc-linux-x64.zip
opencc-linux-arm64.zip
```

完成标准：

- 所有平台 zip 都可下载。
- 每个 zip 的 SHA-256 可验证。
- 解压后的动态库文件名与 `dylibFileName` 规则一致。

## 4. Dart 包骨架

- [x] 确认 `pubspec.yaml` 依赖正确。
- [x] 添加 `analysis_options.yaml`。
- [x] 添加 `ffigen.yaml`。
- [x] 创建 `lib/`、`lib/src/`、`bin/`、`test/` 目录。
- [x] 添加示例工程目录 `example/`。
- [x] 配置 `assets/opencc/`。
- [x] 运行 `dart pub get`。
- [x] 运行 `dart analyze`，确保无问题。

依赖建议：

```yaml
dependencies:
  archive: ^4.1.0
  code_assets: ^2.0.0
  ffi: ^2.2.0
  hooks: ^2.2.0
  path: ^1.9.0

dev_dependencies:
  ffigen: ^20.1.1
  lints: ^6.0.0
  test: ^1.25.15
```

完成标准：

- 包可以被 `flutter pub get` 和 `dart pub get` 解析。
- 静态分析无错误。

## 5. FFI 绑定

- [x] 准备 OpenCC 1.4.1 的 `src/opencc.h`。
- [x] 配置 `ffigen.yaml` 的 header 路径。
- [x] 生成 `lib/src/lib_opencc.dart`。
- [x] 检查 `opencc_open`、`opencc_close`、`opencc_convert_utf8_to_buffer`。
- [x] 检查 `opencc_convert_utf8`、`opencc_convert_utf8_free`、`opencc_error`。
- [x] 确认绑定文件名与 build hook 中 code asset 的 `name` 一致。
- [x] 运行 `dart analyze`。

完成标准：

- 绑定文件自动生成且可编译。
- asset id 默认为 `package:flutter_opencc/src/lib_opencc.dart`。

## 6. CharArray 与内存管理

- [x] 实现 Dart String 到 C UTF-8 缓冲区的转换。
- [x] 实现 C 缓冲区到 Dart String 的转换。
- [x] 支持自动扩容。
- [x] 支持安全释放。
- [x] 保证释放后不可再用。
- [x] 为 `dispose()` 增加幂等保护。

完成标准：

- 单元测试覆盖空字符串、中文、英文和长文本。
- 重复释放不会崩溃。

## 7. Build Hook

- [x] 创建 `hook/build.dart`。
- [x] 根据 `targetOS` 和 `targetArchitecture` 选择下载 URL。
- [x] 根据 iOS SDK 增加 `iphoneos` 或 `iphonesimulator` 后缀。
- [x] 实现 zip 下载和解压。
- [x] 实现 SHA-256 校验。
- [x] 提取动态库到 hook 输出目录。
- [x] 注册 `CodeAsset` 和 `DynamicLoadingBundled`。
- [x] 声明 hook 依赖，保证缓存正确。
- [x] 支持代理和镜像 URL。
- [x] 支持通过 `userDefines` 指定本地预编译目录。
- [x] 在 Windows/Linux/macOS 上跑通 `dart test`。
- [x] 在 Android/iOS 上跑通 `flutter build`。

完成标准：

- 不设置 `OPENCC_SHARED_DIR` 也能运行。
- 用户没有 NDK/Xcode/MSVC 也能构建 Flutter 应用。

## 8. 词库资源加载

- [x] 把 OpenCC 资源和配置放入 `assets/opencc/`。
- [x] 在 `pubspec.yaml` 中声明资源。
- [x] 实现运行时资源目录解析。
- [x] Android 支持从 Flutter assets 复制到可写目录。
- [x] iOS/macOS 支持 app bundle 资源绝对路径。
- [x] Windows/Linux 支持可执行文件旁目录或用户传入目录。
- [x] 支持 `ZhConverter(config, dataDir: ...)`。
- [x] 确保不依赖环境变量。

可选：

- [ ] 实现 C++ shim，使用 `FilesystemResourceProvider`。
- [ ] 评估 `ZipResourceProvider`，把资源压缩成单个 zip。

完成标准：

- 每个平台都能找到 `s2t.json` 和对应词库。
- 移动端首次运行后可以完成转换。

## 9. Dart API

- [x] 实现 `ZhConverter`。
- [x] 实现 `ZhTransformer`。
- [x] 支持全部 OpenCC 配置名。
- [x] 支持自定义 `dataDir`。
- [x] 转换失败抛出明确错误。
- [x] 保证 `dispose()` 幂等。
- [x] 记录并发使用限制。

完成标准：

- `ZhConverter('s2t').convert(...)` 可用。
- `ZhTransformer('t2s')` 可用。
- 空字符串、空白、长文本、混排文本测试通过。

## 10. CLI

- [x] 支持 `-c s2t` 等配置参数。
- [x] 支持 `--data-dir`。
- [x] 支持文本参数。
- [x] 支持文件参数。
- [x] 支持标准输入输出。
- [x] 支持 `-i` 原地替换。
- [x] 支持 `-h` 帮助。
- [x] 完善错误提示和退出码。

完成标准：

- 桌面端可以直接用 `dart run flutter_opencc` 完成转换。
- 文件和文本两种输入都可用。

## 11. 测试

- [ ] 添加 `s2t` 单元测试。
- [ ] 添加 `t2s` 单元测试。
- [ ] 添加空字符串和空白测试。
- [ ] 添加中文英文混排测试。
- [ ] 添加多字节 UTF-8 测试。
- [ ] 添加长文本测试。
- [ ] 添加流式分块测试。
- [ ] 添加错误配置测试。
- [ ] 添加重复 `dispose()` 测试。
- [ ] 添加各平台 smoke test。
- [ ] 添加 Android 模拟器集成测试。
- [ ] 添加 iOS 模拟器集成测试。
- [ ] 添加桌面平台集成测试。

完成标准：

- `dart analyze` 无错误。
- `dart test` 全绿。
- Flutter 示例工程在目标平台全绿。

## 12. CI

- [x] 创建原生库构建 workflow。
- [x] 创建 Dart 静态分析 workflow。
- [x] 创建 Windows/Linux/macOS 测试 workflow。
- [x] 创建 Android 构建测试 workflow。
- [x] 创建 iOS 构建测试 workflow。
- [x] 对 Release 产物做 SHA-256 校验。
- [ ] 验证多架构矩阵。
- [ ] 验证缓存和失败重试。

完成标准：

- push/PR 自动触发测试。
- tag 自动触发原生库构建和发布。
- 没有平台被静默跳过。

## 13. 文档

- [ ] 编写 README。
- [ ] 编写 API 使用示例。
- [ ] 编写 CLI 使用示例。
- [ ] 编写平台支持表。
- [ ] 编写 OpenCC 版本和 ABI 说明。
- [ ] 编写发布产物说明。
- [ ] 编写贡献指南。
- [ ] 补充 LICENSE 和 NOTICE。

完成标准：

- 新用户能照着 README 完成安装和使用。
- 维护者能照着文档重建所有平台产物。

## 14. 发布

- [ ] 更新 `CHANGELOG.md`。
- [ ] 更新包版本号。
- [ ] 打 `opencc-v1.4.1` tag，触发原生库发布。
- [ ] 验证 GitHub Release 产物。
- [ ] 打 `v0.1.0` tag，发布 pub.dev。
- [ ] 在示例工程中安装已发布版本。
- [ ] 验证最终包不包含 OpenCC C++ 源码。
- [ ] 验证最终包不依赖 `.dart_tool/share`。

完成标准：

- pub.dev 包可以被新工程直接安装。
- 安装后无需额外手动拷贝资源即可转换。

## 15. 维护

- [ ] 建立 OpenCC 版本更新流程。
- [ ] 建立词库更新流程。
- [ ] 建立 ABI 变化检测流程。
- [ ] 建立 issue 模板和测试样例收集方式。
- [ ] 记录已知限制，例如 isolate、并发、Jieba 插件。

## 16. 最终验收

- [ ] Android 模拟器转换成功。
- [ ] iOS 模拟器转换成功。
- [ ] macOS 转换成功。
- [ ] Windows 转换成功。
- [ ] Linux 转换成功。
- [ ] 不设置任何环境变量也能转换。
- [ ] 构建过程不需要用户安装 C++ 工具链。
- [ ] 所有 Release 产物带版本号和校验和。
- [ ] `dart analyze` 无错误。
- [ ] `dart test` 全绿。
