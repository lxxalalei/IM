import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/font_settings.dart';

class FontSettingsPage extends StatefulWidget {
  const FontSettingsPage({
    required this.fontSettings,
    required this.onChanged,
    super.key,
  });

  final FontSettings fontSettings;
  final ValueChanged<FontSettings> onChanged;

  @override
  State<FontSettingsPage> createState() => _FontSettingsPageState();
}

class _FontSettingsPageState extends State<FontSettingsPage> {
  late final TextEditingController _chineseFontController;

  @override
  void initState() {
    super.initState();
    _chineseFontController = TextEditingController(
      text: widget.fontSettings.chineseFontFamily,
    );
  }

  @override
  void didUpdateWidget(covariant FontSettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.fontSettings.chineseFontFamily !=
        _chineseFontController.text) {
      _chineseFontController.value = TextEditingValue(
        text: widget.fontSettings.chineseFontFamily,
        selection: TextSelection.collapsed(
          offset: widget.fontSettings.chineseFontFamily.length,
        ),
      );
    }
  }

  @override
  void dispose() {
    _chineseFontController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.fontSettings;

    return Material(
      color: AppColors.panelBackground,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
        children: [
          Row(
            children: [
              const Icon(
                Icons.text_fields_rounded,
                color: AppColors.brandBlue,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                '字体显示测试',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              Tooltip(
                message: '重置字体',
                waitDuration: const Duration(milliseconds: 450),
                child: IconButton(
                  constraints: const BoxConstraints.tightFor(
                    width: 34,
                    height: 34,
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: () => widget.onChanged(const FontSettings()),
                  icon: const Icon(Icons.restart_alt_rounded, size: 19),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FontTextField(
                  label: '中文字体',
                  controller: _chineseFontController,
                  onChanged: (fontFamily) {
                    widget.onChanged(
                      settings.copyWith(chineseFontFamily: fontFamily),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _WesternFontSelector(
                  value: settings.westernFontFamily,
                  onChanged: (fontFamily) {
                    widget.onChanged(
                      settings.copyWith(westernFontFamily: fontFamily),
                    );
                  },
                ),
                const SizedBox(height: 26),
                _FontPreview(fontSettings: settings),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FontTextField extends StatelessWidget {
  const _FontTextField({
    required this.label,
    required this.controller,
    required this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return _FieldBlock(
      label: label,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textAlignVertical: TextAlignVertical.center,
        decoration: const InputDecoration(
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }
}

class _WesternFontSelector extends StatelessWidget {
  const _WesternFontSelector({
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return _FieldBlock(
      label: '西文字体',
      child: DropdownButtonFormField<String>(
        value: value,
        items: FontSettings.westernFontOptions
            .map(
              (fontFamily) => DropdownMenuItem(
                value: fontFamily,
                child: Text(
                  fontFamily,
                  style: TextStyle(fontFamily: fontFamily),
                ),
              ),
            )
            .toList(growable: false),
        onChanged: (fontFamily) {
          if (fontFamily != null) {
            onChanged(fontFamily);
          }
        },
        decoration: const InputDecoration(
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }
}

class _FieldBlock extends StatelessWidget {
  const _FieldBlock({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.secondaryText,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(height: 44, child: child),
      ],
    );
  }
}

class _FontPreview extends StatelessWidget {
  const _FontPreview({required this.fontSettings});

  final FontSettings fontSettings;

  @override
  Widget build(BuildContext context) {
    final previewStyle = TextStyle(
      color: AppColors.primaryText,
      fontSize: 16,
      height: 1.45,
      fontFamily: fontSettings.effectiveWesternFontFamily,
      fontFamilyFallback: fontSettings.fontFamilyFallback,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '即时消息、通讯录、群聊、文件助手',
              style: previewStyle.copyWith(
                fontFamily: fontSettings.effectiveChineseFontFamily,
                fontFamilyFallback: fontSettings.fontFamilyFallback,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'The quick brown fox jumps over 1234567890.',
              style: previewStyle,
            ),
            const SizedBox(height: 10),
            Text(
              'IM Chat 2026 / 工作台 / '
              '${fontSettings.effectiveWesternFontFamily}',
              style: previewStyle,
            ),
          ],
        ),
      ),
    );
  }
}
