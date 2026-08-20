import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_opencc/flutter_opencc.dart';

void main() {
  runApp(const OpenCCExampleApp());
}

const _primary = Color(0xFF4F46E5);
const _background = Color(0xFFF3F4F6);
const _surfaceMuted = Color(0xFFFAFAFA);
const _border = Color(0xFFE5E7EB);
const _textMain = Color(0xFF1F2937);
const _textSub = Color(0xFF6B7280);

class OpenCCExampleApp extends StatelessWidget {
  const OpenCCExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OpenCC 转换工具',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: _primary),
        scaffoldBackgroundColor: _background,
      ),
      home: const _ConverterPage(),
    );
  }
}

class _OpenCCConfig {
  const _OpenCCConfig(
    this.config,
    this.source,
    this.target,
    this.phrase,
    this.description,
  );

  final OpenCCConfig config;
  final String source;
  final String target;
  final bool phrase;
  final String description;

  String get name => config.configName;
}

const _configs = <_OpenCCConfig>[
  _OpenCCConfig(OpenCCConfig.s2t, 's', 't', false, '简体中文转 OpenCC 标准繁体'),
  _OpenCCConfig(OpenCCConfig.t2s, 't', 's', false, 'OpenCC 标准繁体转简体中文'),
  _OpenCCConfig(OpenCCConfig.s2tw, 's', 'tw', false, '简体中文转台湾正体'),
  _OpenCCConfig(OpenCCConfig.tw2s, 'tw', 's', false, '台湾正体转简体中文'),
  _OpenCCConfig(OpenCCConfig.s2hk, 's', 'hk', false, '简体中文转香港繁体'),
  _OpenCCConfig(OpenCCConfig.hk2s, 'hk', 's', false, '香港繁体转简体中文'),
  _OpenCCConfig(OpenCCConfig.s2hkp, 's', 'hk', true, '简体中文转香港繁体并替换常用词'),
  _OpenCCConfig(OpenCCConfig.hk2sp, 'hk', 's', true, '香港繁体转简体中文并替换大陆词'),
  _OpenCCConfig(OpenCCConfig.s2twp, 's', 'tw', true, '简体中文转台湾正体并替换常用词'),
  _OpenCCConfig(OpenCCConfig.tw2sp, 'tw', 's', true, '台湾正体转简体中文并替换大陆词'),
  _OpenCCConfig(OpenCCConfig.t2tw, 't', 'tw', false, 'OpenCC 标准繁体转台湾正体'),
  _OpenCCConfig(OpenCCConfig.tw2t, 'tw', 't', false, '台湾正体转 OpenCC 标准繁体'),
  _OpenCCConfig(OpenCCConfig.t2hk, 't', 'hk', false, 'OpenCC 标准繁体转香港繁体'),
  _OpenCCConfig(OpenCCConfig.hk2t, 'hk', 't', false, '香港繁体转 OpenCC 标准繁体'),
  _OpenCCConfig(OpenCCConfig.t2jp, 't', 'jp', false, '旧日文汉字转新字体'),
  _OpenCCConfig(OpenCCConfig.jp2t, 'jp', 't', false, '新字体转旧日文汉字'),
];

const _localeTitles = <String, String>{
  's': '简体中文 (s)',
  'tw': '台湾正体 (tw)',
  'hk': '香港繁体 (hk)',
  't': 'OpenCC 标准繁体 (t)',
  'jp': '日文新字体 (jp)',
};

class _ConverterPage extends StatefulWidget {
  const _ConverterPage();

  @override
  State<_ConverterPage> createState() => _ConverterPageState();
}

