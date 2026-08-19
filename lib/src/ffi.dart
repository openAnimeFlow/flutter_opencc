import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:math' as math;

import 'package:ffi/ffi.dart';

import 'lib_opencc.dart' as bindings;

/// Loads the OpenCC shared library for the current platform.
ffi.DynamicLibrary loadOpenCCLibrary({String? libraryPath}) {
  if (libraryPath != null && libraryPath.isNotEmpty) {
    return ffi.DynamicLibrary.open(libraryPath);
  }
  if (Platform.isWindows) {
    return ffi.DynamicLibrary.open('opencc.dll');
  }
  if (Platform.isLinux) {
    return ffi.DynamicLibrary.open('libopencc.so');
  }
  if (Platform.isMacOS) {
    return ffi.DynamicLibrary.open('libopencc.dylib');
  }
  throw UnsupportedError(
    'OpenCC is not supported on ${Platform.operatingSystem}.',
  );
}

/// Loads the generated OpenCC bindings.
bindings.FlutterOpenCCBindings loadOpenCCBindings({String? libraryPath}) {
  return bindings.FlutterOpenCCBindings(
    loadOpenCCLibrary(libraryPath: libraryPath),
  );
}

/// A managed UTF-8 buffer passed to the OpenCC C API.
final class CharArray {
  CharArray.fromString(String value) : _length = 0 {
    final bytes = utf8.encode(value);
    _length = bytes.length;
    _data = calloc<ffi.Uint8>(bytes.length + 1);
    _data.asTypedList(bytes.length).setAll(0, bytes);
  }

  CharArray.empty(int size) : _length = size {
    _data = calloc<ffi.Uint8>(size + 1);
  }

  late ffi.Pointer<ffi.Uint8> _data;
  int _length;
  bool _disposed = false;

  ffi.Pointer<ffi.Char> get pointer => _data.cast<ffi.Char>();

  int get length => _length;

  void resize(int size) {
    _ensureNotDisposed();
    final next = calloc<ffi.Uint8>(size + 1);
    final copyLength = math.min(_length, size);
    next.asTypedList(copyLength).setAll(0, _data.asTypedList(copyLength));
    calloc.free(_data);
    _data = next;
    _length = size;
  }

  String asString() {
    _ensureNotDisposed();
    return utf8.decode(_data.asTypedList(_length));
  }

  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    calloc.free(_data);
  }

  void _ensureNotDisposed() {
    if (_disposed) {
      throw StateError('CharArray has been disposed.');
    }
  }
}

/// Converts a Dart string to a Windows `wchar_t` string.
ffi.Pointer<ffi.WChar> toWideString(String value) {
  final codeUnits = value.codeUnits;
  final data = calloc<ffi.Uint16>(codeUnits.length + 1);
  final view = data.asTypedList(codeUnits.length);
  view.setAll(0, codeUnits);
  data[codeUnits.length] = 0;
  return data.cast<ffi.WChar>();
}

void freeWideString(ffi.Pointer<ffi.WChar> pointer) {
  calloc.free(pointer.cast<ffi.Uint16>());
}
