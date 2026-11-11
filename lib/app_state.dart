import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/activity_rating.dart';
import 'models/marine_data.dart';
import 'models/sea_location.dart';
import 'models/weather_data.dart';
import 'services/location_service.dart';
import 'services/open_meteo.dart';
import 'services/tide_service.dart';

class AppState extends ChangeNotifier {
  AppState({OpenMeteoApi? api, LocationService? locationService})
      : _api = api ?? OpenMeteoApi(),
        _locationService = locationService ?? LocationService();

  static const _prefsKey = 'capitan.location';

  final OpenMeteoApi _api;
  final LocationService _locationService;

  SeaLocation? location;
  WeatherData? weather;
  MarineData? marine;

  bool loading = false;
  bool locating = false;
  String? error;
  String? marineNotice;
  DateTime? lastUpdated;

  List<TideEvent> get tides =>
      marine == null ? const [] : TideService.detectTides(marine!.hourly);

  ConditionsSnapshot? get snapshot {
    if (weather == null) return null;
    return ConditionsSnapshot.fromForecast(weather!, marine);
  }

  OpenMeteoApi get api => _api;

  Future<List<SeaLocation>> searchLocations(String query) =>
      _api.searchLocations(query);

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null) {
        location = SeaLocation.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        await refresh();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('AppState.init failed: $e');
    }
  }

  Future<void> setLocation(SeaLocation newLocation) async {
    location = newLocation;
    error = null;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(newLocation.toJson()));
    } catch (e) {
      if (kDebugMode) debugPrint('Could not persist location: $e');
    }
    await refresh();
  }

  Future<void> useDeviceLocation() async {
    locating = true;
    error = null;
    notifyListeners();
    try {
      final position = await _locationService.getCurrentLocation();
      await setLocation(position);
    } on LocationException catch (e) {
      error = e.message;
      notifyListeners();
    } catch (e) {
      error = 'Could not use device location: $e';
      notifyListeners();
    } finally {
      locating = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    final current = location;
    if (current == null) return;

    loading = true;
    error = null;
    notifyListeners();

    final weatherFuture = _api.fetchWeather(current.latitude, current.longitude);
    final marineFuture = _fetchMarineOrNull(current);

    try {
      weather = await weatherFuture;
      final fetchedMarine = await marineFuture;
      if (fetchedMarine == null) {
        marine = null;
        marineNotice = 'No tide or wave model data for this spot. '
            'Ratings are wind-only — pick a coastal location for full sea data.';
      } else {
        marine = fetchedMarine;
        marineNotice = null;
      }
      lastUpdated = DateTime.now();
    } on ApiException catch (e) {
      error = e.message;
    } catch (e) {
      error = 'Something went wrong while fetching conditions: $e';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<MarineData?> _fetchMarineOrNull(SeaLocation current) async {
    try {
      final data = await _api.fetchMarine(current.latitude, current.longitude);
      return data.hasData ? data : null;
    } catch (_) {
      return null;
    }
  }
}

class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({
    super.key,
    required AppState notifier,
    required super.child,
  }) : super(notifier: notifier);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppStateScope>()!.notifier!;
}
