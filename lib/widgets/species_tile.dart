import 'package:flutter/material.dart';

import '../models/species.dart';
import 'condition_tile.dart';
import 'species_image.dart';

class SpeciesTile extends StatelessWidget {
  const SpeciesTile({super.key, required this.entry, required this.onTap});

  final SpeciesEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Color dangerColor;
    if (entry.danger == 'venomous' || entry.danger == 'sting') {
      dangerColor = const Color(0xFFD62828);
    } else if (entry.isDangerous) {
      dangerColor = const Color(0xFFEF6C00);
    } else {
      dangerColor = scheme.onSurfaceVariant;
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              SpeciesImage(entry: entry, width: 52, height: 52, emojiSize: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.name,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (entry.isDangerous)
                          Pill(label: entry.dangerLabel, color: dangerColor),
                      ],
                    ),
                    Text(
                      entry.scientificName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: scheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
