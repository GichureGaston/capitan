import 'package:flutter/material.dart';

import '../models/activity_rating.dart';

class ActivityCard extends StatelessWidget {
  const ActivityCard({super.key, required this.rating, this.compact = false});

  final ActivityRating rating;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = rating.level.color;
    final activity = rating.activity;
    final isLight = Theme.of(context).brightness == Brightness.light;

    Color accent;
    if (isLight) {
      accent = Color.lerp(color, Colors.black, 0.18)!;
    } else {
      accent = color;
    }

    Color cardColor;
    if (isLight) {
      cardColor = Color.alphaBlend(
        accent.withValues(alpha: 0.07),
        scheme.surfaceContainerLowest,
      );
    } else {
      cardColor = scheme.surfaceContainerLow;
    }

    Color pillText;
    if (ThemeData.estimateBrightnessForColor(color) == Brightness.dark) {
      pillText = Colors.white;
    } else {
      pillText = Colors.black87;
    }

    Color borderColor;
    if (isLight) {
      borderColor = accent.withValues(alpha: 0.38);
    } else {
      borderColor = scheme.outlineVariant.withValues(alpha: 0.5);
    }

    final reasons = <Widget>[];
    for (final reason in rating.reasons.take(4)) {
      reasons.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Icon(Icons.circle, size: 4, color: accent),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  reason,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor),
      ),
      margin: const EdgeInsets.all(5),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(activity.icon, size: 20, color: accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    activity.label,
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    rating.level.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: pillText,
                    ),
                  ),
                ),
              ],
            ),
            if (!compact) ...[const SizedBox(height: 8), ...reasons],
          ],
        ),
      ),
    );
  }
}
