import 'package:flutter/material.dart';

import '../data/species_repository.dart';
import 'species_screen.dart';

class CoralScreen extends StatelessWidget {
  const CoralScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SpeciesScreen(type: SpeciesType.coral);
  }
}
