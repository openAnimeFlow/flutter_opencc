import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'asset_bundle_stub.dart'
    if (dart.library.ui) 'asset_bundle_flutter.dart';

const _openccDirName = 'opencc';

/// Resolves the directory that contains OpenCC JSON configs and .ocd2 files.
///
/// Resolution order:
/// 1. [dataDir], when provided.
/// 2. Filesystem locations: `<opencc>` next to the executable, below the
///    current directory, or in this package's source tree.
/// 3. Flutter asset bundle, extracted into a writable cache directory.
Future<String> resolveOpenCCDataDir({String? dataDir}) async {
  final filesystem = resolveOpenCCDataDirSync(dataDir: dataDir);
  if (filesystem != null) {
    return filesystem;
  }
  if (hasFlutterAssetBundle) {
    final extracted = await extractOpenCCDataDirFromFlutterAssets();
    if (extracted != null) {
      return extracted;
    }
  }
  throw StateError(
    'OpenCC resources not found. Pass dataDir, or use ZhConverter.create() '
    'inside a Flutter app that declares the flutter_opencc assets.',
  );
}

/// Synchronous filesystem-only lookup, used when no async resolution is
/// available or needed.
String? resolveOpenCCDataDirSync({String? dataDir}) {
  if (dataDir != null && dataDir.isNotEmpty) {
    _requireDataDir(dataDir);
    return dataDir;
  }
  for (final candidate in _filesystemCandidates()) {
    if (_hasOpenCCResources(candidate)) {
      return candidate;
    }
  }
  return null;
}

void _requireDataDir(String dataDir) {
  if (!_hasOpenCCResources(dataDir)) {
    throw ArgumentError(
      'OpenCC resources not found in dataDir: $dataDir '
      '(expected s2t.json).',
    );
  }
}

bool _hasOpenCCResources(String directory) {
  return File(p.join(directory, 's2t.json')).existsSync();
}

List<String> _filesystemCandidates() {
  final executableDirectory = p.dirname(Platform.resolvedExecutable);
  final candidates = <String>[
    p.join(executableDirectory, _openccDirName),
    if (!Platform.isWindows)
      p.join(executableDirectory, '..', 'share', _openccDirName),
    p.join(Directory.current.path, _openccDirName),
  ];
  final packageRoot = _packageRootFromConfig();
  if (packageRoot != null) {
    candidates.add(p.join(packageRoot, 'assets', _openccDirName));
  }
  if (Platform.script.isScheme('file')) {
    var directory = p.dirname(p.fromUri(Platform.script));
    for (var depth = 0; depth < 4; depth++) {
      candidates.add(p.join(directory, 'assets', _openccDirName));
      directory = p.dirname(directory);
    }
  }
  return candidates;
}

String? _packageRootFromConfig() {
  final configUriText = Platform.packageConfig;
  if (configUriText == null || configUriText.isEmpty) {
    return null;
  }
  final configUri = Uri.parse(configUriText);
  if (!configUri.isScheme('file') ||
      !File(p.fromUri(configUri)).existsSync()) {
    return null;
  }
  try {
    final decoded = jsonDecode(File(p.fromUri(configUri)).readAsStringSync());
    if (decoded is! Map<String, dynamic>) {
      return null;
    }
    final packages = decoded['packages'];
    if (packages is! List) {
      return null;
    }
    for (final entry in packages) {
      if (entry is Map<String, dynamic> &&
          entry['name'] == 'flutter_opencc' &&
          entry['rootUri'] is String) {
        final rootUri = configUri.resolveUri(
          Uri.parse(entry['rootUri'] as String),
        );
        if (rootUri.isScheme('file')) {
          return p.fromUri(rootUri);
        }
      }
    }
  } on Object {
    // A malformed package config should not break resource resolution.
  }
  return null;
}
