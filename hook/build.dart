import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:code_assets/code_assets.dart';
import 'package:crypto/crypto.dart' show sha256;
import 'package:hooks/hooks.dart';

const _assetName = 'src/lib_opencc.dart';
// Override with userDefines `base_url` until the first release exists.
const _defaultBaseUrl =
    'https://github.com/openAnimeFlow/flutter_opencc_plus/releases/latest/download';

void main(List<String> args) async {
  await build(args, (input, output) async {
    if (!input.config.buildCodeAssets) {
      return;
    }

    final targetOS = input.config.code.targetOS;
    final targetArchitecture = input.config.code.targetArchitecture;
    final iOSSdk = targetOS == OS.iOS ? input.config.code.iOS.targetSdk : null;
    final archiveName = _archiveName(targetOS, targetArchitecture, iOSSdk);
    final libraryName = targetOS.dylibFileName('opencc');
    final outputDirectory = Directory.fromUri(input.outputDirectory)
      ..createSync(recursive: true);
    final libraryFile = File.fromUri(outputDirectory.uri.resolve(libraryName));

    final localDirectory = _localPrebuiltDirectory(
      input,
      targetOS,
      targetArchitecture,
      iOSSdk,
    );
    if (localDirectory != null) {
      final source = File.fromUri(localDirectory.resolve(libraryName));
      if (!source.existsSync()) {
        throw StateError('Local OpenCC library not found: ${source.path}');
      }
      if (!libraryFile.existsSync()) {
        source.copySync(libraryFile.path);
      }
      output.dependencies.add(source.uri);
    } else {
      final baseUrl =
          input.userDefines['base_url'] as String? ?? _defaultBaseUrl;
      final archiveUri = Uri.parse('$baseUrl/$archiveName');
      final archiveFile = File.fromUri(
        outputDirectory.uri.resolve(archiveName),
      );
      if (!archiveFile.existsSync()) {
        await _download(archiveUri, archiveFile);
      }
      await _verifySha256(
        archiveFile,
        Uri.parse('$baseUrl/$archiveName.sha256'),
      );
      output.dependencies.add(archiveFile.uri);

      final archiveInput = InputFileStream(archiveFile.path);
      try {
        final archive = ZipDecoder().decodeStream(archiveInput);
        final entry = archive.find(libraryName);
        if (entry == null || !entry.isFile) {
          throw StateError('$archiveName does not contain $libraryName');
        }
        if (!libraryFile.existsSync()) {
          final output = OutputFileStream(libraryFile.path);
          try {
            entry.writeContent(output);
          } finally {
            output.closeSync();
          }
        }
      } finally {
        archiveInput.closeSync();
      }
    }

    output.assets.code.add(
      CodeAsset(
        package: input.packageName,
        name: _assetName,
        linkMode: DynamicLoadingBundled(),
        file: libraryFile.uri,
      ),
    );
  });
}

String _archiveName(
  OS targetOS,
  Architecture targetArchitecture,
  IOSSdk? iOSSdk,
) {
  final sdkSuffix = iOSSdk == null ? '' : '-${iOSSdk.type}';
  return 'opencc-${targetOS.name}-${targetArchitecture.name}$sdkSuffix.zip';
}

Uri? _localPrebuiltDirectory(
  BuildInput input,
  OS targetOS,
  Architecture targetArchitecture,
  IOSSdk? iOSSdk,
) {
  final userDefined = input.userDefines.path('local_dir');
  if (userDefined != null) {
    return Directory.fromUri(userDefined).uri;
  }
  if (input.userDefines['base_url'] != null) {
    return null;
  }
  final relativeDirectory = switch ((targetOS.name, targetArchitecture.name)) {
    ('windows', 'x64') => 'build/opencc/windows-x64/install/bin',
    ('linux', 'x64') => 'build/opencc/linux-x64/install/lib',
    ('linux', 'arm64') => 'build/opencc/linux-arm64/install/lib',
    ('macos', 'x64') => 'build/opencc/macos-x64/install/lib',
    ('macos', 'arm64') => 'build/opencc/macos-arm64/install/lib',
    ('android', 'arm64') => 'build/opencc/android-arm64/install/lib',
    ('android', 'arm') => 'build/opencc/android-arm/install/lib',
    ('android', 'x64') => 'build/opencc/android-x64/install/lib',
    ('android', 'ia32') => 'build/opencc/android-x86/install/lib',
    ('ios', final architecture) when iOSSdk != null =>
      'build/opencc/ios-${iOSSdk.type}-$architecture/install/lib',
    _ => null,
  };
  if (relativeDirectory == null) {
    return null;
  }
  final developmentDirectory = input.packageRoot.resolve(relativeDirectory);
  if (!Directory.fromUri(developmentDirectory).existsSync()) {
    return null;
  }
  return Directory.fromUri(developmentDirectory).uri;
}

Future<void> _download(Uri uri, File target) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(uri);
    final response = await request.close();
    if (response.statusCode != HttpStatus.ok) {
      throw StateError('Failed to download $uri: ${response.statusCode}');
    }
    await target.create(recursive: true);
    await response.pipe(target.openWrite());
  } finally {
    client.close(force: true);
  }
}

Future<void> _verifySha256(File archive, Uri expectedHashUri) async {
  final expectedText = (await _downloadText(expectedHashUri)).trim();
  final expectedHash = expectedText.split(RegExp(r'\s+')).first.toLowerCase();
  if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(expectedHash)) {
    throw StateError('Invalid SHA-256 in $expectedHashUri: $expectedText');
  }
  final actualHash = sha256.convert(await archive.readAsBytes()).toString();
  if (expectedHash != actualHash) {
    throw StateError(
      'SHA-256 mismatch for ${archive.path}: '
      'expected $expectedHash, found $actualHash',
    );
  }
}

Future<String> _downloadText(Uri uri) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(uri);
    final response = await request.close();
    if (response.statusCode != HttpStatus.ok) {
      throw StateError('Failed to download $uri: ${response.statusCode}');
    }
    return await response.transform(utf8.decoder).join();
  } finally {
    client.close(force: true);
  }
}