class _ConverterPageState extends State<_ConverterPage> {
  final _inputController = TextEditingController(text: '开放中文转换 OpenCC');
  final _batchController = TextEditingController(text: '开放中文转换\n鼠标与软件\n网络');
  Timer? _debounce;
  Timer? _copiedTimer;
  String _source = 's';
  String _target = 't';
  bool _phrases = false;
  bool _busy = false;
  bool _showDiff = false;
  bool _copied = false;
  String _output = '';
  String? _error;
  String _status = '就绪';
  int _conversionVersion = 0;
  bool _batchBusy = false;
  String _batchOutput = '';
  String? _batchError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scheduleConversion());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _copiedTimer?.cancel();
    _inputController.dispose();
    _batchController.dispose();
    super.dispose();
  }

  OpenCCConfig? get _resolvedConfig {
    if (_source == _target) {
      return null;
    }
    final base = '${_source}2$_target';
    if (_phrases) {
      return switch (base) {
        's2tw' => OpenCCConfig.s2twp,
        's2hk' => OpenCCConfig.s2hkp,
        'tw2s' => OpenCCConfig.tw2sp,
        'hk2s' => OpenCCConfig.hk2sp,
        _ => null,
      };
    }
    return OpenCCConfig.fromConfigName(base);
  }

  bool get _canUsePhrases {
    return _source != _target &&
        (_source == 's' && (_target == 'tw' || _target == 'hk') ||
            (_source == 'tw' || _source == 'hk') && _target == 's');
  }

  void _scheduleConversion() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _convert);
  }

  Future<void> _convert() async {
    _debounce?.cancel();
    final version = ++_conversionVersion;
    final input = _inputController.text;
    final config = _resolvedConfig;

    if (input.isEmpty) {
      if (mounted && version == _conversionVersion) {
        setState(() {
          _output = '';
          _error = null;
          _busy = false;
          _status = '就绪';
        });
      }
      return;
    }

    if (mounted && version == _conversionVersion) {
      setState(() {
        _busy = true;
        _status = '转换中...';
      });
    }

    try {
      final output = config == null ? input : await _convertWith(config, input);
      if (!mounted ||
          version != _conversionVersion ||
          _inputController.text != input) {
        return;
      }
      setState(() {
        _output = output;
        _error = null;
        _busy = false;
        _status = '完成';
      });
    } catch (error) {
      if (!mounted || version != _conversionVersion) {
        return;
      }
      setState(() {
        _output = '';
        _error = '$error';
        _busy = false;
        _status = '错误';
      });
    }
  }

  Future<String> _convertWith(OpenCCConfig config, String input) async {
    final converter = await ZhConverter.create(config);
    try {
      return converter.convert(input);
    } finally {
      converter.dispose();
    }
  }

  Future<void> _convertBatch() async {
    if (_batchBusy) {
      return;
    }
    final config = _resolvedConfig;
    final lines = _batchController.text.split('\n');
    setState(() {
      _batchBusy = true;
      _batchOutput = '';
      _batchError = null;
    });
    try {
      final outputs = config == null
          ? lines
          : await _convertBatchWith(config, lines);
      if (!mounted) {
        return;
      }
      setState(() {
        _batchOutput = outputs.join('\n');
        _batchBusy = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _batchError = '$error';
        _batchBusy = false;
      });
    }
  }

  Future<List<String>> _convertBatchWith(
    OpenCCConfig config,
    List<String> lines,
  ) async {
    final converter = await ZhConverter.create(config);
    try {
      return converter.convertAll(lines);
    } finally {
      converter.dispose();
    }
  }

  void _onInputChanged(String value) {
    setState(() {
      _status = '就绪';
      _copied = false;
    });
    _scheduleConversion();
  }

  void _clear() {
    _debounce?.cancel();
    _conversionVersion++;
    _inputController.clear();
    setState(() {
      _output = '';
      _error = null;
      _busy = false;
      _status = '就绪';
      _copied = false;
    });
  }

  Future<void> _copyOutput() async {
    if (_output.isEmpty) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: _output));
    if (!mounted) {
      return;
    }
    setState(() {
      _copied = true;
    });
    _copiedTimer?.cancel();
    _copiedTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _copied = false;
        });
      }
    });
  }

  void _selectSource(String value) {
    if (value == _source) {
      return;
    }
    setState(() {
      _source = value;
      if (!_isValidTarget(value, _target)) {
        _target = _defaultTargetFor(value);
      }
      if (!_canUsePhrases) {
        _phrases = false;
      }
      _output = '';
      _error = null;
    });
    _scheduleConversion();
  }

  void _selectTarget(String value) {
    if (value == _target || !_isValidTarget(_source, value)) {
      return;
    }
    setState(() {
      _target = value;
      if (!_canUsePhrases) {
        _phrases = false;
      }
      _output = '';
      _error = null;
    });
    _scheduleConversion();
  }

  void _swap() {
    final source = _target;
    final target = _source;
    setState(() {
      _source = source;
      _target = target;
      if (!_canUsePhrases) {
        _phrases = false;
      }
      _output = '';
      _error = null;
    });
    _scheduleConversion();
  }

  void _setPhrases(bool value) {
    if (!_canUsePhrases || value == _phrases) {
      return;
    }
    setState(() {
      _phrases = value;
      _output = '';
      _error = null;
    });
    _scheduleConversion();
  }

  void _applyConfig(OpenCCConfig config) {
    for (final item in _configs) {
      if (item.config == config) {
        setState(() {
          _source = item.source;
          _target = item.target;
          _phrases = item.phrase;
          _output = '';
          _error = null;
        });
        _scheduleConversion();
        return;
      }
    }
  }

  Future<void> _openConfigPicker() async {
    final selected = await showDialog<OpenCCConfig>(
      context: context,
      builder: (context) => _ConfigPickerDialog(current: _resolvedConfig),
    );
    if (selected == null) {
      return;
    }
    _applyConfig(selected);
  }

  String _localeLabel(String value) {
    if (value == 't' && (_source == 'jp' || _target == 'jp')) {
      return '日文旧字体 (t)';
    }
    return _localeTitles[value] ?? value;
  }

  List<String> _targetsFor(String source) {
    return switch (source) {
      's' => const ['t', 'tw', 'hk'],
      'tw' => const ['s', 't'],
      'hk' => const ['s', 't'],
      't' => const ['s', 'tw', 'hk', 'jp'],
      'jp' => const ['t'],
      _ => const [],
    };
  }

  bool _isValidTarget(String source, String target) {
    return _configs.any((config) => config.name == '${source}2$target');
  }

  String _defaultTargetFor(String source) {
    return switch (source) {
      'tw' || 'hk' || 't' => 's',
      'jp' => 't',
      _ => 't',
    };
  }

  _StatusColors _statusColors() {
    return switch (_status) {
      '转换中...' => const _StatusColors(Color(0xFF4B5563), Color(0xFFF3F4F6)),
      '错误' => const _StatusColors(Color(0xFF991B1B), Color(0xFFFEE2E2)),
      '未复制' => const _StatusColors(Color(0xFFC2410C), Color(0xFFFFEDD5)),
      _ => const _StatusColors(Color(0xFF166534), Color(0xFFDCFCE7)),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: 1200),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  _buildModeSection(),
                  _buildEditor(),
                  _buildBatchSection(),
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final colors = Theme.of(context).colorScheme;
    final statusColors = _statusColors();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.translate_rounded, color: colors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'OpenCC',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: _textMain,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'flutter_opencc 转换工具',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: _textSub),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _StatusBadge(
            message: _status,
            color: statusColors.foreground,
            background: statusColors.background,
            busy: _busy,
          ),
        ],
      ),
    );
  }

  Widget _buildModeSection() {
    final colors = Theme.of(context).colorScheme;
    final config = _resolvedConfig;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: _surfaceMuted,
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '选择转换模式',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: _textMain,
                  fontWeight: FontWeight.w600,
                ),
              ),
              _ConfigChips(config: config, onTap: _openConfigPicker),
              TextButton.icon(
                key: const ValueKey('swap-button'),
                onPressed: _swap,
                icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                label: const Text('对换来源与目标'),
              ),
              OutlinedButton.icon(
                key: const ValueKey('config-picker'),
                onPressed: _openConfigPicker,
                icon: const Icon(Icons.tune_rounded, size: 18),
                label: const Text('选择配置档'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final source = _LocaleGroup(
                title: '来源 (Source)',
                values: _localeTitles.keys.toList(growable: false),
                selected: _source,
                labelBuilder: _localeLabel,
                onSelected: _selectSource,
              );
              final target = _LocaleGroup(
                title: '目标 (Target)',
                values: _targetsFor(_source),
                selected: _target,
                labelBuilder: _localeLabel,
                enabledBuilder: (value) => _isValidTarget(_source, value),
                onSelected: _selectTarget,
              );
              final options = _PhraseOption(
                key: const ValueKey('phrase-option'),
                enabled: _canUsePhrases,
                value: _phrases,
                onChanged: _setPhrases,
              );

              if (constraints.maxWidth >= 760) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: source),
                    const SizedBox(width: 20),
                    Expanded(flex: 2, child: target),
                    const SizedBox(width: 20),
                    Expanded(child: options),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  source,
                  const SizedBox(height: 16),
                  target,
                  const SizedBox(height: 16),
                  options,
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEditor() {
    final colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final input = _InputPane(
            controller: _inputController,
            onChanged: _onInputChanged,
            onClear: _clear,
          );
          final output = _OutputPane(
            input: _inputController.text,
            output: _output,
            error: _error,
            showDiff: _showDiff,
            copied: _copied,
            onCopy: _copyOutput,
            onDiffChanged: (value) {
              setState(() {
                _showDiff = value;
              });
            },
          );
          final convertButton = _ConvertButton(
            busy: _busy,
            vertical: constraints.maxWidth < 720,
            onPressed: _convert,
          );

          if (constraints.maxWidth >= 720) {
            return SizedBox(
              height: 440,
              child: Row(
                children: [
                  Expanded(child: input),
                  convertButton,
                  Expanded(child: output),
                ],
              ),
            );
          }
          return Column(
            children: [
              SizedBox(height: 240, child: input),
              convertButton,
              SizedBox(height: 240, child: output),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBatchSection() {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.format_list_bulleted_rounded,
                color: colors.primary,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '批量转换',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: _textMain,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              FilledButton.icon(
                key: const ValueKey('batch-convert'),
                onPressed: _batchBusy ? null : _convertBatch,
                icon: _batchBusy
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.playlist_add_check_rounded, size: 18),
                label: Text(_batchBusy ? '转换中' : '转换全部'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final input = _BatchInputPane(controller: _batchController);
              final output = _BatchOutputPane(
                output: _batchOutput,
                error: _batchError,
              );
              if (constraints.maxWidth >= 720) {
                return SizedBox(
                  height: 220,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: input),
                      const SizedBox(width: 16),
                      Expanded(child: output),
                    ],
                  ),
                );
              }
              return Column(
                children: [
                  SizedBox(height: 220, child: input),
                  const SizedBox(height: 16),
                  SizedBox(height: 220, child: output),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      color: _surfaceMuted,
      child: Column(
        children: [
          Text(
            'OpenCC 1.4.1 · flutter_opencc',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }
}

class _StatusColors {
  const _StatusColors(this.foreground, this.background);

  final Color foreground;
  final Color background;
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.message,
    required this.color,
    required this.background,
    required this.busy,
  });

  final String message;
  final Color color;
  final Color background;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (busy)
            SizedBox.square(
              dimension: 12,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            )
          else
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
          const SizedBox(width: 7),
          Text(
            message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfigChips extends StatelessWidget {
  const _ConfigChips({required this.config, required this.onTap});

  final OpenCCConfig? config;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final currentConfig = config;
    if (currentConfig == null) {
      return Chip(
        label: const Text('无转换 (同源)'),
        backgroundColor: const Color(0xFFF3F4F6),
        side: const BorderSide(color: _border),
        labelStyle: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: _textSub),
      );
    }
    return ActionChip(
      label: Text('${currentConfig.configName}.json'),
      backgroundColor: const Color(0xFFEEF2FF),
      side: BorderSide.none,
      labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: _primary,
        fontWeight: FontWeight.w500,
      ),
      onPressed: onTap,
    );
  }
}

class _LocaleGroup extends StatelessWidget {
  const _LocaleGroup({
    required this.title,
    required this.values,
    required this.selected,
    required this.onSelected,
    required this.labelBuilder,
    this.enabledBuilder,
  });

  final String title;
  final List<String> values;
  final String selected;
  final ValueChanged<String> onSelected;
  final String Function(String) labelBuilder;
  final bool Function(String)? enabledBuilder;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: _textSub, fontSize: 13),
        ),
        const SizedBox(height: 8),
        for (final value in values) ...[
          _LocaleOption(
            key: ValueKey('$title-$value'),
            label: labelBuilder(value),
            selected: selected == value,
            enabled: enabledBuilder?.call(value) ?? true,
            onTap: () => onSelected(value),
          ),
          const SizedBox(height: 6),
        ],
      ],
    );
  }
}

