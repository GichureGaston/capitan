import 'package:flutter_test/flutter_test.dart';

import 'package:capitan/models/activity_rating.dart';
import 'package:capitan/models/weather_data.dart';

void main() {
  ConditionsSnapshot snapshot({
    required bool isDay,
    double windSpeed = 8,
    double? waveHeight = 0.2,
    bool hasMarineData = true,
  }) {
    return ConditionsSnapshot(
      time: DateTime(2026, 11, 11, isDay ? 11 : 23),
      windSpeed: windSpeed,
      windDirection: 90,
      waveHeight: waveHeight,
      seaSurfaceTemp: 23,
      hasMarineData: hasMarineData,
      isDay: isDay,
    );
  }

  group('night time', () {
    test('every activity becomes a rest suggestion at night', () {
      final ratings = ActivityRater.rateAll(snapshot(isDay: false));

      expect(ratings, hasLength(4));
      for (final rating in ratings) {
        expect(rating.level, RatingLevel.night);
        expect(rating.isNight, isTrue);
        expect(rating.reasons.first, contains('rest'));
      }
    });

    test('bestOf suggests nothing at night', () {
      final best = ActivityRater.bestOf(ActivityRater.rateAll(snapshot(isDay: false)));
      expect(best, isNull);
    });

    test('night applies even without marine data', () {
      final rating = ActivityRater.rate(
        SeaActivity.swimming,
        snapshot(isDay: false, hasMarineData: false, waveHeight: null),
      );
      expect(rating.level, RatingLevel.night);
    });

    test('night outranks even perfect sea conditions', () {
      final rating = ActivityRater.rate(SeaActivity.swimming, snapshot(isDay: false));
      expect(rating.level, RatingLevel.night);
      expect(rating.level.rank, 0);
    });

    test('calm daytime conditions are still rated as usual', () {
      final best = ActivityRater.bestOf(ActivityRater.rateAll(snapshot(isDay: true)));
      expect(best, isNotNull);
      expect(best!.level, RatingLevel.excellent);
    });
  });

  group('ConditionsSnapshot.fromForecast', () {
    WeatherData weatherFor({required bool isDay, bool includeIsDay = true}) =>
        WeatherData.fromJson({
          'current': {
            'time': isDay ? '2026-11-11T11:00' : '2026-11-11T23:00',
            'temperature_2m': 22,
            'wind_speed_10m': 8,
            'wind_direction_10m': 90,
            if (includeIsDay == true) 'is_day': isDay ? 1 : 0,
          },
          'hourly': const {
            'time': ['2026-11-11T23:00'],
          },
        });

    test('carries day/night from the current forecast', () {
      expect(
        ConditionsSnapshot.fromForecast(weatherFor(isDay: false), null).isDay,
        isFalse,
      );
      expect(
        ConditionsSnapshot.fromForecast(weatherFor(isDay: true), null).isDay,
        isTrue,
      );
    });

    test('a missing is_day field falls back to daytime, not night', () {
      expect(weatherFor(isDay: false, includeIsDay: false).current.isDay, isTrue);
    });
  });
}
