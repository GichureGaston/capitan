import 'package:flutter/material.dart';

import '../models/uv_advice.dart';

class UvCard extends StatelessWidget {
  const UvCard({
    super.key,
    required this.advice,
    this.peakLabel,
    this.compact = false,
  });

  final UvAdvice advice;

  final String? peakLabel;

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = advice.color;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.22),
              scheme.surfaceContainerLow,
            ],
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.wb_sunny, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sun exposure · UV ${advice.uvIndexLabel} (${advice.category})',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _UvBar(uvIndex: advice.uvIndex, color: color),
            const SizedBox(height: 10),
            Text(
              advice.headline,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: color, fontWeight: FontWeight.w700),
            ),
            if (peakLabel != null) ...[
              const SizedBox(height: 2),
              Text(
                peakLabel!,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
            if (!compact) ...[
              const SizedBox(height: 10),
              ...advice.tips.map(
                (tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(Icons.check_circle_outline,
                            size: 14, color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(tip)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _UvBar extends StatelessWidget {
  const _UvBar({required this.uvIndex, required this.color});

  final double uvIndex;
  final Color color;

  static const _bands = <(double, Color)>[
    (0, Color(0xFF3E9B4F)),
    (3, Color(0xFFE6C229)),
    (6, Color(0xFFF77F00)),
    (8, Color(0xFFD62828)),
    (11, Color(0xFF8E24AA)),
  ];

  @override
  Widget build(BuildContext context) {
    final fraction = (uvIndex / 12).clamp(0.0, 1.0);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return SizedBox(
          height: 26,
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    children: [
                      for (var i = 0; i < _bands.length; i++)
                        Expanded(
                          child: Container(color: _bands[i].$2.withValues(alpha: 0.85)),
                        ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: fraction * (width - 3),
                child: Container(
                  width: 3,
                  height: 26,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: const [
                      BoxShadow(color: Colors.black38, blurRadius: 2, spreadRadius: 0.5),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 6,
                top: 5,
                child: Text(
                  '0',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.95),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Positioned(
                right: 6,
                top: 5,
                child: Text(
                  '11+',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
