import 'package:flutter/material.dart';
import './ui/screens/main_platform_screen.dart';

void main() {
  runApp(const PluginPlatformApp());
}

class PluginPlatformApp extends StatelessWidget {
  const PluginPlatformApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plugin Platform',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MainPlatformScreen(),
    );
  }
}
