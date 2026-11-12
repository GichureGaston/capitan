import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:capitan/models/species.dart';
import 'package:capitan/widgets/species_tile.dart';

SpeciesEntry _entry({String? image}) => SpeciesEntry(
      id: 'clownfish',
      name: 'Clownfish',
      scientificName: 'Amphiprion ocellaris',
      emoji: '🐠',
      description: 'Orange reef fish.',
      funFact: '',
      regions: const ['indo-pacific'],
      image: image,
      imageCredit: image == null ? null : 'Ritiks',
      imageLicense: image == null ? null : 'CC BY-SA 3.0',
    );

void main() {
  testWidgets('species tile falls back to the emoji when there is no photo',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SpeciesTile(entry: _entry(), onTap: () {}),
        ),
      ),
    );

    expect(find.text('🐠'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('species tile shows the bundled photo when available',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SpeciesTile(
            entry: _entry(image: 'assets/images/clownfish.jpg'),
            onTap: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsOneWidget);
  });
}
