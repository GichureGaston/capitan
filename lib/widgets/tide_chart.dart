import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';

import '../models/marine_data.dart';

class TideChart extends StatelessWidget {
  const TideChart({
    super.key,
    required this.hourly,
    required this.from,
    required this.windowHours,
    this.height = 220,
  });

  static final _timeFormat = DateFormat('HH:mm');
  static final _dayFormat = DateFormat('E');

  final MarineHourly hourly;

  final DateTime from;

  final int windowHours;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final startIndex = hourly.indexOfNearestHour(from);
    final spots = <FlSpot>[];
    double? minY;
    double? maxY;
    for (
      var i = startIndex;
      i < hourly.length && i <= startIndex + windowHours;
      i++
    ) {
      final level = hourly.seaLevelHeightMsl[i];
      if (level == null) continue;
      final hoursFromStart = i - startIndex;
      spots.add(FlSpot(hoursFromStart.toDouble(), level));
      if (minY == null || level < minY) minY = level;
      if (maxY == null || level > maxY) maxY = level;
    }
    if (spots.length < 3) {
      return SizedBox(
        height: height,
        child: const Center(child: Text('No tide data for this window.')),
      );
    }

    final padding = 0.12;
    final yMin = (minY ?? 0) - padding;
    final yMax = (maxY ?? 1) + padding;

    double tickInterval;
    if (windowHours <= 24) {
      tickInterval = 3.0;
    } else if (windowHours <= 48) {
      tickInterval = 6.0;
    } else {
      tickInterval = 24.0;
    }

    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.only(top: 8, right: 10, left: 4),
        child: RepaintBoundary(
          child: LineChart(
            duration: Duration.zero,
            LineChartData(
              minY: yMin,
              maxY: yMax,
              minX: 0,
              maxX: windowHours.toDouble(),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 0.5,
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
                  axisNameWidget: Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text('m', style: textTheme.bodySmall),
                  ),
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: 0.5,
                    getTitlesWidget: (value, meta) => SideTitleWidget(
                      meta: meta,
                      child: Text(
                        value.toStringAsFixed(1),
                        style: textTheme.bodySmall,
                      ),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    interval: tickInterval,
                    getTitlesWidget: (value, meta) {
                      if (value % tickInterval != 0) {
                        return const SizedBox.shrink();
                      }
                      final hourIndex = startIndex + value.toInt();
                      if (hourIndex < 0 || hourIndex >= hourly.length) {
                        return const SizedBox.shrink();
                      }
                      final time = hourly.time[hourIndex];

                      String label;
                      if (windowHours <= 48) {
                        label = _timeFormat.format(time);
                      } else {
                        label = _dayFormat.format(time);
                      }

                      return SideTitleWidget(
                        meta: meta,
                        child: Text(label, style: textTheme.bodySmall),
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.35,
                  preventCurveOverShooting: true,
                  barWidth: 2.4,
                  color: scheme.primary,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        scheme.primary.withValues(alpha: 0.30),
                        scheme.primary.withValues(alpha: 0.04),
                      ],
                    ),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spots) {
                    final items = <LineTooltipItem>[];
                    for (final spot in spots) {
                      items.add(
                        LineTooltipItem(
                          '${spot.y.toStringAsFixed(2)} m',
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
      ),
    );
  }
}
