# Contributing

感谢你愿意为 `flutter_opencc_plus` 贡献代码。提交前请先阅读
[IMPLEMENTATION.md](IMPLEMENTATION.md) 和 [TASKS.md](TASKS.md)，保持实现方式和
任务清单同步更新。

## 环境准备

1. Fork 并克隆仓库。
2. 安装 Flutter stable，确保 `flutter doctor` 通过。
3. 获取固定版本的 OpenCC 源码：

   ```bash
   git clone --depth 1 --branch ver.1.4.1 --recurse-submodules \
     https://github.com/BYVoid/OpenCC.git third_party/opencc
   ```

4. 安装依赖：

   ```bash
   flutter pub get
   cd example && flutter pub get
   ```

## 本地验证

每次改动后至少运行：

```bash
dart format .
dart analyze
dart test
cd example && flutter analyze && flutter test
```

涉及原生构建时，在对应主机上构建目标平台并运行 smoke test：

```bash
dart tool/build_opencc.dart \
  --target <platform> \
  --source third_party/opencc \
  --build build/opencc/<platform> \
  --install build/opencc/<platform>/install \
  --package build/opencc/<platform>/opencc-<platform>.zip
```

Android/iOS 构建需要 NDK 或 Xcode。构建脚本会优先使用本地预编译目录，避免每次
构建都下载 Release 产物。

## 提交要求

- 使用 `dart format` 格式化 Dart 代码。
- `dart analyze` 和 `dart test` 必须通过。
- 不直接修改 `lib/src/lib_opencc.dart`，它由 `ffigen` 自动生成。
- 不提交 `third_party/opencc/` 源码和 `build/` 产物。
- 修改行为时同步更新 `IMPLEMENTATION.md`、README 和对应测试。
- 新功能提交 PR 时附带测试。

## 发布流程

发布预编译 OpenCC 原生库：

1. 更新 `third_party/opencc.version`。
2. 推送 `opencc-v<版本>` tag。
3. 等待 `Build Native Assets` workflow 完成。
4. 验证 GitHub Release 中的 zip 和 `.sha256`。

发布 Dart/Flutter 包：

1. 更新 `CHANGELOG.md` 和 `pubspec.yaml` 版本号。
2. 推送 `v<版本>` tag。
3. 使用 `dart pub publish` 发布到 pub.dev。
