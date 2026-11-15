import 'package:flutter/material.dart';

import '../models/species.dart';

/// Bundled species photo with a graceful emoji fallback when the entry has no
/// image (or the asset cannot be loaded).
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

    // Decode only as many pixels as the widget can actually show. The source
    // photos are ~600x400–960x640, so list thumbnails would otherwise allocate
    // a full-resolution bitmap for every row.
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final isThumbnail = width != null && width! <= 100;

    final photo = entry.hasImage
        ? Image.asset(
            entry.image!,
            width: width,
            height: height,
            fit: BoxFit.cover,
            cacheWidth: width == null ? null : (width! * dpr).round(),
            cacheHeight: height == null ? null : (height! * dpr).round(),
            filterQuality:
                isThumbnail ? FilterQuality.low : FilterQuality.medium,
            errorBuilder: (_, _, _) => fallback,
          )
        : fallback;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: photo,
    );
  }
}
