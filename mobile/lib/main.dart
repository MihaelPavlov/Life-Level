import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: LifeLevelApp()));
}

class LifeLevelApp extends StatelessWidget {
  const LifeLevelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LifeLevel',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const Scaffold(
        body: Center(
          child: Text('LifeLevel — coming soon'),
        ),
      ),
    );
  }
}
