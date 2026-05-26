import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/shell/app_shell.dart';

class FeishuImApp extends StatelessWidget {
  const FeishuImApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vibe IM',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const AppShell(),
    );
  }
}
