import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../utils/geo.dart';

class CompassDial extends StatelessWidget {
  const CompassDial({
    super.key,
    required this.direction,
    this.size = 132,
    this.color,
    this.center,
    this.caption,
  });

  final double direction;
  final double size;
  final Color? color;
  final Widget? center;
  final Widget? caption;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final arrowColor = color ?? scheme.primary;

    final dialChildren = <Widget>[
      CustomPaint(
        size: Size.square(size),
        painter: _CompassPainter(
          ringColor: scheme.outlineVariant,
          labelColor: scheme.onSurfaceVariant,
        ),
      ),
      Transform.rotate(
        angle: (direction + 180) * math.pi / 180.0,
        child: Icon(Icons.navigation, color: arrowColor, size: size * 0.36),
      ),
    ];
    if (center != null) {
      dialChildren.add(center!);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(alignment: Alignment.center, children: dialChildren),
        ),
        if (caption != null) ...[const SizedBox(height: 4), caption!],
      ],
    );
  }
}

class WindCompass extends StatelessWidget {
  const WindCompass({
    super.key,
    required this.direction,
    required this.speedKmh,
    this.gustsKmh,
    this.size = 132,
    this.color,
  });

  final double direction;
  final double speedKmh;
  final double? gustsKmh;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final from = compass16(direction);

    String caption = 'From $from';
    if (gustsKmh != null) {
      caption = '$caption · gusts ${gustsKmh!.round()}';
    }

    return CompassDial(
      direction: direction,
      size: size,
      color: color,
      caption: Text(
        caption,
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: scheme.onSurfaceVariant),
      ),
      center: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${speedKmh.round()}',
            style: TextStyle(
              fontSize: size * 0.17,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          Text(
            'km/h',
            style: TextStyle(
              fontSize: size * 0.09,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompassPainter extends CustomPainter {
  _CompassPainter({required this.ringColor, required this.labelColor});

  final Color ringColor;
  final Color labelColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 14;

    final circle = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..color = ringColor;
    canvas.drawCircle(center, radius, circle);

    final tick = Paint()
      ..strokeWidth = 1.1
      ..color = ringColor;
    for (var deg = 0; deg < 360; deg += 15) {
      final angle = deg * math.pi / 180.0;
      final inner = deg % 90 == 0 ? radius - 6 : radius - 3.5;
      canvas.drawLine(
        center + Offset(radius * math.sin(angle), -radius * math.cos(angle)),
        center + Offset(inner * math.sin(angle), -inner * math.cos(angle)),
        tick,
      );
    }

    const labels = ['N', 'E', 'S', 'W'];
    for (var i = 0; i < labels.length; i++) {
      final angle = i * 90 * math.pi / 180.0;
      final anchor =
          center +
          Offset(
            (radius + 8) * math.sin(angle),
            -(radius + 8) * math.cos(angle),
          );
      _paintLabel(canvas, labels[i], anchor);
    }
  }

  void _paintLabel(Canvas canvas, String label, Offset anchor) {
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: labelColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      anchor - Offset(painter.width / 2, painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _CompassPainter oldDelegate) =>
      oldDelegate.ringColor != ringColor ||
      oldDelegate.labelColor != labelColor;
}
