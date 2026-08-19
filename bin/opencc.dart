import 'dart:io';

/// Skeleton CLI. Conversion support lands in a later milestone.
void main(List<String> args) {
  if (args.isEmpty || args.contains('-h') || args.contains('--help')) {
    stdout.writeln('Usage: dart run flutter_opencc -c <config> [<file>]');
    return;
  }
  stderr.writeln('flutter_opencc CLI is not implemented yet.');
  exitCode = 1;
}
