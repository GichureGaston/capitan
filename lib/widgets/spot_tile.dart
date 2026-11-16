import 'package:flutter/material.dart';

import '../models/activity_rating.dart';
import '../models/swim_spot.dart';
import 'condition_tile.dart';

class SpotTile extends StatelessWidget {
  const SpotTile({super.key, required this.spot, required this.onUse});

  final SwimSpot spot;
  final void Function(SwimSpot spot) onUse;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rating = spot.swimmingRating;
    final conditions = spot.conditions;

    String waveText = '—';
    if (conditions != null && conditions.snapshot.waveHeight != null) {
      waveText = '${conditions.snapshot.waveHeight!.toStringAsFixed(1)} m';
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.beach_access, color: scheme.primary, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        spot.name,
                        style: Theme.of(context).textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${spot.distanceKm.toStringAsFixed(1)} km away · ${spot.surfaceLabel}',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                if (rating != null)
                  Pill(label: rating.level.label, color: rating.level.color),
              ],
            ),
            if (conditions != null) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 16,
                runSpacing: 4,
                children: [
                  _conditionText(context, Icons.waves, 'Waves', waveText),
                  _conditionText(
                    context,
                    Icons.air,
                    'Wind',
                    '${conditions.snapshot.windSpeed.round()} km/h',
                  ),
                  if (conditions.seaSurfaceTemp != null)
                    _conditionText(
                      context,
                      Icons.thermostat,
                      'Sea',
                      '${conditions.seaSurfaceTemp!.round()} °C',
                    ),
                  if (spot.supervised == true)
                    _conditionText(context, Icons.flag, 'Patrolled', 'Yes'),
                ],
              ),
              if (rating != null && rating.reasons.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  rating.reasons.first,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ],
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                onPressed: () => onUse(spot),
                icon: const Icon(Icons.near_me, size: 16),
                label: const Text('Use this spot'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _conditionText(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: scheme.primary),
        const SizedBox(width: 4),
        Text('$label $value', style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
