import 'dart:io';

import 'package:flutter_opencc_plus/flutter_opencc_plus.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'package:flutter_opencc_plus/src/resources.dart';

void main() {
  test('package exposes its package name', () {
    expect(packageName, 'flutter_opencc_plus');
  });

  group('resources', () {
    test('sync resolution finds package assets', () {
      final dataDir = resolveOpenCCDataDirSync();
      expect(dataDir, isNotNull);
      expect(File(p.join(dataDir!, 's2t.json')).existsSync(), isTrue);
    });

    test('async resolution finds package assets', () async {
      final dataDir = await resolveOpenCCDataDir();
      expect(File(p.join(dataDir, 's2t.json')).existsSync(), isTrue);
    });

    test('rejects a dataDir without OpenCC resources', () {
      expect(
        () => resolveOpenCCDataDirSync(dataDir: Directory.systemTemp.path),
        throwsArgumentError,
      );
    });
  });
}
