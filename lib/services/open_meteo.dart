import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/marine_data.dart';
import '../models/sea_location.dart';
import '../models/weather_data.dart';

class ApiException implements Exception {
  ApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class OpenMeteoApi {
  OpenMeteoApi({http.Client? client, this.baseUrl = 'https://api.open-meteo.com'})
      : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;

  static const _timeout = Duration(seconds: 25);

  static const _currentWeatherVars = [
    'temperature_2m',
    'relative_humidity_2m',
    'apparent_temperature',
    'is_day',
    'precipitation',
    'weather_code',
    'cloud_cover',
    'wind_speed_10m',
    'wind_direction_10m',
    'wind_gusts_10m',
  ];

  static const _hourlyWeatherVars = [
    'temperature_2m',
    'relative_humidity_2m',
    'precipitation_probability',
    'weather_code',
    'wind_speed_10m',
    'wind_direction_10m',
    'wind_gusts_10m',
    'uv_index',
    'visibility',
  ];

  static const _dailyWeatherVars = [
    'weather_code',
    'temperature_2m_max',
    'temperature_2m_min',
    'uv_index_max',
    'precipitation_probability_max',
    'wind_speed_10m_max',
    'wind_gusts_10m_max',
    'wind_direction_10m_dominant',
    'sunrise',
    'sunset',
  ];

  Future<WeatherData> fetchWeather(double latitude, double longitude) async {
    final uri = Uri.parse('$baseUrl/v1/forecast').replace(queryParameters: {
      'latitude': '$latitude',
      'longitude': '$longitude',
      'current': _currentWeatherVars.join(','),
      'hourly': _hourlyWeatherVars.join(','),
      'daily': _dailyWeatherVars.join(','),
      'timezone': 'auto',
      'forecast_days': '7',
    });
    final json = await _getJson(uri);
    return WeatherData.fromJson(_asMap(json));
  }

  Future<MarineData> fetchMarine(double latitude, double longitude) async {
    final uri = Uri.parse('https://marine-api.open-meteo.com/v1/marine')
        .replace(queryParameters: {
      'latitude': '$latitude',
      'longitude': '$longitude',
      'current': 'wave_height,wave_direction,wave_period,sea_surface_temperature,'
          'ocean_current_velocity,ocean_current_direction,sea_level_height_msl',
      'hourly': 'wave_height,wave_direction,wave_period,sea_surface_temperature,'
          'sea_level_height_msl,ocean_current_velocity,ocean_current_direction',
      'daily': 'wave_height_max,wave_direction_dominant,wave_period_max',
      'timezone': 'auto',
      'forecast_days': '7',
      'length_unit': 'metric',
      'cell_selection': 'sea',
    });
    final json = await _getJson(uri);
    return MarineData.fromJson(_asMap(json));
  }

  Future<List<MarineData>> fetchMarineBatch(List<SeaLocation> locations) async {
    if (locations.isEmpty) return const [];
    final uri =
        Uri.parse('https://marine-api.open-meteo.com/v1/marine').replace(queryParameters: {
      'latitude': locations.map((l) => l.latitude).join(','),
      'longitude': locations.map((l) => l.longitude).join(','),
      'current': 'wave_height,wave_period,sea_surface_temperature,ocean_current_velocity',
      'timezone': 'auto',
      'cell_selection': 'sea',
    });
    final json = await _getJson(uri);
    final list = _asList(json);
    return list.map(MarineData.fromJson).toList();
  }

  Future<List<WeatherData>> fetchWeatherBatch(List<SeaLocation> locations) async {
    if (locations.isEmpty) return const [];
    final uri = Uri.parse('$baseUrl/v1/forecast').replace(queryParameters: {
      'latitude': locations.map((l) => l.latitude).join(','),
      'longitude': locations.map((l) => l.longitude).join(','),
      'current': 'weather_code,wind_speed_10m,wind_direction_10m,wind_gusts_10m,uv_index',
      'timezone': 'auto',
    });
    final json = await _getJson(uri);
    final list = _asList(json);
    return list.map(WeatherData.fromJson).toList();
  }

  Future<List<SeaLocation>> searchLocations(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];
    final uri = Uri.parse('https://geocoding-api.open-meteo.com/v1/search')
        .replace(queryParameters: {
      'name': trimmed,
      'count': '10',
      'language': 'en',
      'format': 'json',
    });
    final json = await _getJson(uri);
    final results = json['results'] as List?;
    if (results == null) return const [];
    return results
        .map((e) => SeaLocation.fromGeocoding(e as Map<String, dynamic>))
        .toList();
  }

  Future<dynamic> _getJson(Uri uri) async {
    http.Response response;
    try {
      response = await _client.get(uri, headers: _headers).timeout(_timeout);
    } on TimeoutException {
      throw ApiException('The request timed out — check your connection.');
    } catch (e) {
      throw ApiException('Network error: $e');
    }
    if (response.statusCode != 200) {
      throw ApiException('Service error (HTTP ${response.statusCode}).');
    }
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      throw ApiException('Could not read the server response.');
    }
  }

  Map<String, String> get _headers => {
        'User-Agent': 'Capitan sea companion (Flutter app)',
        'Accept': 'application/json',
      };

  static Map<String, dynamic> _asMap(dynamic json) {
    if (json is Map<String, dynamic>) return json;
    if (json is List && json.isNotEmpty && json.first is Map<String, dynamic>) {
      return json.first as Map<String, dynamic>;
    }
    throw ApiException('Unexpected response shape.');
  }

  static List<Map<String, dynamic>> _asList(dynamic json) {
    if (json is List) {
      return json.map((e) => e as Map<String, dynamic>).toList();
    }
    return [json as Map<String, dynamic>];
  }
}
