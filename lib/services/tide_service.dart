import '../models/marine_data.dart';

class TideService {
  const TideService._();

  static List<TideEvent> detectTides(MarineHourly hourly) {
    final events = <TideEvent>[];
    final levels = hourly.seaLevelHeightMsl;
    final times = hourly.time;

    int? lastValuedIndex;
    int direction = 0;

    for (var i = 0; i < levels.length; i++) {
      final level = levels[i];
      if (level == null) {
        lastValuedIndex = null;
        direction = 0;
        continue;
      }
      if (lastValuedIndex == null) {
        lastValuedIndex = i;
        continue;
      }
      final previous = levels[lastValuedIndex]!;
      if (level > previous) {
        if (direction < 0) {
          events.add(TideEvent(
            time: times[lastValuedIndex],
            isHigh: false,
            heightMsl: previous,
          ));
        }
        direction = 1;
      } else if (level < previous) {
        if (direction > 0) {
          events.add(TideEvent(
            time: times[lastValuedIndex],
            isHigh: true,
            heightMsl: previous,
          ));
        }
        direction = -1;
      }
      lastValuedIndex = i;
    }
    return events;
  }

  static List<TideEvent> upcomingTides(List<TideEvent> tides, DateTime from) =>
      tides.where((t) => t.time.isAfter(from)).toList();

  static TideEvent? nextTide(List<TideEvent> tides, DateTime from) {
    TideEvent? next;
    for (final t in tides) {
      if (t.time.isAfter(from) && (next == null || t.time.isBefore(next.time))) {
        next = t;
      }
    }
    return next;
  }

  static int tideTrend(MarineHourly hourly, DateTime at) {
    final i = hourly.indexOfNearestHour(at);
    if (i < 0) return 0;
    DoublePoint? previous;
    for (var j = i; j >= 0 && j > i - 3; j--) {
      final v = hourly.seaLevelHeightMsl[j];
      if (v != null) {
        previous = DoublePoint(hourly.time[j], v);
        break;
      }
    }
    DoublePoint? next;
    for (var j = i + 1; j < hourly.length; j++) {
      final v = hourly.seaLevelHeightMsl[j];
      if (v != null) {
        next = DoublePoint(hourly.time[j], v);
        break;
      }
    }
    if (previous == null || next == null) return 0;
    if (next.value > previous.value + 0.001) return 1;
    if (next.value < previous.value - 0.001) return -1;
    return 0;
  }

  static (double, double)? rangeAround(MarineHourly hourly, DateTime from, int hours) {
    final i = hourly.indexOfNearestHour(from);
    if (i < 0) return null;
    double? min;
    double? max;
    for (var j = i; j < hourly.length && j <= i + hours; j++) {
      final v = hourly.seaLevelHeightMsl[j];
      if (v == null) continue;
      if (min == null || v < min) min = v;
      if (max == null || v > max) max = v;
    }
    if (min == null || max == null) return null;
    return (min, max);
  }
}

class DoublePoint {
  const DoublePoint(this.time, this.value);
  final DateTime time;
  final double value;
}
