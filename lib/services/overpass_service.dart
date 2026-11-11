import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/swim_spot.dart';
import '../utils/geo.dart';
import 'open_meteo.dart';

class OverpassService {
  OverpassService({http.Client? client, this.endpoint = 'https://overpass-api.de/api/interpreter'})
      : _client = client ?? http.Client();

  final http.Client _client;
  final String endpoint;

  Future<List<SwimSpot>> fetchSpots(
    double latitude,
    double longitude, {
    int radiusKm = 25,
    int limit = 15,
  }) async {
    final radiusM = (radiusKm * 1000).round();
    final query = '[out:json][timeout:30];('
        'node["natural"="beach"](around:$radiusM,$latitude,$longitude);'
        'way["natural"="beach"](around:$radiusM,$latitude,$longitude);'
        'relation["natural"="beach"](around:$radiusM,$latitude,$longitude);'
        'node["leisure"="swimming_area"](around:$radiusM,$latitude,$longitude);'
        'way["leisure"="swimming_area"](around:$radiusM,$latitude,$longitude);'
        ');out tags center 60;';

    final uri = Uri.parse(endpoint).replace(queryParameters: {'data': query});
    http.Response response;
    try {
      response = await _client.get(uri, headers: {
        'User-Agent': 'Capitan sea companion (Flutter app)',
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 40));
    } on TimeoutException {
      throw ApiException('The beach search timed out — try again.');
    } catch (e) {
      throw ApiException('Network error: $e');
    }
    if (response.statusCode != 200) {
      throw ApiException('Beach search failed (HTTP ${response.statusCode}).');
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    final elements = (decoded['elements'] as List?) ?? const [];

    final spots = <SwimSpot>[];
    final seen = <String>{};
    for (final element in elements) {
      final map = element as Map<String, dynamic>;
      final tags = map['tags'] as Map<String, dynamic>?;
      final name = tags?['name'] as String?;
      if (name == null || name.trim().isEmpty) continue;

      double spotLat;
      double spotLon;
      if (map.containsKey('center')) {
        spotLat = (map['center']['lat'] as num).toDouble();
        spotLon = (map['center']['lon'] as num).toDouble();
      } else if (map.containsKey('lat')) {
        spotLat = (map['lat'] as num).toDouble();
        spotLon = (map['lon'] as num).toDouble();
      } else {
        continue;
      }

      final key =
          '$name|${spotLat.toStringAsFixed(3)}|${spotLon.toStringAsFixed(3)}';
      if (!seen.add(key)) continue;

      spots.add(SwimSpot.fromOverpass(
        map,
        distanceKm: geoDistance(latitude, longitude, spotLat, spotLon),
      ));
    }

    spots.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return spots.take(limit).toList();
  }
}

double geoDistance(double lat1, double lon1, double lat2, double lon2) =>
    distanceKm(lat1, lon1, lat2, lon2);
