import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:capitan/app_bloc.dart';
import 'package:capitan/models/marine_data.dart';
import 'package:capitan/models/sea_location.dart';
import 'package:capitan/models/weather_data.dart';
import 'package:capitan/services/open_meteo.dart';

const _bondi = SeaLocation(
  name: 'Bondi Beach',
  latitude: -33.8909,
  longitude: 151.2743,
  country: 'Australia',
);

class _OfflineApi extends OpenMeteoApi {
  @override
  Future<WeatherData> fetchWeather(double latitude, double longitude) async {
    throw ApiException('offline');
  }

  @override
  Future<MarineData> fetchMarine(double latitude, double longitude) async {
    throw ApiException('offline');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('initial state is empty', () {
    final bloc = AppBloc();
    expect(bloc.state, const AppState());
    bloc.close();
  });

  test('copyWith keeps unspecified fields and clears nullable ones', () {
    const base = AppState(error: 'boom', marineNotice: 'note', loading: true);

    final kept = base.copyWith(loading: false);
    expect(kept.error, 'boom');
    expect(kept.marineNotice, 'note');
    expect(kept.loading, isFalse);

    final cleared = base.copyWith(error: null, marineNotice: null);
    expect(cleared.error, isNull);
    expect(cleared.marineNotice, isNull);
  });

  test('RefreshRequested without location is ignored', () async {
    final bloc = AppBloc();
    bloc.add(const RefreshRequested());
    await bloc.close();
    expect(bloc.state, const AppState());
  });

  test('AppStarted restores the persisted location', () async {
    SharedPreferences.setMockInitialValues({
      'capitan.location': jsonEncode(_bondi.toJson()),
    });
    final bloc = AppBloc(api: _OfflineApi());
    bloc.add(const AppStarted());

    await bloc.stream.firstWhere((state) => state.error != null);

    expect(bloc.state.location?.name, _bondi.name);
    expect(bloc.state.error, 'offline');
    expect(bloc.state.loading, isFalse);
    await bloc.close();
  });

  test('LocationSelected stores the location and surfaces refresh errors',
      () async {
    SharedPreferences.setMockInitialValues({});
    final bloc = AppBloc(api: _OfflineApi());
    bloc.add(const LocationSelected(_bondi));

    await bloc.stream.firstWhere((state) => state.error != null);

    expect(bloc.state.location?.name, _bondi.name);
    expect(bloc.state.error, 'offline');
    expect(bloc.state.loading, isFalse);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('capitan.location'), jsonEncode(_bondi.toJson()));
    await bloc.close();
  });
}
