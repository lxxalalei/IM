import 'package:flutter/foundation.dart';

@immutable
class FontSettings {
  const FontSettings({
    this.chineseFontFamily = defaultChineseFontFamily,
    this.westernFontFamily = defaultWesternFontFamily,
  });

  static const defaultChineseFontFamily = 'Microsoft YaHei';
  static const defaultWesternFontFamily = 'Arial';

  static const westernFontOptions = [
    'Arial',
    'Tahoma',
    'Consolas',
    'Segoe UI',
    'Verdana',
  ];

  final String chineseFontFamily;
  final String westernFontFamily;

  String get effectiveChineseFontFamily => chineseFontFamily.trim().isEmpty
      ? defaultChineseFontFamily
      : chineseFontFamily.trim();

  String get effectiveWesternFontFamily => westernFontFamily.trim().isEmpty
      ? defaultWesternFontFamily
      : westernFontFamily.trim();

  List<String> get fontFamilyFallback => [
    effectiveWesternFontFamily,
    effectiveChineseFontFamily,
    defaultChineseFontFamily,
    'PingFang SC',
    defaultWesternFontFamily,
  ].toSet().toList(growable: false);

  FontSettings copyWith({
    String? chineseFontFamily,
    String? westernFontFamily,
  }) {
    return FontSettings(
      chineseFontFamily: chineseFontFamily ?? this.chineseFontFamily,
      westernFontFamily: westernFontFamily ?? this.westernFontFamily,
    );
  }
}
