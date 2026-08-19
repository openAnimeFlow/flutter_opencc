import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

const bool hasFlutterAssetBundle = true;
const String _assetPrefix = 'packages/flutter_opencc/assets/opencc/';

Future<String?> extractOpenCCDataDirFromFlutterAssets() async {
  final cacheDirectory = Directory(
    p.join(Directory.systemTemp.path, 'flutter_opencc_assets'),
  );
  if (File(p.join(cacheDirectory.path, 's2t.json')).existsSync()) {
    return cacheDirectory.path;
  }

  final assetNames = await _openccAssetNames();
  if (assetNames.isEmpty) {
    return null;
  }
  await cacheDirectory.create(recursive: true);
  for (final assetName in assetNames) {
    final relative = assetName.substring(_assetPrefix.length);
    final data = await rootBundle.load(assetName);
    final target = File(p.join(cacheDirectory.path, relative))
      ..createSync(recursive: true);
    await target.writeAsBytes(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      flush: true,
    );
  }
  return cacheDirectory.path;
}

Future<List<String>> _openccAssetNames() async {
  try {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    return manifest
        .listAssets()
        .where((name) => name.startsWith(_assetPrefix))
        .toList();
  } on Object {
    final text = await rootBundle.loadString('AssetManifest.json');
    final decoded = jsonDecode(text);
    if (decoded is Map<String, dynamic>) {
      return decoded.keys
          .where((name) => name.startsWith(_assetPrefix))
          .toList();
    }
    return const [];
  }
}
