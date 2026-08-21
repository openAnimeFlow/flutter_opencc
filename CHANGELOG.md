# Changelog

## 0.1.1

- 修复 iOS 构建时 release 产物 URL 命名顺序错误的问题。

## 0.1.0

- 首个正式发布版本。
- 支持全部 16 个 OpenCC 1.4.1 内置配置。
- 提供同步 `ZhConverter`、流式 `ZhTransformer` 和批量 `convertAll` API。
- 提供 `run` / `runFromConfigName` 作用域 API，自动释放原生句柄。
- 支持 Android、iOS、macOS、Windows、Linux 原生共享库。
- 词库资源随 Flutter package assets 打包，运行时自动解析。
- 内置 CLI，支持文本参数、文件、标准输入输出和原地替换。
- 非汉字内容（标点、英文、数字、换行、Emoji）原样保留。
