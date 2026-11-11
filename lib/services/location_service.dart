import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../models/sea_location.dart';

class LocationException implements Exception {
  LocationException(this.message);
  final String message;

  @override
  String toString() => message;
}

class LocationService {
  LocationService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<SeaLocation> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw LocationException('Location services are turned off — enable them or search instead.');
      }
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw LocationException('Location permission was denied — search for a place instead.');
      }
    } on LocationException {
      rethrow;
    } catch (e) {
      throw LocationException('Device location is unavailable here — search for a place instead.');
    }

    Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 20),
        ),
      );
    } on LocationServiceDisabledException {
      throw LocationException('Location services are turned off — enable them or search instead.');
    } catch (e) {
      throw LocationException('Could not get a GPS fix — try again or search instead.');
    }

    final name = await _reverseGeocode(position.latitude, position.longitude);
    return SeaLocation(
      name: name,
      latitude: position.latitude,
      longitude: position.longitude,
      admin: null,
      country: null,
      timezone: null,
    );
  }

  Future<String> _reverseGeocode(double lat, double lon) async {
    try {
      final uri = Uri.parse('https://nominatim.openstreetmap.org/reverse').replace(
        queryParameters: {
          'lat': '$lat',
          'lon': '$lon',
          'format': 'jsonv2',
          'zoom': '14',
        },
      );
      final response = await _client.get(uri, headers: {
        'User-Agent': 'Capitan sea companion (Flutter app)',
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return _fallbackName(lat, lon);
      final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final address = json['address'] as Map<String, dynamic>?;
      if (address == null) return _fallbackName(lat, lon);
      final parts = [
        address['suburb'] ?? address['village'] ?? address['town'] ?? address['city'],
        address['country'],
      ].whereType<String>().where((s) => s.isNotEmpty).toList();
      if (parts.isEmpty) return _fallbackName(lat, lon);
      return parts.join(', ');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Reverse geocode failed: $e');
      }
      return _fallbackName(lat, lon);
    }
  }

  static String _fallbackName(double lat, double lon) {
    final latLabel = '${lat.abs().toStringAsFixed(2)}°${lat >= 0 ? 'N' : 'S'}';
    final lonLabel = '${lon.abs().toStringAsFixed(2)}°${lon >= 0 ? 'E' : 'W'}';
    return 'My position ($latLabel, $lonLabel)';
  }
}
