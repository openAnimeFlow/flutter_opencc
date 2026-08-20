import 'dart:async';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as p;

import 'ffi.dart';
import 'lib_opencc.dart' as bindings;
import 'resources.dart';

/// Built-in OpenCC conversion configs.
///
/// Pass one of these values to [ZhConverter] or [ZhTransformer]. Use
/// [ZhConverter.fromConfigName] when a custom config file is required.
enum OpenCCConfig {
  s2t('s2t'),
  t2s('t2s'),
  s2tw('s2tw'),
  tw2s('tw2s'),
  s2hk('s2hk'),
  hk2s('hk2s'),
  s2hkp('s2hkp'),
  hk2sp('hk2sp'),
  s2twp('s2twp'),
  tw2sp('tw2sp'),
  t2tw('t2tw'),
  tw2t('tw2t'),
  t2hk('t2hk'),
  hk2t('hk2t'),
  t2jp('t2jp'),
  jp2t('jp2t');

  const OpenCCConfig(this.configName);

  /// The config file name without the `.json` suffix.
  final String configName;

  /// Resolves a built-in config from [configName], accepting an optional
  /// `.json` suffix. Returns `null` for unknown or custom configs.
  static OpenCCConfig? fromConfigName(String configName) {
    final normalized = configName.endsWith('.json')
        ? configName.substring(0, configName.length - '.json'.length)
        : configName;
    for (final config in values) {
      if (config.configName == normalized) {
        return config;
      }
    }
    return null;
  }
}

/// Converts text between Chinese variants using OpenCC.
///
/// One instance is not safe to share across isolates; create one per isolate.
final class ZhConverter {
  ZhConverter(OpenCCConfig config, {String? dataDir})
    : _configPath = _resolveConfigPath(
        config.configName,
        dataDir ?? _resolveSyncDataDir(),
      ) {
    _handle = _openConverter(_configPath);
  }

  /// Creates a converter for a custom config name.
  factory ZhConverter.fromConfigName(String configName, {String? dataDir}) {
    return ZhConverter._fromConfigName(configName, dataDir: dataDir);
  }

  ZhConverter._fromConfigName(String configName, {String? dataDir})
    : _configPath = _resolveConfigPath(
        configName,
        dataDir ?? _resolveSyncDataDir(),
      ) {
    _handle = _openConverter(_configPath);
  }

  /// Resolves OpenCC resources, including Flutter assets, then opens a
  /// converter. Prefer this when no [dataDir] is supplied.
  static Future<ZhConverter> create(
    OpenCCConfig config, {
    String? dataDir,
  }) async {
    final resolved = await resolveOpenCCDataDir(dataDir: dataDir);
    return ZhConverter(config, dataDir: resolved);
  }

  /// Asynchronously creates a converter for a custom config name.
  static Future<ZhConverter> createFromConfigName(
    String configName, {
    String? dataDir,
  }) async {
    final resolved = await resolveOpenCCDataDir(dataDir: dataDir);
    return ZhConverter._fromConfigName(configName, dataDir: resolved);
  }

  final String _configPath;
  late final bindings.opencc_t _handle;
  bool _disposed = false;

  String convert(String text) {
    _ensureOpen();
    return _convertRaw(text);
  }

  /// Converts a batch of texts with a single native call when possible.
  ///
  /// The implementation joins the inputs with a control-character separator
  /// that does not appear in any input, calls the OpenCC C API once, and splits
  /// the result. If no safe separator is available, it falls back to one native
  /// call per item.
  List<String> convertAll(Iterable<String> texts) {
    _ensureOpen();
    final inputs = texts.toList(growable: false);
    if (inputs.isEmpty) {
      return const [];
    }
    if (inputs.length == 1) {
      return [convert(inputs.single)];
    }

    final separator = _batchSeparator(inputs);
    if (separator == null) {
      return [for (final text in inputs) _convertRaw(text)];
    }

    final output = _convertRaw(inputs.join(separator));
    final parts = output.split(separator);
    if (parts.length != inputs.length) {
      return [for (final text in inputs) _convertRaw(text)];
    }
    return parts;
  }

