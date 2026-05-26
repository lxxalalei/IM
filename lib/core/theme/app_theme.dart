import 'package:flutter/material.dart';

import 'font_settings.dart';

class AppColors {
  static const appBackground = Color(0xFFEEF3FA);
  static const panelBackground = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF7F9FC);
  static const line = Color(0xFFE5E8EF);
  static const primaryText = Color(0xFF1F2329);
  static const secondaryText = Color(0xFF646A73);
  static const tertiaryText = Color(0xFF8F959E);
  static const selected = Color(0xFFE8F0FF);
  static const brandBlue = Color(0xFF3370FF);
  static const brandGreen = Color(0xFF34A853);
  static const bubbleIncoming = Color(0xFFF2F3F5);
  static const bubbleMine = Color(0xFFDDEAFF);
  static const tagBlue = Color(0xFFE9EFFF);
  static const tagGold = Color(0xFFFFF4D6);
  static const tagPurple = Color(0xFFF1E8FF);
}

ThemeData buildAppTheme({FontSettings fontSettings = const FontSettings()}) {
  final fontFallback = fontSettings.fontFamilyFallback;
  final textTheme = const TextTheme(
    titleMedium: TextStyle(
      color: AppColors.primaryText,
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
    bodyMedium: TextStyle(
      color: AppColors.primaryText,
      fontSize: 14,
      height: 1.35,
    ),
    bodySmall: TextStyle(
      color: AppColors.secondaryText,
      fontSize: 12,
      height: 1.35,
    ),
  ).apply(
    fontFamily: fontSettings.effectiveWesternFontFamily,
    fontFamilyFallback: fontFallback,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.brandBlue,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: AppColors.appBackground,
    fontFamily: fontSettings.effectiveWesternFontFamily,
    fontFamilyFallback: fontFallback,
    textTheme: textTheme,
  );
}
