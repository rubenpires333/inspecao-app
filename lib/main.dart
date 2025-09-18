import 'package:flutter/material.dart';
import 'package:inspecao/theme.dart';
import 'package:inspecao/screens/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light; // Sempre modo light

  void changeThemeMode(ThemeMode themeMode) {
    setState(() {
      _themeMode = ThemeMode.light; // Sempre forçar light
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inspecao Pro - Sistema de Gestão de Inspeção e Vistoria',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: _themeMode,
      home: SplashScreen(changeThemeMode: changeThemeMode),
      debugShowCheckedModeBanner: false,
    );
  }
}
