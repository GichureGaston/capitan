import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../app_bloc.dart';
import 'coral_screen.dart';
import 'dashboard_screen.dart';
import 'fish_screen.dart';
import 'location_sheet.dart';
import 'spots_screen.dart';
import 'tides_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  static const _titles = [
    'Capitán',
    'Tides & sea',
    'Swim spots',
    'Fish guide',
    'Coral guide',
  ];

  void _openLocationSheet() => showLocationSheet(context);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final locationName =
        context.select<AppBloc, String?>((bloc) => bloc.state.location?.name);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_tab],
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 4),
            child: TextButton.icon(
              onPressed: _openLocationSheet,
              icon: const Icon(Icons.place, size: 18),
              label: Text(
                locationName ?? 'Set location',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ),
        ],
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          const DashboardScreen(),
          const TidesScreen(),
          SpotsScreen(
            onUseSpot: () => setState(() => _tab = 0),
          ),
          const FishScreen(),
          const CoralScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (index) => setState(() => _tab = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Now',
          ),
          NavigationDestination(
            icon: Icon(Icons.waves_outlined),
            selectedIcon: Icon(Icons.waves),
            label: 'Tides',
          ),
          NavigationDestination(
            icon: Icon(Icons.beach_access_outlined),
            selectedIcon: Icon(Icons.beach_access),
            label: 'Spots',
          ),
          NavigationDestination(
            icon: Icon(Icons.set_meal_outlined),
            selectedIcon: Icon(Icons.set_meal),
            label: 'Fish',
          ),
          NavigationDestination(
            icon: Icon(Icons.filter_vintage_outlined),
            selectedIcon: Icon(Icons.filter_vintage),
            label: 'Coral',
          ),
        ],
      ),
    );
  }
}
