class SpeciesEntry {
  const SpeciesEntry({
    required this.id,
    required this.name,
    required this.scientificName,
    required this.emoji,
    required this.description,
    required this.funFact,
    required this.regions,
    this.danger = 'harmless',
    this.diet,
    this.size,
    this.habitat,
    this.conservation,
    this.image,
    this.imageSource,
    this.imageCredit,
    this.imageLicense,
  });

  final String id;
  final String name;
  final String scientificName;
  final String emoji;
  final String description;
  final String funFact;
  final List<String> regions;

  final String danger;
  final String? diet;
  final String? size;
  final String? habitat;
  final String? conservation;

  final String? image;
  final String? imageSource;
  final String? imageCredit;
  final String? imageLicense;

  factory SpeciesEntry.fromJson(Map<String, dynamic> json) => SpeciesEntry(
    id: json['id'] as String,
    name: json['name'] as String,
    scientificName: json['scientificName'] as String,
    emoji: (json['emoji'] as String?) ?? '🐠',
    description: json['description'] as String,
    funFact: (json['funFact'] as String?) ?? '',
    regions: (json['regions'] as List).map((e) => e as String).toList(),
    danger: (json['danger'] as String?) ?? 'harmless',
    diet: json['diet'] as String?,
    size: json['size'] as String?,
    habitat: json['habitat'] as String?,
    conservation: json['conservation'] as String?,
    image: json['image'] as String?,
    imageSource: json['imageSource'] as String?,
    imageCredit: json['imageCredit'] as String?,
    imageLicense: json['imageLicense'] as String?,
  );

  bool get isDangerous => danger != 'harmless';

  bool get hasImage => image != null && image!.isNotEmpty;

  String? get imageAttribution {
    if (!hasImage) return null;
    final parts = [
      if (imageCredit?.trim().isNotEmpty ?? false) imageCredit!.trim(),
      if (imageLicense?.trim().isNotEmpty ?? false) imageLicense!.trim(),
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  String get dangerLabel {
    switch (danger) {
      case 'sting':
        return 'Stings';
      case 'venomous':
        return 'Venomous';
      case 'bite':
        return 'Bites when provoked';
      case 'sharp':
        return 'Sharp / spiny';
      case 'poison':
        return 'Poisonous to eat';
      default:
        return 'Harmless';
    }
  }

  bool matchesQuery(String query) {
    if (query.trim().isEmpty) return true;
    final q = query.trim().toLowerCase();
    return name.toLowerCase().contains(q) ||
        scientificName.toLowerCase().contains(q);
  }

  bool inAnyRegion(List<String> tags) => regions.any(tags.contains);
}
