import 'package:flutter/material.dart';import 'package:inspecao/theme.dart';
import 'package:inspecao/screens/splash_screen.dart';
import 'package:inspecao/services/connectivity_service.dart';
import 'package:inspecao/widgets/offline_mode_chip.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ConnectivityService().initialize();
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
      title: 'INSPEV - Sistema de Gestão de Inspeção e Vistoria',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: _themeMode,
      builder: (context, child) {
        return GlobalOfflineOverlay(child: child ?? const SizedBox.shrink());
      },
      home: SplashScreen(changeThemeMode: changeThemeMode),
      debugShowCheckedModeBanner: false,
    );
  }
}
