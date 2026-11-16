import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app_bloc.dart';
import 'screens/home_shell.dart';
import 'services/open_meteo.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CapitanApp());
}

class CapitanApp extends StatelessWidget {
  const CapitanApp({super.key, this.bloc});

  final AppBloc? bloc;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<OpenMeteoApi>(
      create: (_) => OpenMeteoApi(),
      child: BlocProvider<AppBloc>(
        create: (context) {
          final appBloc = bloc ?? AppBloc(api: context.read<OpenMeteoApi>());
          appBloc.add(const AppStarted());
          return appBloc;
        },
        child: MaterialApp(
          title: 'Capitán',
          debugShowCheckedModeBanner: false,
          theme: _seaTheme(Brightness.light),
          darkTheme: _seaTheme(Brightness.dark),
          home: const HomeShell(),
        ),
      ),
    );
  }

  static ThemeData _seaTheme(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0077B6),
      brightness: brightness,
    );

    Color background;
    if (brightness == Brightness.light) {
      background = const Color(0xFFF3F8FB);
    } else {
      background = const Color(0xFF0B1520);
    }

    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(centerTitle: false),
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 66,
        indicatorColor: scheme.primaryContainer,
      ),
    );
  }
}