  String _convertRaw(String text) {
    final input = CharArray.fromString(text);
    try {
      final output = bindings.opencc_convert_utf8(
        _handle,
        input.pointer,
        input.length,
      );
      if (output.address == 0) {
        throw StateError('OpenCC conversion failed: ${_lastError()}');
      }
      try {
        return output.cast<Utf8>().toDartString();
      } finally {
        bindings.opencc_convert_utf8_free(output);
      }
    } finally {
      input.dispose();
    }
  }

  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    bindings.opencc_close(_handle);
  }

  void _ensureOpen() {
    if (_disposed) {
      throw StateError('ZhConverter has been disposed.');
    }
  }

  String _lastError() {
    final error = bindings.opencc_error();
    if (error.address == 0) {
      return 'unknown error';
    }
    return error.cast<Utf8>().toDartString();
  }

  String? _batchSeparator(List<String> inputs) {
    for (final separator in _batchSeparatorCandidates) {
      var used = false;
      for (final input in inputs) {
        if (input.contains(separator)) {
          used = true;
          break;
        }
      }
      if (!used) {
        return separator;
      }
    }
    return null;
  }

  static String _resolveConfigPath(String config, String dataDir) {
    final name = config.endsWith('.json') ? config : '$config.json';
    final path = p.join(dataDir, name);
    if (!File(path).existsSync()) {
      throw ArgumentError('OpenCC config not found: $path');
    }
    return path;
  }
}

const _batchSeparatorCandidates = [
  '\u0001',
  '\u0002',
  '\u0003',
  '\u0004',
  '\u0005',
  '\u0006',
  '\u0007',
  '\u0008',
  '\u000B',
  '\u000C',
  '\u000E',
  '\u000F',
  '\u0010',
  '\u0011',
  '\u0012',
  '\u0013',
  '\u0014',
  '\u0015',
  '\u0016',
  '\u0017',
  '\u0018',
  '\u0019',
  '\u001A',
  '\u001B',
  '\u001C',
  '\u001D',
  '\u001E',
  '\u001F',
  '\u007F',
  '\u2028',
  '\u2029',
  '\uFEFF',
];

/// A stream transformer that converts text in chunks.
final class ZhTransformer extends StreamTransformerBase<String, String> {
  ZhTransformer(OpenCCConfig config, {String? dataDir})
    : _converter = ZhConverter(config, dataDir: dataDir);

  /// Creates a transformer for a custom config name.
  factory ZhTransformer.fromConfigName(String configName, {String? dataDir}) {
    return ZhTransformer._fromConverter(
      ZhConverter.fromConfigName(configName, dataDir: dataDir),
    );
  }

  /// Resolves OpenCC resources, including Flutter assets, then creates a
  /// transformer.
  static Future<ZhTransformer> create(
    OpenCCConfig config, {
    String? dataDir,
  }) async {
    final converter = await ZhConverter.create(config, dataDir: dataDir);
    return ZhTransformer._fromConverter(converter);
  }

  /// Asynchronously creates a transformer for a custom config name.
  static Future<ZhTransformer> createFromConfigName(
    String configName, {
    String? dataDir,
  }) async {
    final converter = await ZhConverter.createFromConfigName(
      configName,
      dataDir: dataDir,
    );
    return ZhTransformer._fromConverter(converter);
  }

  ZhTransformer._fromConverter(this._converter);

  final ZhConverter _converter;

  @override
  Stream<String> bind(Stream<String> stream) async* {
    var pending = '';
    await for (final chunk in stream) {
      pending += chunk;
      while (true) {
        final newline = pending.indexOf('\n');
        if (newline < 0) {
          break;
        }
        final line = pending.substring(0, newline);
        pending = pending.substring(newline + 1);
        yield _converter.convert(line);
        yield '\n';
      }
    }
    if (pending.isNotEmpty) {
      yield _converter.convert(pending);
    }
  }

  void dispose() => _converter.dispose();
}

String _resolveSyncDataDir() {
  final resolved = resolveOpenCCDataDirSync();
  if (resolved == null) {
    throw StateError(
      'OpenCC resources not found in the filesystem. Pass dataDir or use '
      'await ZhConverter.create() inside a Flutter app.',
    );
  }
  return resolved;
}

bindings.opencc_t _openConverter(String configPath) {
  if (Platform.isWindows) {
    final wide = toWideString(configPath);
    try {
      return _checkHandle(bindings.opencc_open_w(wide));
    } finally {
      freeWideString(wide);
    }
  }
  final path = CharArray.fromString(configPath);
  try {
    return _checkHandle(bindings.opencc_open(path.pointer));
  } finally {
    path.dispose();
  }
}

bindings.opencc_t _checkHandle(bindings.opencc_t handle) {
  if (handle.address == 0xFFFFFFFFFFFFFFFF) {
    final error = bindings.opencc_error();
    final message = error.address == 0
        ? 'unknown error'
        : error.cast<Utf8>().toDartString();
    throw StateError('Failed to open OpenCC config: $message');
  }
  return handle;
}
