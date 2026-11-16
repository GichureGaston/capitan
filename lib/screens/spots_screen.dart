import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../app_bloc.dart';
import '../models/activity_rating.dart';
import '../models/marine_data.dart';
import '../models/sea_location.dart';
import '../models/swim_spot.dart';
import '../models/weather_data.dart';
import '../services/open_meteo.dart';
import '../services/overpass_service.dart';
import '../widgets/spot_tile.dart';
import 'location_sheet.dart';

class SpotsScreen extends StatefulWidget {
  const SpotsScreen({super.key, this.onUseSpot, this.overpass});

  final VoidCallback? onUseSpot;

  final OverpassService? overpass;

  @override
  State<SpotsScreen> createState() => _SpotsScreenState();
}

class _SpotsScreenState extends State<SpotsScreen> {
  late OverpassService _overpass;

  List<SwimSpot> _spots = const [];
  bool _loading = false;
  String? _error;
  int _radiusKm = 25;
  String? _loadedKey;
  int _loadSeq = 0;

  @override
  void initState() {
    super.initState();
    _overpass = widget.overpass ?? OverpassService();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final location = context.watch<AppBloc>().state.location;
    final key = location == null
        ? null
        : '${location.label}|${location.latitude}|${location.longitude}';
    if (key == _loadedKey) return;
    if (location == null) {
      if (_loadedKey != null) {
        setState(() {
          _spots = const [];
          _loadedKey = null;
          _error = null;
        });
      }
      return;
    }
    _loadSpots();
  }

  Future<void> _loadSpots() async {
    final location = context.read<AppBloc>().state.location;
    if (location == null) return;
    final api = context.read<OpenMeteoApi>();
    final seq = ++_loadSeq;

    setState(() {
      _loading = true;
      _error = null;
      _loadedKey =
          '${location.label}|${location.latitude}|${location.longitude}';
    });

    try {
      final spots = await _overpass.fetchSpots(
        location.latitude,
        location.longitude,
        radiusKm: _radiusKm,
      );
      if (seq != _loadSeq || !mounted) return;

      if (spots.isEmpty) {
        setState(() {
          _loading = false;
          _spots = const [];
        });
        return;
      }

      final target = spots.take(10).toList();
      final locations = <SeaLocation>[];
      for (final spot in target) {
        locations.add(
          SeaLocation(
            name: spot.name,
            latitude: spot.latitude,
            longitude: spot.longitude,
          ),
        );
      }

      List<WeatherData> weatherBatch = const [];
      List<MarineData> marineBatch = const [];
      try {
        weatherBatch = await api.fetchWeatherBatch(locations);
        marineBatch = await api.fetchMarineBatch(locations);
      } on ApiException {
        weatherBatch = const [];
        marineBatch = const [];
      }

      final enriched = <SwimSpot>[];
      for (var i = 0; i < target.length; i++) {
        final spot = target[i];
        final weather = i < weatherBatch.length ? weatherBatch[i] : null;
        final marine = i < marineBatch.length ? marineBatch[i] : null;
        final marineOk = marine != null && marine.hasData;

        ConditionsSnapshot? snapshot;
        if (weather != null) {
          if (marineOk) {
            snapshot = ConditionsSnapshot.fromForecast(weather, marine);
          } else {
            snapshot = ConditionsSnapshot.fromForecast(weather, null);
          }
        }

        if (snapshot == null) {
          enriched.add(spot);
          continue;
        }

        enriched.add(
          spot.copyWith(
            conditions: SpotConditions(
              snapshot: snapshot,
              rating: ActivityRater.rate(SeaActivity.swimming, snapshot),
              seaSurfaceTemp: marine?.current.seaSurfaceTemperature,
            ),
          ),
        );
      }

      if (seq != _loadSeq || !mounted) return;
      setState(() {
        _loading = false;
        _spots = enriched;
      });
    } on ApiException catch (e) {
      if (seq != _loadSeq || !mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (e) {
      if (seq != _loadSeq || !mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load nearby spots: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = context.watch<AppBloc>().state.location;
    final scheme = Theme.of(context).colorScheme;

    if (location == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.beach_access, size: 64, color: scheme.primary),
              const SizedBox(height: 16),
              const Text('Choose a location to find nearby swim spots.'),
              const SizedBox(height: 16),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Around ${location.name}',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                tooltip: 'Refresh spots',
                onPressed: _loading ? null : _loadSpots,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 10, label: Text('10 km')),
              ButtonSegment(value: 25, label: Text('25 km')),
              ButtonSegment(value: 50, label: Text('50 km')),
            ],
            selected: {_radiusKm},
            onSelectionChanged: (selection) {
              setState(() => _radiusKm = selection.first);
              _loadSpots();
            },
          ),
        ),
        const SizedBox(height: 6),
        Expanded(child: _buildBody(context)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Text(
            'Spots from OpenStreetMap. Conditions are model forecasts for the '
            'area — always respect local signage and lifeguard advice.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10.5, color: scheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 48),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(_error!, textAlign: TextAlign.center),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _loadSpots,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_spots.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'No named beaches within $_radiusKm km. '
            'Try a larger search radius or another location.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 6),
      itemCount: _spots.length,
      itemBuilder: (context, index) => SpotTile(
        spot: _spots[index],
        onUse: (spot) {
          final location = context.read<AppBloc>().state.location;
          context.read<AppBloc>().add(
            LocationSelected(
              SeaLocation(
                name: spot.name,
                latitude: spot.latitude,
                longitude: spot.longitude,
                admin: location?.admin,
                country: location?.country,
              ),
            ),
          );
          widget.onUseSpot?.call();
        },
      ),
    );
  }
}
