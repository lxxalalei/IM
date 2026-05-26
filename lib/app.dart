import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/font_settings.dart';
import 'features/shell/app_shell.dart';

class FeishuImApp extends StatefulWidget {
  const FeishuImApp({super.key});

  @override
  State<FeishuImApp> createState() => _FeishuImAppState();
}

class _FeishuImAppState extends State<FeishuImApp> {
  FontSettings _fontSettings = const FontSettings();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vibe IM',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(fontSettings: _fontSettings),
      home: AppShell(
        fontSettings: _fontSettings,
        onFontSettingsChanged: (settings) {
          setState(() => _fontSettings = settings);
        },
      ),
    );
  }
}
