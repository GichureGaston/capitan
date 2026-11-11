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
      );

  bool get isDangerous => danger != 'harmless';

  String get dangerLabel => switch (danger) {
        'sting' => 'Stings',
        'venomous' => 'Venomous',
        'bite' => 'Bites when provoked',
        'sharp' => 'Sharp / spiny',
        'poison' => 'Poisonous to eat',
        _ => 'Harmless',
      };

  bool matchesQuery(String query) {
    if (query.trim().isEmpty) return true;
    final q = query.trim().toLowerCase();
    return name.toLowerCase().contains(q) || scientificName.toLowerCase().contains(q);
  }

  bool inAnyRegion(List<String> tags) => regions.any(tags.contains);
}