class _LocaleOption extends StatelessWidget {
  const _LocaleOption({
    super.key,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: enabled ? onTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFEEF2FF) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected ? _primary : colors.outlineVariant,
                width: selected ? 1.4 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 20,
                  color: selected ? _primary : _textSub,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: selected ? _primary : _textMain,
                      fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PhraseOption extends StatelessWidget {
  const _PhraseOption({
    super.key,
    required this.enabled,
    required this.value,
    required this.onChanged,
  });

  final bool enabled;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '地域 / 特殊 (Phrases & Special)',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: _textSub, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Opacity(
          opacity: enabled ? 1 : 0.45,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: enabled ? () => onChanged(!value) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: value ? const Color(0xFFEEF2FF) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: value ? _primary : colors.outlineVariant,
                    width: value ? 1.4 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      value
                          ? Icons.check_box_rounded
                          : Icons.check_box_outline_blank_rounded,
                      size: 20,
                      color: value ? _primary : _textSub,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        '转换地域用词 (p)',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: value ? _primary : _textMain,
                          fontWeight: value ? FontWeight.w500 : FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BatchInputPane extends StatelessWidget {
  const _BatchInputPane({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          const _EditorHeader(title: '批量输入', actions: []),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: TextField(
                key: const ValueKey('batch-input'),
                controller: controller,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: const TextStyle(
                  color: _textMain,
                  fontSize: 16,
                  height: 1.6,
                ),
                decoration: const InputDecoration.collapsed(
                  hintText: '请输入多条文本',
                  hintStyle: TextStyle(color: Color(0xFFD1D5DB)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BatchOutputPane extends StatelessWidget {
  const _BatchOutputPane({required this.output, required this.error});

  final String output;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          const _EditorHeader(title: '批量输出', actions: []),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Align(
                alignment: Alignment.topLeft,
                child: SingleChildScrollView(
                  child: error != null
                      ? SelectableText(
                          error!,
                          style: const TextStyle(
                            color: Color(0xFF991B1B),
                            fontSize: 16,
                            height: 1.6,
                          ),
                        )
                      : output.isEmpty
                      ? Text(
                          '—',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.outline,
                            fontSize: 24,
                          ),
                        )
                      : SelectableText(
                          output,
                          style: const TextStyle(
                            color: _textMain,
                            fontSize: 16,
                            height: 1.6,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputPane extends StatelessWidget {
  const _InputPane({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          _EditorHeader(
            title: '输入原文',
            actions: [
              TextButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.clear_all_rounded, size: 16),
                label: const Text('清空'),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: TextField(
                key: const ValueKey('input-field'),
                controller: controller,
                onChanged: onChanged,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: const TextStyle(
                  color: _textMain,
                  fontSize: 17,
                  height: 1.6,
                ),
                decoration: const InputDecoration.collapsed(
                  hintText: '请输入要转换的文字',
                  hintStyle: TextStyle(color: Color(0xFFD1D5DB)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OutputPane extends StatelessWidget {
  const _OutputPane({
    required this.input,
    required this.output,
    required this.error,
    required this.showDiff,
    required this.copied,
    required this.onCopy,
    required this.onDiffChanged,
  });

  final String input;
  final String output;
  final String? error;
  final bool showDiff;
  final bool copied;
  final VoidCallback onCopy;
  final ValueChanged<bool> onDiffChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          _EditorHeader(
            title: '转换结果',
            actions: [
              _DiffToggle(value: showDiff, onChanged: onDiffChanged),
              const SizedBox(width: 6),
              IconButton(
                tooltip: copied ? '已复制' : '复制',
                visualDensity: VisualDensity.compact,
                onPressed: output.isEmpty ? null : onCopy,
                icon: Icon(
                  copied ? Icons.check_rounded : Icons.copy_rounded,
                  size: 18,
                ),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: Align(
                alignment: Alignment.topLeft,
                child: SingleChildScrollView(
                  child: error != null
                      ? SelectableText(
                          error!,
                          style: const TextStyle(
                            color: Color(0xFF991B1B),
                            fontSize: 16,
                            height: 1.6,
                          ),
                        )
                      : output.isEmpty
                      ? Text(
                          '—',
                          style: TextStyle(color: colors.outline, fontSize: 24),
                        )
                      : SelectableText.rich(
                          showDiff && input.isNotEmpty
                              ? _diffSpans(input, output)
                              : TextSpan(text: output),
                          style: const TextStyle(
                            color: _textMain,
                            fontSize: 17,
                            height: 1.6,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditorHeader extends StatelessWidget {
  const _EditorHeader({required this.title, required this.actions});

  final String title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: _textSub,
                letterSpacing: 0.6,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

class _DiffToggle extends StatelessWidget {
  const _DiffToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: value,
                visualDensity: VisualDensity.compact,
                onChanged: (next) => onChanged(next ?? false),
              ),
            ),
            const SizedBox(width: 3),
            Text(
              '显示差异',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: _textSub),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConvertButton extends StatelessWidget {
  const _ConvertButton({
    required this.busy,
    required this.vertical,
    required this.onPressed,
  });

  final bool busy;
  final bool vertical;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      width: 60,
      color: const Color(0xFFF8FAFC),
      child: Center(
        child: IconButton.filled(
          key: const ValueKey('convert-button'),
          tooltip: '点击转换',
          onPressed: busy ? null : onPressed,
          style: IconButton.styleFrom(
            backgroundColor: _primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFF9CA3AF),
          ),
          icon: busy
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(
                  vertical
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_forward_rounded,
                ),
        ),
      ),
    );
    if (vertical) {
      return SizedBox(
        height: 60,
        child: Row(
          children: [
            Expanded(child: Container(color: const Color(0xFFF8FAFC))),
            child,
            Expanded(child: Container(color: const Color(0xFFF8FAFC))),
          ],
        ),
      );
    }
    return SizedBox(height: 440, child: child);
  }
}

class _ConfigPickerDialog extends StatelessWidget {
  const _ConfigPickerDialog({required this.current});

  final OpenCCConfig? current;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 560),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 12),
              child: Row(
                children: [
                  Icon(Icons.tune_rounded, color: colors.primary, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '选择配置档',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: _textMain,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: '关闭',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: _border),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 300,
                  mainAxisExtent: 94,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _configs.length,
                itemBuilder: (context, index) {
                  final config = _configs[index];
                  final selected = config.config == current;
                  return Material(
                    key: ValueKey('config-${config.name}'),
                    color: selected ? const Color(0xFFEEF2FF) : colors.surface,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => Navigator.of(context).pop(config.config),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: selected ? _primary : colors.outlineVariant,
                            width: selected ? 1.4 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              config.name,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    color: _primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              config.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: _textSub, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

TextSpan _diffSpans(String source, String output) {
  final sourceRunes = source.runes.toList(growable: false);
  final outputRunes = output.runes.toList(growable: false);
  if (sourceRunes.isEmpty ||
      outputRunes.isEmpty ||
      sourceRunes.length * outputRunes.length > 250000) {
    return TextSpan(text: output);
  }

  final rows = sourceRunes.length + 1;
  final columns = outputRunes.length + 1;
  final dp = List.generate(
    rows,
    (_) => List<int>.filled(columns, 0),
    growable: false,
  );
  for (var i = 1; i < rows; i++) {
    for (var j = 1; j < columns; j++) {
      dp[i][j] = sourceRunes[i - 1] == outputRunes[j - 1]
          ? dp[i - 1][j - 1] + 1
          : dp[i - 1][j] > dp[i][j - 1]
          ? dp[i - 1][j]
          : dp[i][j - 1];
    }
  }

  final segments = <({String text, bool inserted})>[];
  var i = sourceRunes.length;
  var j = outputRunes.length;
  while (i > 0 && j > 0) {
    if (sourceRunes[i - 1] == outputRunes[j - 1]) {
      segments.add((
        text: String.fromCharCode(sourceRunes[i - 1]),
        inserted: false,
      ));
      i--;
      j--;
    } else if (dp[i][j - 1] >= dp[i - 1][j]) {
      segments.add((
        text: String.fromCharCode(outputRunes[j - 1]),
        inserted: true,
      ));
      j--;
    } else {
      i--;
    }
  }
  while (j > 0) {
    segments.add((
      text: String.fromCharCode(outputRunes[j - 1]),
      inserted: true,
    ));
    j--;
  }

  final grouped = <({String text, bool inserted})>[];
  for (final segment in segments.reversed) {
    if (grouped.isNotEmpty && grouped.last.inserted == segment.inserted) {
      grouped[grouped.length - 1] = (
        text: grouped.last.text + segment.text,
        inserted: segment.inserted,
      );
    } else {
      grouped.add(segment);
    }
  }
  final spans = [
    for (final segment in grouped)
      TextSpan(
        text: segment.text,
        style: segment.inserted
            ? const TextStyle(
                backgroundColor: Color(0xFFDCFCE7),
                color: Color(0xFF166534),
              )
            : null,
      ),
  ];
  return TextSpan(children: spans);
}
