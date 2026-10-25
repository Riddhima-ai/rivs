import 'package:flutter/material.dart';

import 'app_state.dart';
import 'pages/home_page.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const DeepfakeShieldApp());
}

class DeepfakeShieldApp extends StatefulWidget {
  const DeepfakeShieldApp({super.key});

  @override
  State<DeepfakeShieldApp> createState() => _DeepfakeShieldAppState();
}

class _DeepfakeShieldAppState extends State<DeepfakeShieldApp> {
  final AppState _appState = AppState();

  @override
  void dispose() {
    _appState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Deepfake Shield',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: HomePage(appState: _appState),
    );
  }
}
