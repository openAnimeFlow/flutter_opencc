import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart' show sha256;
import 'package:path/path.dart' as p;

Future<void> main(List<String> args) async {
  final options = _parseOptions(args);
  final target = options['--target']!;
  final source = options['--source']!;
  final build = options['--build']!;
  final install = options['--install']!;
  final package = options['--package']!;
  final cmake = options['--cmake'] ?? 'cmake';
  final generator = options['--generator'];

  await _run(cmake, _configureArgs(target, source, build, generator));
  await _run(cmake, [
    '--build',
    build,
    '--config',
    'Release',
    '--target',
    'libopencc',
    'Dictionaries',
    'opencc',
    'opencc_dict',
    'opencc_phrase_extract',
    '--parallel',
  ]);
  await _run(cmake, ['--install', build, '--prefix', install]);

  final archive = _createPackage(target, install);
  final bytes = ZipEncoder().encode(archive);
  File(package)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes);
  final hash = sha256.convert(bytes).toString();
  File('$package.sha256').writeAsStringSync('$hash  ${p.basename(package)}\n');
  stdout.writeln('Packaged ${p.basename(package)} ($hash)');
}

List<String> _configureArgs(
  String target,
  String source,
  String build,
  String? generator,
) {
  final common = <String>[
    '-S',
    source,
    '-B',
    build,
    '-DCMAKE_BUILD_TYPE=Release',
    '-DBUILD_SHARED_LIBS=ON',
    '-DBUILD_OPENCC_JIEBA_PLUGIN=OFF',
    '-DOPENCC_ENABLE_INSTALL=ON',
    '-DOPENCC_DICT_FORMAT=ocd2',
  ];
  switch (target) {
    case 'windows-x64':
      return [
        ...common,
        '-G',
        generator ?? 'Visual Studio 17 2022',
        '-A',
        'x64',
      ];
    case 'windows-arm64':
      return [
        ...common,
        '-G',
        generator ?? 'Visual Studio 17 2022',
        '-A',
        'arm64',
      ];
    case 'linux-x64':
    case 'linux-arm64':
      return common;
    case 'macos-x64':
      return [
        ...common,
        '-DCMAKE_OSX_ARCHITECTURES=x86_64',
        '-DCMAKE_OSX_DEPLOYMENT_TARGET=10.15',
      ];
    case 'macos-arm64':
      return [
        ...common,
        '-DCMAKE_OSX_ARCHITECTURES=arm64',
        '-DCMAKE_OSX_DEPLOYMENT_TARGET=10.15',
      ];
    case 'ios-iphoneos-arm64':
      return [
        ...common,
        '-DCMAKE_SYSTEM_NAME=iOS',
        '-DCMAKE_OSX_SYSROOT=iphoneos',
        '-DCMAKE_OSX_ARCHITECTURES=arm64',
        '-DCMAKE_OSX_DEPLOYMENT_TARGET=13.0',
      ];
    case 'ios-iphonesimulator-arm64':
      return [
        ...common,
        '-DCMAKE_SYSTEM_NAME=iOS',
        '-DCMAKE_OSX_SYSROOT=iphonesimulator',
        '-DCMAKE_OSX_ARCHITECTURES=arm64',
        '-DCMAKE_OSX_DEPLOYMENT_TARGET=13.0',
      ];
    case 'android-arm64':
      return [...common, ..._androidArgs('arm64-v8a')];
    case 'android-arm':
      return [...common, ..._androidArgs('armeabi-v7a')];
    case 'android-x64':
      return [...common, ..._androidArgs('x86_64')];
    case 'android-x86':
      return [...common, ..._androidArgs('x86')];
    default:
      throw ArgumentError('Unknown target: $target');
  }
}

List<String> _androidArgs(String abi) {
  final ndk =
      Platform.environment['ANDROID_NDK_LATEST_HOME'] ??
      Platform.environment['ANDROID_NDK_HOME'] ??
      Platform.environment['ANDROID_NDK'];
  if (ndk == null || ndk.isEmpty) {
    throw StateError(
      'Android NDK not found. Set ANDROID_NDK_LATEST_HOME or ANDROID_NDK_HOME.',
    );
  }
  final toolchain = p.join(ndk, 'build', 'cmake', 'android.toolchain.cmake');
  return [
    '-DCMAKE_TOOLCHAIN_FILE=$toolchain',
    '-DANDROID_ABI=$abi',
    '-DANDROID_PLATFORM=android-21',
  ];
}

Archive _createPackage(String target, String install) {
  final archive = Archive();
  final libraryName = _libraryFileName(target);
  final librarySource = _librarySource(target, install);
  final libraryFile = File(librarySource);
  if (!libraryFile.existsSync()) {
    throw StateError('Library not found: $librarySource');
  }
  archive.add(ArchiveFile.bytes(libraryName, libraryFile.readAsBytesSync()));

  final resources = Directory(p.join(install, 'share', 'opencc'));
  if (!resources.existsSync()) {
    throw StateError('OpenCC resources not found: ${resources.path}');
  }
  for (final file in resources.listSync(recursive: true).whereType<File>()) {
    final relative = p.relative(file.path, from: resources.path);
    final name = p.join('opencc', relative).replaceAll('\\', '/');
    archive.add(ArchiveFile.bytes(name, file.readAsBytesSync()));
  }
  return archive;
}

String _libraryFileName(String target) {
  if (target.startsWith('windows')) {
    return 'opencc.dll';
  }
  if (target.startsWith('macos') || target.startsWith('ios')) {
    return 'libopencc.dylib';
  }
  return 'libopencc.so';
}

String _librarySource(String target, String install) {
  final directory = target.startsWith('windows') ? 'bin' : 'lib';
  return p.join(install, directory, _libraryFileName(target));
}

Map<String, String> _parseOptions(List<String> args) {
  if (args.isEmpty || args.length.isOdd) {
    throw ArgumentError(
      'Usage: dart tool/build_opencc.dart '
      '--target <name> --source <dir> --build <dir> '
      '--install <dir> --package <zip> [--cmake <cmake>] '
      '[--generator <generator>]',
    );
  }
  return {for (var i = 0; i < args.length; i += 2) args[i]: args[i + 1]};
}

Future<void> _run(String executable, List<String> arguments) async {
  final result = await Process.run(executable, arguments);
  stdout.write(result.stdout);
  stderr.write(result.stderr);
  if (result.exitCode != 0) {
    throw StateError(
      '$executable ${arguments.join(' ')} failed with exit code '
      '${result.exitCode}',
    );
  }
}
