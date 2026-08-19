import 'package:flutter/material.dart';
import 'package:flutter_opencc/flutter_opencc.dart';

const _defaultDataDir = String.fromEnvironment('FLUTTER_OPENCC_DATA_DIR');

void main() {
  runApp(const OpenCCExampleApp());
}

class OpenCCExampleApp extends StatefulWidget {
  const OpenCCExampleApp({super.key, this.dataDir = _defaultDataDir});

  final String dataDir;

  @override
  State<OpenCCExampleApp> createState() => _OpenCCExampleAppState();
}

class _OpenCCExampleAppState extends State<OpenCCExampleApp> {
  final _controller = TextEditingController(text: '开放中文转换');
  String _output = '';
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _convert() {
    final text = _controller.text;
    if (widget.dataDir.isEmpty) {
      setState(() {
        _error = 'Set FLUTTER_OPENCC_DATA_DIR to the OpenCC data directory.';
        _output = '';
      });
      return;
    }

    final converter = ZhConverter('s2t', dataDir: widget.dataDir);
    try {
      final output = converter.convert(text);
      setState(() {
        _output = output;
        _error = null;
      });
    } catch (error) {
      setState(() {
        _error = '$error';
        _output = '';
      });
    } finally {
      converter.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'flutter_opencc example',
      home: Scaffold(
        appBar: AppBar(title: const Text('flutter_opencc example')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Simplified Chinese',
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _convert,
                icon: const Icon(Icons.swap_horiz),
                label: const Text('Convert'),
              ),
              const SizedBox(height: 16),
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                )
              else
                SelectableText(
                  _output,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
