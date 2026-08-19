import 'dart:io';

import 'package:path/path.dart' as p;

const nativeBuildSkipReason = 'local OpenCC build not found';

/// Returns the first local OpenCC resource directory found under
/// `build/opencc/<target>/install/share/opencc`.
String? localOpenCCDataDir() {
  final root = Directory(p.join('build', 'opencc'));
  if (!root.existsSync()) {
    return null;
  }
  for (final entry in root.listSync(followLinks: false)) {
    if (entry is! Directory) {
      continue;
    }
    final dataDir = p.join(entry.path, 'install', 'share', 'opencc');
    if (File(p.join(dataDir, 's2t.json')).existsSync()) {
      return dataDir;
    }
  }
  return null;
}

bool get hasLocalOpenCCBuild => localOpenCCDataDir() != null;
