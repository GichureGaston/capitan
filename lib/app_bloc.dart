import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/activity_rating.dart';
import 'models/marine_data.dart';
import 'models/sea_location.dart';
import 'models/weather_data.dart';
import 'services/location_service.dart';
import 'services/open_meteo.dart';

abstract class AppEvent {
  const AppEvent();
}

class AppStarted extends AppEvent {
  const AppStarted();
}

class LocationSelected extends AppEvent {
  const LocationSelected(this.location);

  final SeaLocation location;
}

class DeviceLocationRequested extends AppEvent {
  const DeviceLocationRequested();
}

class RefreshRequested extends AppEvent {
  const RefreshRequested();
}

class AppState extends Equatable {
  const AppState({
    this.location,
    this.weather,
    this.marine,
    this.loading = false,
    this.locating = false,
    this.error,
    this.marineNotice,
    this.lastUpdated,
  });

  final SeaLocation? location;
  final WeatherData? weather;
  final MarineData? marine;
  final bool loading;
  final bool locating;
  final String? error;
  final String? marineNotice;
  final DateTime? lastUpdated;

  ConditionsSnapshot? get snapshot {
    if (weather == null) return null;
    return ConditionsSnapshot.fromForecast(weather!, marine);
  }

  AppState copyWith({
    SeaLocation? location,
    WeatherData? weather,
    MarineData? marine,
    bool clearMarine = false,
    bool? loading,
    bool? locating,
    String? error,
    bool clearError = false,
    String? marineNotice,
    bool clearMarineNotice = false,
    DateTime? lastUpdated,
  }) {
    return AppState(
      location: location ?? this.location,
      weather: weather ?? this.weather,
      marine: clearMarine ? null : (marine ?? this.marine),
      loading: loading ?? this.loading,
      locating: locating ?? this.locating,
      error: clearError ? null : (error ?? this.error),
      marineNotice: clearMarineNotice
          ? null
          : (marineNotice ?? this.marineNotice),
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object?> get props => [
    location,
    weather,
    marine,
    loading,
    locating,
    error,
    marineNotice,
    lastUpdated,
  ];
}

class AppBloc extends Bloc<AppEvent, AppState> {
  AppBloc({OpenMeteoApi? api, LocationService? locationService})
    : _api = api ?? OpenMeteoApi(),
      _locationService = locationService ?? LocationService(),
      super(const AppState()) {
    on<AppStarted>(_onAppStarted);
    on<LocationSelected>(_onLocationSelected);
    on<DeviceLocationRequested>(_onDeviceLocationRequested);
    on<RefreshRequested>(_onRefreshRequested);
  }

  static const _prefsKey = 'capitan.location';

  final OpenMeteoApi _api;
  final LocationService _locationService;

  int _refreshSeq = 0;

  Future<void> _onAppStarted(AppStarted event, Emitter<AppState> emit) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null) return;
      final location = SeaLocation.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      emit(state.copyWith(location: location));
      await _refresh(emit);
    } catch (e) {
      if (kDebugMode) debugPrint('AppBloc could not restore location: $e');
    }
  }

  Future<void> _onLocationSelected(
    LocationSelected event,
    Emitter<AppState> emit,
  ) async {
    await _applyLocation(event.location, emit);
    await _refresh(emit);
  }

  Future<void> _onDeviceLocationRequested(
    DeviceLocationRequested event,
    Emitter<AppState> emit,
  ) async {
    if (state.locating) return;
    emit(state.copyWith(locating: true, clearError: true));
    try {
      final position = await _locationService.getCurrentLocation();
      await _applyLocation(position, emit);
      await _refresh(emit);
    } on LocationException catch (e) {
      emit(state.copyWith(error: e.message));
    } catch (e) {
      emit(state.copyWith(error: 'Could not use device location: $e'));
    } finally {
      emit(state.copyWith(locating: false));
    }
  }

  Future<void> _onRefreshRequested(
    RefreshRequested event,
    Emitter<AppState> emit,
  ) async {
    await _refresh(emit);
  }

  Future<void> _applyLocation(
    SeaLocation location,
    Emitter<AppState> emit,
  ) async {
    emit(state.copyWith(location: location, clearError: true));
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(location.toJson()));
    } catch (e) {
      if (kDebugMode) debugPrint('Could not persist location: $e');
    }
  }

  Future<void> _refresh(Emitter<AppState> emit) async {
    final current = state.location;
    if (current == null) return;

    final seq = ++_refreshSeq;
    emit(state.copyWith(loading: true, clearError: true));

    final weatherFuture = _api.fetchWeather(
      current.latitude,
      current.longitude,
    );
    final marineFuture = _fetchMarineOrNull(current);

    try {
      final weather = await weatherFuture;
      final fetchedMarine = await marineFuture;
      if (seq != _refreshSeq) return;

      if (fetchedMarine == null) {
        emit(
          state.copyWith(
            weather: weather,
            clearMarine: true,
            marineNotice:
                'No tide or wave model data for this spot. '
                'Ratings are wind-only — pick a coastal location for full sea data.',
            lastUpdated: DateTime.now(),
            loading: false,
          ),
        );
      } else {
        emit(
          state.copyWith(
            weather: weather,
            marine: fetchedMarine,
            clearMarineNotice: true,
            lastUpdated: DateTime.now(),
            loading: false,
          ),
        );
      }
    } on ApiException catch (e) {
      if (seq == _refreshSeq) {
        emit(state.copyWith(error: e.message, loading: false));
      }
    } catch (e) {
      if (seq == _refreshSeq) {
        emit(
          state.copyWith(
            error: 'Something went wrong while fetching conditions: $e',
            loading: false,
          ),
        );
      }
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
