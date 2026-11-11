import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../app_bloc.dart';
import '../models/marine_data.dart';
import '../models/weather_data.dart';
import '../services/tide_service.dart';
import '../utils/geo.dart';
import '../widgets/condition_tile.dart';
import '../widgets/simple_line_chart.dart';
import '../widgets/tide_chart.dart';
import '../widgets/wind_compass.dart';

class TidesScreen extends StatelessWidget {
  const TidesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppBloc>().state;

    if (state.location == null) {
      return _promptLocation(context);
    }
    if (state.weather == null) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (state.marine == null) {
      return _noMarineData(context);
    }

    return const _TidesBody();
  }

  Widget _promptLocation(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.waves, size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            const Text('Pick a coastal location to see tides.'),
          ],
        ),
      ),
    );
  }

  Widget _noMarineData(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.waves, size: 64, color: scheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text('No tide data at this location',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'The tide model covers open ocean and coastal waters. '
              'Try a spot closer to the sea.',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _TidesBody extends StatefulWidget {
  const _TidesBody();

  @override
  State<_TidesBody> createState() => _TidesBodyState();
}

class _TidesBodyState extends State<_TidesBody> {
  int _windowHours = 48;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppBloc>().state;
    final marine = state.marine!;
    final weather = state.weather!;
    final now = weather.current.time;
    final hourly = marine.hourly;

    final tides = TideService.detectTides(hourly);
    final upcoming = TideService.upcomingTides(tides, now);
    final next = upcoming.isEmpty ? null : upcoming.first;
    final levelNow = hourly.seaLevelAt(now);
    final trend = TideService.tideTrend(hourly, now);
    final range = TideService.rangeAround(hourly, now, 24);
    final uvNow = weather.uvNow;

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _NextTideBanner(
          next: next,
          levelNow: levelNow,
          trend: trend,
          locationLabel: state.location!.name,
        ),
        const SectionHeader('Sea level (tides)', icon: Icons.waves),
        Card(
          elevation: 0,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 6, 10, 6),
            child: Column(
              children: [
                TideChart(
                  hourly: hourly,
                  from: now,
                  windowHours: _windowHours,
                ),
                const SizedBox(height: 8),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 24, label: Text('24 h')),
                    ButtonSegment(value: 48, label: Text('48 h')),
                    ButtonSegment(value: 168, label: Text('7 d')),
                  ],
                  selected: {_windowHours},
                  onSelectionChanged: (selection) =>
                      setState(() => _windowHours = selection.first),
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        ),
        if (range != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Expanded(
                  child: ConditionTile(
                    icon: Icons.swap_vert,
                    label: 'Tidal range · next 24 h',
                    value:
                        '${(range.$2 - range.$1).toStringAsFixed(2)} m',
                    sublabel:
                        'Low ${(range.$1).toStringAsFixed(2)} m · high ${(range.$2).toStringAsFixed(2)} m',
                  ),
                ),
              ],
            ),
          ),
        const SectionHeader('Upcoming tides', icon: Icons.update),
        for (final tide in upcoming.take(6))
          _TideRow(tide: tide, isNext: tide == next),
        const SectionHeader('Waves & currents', icon: Icons.waves),
        _WaveCard(marine: marine),
        const SectionHeader('Wind & gusts', icon: Icons.air),
        _WindHourlyChart(weather: weather),
        if (uvNow != null) ...[
          const SectionHeader('Sun while you swim', icon: Icons.wb_sunny),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'UV index is ${uvNow.toStringAsFixed(1)} right now — see the '
              'dashboard for your sunscreen plan.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Tide heights are modelled above mean sea level (Open-Meteo, '
            'Copernicus Marine). Coastal features can shift local tides — '
            'always check local tide tables for navigation-critical use.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.5,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _NextTideBanner extends StatelessWidget {
  const _NextTideBanner({
    required this.next,
    required this.levelNow,
    required this.trend,
    required this.locationLabel,
  });

  final TideEvent? next;
  final double? levelNow;
  final int trend;
  final String locationLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();

    String headline;
    String detail;
    if (next == null) {
      headline = 'Tide model available';
      detail = 'No turning points found in the current forecast window.';
    } else {
      final remaining = next!.time.difference(now);
      final hours = remaining.inMinutes ~/ 60;
      final minutes = remaining.inMinutes % 60;
      final inPhrase = remaining.isNegative
          ? 'about now'
          : 'in ${hours > 0 ? '$hours h ' : ''}$minutes min';
      headline = '${next!.label} $inPhrase';
      detail = '${next!.label} at ${DateFormat('HH:mm').format(next!.time)} · '
          '${next!.heightMsl.toStringAsFixed(2)} m';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary,
            scheme.primary.withValues(alpha: 0.72),
            scheme.tertiary,
          ],
        ),
      ),
      child: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.place, color: scheme.onPrimary, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    locationLabel,
                    style: TextStyle(
                      color: scheme.onPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (levelNow != null)
                  Text(
                    'Sea ${levelNow!.toStringAsFixed(2)} m',
                    style: TextStyle(
                      color: scheme.onPrimary.withValues(alpha: 0.9),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  trend > 0
                      ? Icons.north
                      : trend < 0
                          ? Icons.south
                          : Icons.swap_vert,
                  color: scheme.onPrimary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        headline,
                        style: TextStyle(
                          color: scheme.onPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        detail,
                        style: TextStyle(
                          color: scheme.onPrimary.withValues(alpha: 0.9),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TideRow extends StatelessWidget {
  const _TideRow({required this.tide, required this.isNext});

  final TideEvent tide;
  final bool isNext;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = tide.isHigh ? scheme.primary : scheme.tertiary;

    return Card(
      elevation: 0,
      color: isNext ? scheme.primaryContainer.withValues(alpha: 0.4) : null,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: ListTile(
        dense: true,
        leading: Icon(
          tide.isHigh ? Icons.north : Icons.south,
          color: color,
        ),
        title: Text(
          '${tide.label} · ${tide.heightMsl.toStringAsFixed(2)} m',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: isTextToday(tide.time)
            ? Text('Today at ${DateFormat('HH:mm').format(tide.time)}')
            : Text(DateFormat('EEE HH:mm').format(tide.time)),
        trailing: isNext ? const Pill(label: 'Next', color: Colors.teal) : null,
      ),
    );
  }

  static bool isTextToday(DateTime time) {
    final now = DateTime.now();
    return time.year == now.year && time.month == now.month && time.day == now.day;
  }
}

class _WaveCard extends StatelessWidget {
  const _WaveCard({required this.marine});

  final MarineData marine;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final current = marine.current;
    final waveDirection = current.waveDirection;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CompassDial(
              direction: waveDirection ?? 0,
              size: 112,
              color: scheme.secondary,
              center: Text(
                current.waveHeight == null
                    ? '—'
                    : '${current.waveHeight!.toStringAsFixed(1)} m',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              caption: Text(
                waveDirection == null ? 'Direction unknown' : 'Waves from ${compass16(waveDirection)}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ConditionTile(
                          icon: Icons.av_timer,
                          label: 'Wave period',
                          value: current.wavePeriod == null
                              ? '—'
                              : '${current.wavePeriod!.round()} s',
                        ),
                      ),
                      Expanded(
                        child: ConditionTile(
                          icon: Icons.thermostat,
                          label: 'Sea temperature',
                          value: current.seaSurfaceTemperature == null
                              ? '—'
                              : '${current.seaSurfaceTemperature!.toStringAsFixed(1)} °C',
                        ),
                      ),
                    ],
                  ),
                  ConditionTile(
                    icon: Icons.water,
                    label: 'Ocean current',
                    value: current.oceanCurrentVelocity == null
                        ? '—'
                        : '${current.oceanCurrentVelocity!.toStringAsFixed(1)} km/h',
                    sublabel: current.oceanCurrentDirection == null
                        ? null
                        : 'towards ${compass16(current.oceanCurrentDirection!)}',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WindHourlyChart extends StatelessWidget {
  const _WindHourlyChart({required this.weather});

  final WeatherData weather;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final hourly = weather.hourly;
    final startIndex = hourly.indexOfNearestHour(weather.current.time);

    final windSpots = <FlSpot>[];
    final gustSpots = <FlSpot>[];
    double maxVal = 10;
    for (var i = startIndex; i < hourly.length && i <= startIndex + 24; i++) {
      final wind = hourly.windSpeed[i];
      final gust = hourly.windGusts[i];
      final x = (i - startIndex).toDouble();
      if (wind != null) {
        windSpots.add(FlSpot(x, wind));
        if (wind > maxVal) maxVal = wind;
      }
      if (gust != null) {
        gustSpots.add(FlSpot(x, gust));
        if (gust > maxVal) maxVal = gust;
      }
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 14, 8, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.show_chart, size: 16, color: scheme.primary),
                const SizedBox(width: 6),
                Text('Wind speed next 24 h (km/h)',
                    style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
                const Spacer(),
                Icon(Icons.circle, size: 8, color: scheme.primary),
                const SizedBox(width: 3),
                Text('avg', style: textTheme.bodySmall),
                const SizedBox(width: 8),
                Icon(Icons.circle, size: 8, color: scheme.error),
                const SizedBox(width: 3),
                Text('gusts', style: textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 10),
            SimpleLineChart(
              series: [windSpots, gustSpots],
              colors: [scheme.primary, scheme.error],
              minX: 0,
              maxX: 24,
              minY: 0,
              maxY: maxVal * 1.15,
              yInterval: 10,
              xInterval: 6,
              xLabelBuilder: (x) {
                final hourIndex = startIndex + x.toInt();
                if (hourIndex < 0 || hourIndex >= hourly.length) return '';
                return DateFormat('HH:mm').format(hourly.time[hourIndex]);
              },
            ),
          ],
        ),
      ),
    );
  }
}
