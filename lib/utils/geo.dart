library;

import 'dart:math' as math;

String compass16(double degrees) {
  const labels = [
    'N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE',
    'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW',
  ];
  final normalized = degrees % 360;
  final index = ((normalized + 11.25) / 22.5).floor() % 16;
  return labels[index];
}

double distanceKm(double lat1, double lon1, double lat2, double lon2) {
  const earthRadiusKm = 6371.0;
  double rad(double deg) => deg * math.pi / 180.0;
  final dLat = rad(lat2 - lat1);
  final dLon = rad(lon2 - lon1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(rad(lat1)) * math.cos(rad(lat2)) * math.sin(dLon / 2) * math.sin(dLon / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthRadiusKm * c;
}

String formatCoords(double lat, double lon) {
  final latLabel = '${lat.abs().toStringAsFixed(2)}°${lat >= 0 ? 'N' : 'S'}';
  final lonLabel = '${lon.abs().toStringAsFixed(2)}°${lon >= 0 ? 'E' : 'W'}';
  return '$latLabel, $lonLabel';
}
