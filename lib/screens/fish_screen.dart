import 'package:material_ui/material_ui.dart';

import '../data/species_repository.dart';
import 'species_screen.dart';

class FishScreen extends StatelessWidget {
  const FishScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SpeciesScreen(type: SpeciesType.fish);
  }
}
