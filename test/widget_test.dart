import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:capitan/app_state.dart';
import 'package:capitan/data/species_repository.dart';
import 'package:capitan/main.dart';
import 'package:capitan/models/species.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('app smoke test', () {
    testWidgets('shows the no-location welcome state and builds all tabs',
        (tester) async {
      await tester.pumpWidget(CapitanApp(appState: AppState()));

      expect(find.text('Where are you headed?'), findsOneWidget);
      expect(find.text('Choose location'), findsOneWidget);

      for (final label in ['Now', 'Tides', 'Spots', 'Fish', 'Coral']) {
        expect(find.text(label), findsWidgets);
      }

      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('bundled species data', () {
    List<Map<String, dynamic>> load(String path) {
      final raw = File(path).readAsStringSync();
      return (jsonDecode(raw) as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();
    }

    test('fish.json parses into valid entries', () {
      final entries = load('assets/data/fish.json');
      expect(entries.length, greaterThanOrEqualTo(25));

      final ids = <String>{};
      final validDanger = {
        'harmless', 'sting', 'venomous', 'bite', 'sharp', 'poison',
      };
      for (final e in entries) {
        final entry = SpeciesEntry.fromJson(e);
        expect(entry.name, isNotEmpty);
        expect(entry.scientificName, isNotEmpty);
        expect(entry.description, isNotEmpty);
        expect(entry.regions, isNotEmpty);
        expect(validDanger, contains(entry.danger));
        expect(ids, isNot(contains(entry.id)),
            reason: 'duplicate id ${entry.id}');
        ids.add(entry.id);
      }
    });

    test('coral.json parses into valid entries', () {
      final entries = load('assets/data/coral.json');
      expect(entries.length, greaterThanOrEqualTo(15));

      final ids = <String>{};
      for (final e in entries) {
        final entry = SpeciesEntry.fromJson(e);
        expect(entry.name, isNotEmpty);
        expect(entry.scientificName, isNotEmpty);
        expect(entry.regions, isNotEmpty);
        expect(ids, isNot(contains(entry.id)),
            reason: 'duplicate id ${entry.id}');
        ids.add(entry.id);
      }
    });

    test('species queries match common and scientific names', () {
      const entry = SpeciesEntry(
        id: 't',
        name: 'Queen Angelfish',
        scientificName: 'Holacanthus ciliaris',
        emoji: '🐠',
        description: 'A striking Caribbean reef fish.',
        funFact: '',
        regions: ['caribbean'],
      );
      expect(entry.matchesQuery('queen'), isTrue);
      expect(entry.matchesQuery('CILIARIS'), isTrue);
      expect(entry.matchesQuery(' clown'), isFalse);
      expect(entry.inAnyRegion(['indo-pacific']), isFalse);
      expect(entry.inAnyRegion(['caribbean', 'global']), isTrue);
    });
  });

  group('region matching', () {
    test('maps known coordinates to biogeographic tags', () {
      expect(SpeciesRepository.regionsForLocation(18.0, -77.0),
          containsAll(['tropical', 'caribbean']));
      expect(SpeciesRepository.regionsForLocation(27.0, 34.0),
          containsAll(['red-sea', 'indo-pacific']));
      expect(SpeciesRepository.regionsForLocation(41.0, 2.0),
          contains('mediterranean'));
      expect(SpeciesRepository.regionsForLocation(-33.9, 151.2),
          containsAll(['australia-temperate']));
      expect(SpeciesRepository.regionsForLocation(60.0, 5.0),
          contains('temperate'));
    });
  });
}
