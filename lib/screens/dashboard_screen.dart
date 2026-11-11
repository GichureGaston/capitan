import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_state.dart';
import '../models/activity_rating.dart';
import '../models/marine_data.dart';
import '../models/uv_advice.dart';
import '../models/weather_data.dart';
import '../services/tide_service.dart';
import '../widgets/activity_card.dart';
import '../widgets/condition_tile.dart';
import '../widgets/uv_card.dart';
import '../widgets/wind_compass.dart';
import 'location_sheet.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppStateScope.of(context);

    if (app.location == null) {
      return const _NoLocationState();
    }
    if (app.error != null && app.weather == null) {
      return _ErrorState(message: app.error!, onRetry: app.refresh);
    }
    if (app.weather == null) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    final weather = app.weather!;
    final marine = app.marine;
    final snapshot = app.snapshot;
    final current = weather.current;
    final uvNow = weather.uvNow ?? 0;
    final uvMax = weather.uvMaxToday ?? uvNow;
    final ratings =
        snapshot == null ? const <ActivityRating>[] : ActivityRater.rateAll(snapshot);
    final best = ActivityRater.bestOf(ratings);
    final tideTrend = marine == null ? 0 : TideService.tideTrend(marine.hourly, current.time);

    return RefreshIndicator(
      onRefresh: app.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _HeroHeader(app: app, weather: weather, best: best),
          if (app.error != null) _RefreshFailedBanner(message: app.error!),
          if (app.marineNotice != null) _MarineNoticeCard(text: app.marineNotice!),
          const SectionHeader('Conditions right now'),
          _WindCard(weather: weather),
          _ConditionGrid(weather: weather, marine: marine, tideTrend: tideTrend),
          const SectionHeader('Sun protection', icon: Icons.wb_sunny),
          UvCard(
            advice: UvAdvice.current(uvNow),
            peakLabel: weather.uvPeakTimeToday == null
                ? 'Peak UV today: ${_formatUv(uvMax)}'
                : 'Peak UV today: ${_formatUv(uvMax)} around '
                    '${DateFormat('HH:mm').format(weather.uvPeakTimeToday!)}',
          ),
          const SectionHeader('Activity ratings'),
          if (ratings.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Ratings appear once conditions load.'),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth > 600 ? 4 : 2;
                  final cardWidth = constraints.maxWidth / columns - 10;
                  return Wrap(
                    children: [
                      for (final r in ratings)
                        SizedBox(width: cardWidth, child: ActivityCard(rating: r)),
                    ],
                  );
                },
              ),
            ),
          const SectionHeader('Sun times'),
          const _SunTimesCard(),
          const SectionHeader('Next 7 days'),
          _DailyStrip(weather: weather),
          const SizedBox(height: 12),
          const _AttributionFooter(),
        ],
      ),
    );
  }

  static String _formatUv(double uv) =>
      uv >= 10 ? uv.round().toString() : uv.toStringAsFixed(1);
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.app, required this.weather, this.best});

  final AppState app;
  final WeatherData weather;
  final ActivityRating? best;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final current = weather.current;
    final location = app.location!;

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
                    location.label,
                    style: TextStyle(
                      color: scheme.onPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (app.lastUpdated != null)
                  Text(
                    'Updated ${DateFormat('HH:mm').format(app.lastUpdated!)}',
                    style: TextStyle(
                        color: scheme.onPrimary.withValues(alpha: 0.85), fontSize: 12),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  WmoWeather.icon(current.weatherCode, isDay: current.isDay),
                  color: scheme.onPrimary,
                  size: 54,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${current.temperature.round()}°C',
                      style: TextStyle(
                        color: scheme.onPrimary,
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    Text(
                      '${WmoWeather.label(current.weatherCode)} · feels like '
                      '${current.apparentTemperature.round()}°C',
                      style: TextStyle(
                        color: scheme.onPrimary.withValues(alpha: 0.9),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (best != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(best!.activity.icon, size: 18, color: scheme.onPrimary),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Best right now: ${best!.activity.label} — '
                        '${best!.level.label.toLowerCase()}',
                        style: TextStyle(
                          color: scheme.onPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RefreshFailedBanner extends StatelessWidget {
  const _RefreshFailedBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
      child: Card(
        color: scheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.cloud_off, size: 18, color: scheme.onErrorContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Last refresh failed: $message',
                  style: TextStyle(color: scheme.onErrorContainer),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MarineNoticeCard extends StatelessWidget {
  const _MarineNoticeCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
      child: Card(
        color: scheme.secondaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: scheme.onSecondaryContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(color: scheme.onSecondaryContainer),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WindCard extends StatelessWidget {
  const _WindCard({required this.weather});

  final WeatherData weather;

  @override
  Widget build(BuildContext context) {
    final current = weather.current;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            WindCompass(
              direction: current.windDirection,
              speedKmh: current.windSpeed,
              gustsKmh: current.windGusts,
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _stat(context, Icons.water_drop, 'Humidity',
                      '${current.humidity.round()}%'),
                  const SizedBox(height: 8),
                  _stat(context, Icons.air, 'Gusts',
                      current.windGusts > 0 ? '${current.windGusts.round()} km/h' : '—'),
                  const SizedBox(height: 8),
                  _stat(
                    context,
                    Icons.cloud,
                    'Cloud cover',
                    '${current.cloudCover.round()}%',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(BuildContext context, IconData icon, String label, String value) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 15, color: scheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _ConditionGrid extends StatelessWidget {
  const _ConditionGrid({
    required this.weather,
    required this.marine,
    required this.tideTrend,
  });

  final WeatherData weather;
  final MarineData? marine;
  final int tideTrend;

  @override
  Widget build(BuildContext context) {
    final current = weather.current;
    final seaLevel = marine?.current.seaLevelMsl;
    final waveHeight = marine?.current.waveHeight;
    final wavePeriod = marine?.current.wavePeriod;
    final seaTemp = marine?.current.seaSurfaceTemperature;
    final uvNow = weather.uvNow;

    final tiles = <Widget>[
      ConditionTile(
        icon: Icons.waves,
        label: 'Wave height',
        value: waveHeight == null ? '—' : '${waveHeight.toStringAsFixed(1)} m',
        sublabel: wavePeriod == null
            ? 'No sea model data'
            : '${wavePeriod.round()} s intervals',
      ),
      ConditionTile(
        icon: Icons.thermostat,
        label: 'Sea temperature',
        value: seaTemp == null ? '—' : '${seaTemp.toStringAsFixed(1)} °C',
        sublabel: _seaTempComment(seaTemp),
      ),
      ConditionTile(
        icon: tideTrend >= 0 ? Icons.north : Icons.south,
        label: 'Sea level & tide',
        value: seaLevel == null ? '—' : '${seaLevel.toStringAsFixed(2)} m',
        sublabel: tideTrend > 0
            ? 'Rising — flooding'
            : tideTrend < 0
                ? 'Falling — ebbing'
                : seaLevel != null
                    ? 'Slack / steady'
                    : 'No tide data here',
      ),
      ConditionTile(
        icon: Icons.wb_sunny,
        label: 'UV index',
        value: uvNow == null ? '—' : UvAdvice.current(uvNow).uvIndexLabel,
        sublabel: weather.uvMaxToday == null ? null : 'Peak ${weather.uvMaxToday!.round()} today',
        accentColor: uvNow == null ? null : UvAdvice.current(uvNow).color,
      ),
      ConditionTile(
        icon: Icons.visibility,
        label: 'Visibility',
        value: _visibilityLabel(weather.hourly, current.time),
      ),
      ConditionTile(
        icon: Icons.umbrella,
        label: 'Rain chance',
        value: _rainChanceLabel(weather.hourly, current.time),
        sublabel: 'Next few hours',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: GridView.count(
        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.95,
        children: tiles,
      ),
    );
  }

  static String? _seaTempComment(double? t) {
    if (t == null) return null;
    if (t >= 24) return 'Tropical — no wetsuit';
    if (t >= 20) return 'Pleasant';
    if (t >= 16) return 'Wetsuit territory';
    return 'Cold water';
  }

  static String _visibilityLabel(WeatherHourly hourly, DateTime now) {
    final i = hourly.indexOfNearestHour(now);
    if (i < 0 || hourly.visibility[i] == null) return '—';
    final km = hourly.visibility[i]! / 1000;
    if (km >= 20) return '${km.round()} km — clear';
    if (km >= 10) return '${km.round()} km';
    return '${km.toStringAsFixed(1)} km — hazy';
  }

  static String _rainChanceLabel(WeatherHourly hourly, DateTime now) {
    final i = hourly.indexOfNearestHour(now);
    if (i < 0) return '—';
    double? max;
    for (var j = i; j < hourly.length && j < i + 4; j++) {
      final v = hourly.precipitationProbability[j];
      if (v != null) max = max == null || v > max ? v : max;
    }
    return max == null ? '—' : '${max.round()}%';
  }
}

class _SunTimesCard extends StatelessWidget {
  const _SunTimesCard();

  @override
  Widget build(BuildContext context) {
    final app = AppStateScope.of(context);
    final weather = app.weather;
    final scheme = Theme.of(context).colorScheme;
    final sunrise = weather?.sunriseToday;
    final sunset = weather?.sunsetToday;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _timeEntry(context, Icons.wb_twilight, 'Sunrise',
                sunrise == null ? '—' : DateFormat('HH:mm').format(sunrise)),
            Container(width: 1, height: 36, color: scheme.outlineVariant),
            _timeEntry(context, Icons.wb_sunny, 'Peak UV window', '11:00-15:00'),
            Container(width: 1, height: 36, color: scheme.outlineVariant),
            _timeEntry(context, Icons.nights_stay, 'Sunset',
                sunset == null ? '—' : DateFormat('HH:mm').format(sunset)),
          ],
        ),
      ),
    );
  }

  Widget _timeEntry(BuildContext context, IconData icon, String label, String value) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Icon(icon, color: scheme.primary, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        Text(label, style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
      ],
    );
  }
}

class _DailyStrip extends StatelessWidget {
  const _DailyStrip({required this.weather});

  final WeatherData weather;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: weather.daily.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final day = weather.daily[index];
          final uvMax = day.uvIndexMax;
          final uvColor = uvMax == null ? null : UvAdvice.dailyMax(uvMax).color;
          return SizedBox(
            width: 108,
            child: Card(
              elevation: 0,
              color: scheme.surfaceContainerLow,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      index == 0 ? 'Today' : DateFormat('EEE').format(day.date),
                      style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Icon(
                      WmoWeather.icon(day.weatherCode, isDay: true),
                      size: 28,
                      color: scheme.primary,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${day.tempMin?.round() ?? '-'}° / ${day.tempMax?.round() ?? '-'}°',
                      style: textTheme.bodySmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      day.windSpeedMax == null ? '' : '${day.windSpeedMax!.round()} km/h',
                      style:
                          textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                    if (uvMax != null)
                      Text(
                        'UV ${uvMax.round()}',
                        style: textTheme.bodySmall?.copyWith(
                          color: uvColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AttributionFooter extends StatelessWidget {
  const _AttributionFooter();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        'Weather, tides & sea state: Open-Meteo (Copernicus Marine, NOAA, DWD, '
        'ECMWF). Tide heights are model estimates above mean sea level — not for '
        'navigation. Beaches: © OpenStreetMap contributors.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 10.5, color: scheme.onSurfaceVariant),
      ),
    );
  }
}

class _NoLocationState extends StatelessWidget {
  const _NoLocationState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sailing, size: 64, color: scheme.primary),
            const SizedBox(height: 16),
            Text('Where are you headed?', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Pick your beach, bay or island to see tides, wind, UV and '
              'swimming conditions for your spot.',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => showLocationSheet(context),
              icon: const Icon(Icons.search),
              label: const Text('Choose location'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 64, color: scheme.error),
            const SizedBox(height: 16),
            Text('Could not load conditions',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
