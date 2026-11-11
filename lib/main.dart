import 'package:flutter/material.dart';

import 'app_state.dart';
import 'screens/home_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final appState = AppState();
  appState.init();
  runApp(CapitanApp(appState: appState));
}

class CapitanApp extends StatelessWidget {
  const CapitanApp({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return AppStateScope(
      notifier: appState,
      child: MaterialApp(
        title: 'Capitán',
        debugShowCheckedModeBanner: false,
        theme: _seaTheme(Brightness.light),
        darkTheme: _seaTheme(Brightness.dark),
        home: const HomeShell(),
      ),
    );
  }

  static ThemeData _seaTheme(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0077B6),
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: brightness == Brightness.light
          ? const Color(0xFFF3F8FB)
          : const Color(0xFF0B1520),
      appBarTheme: const AppBarTheme(centerTitle: false),
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 66,
        indicatorColor: scheme.primaryContainer,
      ),
    );
  }
}
