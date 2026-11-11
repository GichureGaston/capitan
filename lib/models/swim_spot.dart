import 'activity_rating.dart';

class SwimSpot {
  const SwimSpot({
    required this.osmId,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
    this.surface,
    this.supervised,
    this.conditions,
  });

  final String osmId;
  final String name;
  final double latitude;
  final double longitude;
  final double distanceKm;
  final String? surface;
  final bool? supervised;

  final SpotConditions? conditions;

  SwimSpot copyWith({SpotConditions? conditions}) => SwimSpot(
        osmId: osmId,
        name: name,
        latitude: latitude,
        longitude: longitude,
        distanceKm: distanceKm,
        surface: surface,
        supervised: supervised,
        conditions: conditions ?? this.conditions,
      );

  factory SwimSpot.fromOverpass(Map<String, dynamic> element, {required double distanceKm}) {
    final type = element['type'] as String;
    final id = element['id'] as int;
    double lat;
    double lon;
    if (element.containsKey('center')) {
      lat = (element['center']['lat'] as num).toDouble();
      lon = (element['center']['lon'] as num).toDouble();
    } else {
      lat = (element['lat'] as num).toDouble();
      lon = (element['lon'] as num).toDouble();
    }
    final tags = element['tags'] as Map<String, dynamic>?;
    return SwimSpot(
      osmId: '$type/$id',
      name: (tags?['name'] as String?) ?? 'Unnamed beach',
      latitude: lat,
      longitude: lon,
      distanceKm: distanceKm,
      surface: tags?['surface'] as String?,
      supervised: tags?['supervised'] == 'yes' ? true : null,
    );
  }

  ActivityRating? get swimmingRating => conditions?.rating;

  String get surfaceLabel => switch (surface) {
        'sand' => 'Sandy',
        'gravel' => 'Gravel',
        'pebblestone' => 'Pebbles',
        'shingle' => 'Shingle',
        'rock' => 'Rocky',
        'stones' => 'Stony',
        null => 'Natural',
        _ => surface!,
      };
}

class SpotConditions {
  const SpotConditions({
    required this.snapshot,
    required this.rating,
    required this.seaSurfaceTemp,
  });

  final ConditionsSnapshot snapshot;
  final ActivityRating rating;
  final double? seaSurfaceTemp;
}
