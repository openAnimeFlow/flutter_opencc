import 'dart:async';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as p;

import 'ffi.dart';
import 'lib_opencc.dart' as bindings;

/// Converts text between Chinese variants using OpenCC.
///
/// One instance is not safe to share across isolates; create one per isolate.
final class ZhConverter {
  ZhConverter(String config, {required String dataDir})
    : _configPath = _resolveConfigPath(config, dataDir) {
    _handle = _openConverter(_configPath);
  }

  final String _configPath;
  late final bindings.opencc_t _handle;
  bool _disposed = false;

  String convert(String text) {
    _ensureOpen();
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

  static String _resolveConfigPath(String config, String dataDir) {
    final name = config.endsWith('.json') ? config : '$config.json';
    final path = p.join(dataDir, name);
    if (!File(path).existsSync()) {
      throw ArgumentError('OpenCC config not found: $path');
    }
    return path;
  }
}

/// A stream transformer that converts text in chunks.
final class ZhTransformer extends StreamTransformerBase<String, String> {
  ZhTransformer(String config, {required String dataDir})
    : _converter = ZhConverter(config, dataDir: dataDir);

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
