import 'package:flutter/material.dart';
import 'package:flutter_opencc/flutter_opencc.dart';

void main() {
  runApp(const OpenCCExampleApp());
}

class OpenCCExampleApp extends StatefulWidget {
  const OpenCCExampleApp({super.key});

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

  Future<void> _convert() async {
    final text = _controller.text;
    final converter = await ZhConverter.create('s2t');
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
