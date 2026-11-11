class SeaLocation {
  const SeaLocation({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.admin,
    this.country,
    this.timezone,
  });

  final String name;

  final String? admin;

  final String? country;
  final double latitude;
  final double longitude;
  final String? timezone;

  String get label {
    final parts = <String>[name];
    if (admin != null && admin!.isNotEmpty && admin != name) parts.add(admin!);
    if (country != null && country!.isNotEmpty) parts.add(country!);
    return parts.join(', ');
  }

  factory SeaLocation.fromJson(Map<String, dynamic> json) => SeaLocation(
        name: json['name'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        admin: json['admin'] as String?,
        country: json['country'] as String?,
        timezone: json['timezone'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'admin': admin,
        'country': country,
        'timezone': timezone,
      };

  factory SeaLocation.fromGeocoding(Map<String, dynamic> json) => SeaLocation(
        name: json['name'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        admin: json['admin1'] as String?,
        country: json['country'] as String?,
        timezone: json['timezone'] as String?,
      );

  SeaLocation withName(String newName) => SeaLocation(
        name: newName,
        latitude: latitude,
        longitude: longitude,
        admin: admin,
        country: country,
        timezone: timezone,
      );

  @override
  String toString() => 'SeaLocation($label @ $latitude,$longitude)';
}
