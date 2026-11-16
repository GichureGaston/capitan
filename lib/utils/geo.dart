import 'dart:math' as math;

String compass16(double degrees) {
  const labels = [
    'N',
    'NNE',
    'NE',
    'ENE',
    'E',
    'ESE',
    'SE',
    'SSE',
    'S',
    'SSW',
    'SW',
    'WSW',
    'W',
    'WNW',
    'NW',
    'NNW',
  ];
  final normalized = degrees % 360;
  final index = ((normalized + 11.25) / 22.5).floor() % 16;
  return labels[index];
}

double distanceKm(double lat1, double lon1, double lat2, double lon2) {
  const earthRadiusKm = 6371.0;
  final dLat = _toRadians(lat2 - lat1);
  final dLon = _toRadians(lon2 - lon1);
  final a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_toRadians(lat1)) *
          math.cos(_toRadians(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthRadiusKm * c;
}

double _toRadians(double degrees) => degrees * math.pi / 180.0;

String formatCoords(double lat, double lon) {
  final latLabel = '${lat.abs().toStringAsFixed(2)}°${lat >= 0 ? 'N' : 'S'}';
  final lonLabel = '${lon.abs().toStringAsFixed(2)}°${lon >= 0 ? 'E' : 'W'}';
  return '$latLabel, $lonLabel';
}
