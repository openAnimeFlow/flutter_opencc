import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_opencc/flutter_opencc.dart';

void main() {
  runApp(const OpenCCExampleApp());
}

class _OpenCCConfig {
  const _OpenCCConfig(this.name, this.label, this.description);

  final String name;
  final String label;
  final String description;
}

class _Sample {
  const _Sample(this.label, this.text, this.config);

  final String label;
  final String text;
  final String config;
}

const _configs = <_OpenCCConfig>[
  _OpenCCConfig('s2t', '简 → 繁（标准）', 'OpenCC 标准简繁转换'),
  _OpenCCConfig('t2s', '繁 → 简（标准）', 'OpenCC 标准繁简转换'),
  _OpenCCConfig('s2tw', '简 → 繁（台湾）', '转换为台湾繁体字形'),
  _OpenCCConfig('tw2s', '繁（台湾）→ 简', '台湾繁体转换为简体'),
  _OpenCCConfig('s2hk', '简 → 繁（香港）', '转换为香港繁体字形'),
  _OpenCCConfig('hk2s', '繁（香港）→ 简', '香港繁体转换为简体'),
  _OpenCCConfig('s2hkp', '简 → 繁（香港常用词）', '香港字形并替换常用香港词'),
  _OpenCCConfig('hk2sp', '繁（香港）→ 简（大陆词）', '香港繁体转换为大陆简体词'),
  _OpenCCConfig('s2twp', '简 → 繁（台湾常用词）', '台湾字形并替换常用台湾词'),
  _OpenCCConfig('tw2sp', '繁（台湾）→ 简（大陆词）', '台湾繁体转换为大陆简体词'),
  _OpenCCConfig('t2tw', '繁（标准）→ 繁（台湾）', '标准繁体转台湾繁体'),
  _OpenCCConfig('tw2t', '繁（台湾）→ 繁（标准）', '台湾繁体转标准繁体'),
  _OpenCCConfig('t2hk', '繁（标准）→ 繁（香港）', '标准繁体转香港繁体'),
  _OpenCCConfig('hk2t', '繁（香港）→ 繁（标准）', '香港繁体转标准繁体'),
  _OpenCCConfig('t2jp', '旧字体 → 新字体', '旧日文汉字转新字体'),
  _OpenCCConfig('jp2t', '新字体 → 旧字体', '新字体转旧日文汉字'),
];

const _samples = <_Sample>[
  _Sample('简体', '开放中文转换 OpenCC', 's2t'),
  _Sample('繁体', '開放中文轉換 OpenCC', 't2s'),
  _Sample('台湾', '鼠标 内存 硬盘 网络', 's2twp'),
  _Sample('香港', '软件 鼠标 网络', 's2hk'),
  _Sample('新字体', '国 学 体', 'jp2t'),
  _Sample('旧字体', '國 學 體', 't2jp'),
];

class OpenCCExampleApp extends StatefulWidget {
  const OpenCCExampleApp({super.key});

  @override
  State<OpenCCExampleApp> createState() => _OpenCCExampleAppState();
}

class _OpenCCExampleAppState extends State<OpenCCExampleApp> {
  final _controller = TextEditingController(text: '开放中文转换 OpenCC');
  String _selectedConfig = 's2t';
  bool _useStreaming = false;
  bool _busy = false;
  String _output = '';
  String? _error;
  String? _stats;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _convert() async {
    final text = _controller.text;
    if (text.trim().isEmpty || _busy) {
      return;
    }
    setState(() {
      _busy = true;
      _output = '';
      _error = null;
      _stats = null;
    });

    try {
      if (_useStreaming) {
        await _convertStreaming(text);
      } else {
        await _convertDirect(text);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _output = '';
          _error = '$error';
          _stats = null;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _convertDirect(String text) async {
    final converter = await ZhConverter.create(_selectedConfig);
    try {
      final output = converter.convert(text);
      if (mounted) {
        setState(() {
          _output = output;
          _stats = null;
        });
      }
    } finally {
      converter.dispose();
    }
  }

  Future<void> _convertStreaming(String text) async {
    final transformer = await ZhTransformer.create(_selectedConfig);
    try {
      final chunks = _chunkText(text);
      final buffer = StringBuffer();
      await for (final part in Stream<String>.fromIterable(
        chunks,
      ).transform(transformer)) {
        buffer.write(part);
      }
      if (mounted) {
        setState(() {
          _output = buffer.toString();
          _stats = '${chunks.length} 个分块';
        });
      }
    } finally {
      transformer.dispose();
    }
  }

  void _useSample(_Sample sample) {
    _controller.text = sample.text;
    setState(() {
      _selectedConfig = sample.config;
      _output = '';
      _error = null;
      _stats = null;
    });
  }

  void _clear() {
    _controller.clear();
    setState(() {
      _output = '';
      _error = null;
      _stats = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final selected = _configs.firstWhere(
      (config) => config.name == _selectedConfig,
    );

    return MaterialApp(
      title: 'flutter_opencc example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00696D)),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('flutter_opencc example'),
          actions: [
            IconButton(
              tooltip: '清空',
              onPressed: _busy ? null : _clear,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DropdownButtonFormField<String>(
                initialValue: _selectedConfig,
                decoration: const InputDecoration(
                  labelText: '转换配置',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final config in _configs)
                    DropdownMenuItem(
                      value: config.name,
                      child: Text(config.label),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedConfig = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 8),
              Text(
                selected.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: '输入文本',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final sample in _samples)
                    ActionChip(
                      avatar: const Icon(Icons.text_fields, size: 18),
                      label: Text(sample.label),
                      onPressed: _busy ? null : () => _useSample(sample),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<bool>(
                  expandedInsets: EdgeInsets.zero,
                  segments: const [
                    ButtonSegment(
                      value: false,
                      icon: Icon(Icons.swap_horiz),
                      label: Text('直接'),
                    ),
                    ButtonSegment(
                      value: true,
                      icon: Icon(Icons.stream),
                      label: Text('流式'),
                    ),
                  ],
                  selected: {_useStreaming},
                  onSelectionChanged: (selection) {
                    setState(() {
                      _useStreaming = selection.first;
                    });
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _busy ? null : _convert,
                      icon: _busy
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.translate),
                      label: Text(_busy ? '转换中' : '转换'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: '清空',
                    onPressed: _busy ? null : _clear,
                    icon: const Icon(Icons.restart_alt),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.output, size: 18, color: colors.primary),
                        const SizedBox(width: 8),
                        Text('输出', style: theme.textTheme.titleSmall),
                        const Spacer(),
                        if (_stats != null)
                          Text(
                            _stats!,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_error != null)
                      Text(
                        _error!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.error,
                        ),
                      )
                    else if (_output.isEmpty)
                      Text(
                        '—',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      )
                    else
                      SelectableText(
                        _output,
                        style: theme.textTheme.titleMedium,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

List<String> _chunkText(String text, {int maxRunes = 64}) {
  final runes = text.runes.toList();
  if (runes.isEmpty) {
    return const [];
  }
  final chunks = <String>[];
  for (var start = 0; start < runes.length; start += maxRunes) {
    final end = math.min(start + maxRunes, runes.length);
    chunks.add(String.fromCharCodes(runes.sublist(start, end)));
  }
  return chunks;
}
