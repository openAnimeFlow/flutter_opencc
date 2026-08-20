import 'dart:convert';
import 'dart:io';

import 'package:flutter_opencc/flutter_opencc.dart';

const _usage = '''
Usage: dart run flutter_opencc [options] [<text|file>...]

Options:
  -c, --config <name>   OpenCC config name (default: s2t)
      --data-dir <dir>  Directory containing config JSON and .ocd2 files
                        (optional; auto-resolved when omitted)
  -i, --in-place        Rewrite input files in place
  -h, --help            Show this help

With no text or file arguments, input is read from stdin.
''';

Future<void> main(List<String> args) async {
  if (args.contains('-h') || args.contains('--help') || args.isEmpty) {
    stdout.write(_usage);
    return;
  }

  var config = 's2t';
  String? dataDir;
  var inPlace = false;
  final inputs = <String>[];

  try {
    for (var i = 0; i < args.length; i++) {
      final arg = args[i];
      if (arg == '-c' || arg == '--config') {
        config = _nextValue(args, ++i, arg);
      } else if (arg == '--data-dir') {
        dataDir = _nextValue(args, ++i, arg);
      } else if (arg == '-i' || arg == '--in-place') {
        inPlace = true;
      } else if (arg.startsWith('--data-dir=')) {
        dataDir = arg.substring('--data-dir='.length);
      } else {
        inputs.add(arg);
      }
    }
  } catch (error) {
    stderr.writeln('error: $error');
    exitCode = 1;
    return;
  }

  final converter = await ZhConverter.createFromConfigName(
    config,
    dataDir: dataDir,
  );
  try {
    if (inputs.isEmpty) {
      final text = await utf8.decoder.bind(stdin).join();
      stdout.write(converter.convert(text));
    } else {
      for (final input in inputs) {
        if (File(input).existsSync()) {
          final original = File(input).readAsStringSync();
          final converted = converter.convert(original);
          if (inPlace) {
            File(input).writeAsStringSync(converted);
          } else {
            stdout.write(converted);
          }
        } else {
          stdout.writeln(converter.convert(input));
        }
      }
    }
  } catch (error) {
    stderr.writeln('error: $error');
    exitCode = 1;
  } finally {
    converter.dispose();
  }
}

String _nextValue(List<String> args, int index, String flag) {
  if (index >= args.length) {
    throw ArgumentError('Missing value for $flag');
  }
  return args[index];
}
