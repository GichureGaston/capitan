import 'package:flutter/material.dart';

import '../models/species.dart';

class SpeciesImage extends StatelessWidget {
  const SpeciesImage({
    super.key,
    required this.entry,
    this.width,
    this.height,
    this.borderRadius = 12,
    this.emojiSize = 24,
  });

  final SpeciesEntry entry;
  final double? width;
  final double? height;
  final double borderRadius;
  final double emojiSize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fallback = Container(
      width: width,
      height: height,
      color: scheme.primaryContainer.withValues(alpha: 0.5),
      alignment: Alignment.center,
      child: Text(entry.emoji, style: TextStyle(fontSize: emojiSize)),
    );

    Widget photo;
    if (entry.hasImage) {
      photo = Image.asset(
        entry.image!,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      );
    } else {
      photo = fallback;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: photo,
    );
  }
}
