import 'package:flutter/material.dart';

import '../data/species_repository.dart';
import '../models/species.dart';
import '../widgets/condition_tile.dart';
import '../widgets/species_image.dart';

class SpeciesDetailScreen extends StatelessWidget {
  const SpeciesDetailScreen({
    super.key,
    required this.entry,
    required this.type,
  });

  final SpeciesEntry entry;
  final SpeciesType type;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Color? dangerColor;
    if (entry.danger == 'venomous' || entry.danger == 'sting') {
      dangerColor = const Color(0xFFD62828);
    } else if (entry.isDangerous) {
      dangerColor = const Color(0xFFEF6C00);
    }

    final rows = <_DetailRow>[];
    if (entry.size != null) {
      rows.add(_DetailRow(Icons.straighten, 'Typical size', entry.size!));
    }
    if (entry.diet != null) {
      rows.add(_DetailRow(Icons.restaurant, 'Diet', entry.diet!));
    }
    if (entry.habitat != null) {
      rows.add(_DetailRow(Icons.waves, 'Habitat', entry.habitat!));
    }
    if (entry.conservation != null) {
      rows.add(
        _DetailRow(Icons.eco, 'Conservation status', entry.conservation!),
      );
    }
    if (entry.imageSource != null) {
      rows.add(
        _DetailRow(
          Icons.photo_camera_outlined,
          'Photo source',
          entry.imageSource!,
        ),
      );
    }
    rows.add(
      _DetailRow(
        Icons.public,
        'Regions',
        entry.regions.map(SpeciesRepository.regionLabel).join(' · '),
      ),
    );

    final detailWidgets = <Widget>[];
    for (final row in rows) {
      detailWidgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(row.icon, size: 18, color: scheme.primary),
              const SizedBox(width: 12),
              SizedBox(
                width: 130,
                child: Text(
                  row.label,
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(child: Text(row.value)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(entry.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (entry.hasImage) ...[
            SpeciesImage(
              entry: entry,
              height: 220,
              borderRadius: 18,
              emojiSize: 64,
            ),
            if (entry.imageAttribution != null)
              Padding(
                padding: const EdgeInsets.only(top: 6, right: 4),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Photo: ${entry.imageAttribution}',
                    style: textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 14),
          ],
          Row(
            children: [
              if (!entry.hasImage)
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    entry.emoji,
                    style: const TextStyle(fontSize: 44),
                  ),
                ),
              if (!entry.hasImage) const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.name,
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entry.scientificName,
                      style: textTheme.titleSmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (dangerColor != null)
                          Pill(label: entry.dangerLabel, color: dangerColor),
                        if (entry.conservation != null)
                          Pill(
                            label: entry.conservation!,
                            color: scheme.tertiary,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'About',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            entry.description,
            style: textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
          if (entry.funFact.isNotEmpty) ...[
            const SizedBox(height: 20),
            Card(
              elevation: 0,
              color: scheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: scheme.onSecondaryContainer,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        entry.funFact,
                        style: textTheme.bodyMedium?.copyWith(
                          color: scheme.onSecondaryContainer,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (entry.isDangerous) ...[
            const SizedBox(height: 20),
            Card(
              elevation: 0,
              color: const Color(0xFFD62828).withValues(alpha: 0.12),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber, color: Color(0xFFD62828)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _safetyNote(),
                        style: textTheme.bodyMedium?.copyWith(height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          ...detailWidgets,
          const SizedBox(height: 8),
          Text(
            'This guide is for identification and general interest — local '
            'regulations and protected-species rules always apply.',
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _safetyNote() {
    switch (entry.danger) {
      case 'venomous':
        return 'Venomous species. Do not touch or harass — stings can be '
            'medically serious. Give them space and watch from a distance. '
            'If stung: leave the water, immobilise the area and seek medical '
            'help (for tropical species, hot water immersion helps for some '
            'stings, but follow local emergency guidance).';
      case 'sting':
        return 'This species stings on contact. Keep your distance, avoid '
            'brushing against it, and consider a full-body rash guard in '
            'areas where it is common.';
      case 'bite':
        return 'Can bite when provoked or guarding nests. Keep a respectful '
            'distance and never corner one.';
      case 'poison':
        return 'Poisonous to eat and risky to handle — never touch bare-handed '
            'and never consume.';
      case 'sharp':
        return 'Sharp spines or edges — watch where you put your hands and '
            'feet, and consider reef shoes.';
      default:
        return 'Treat all wildlife with respect — look, don\'t touch.';
    }
  }
}

class _DetailRow {
  const _DetailRow(this.icon, this.label, this.value);
  final IconData icon;
  final String label;
  final String value;
}
