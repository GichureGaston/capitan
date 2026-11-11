import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/species.dart';

class SpeciesRepository {
  const SpeciesRepository._();

  static final Map<String, List<SpeciesEntry>> _cache = {};

  static Future<List<SpeciesEntry>> load(SpeciesType type) async {
    final key = type.name;
    if (_cache.containsKey(key)) return _cache[key]!;
    final path = switch (type) {
      SpeciesType.fish => 'assets/data/fish.json',
      SpeciesType.coral => 'assets/data/coral.json',
    };
    final raw = await rootBundle.loadString(path);
    final list = jsonDecode(raw) as List;
    final entries =
        list.map((e) => SpeciesEntry.fromJson(e as Map<String, dynamic>)).toList();
    _cache[key] = entries;
    return entries;
  }

  static List<String> regionsForLocation(double latitude, double longitude) {
    final tags = <String>{'global'};
    final tropical = latitude.abs() <= 23.5;
    if (tropical) tags.add('tropical');

    if (latitude >= 7 && latitude <= 28 && longitude >= -100 && longitude <= -55) {
      tags.add('caribbean');
    }

    final inIndoPacificBox =
        (longitude >= 28 && longitude <= 180 || longitude >= -155 && longitude <= -140) &&
            latitude >= -35 &&
            latitude <= 35;
    if (inIndoPacificBox) {
      tags.add('indo-pacific');
    }

    if (latitude >= 10 && latitude <= 30 && longitude >= 32 && longitude <= 45) {
      tags.add('red-sea');
    }

    if (latitude >= 30 && latitude <= 46 && longitude >= -6 && longitude <= 36) {
      tags.add('mediterranean');
    }

    if (longitude < -78 && longitude >= -170 && latitude >= -42 && latitude <= 48) {
      tags.add('east-pacific');
    }

    if (latitude <= -28 && latitude >= -44 && longitude >= 138 && longitude <= 155) {
      tags.add('australia-temperate');
    }

    if (!tropical && tags.length == 1) {
      tags.add('temperate');
    }
    return tags.toList(growable: false);
  }

  static List<SpeciesEntry> filter(
    List<SpeciesEntry> entries, {
    String query = '',
    List<String>? regionTags,
  }) {
    Iterable<SpeciesEntry> result = entries;
    if (regionTags != null && regionTags.isNotEmpty) {
      result = result.where((e) => e.inAnyRegion(regionTags));
    }
    if (query.trim().isNotEmpty) {
      result = result.where((e) => e.matchesQuery(query));
    }
    return result.toList();
  }

  static String regionLabel(String tag) => switch (tag) {
        'global' => 'Worldwide',
        'tropical' => 'Tropical seas',
        'caribbean' => 'Caribbean & W. Atlantic',
        'indo-pacific' => 'Indo-Pacific',
        'red-sea' => 'Red Sea',
        'mediterranean' => 'Mediterranean',
        'east-pacific' => 'E. Pacific & Americas',
        'australia-temperate' => 'S. Australia',
        'temperate' => 'Temperate waters',
        _ => tag,
      };
}

enum SpeciesType { fish, coral }
