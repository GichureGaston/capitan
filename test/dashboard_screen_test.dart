import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:capitan/app_bloc.dart';
import 'package:capitan/models/marine_data.dart';
import 'package:capitan/models/sea_location.dart';
import 'package:capitan/models/weather_data.dart';
import 'package:capitan/screens/dashboard_screen.dart';
import 'package:capitan/services/open_meteo.dart';

const _bondi = SeaLocation(
  name: 'Bondi Beach',
  latitude: -33.8909,
  longitude: 151.2743,
  country: 'Australia',
);

WeatherData _weather({required bool isDay}) => WeatherData.fromJson({
      'current': {
        'time': isDay ? '2026-11-11T11:00' : '2026-11-11T23:00',
        'temperature_2m': 22,
        'apparent_temperature': 22,
        'relative_humidity_2m': 55,
        'precipitation': 0,
        'weather_code': 0,
        'cloud_cover': 5,
        'wind_speed_10m': 8,
        'wind_direction_10m': 90,
        'wind_gusts_10m': 12,
        'is_day': isDay ? 1 : 0,
      },
      'hourly': const {
        'time': ['2026-11-11T23:00'],
        'uv_index': [0],
      },
      'daily': const {
        'time': ['2026-11-11'],
        'sunrise': ['2026-11-11T06:00'],
        'sunset': ['2026-11-11T19:30'],
      },
    });

class _FakeApi extends OpenMeteoApi {
  _FakeApi({required this.isDay});

  final bool isDay;

  @override
  Future<WeatherData> fetchWeather(double latitude, double longitude) async =>
      _weather(isDay: isDay);

  @override
  Future<MarineData> fetchMarine(double latitude, double longitude) async =>
      throw ApiException('no marine data');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<AppBloc> pumpDashboard(WidgetTester tester, {required bool isDay}) async {
    // A roomy surface keeps the condition grid clear of the test-font layout
    // overflows that the default 800x600 window hits.
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final bloc = AppBloc(api: _FakeApi(isDay: isDay));
    final loaded = bloc.stream.firstWhere((state) => state.weather != null);
    bloc.add(const LocationSelected(_bondi));
    await loaded;

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AppBloc>.value(
          value: bloc,
          child: const DashboardScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return bloc;
  }

  testWidgets('at night the dashboard suggests rest instead of swimming',
      (tester) async {
    final bloc = await pumpDashboard(tester, isDay: false);

    expect(find.text('It\'s night — rest up for tomorrow\'s swim'), findsOneWidget);
    expect(find.textContaining('Best right now'), findsNothing);

    // Scroll down to the activity ratings: every card says rest, not swim.
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text('Night — rest'), findsNWidgets(4));
    expect(find.text('It\'s night — rest up and swim in daylight'), findsNWidgets(4));

    await bloc.close();
  });

  testWidgets('during the day the dashboard still suggests the best activity',
      (tester) async {
    final bloc = await pumpDashboard(tester, isDay: true);

    expect(find.textContaining('Best right now'), findsOneWidget);
    expect(find.text('It\'s night — rest up for tomorrow\'s swim'), findsNothing);

    await bloc.close();
  });
}
