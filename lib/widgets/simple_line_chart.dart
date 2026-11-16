import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class SimpleLineChart extends StatelessWidget {
  const SimpleLineChart({
    super.key,
    required this.series,
    required this.colors,
    this.minX,
    this.maxX,
    this.minY = 0,
    this.maxY = 10,
    this.yInterval,
    this.xLabelBuilder,
    this.height = 150,
    this.xInterval,
  });

  final List<List<FlSpot>> series;

  final List<Color> colors;

  final double? minX;
  final double? maxX;
  final double minY;
  final double maxY;
  final double? yInterval;
  final double? xInterval;

  final String Function(double x)? xLabelBuilder;

  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final lines = <LineChartBarData>[];
    for (var i = 0; i < series.length; i++) {
      lines.add(
        LineChartBarData(
          spots: series[i],
          isCurved: true,
          curveSmoothness: 0.3,
          preventCurveOverShooting: true,
          barWidth: 2.2,
          color: colors[i % colors.length],
          dotData: const FlDotData(show: false),
        ),
      );
    }

    final span = (maxX ?? 24) - (minX ?? 0);

    double defaultInterval = 1.0;
    if (span / 4 > 0) {
      defaultInterval = span / 4;
    }

    final xInterval = this.xInterval ?? defaultInterval;

    return SizedBox(
      height: height,
      child: RepaintBoundary(
        child: LineChart(
          duration: Duration.zero,
          LineChartData(
            minY: minY,
            maxY: maxY,
            minX: minX,
            maxX: maxX,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: yInterval,
              getDrawingHorizontalLine: (v) => FlLine(
                color: scheme.outlineVariant.withValues(alpha: 0.5),
                strokeWidth: 0.8,
              ),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: yInterval,
                  getTitlesWidget: (value, meta) {
                    String label;
                    if (value == value.roundToDouble()) {
                      label = value.round().toString();
                    } else {
                      label = value.toStringAsFixed(1);
                    }

                    return SideTitleWidget(
                      meta: meta,
                      child: Text(label, style: textTheme.bodySmall),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  interval: xInterval == 0 ? 1 : xInterval,
                  getTitlesWidget: (value, meta) {
                    final label = xLabelBuilder?.call(value);
                    if (label == null) return const SizedBox.shrink();
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(label, style: textTheme.bodySmall),
                    );
                  },
                ),
              ),
            ),
            lineBarsData: lines,
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (spots) {
                  final items = <LineTooltipItem>[];
                  for (final spot in spots) {
                    items.add(
                      LineTooltipItem(
                        spot.y.toStringAsFixed(1),
                        textTheme.bodySmall!.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  }
                  return items;
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
