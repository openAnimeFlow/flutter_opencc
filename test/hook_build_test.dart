import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:crypto/crypto.dart' show sha256;
import 'package:hooks/hooks.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:zip2/zip2.dart';

import '../hook/build.dart' as hook;

void main() {
  final localDir = p.join('build', 'opencc', 'windows-x64', 'install', 'bin');
  final sourceDll = File(p.join(localDir, 'opencc.dll'));

  test(
    'bundles the local OpenCC library as a code asset',
    () async {
      await testCodeBuildHook(
        mainMethod: hook.main,
        check: (input, output) {
          final assets = output.assets.code;
          expect(assets, hasLength(1));
          expect(
            assets.single.id,
            'package:flutter_opencc/src/lib_opencc.dart',
          );
          expect(assets.single.linkMode, isA<DynamicLoadingBundled>());
          expect(File.fromUri(assets.single.file!).existsSync(), isTrue);
        },
        userDefines: PackageUserDefines(
          workspacePubspec: PackageUserDefinesSource(
            defines: {'local_dir': localDir},
            basePath: Directory.current.uri,
          ),
        ),
      );
    },
    skip:
        Directory(
          p.join('build', 'opencc', 'windows-x64', 'install'),
        ).existsSync()
        ? false
        : 'local OpenCC build not found',
  );

  test('downloads, verifies, and extracts a release zip', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'flutter_opencc_hook_test_',
    );
    addTearDown(() => tempDir.deleteSync(recursive: true));

    const archiveName = 'opencc-windows-x64.zip';
    final archiveFile = File(p.join(tempDir.path, archiveName));
    final archive = ZipArchive([
      ZipFileEntry(
        name: 'opencc.dll',
        data: Stream.value(sourceDll.readAsBytesSync()),
        method: ZipMethod.stored,
      ),
    ]);
    await archive.zip().pipe(archiveFile.openWrite());

      final hash = sha256.convert(await archiveFile.readAsBytes()).toString();
    await File(
      p.join(tempDir.path, '$archiveName.sha256'),
    ).writeAsString('$hash  $archiveName\n');

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) {
      final name = request.uri.pathSegments.isEmpty
          ? ''
          : request.uri.pathSegments.last;
      final file = File(p.join(tempDir.path, name));
      if (file.existsSync()) {
        request.response.headers.contentType = ContentType.binary;
        request.response.add(file.readAsBytesSync());
      } else {
        request.response.statusCode = HttpStatus.notFound;
      }
      request.response.close();
    });

    await testCodeBuildHook(
      mainMethod: hook.main,
      targetOS: OS.windows,
      targetArchitecture: Architecture.x64,
      check: (input, output) {
        final assets = output.assets.code;
        expect(assets, hasLength(1));
        expect(File.fromUri(assets.single.file!).existsSync(), isTrue);
      },
      userDefines: PackageUserDefines(
        workspacePubspec: PackageUserDefinesSource(
          defines: {'base_url': 'http://127.0.0.1:${server.port}'},
          basePath: Directory.current.uri,
        ),
      ),
    );
  }, skip: sourceDll.existsSync() ? false : 'local OpenCC build not found');
}
