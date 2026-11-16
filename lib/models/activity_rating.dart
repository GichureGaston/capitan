import 'package:flutter/material.dart';

import '../utils/geo.dart';
import 'marine_data.dart';
import 'uv_advice.dart';
import 'weather_data.dart';

enum SeaActivity { snorkeling, freediving, surfing, swimming }

extension SeaActivityX on SeaActivity {
  String get label {
    switch (this) {
      case SeaActivity.snorkeling:
        return 'Snorkeling';
      case SeaActivity.freediving:
        return 'Freediving';
      case SeaActivity.surfing:
        return 'Surfing';
      case SeaActivity.swimming:
        return 'Swimming';
    }
  }

  IconData get icon {
    switch (this) {
      case SeaActivity.snorkeling:
        return Icons.visibility;
      case SeaActivity.freediving:
        return Icons.scuba_diving;
      case SeaActivity.surfing:
        return Icons.surfing;
      case SeaActivity.swimming:
        return Icons.pool;
    }
  }
}

enum RatingLevel { excellent, good, fair, poor, dangerous, unknown, night }

extension RatingLevelX on RatingLevel {
  String get label {
    switch (this) {
      case RatingLevel.excellent:
        return 'Excellent';
      case RatingLevel.good:
        return 'Good';
      case RatingLevel.fair:
        return 'Fair';
      case RatingLevel.poor:
        return 'Poor';
      case RatingLevel.dangerous:
        return 'Dangerous';
      case RatingLevel.unknown:
        return 'No sea data';
      case RatingLevel.night:
        return 'Night — rest';
    }
  }

  Color get color {
    switch (this) {
      case RatingLevel.excellent:
        return const Color(0xFF2E7D32);
      case RatingLevel.good:
        return const Color(0xFF7CB342);
      case RatingLevel.fair:
        return const Color(0xFFF9A825);
      case RatingLevel.poor:
        return const Color(0xFFEF6C00);
      case RatingLevel.dangerous:
        return const Color(0xFFC62828);
      case RatingLevel.unknown:
        return Colors.blueGrey;
      case RatingLevel.night:
        return const Color(0xFF3949AB);
    }
  }

  int get rank {
    switch (this) {
      case RatingLevel.excellent:
        return 5;
      case RatingLevel.good:
        return 4;
      case RatingLevel.fair:
        return 3;
      case RatingLevel.poor:
        return 2;
      case RatingLevel.dangerous:
        return 1;
      case RatingLevel.unknown:
        return 0;
      case RatingLevel.night:
        return 0;
    }
  }
}

class ConditionsSnapshot {
  const ConditionsSnapshot({
    required this.time,
    required this.windSpeed,
    required this.windDirection,
    this.windGusts,
    this.weatherCode,
    this.uvIndex,
    this.waveHeight,
    this.wavePeriod,
    this.seaSurfaceTemp,
    this.currentVelocity,
    this.hasMarineData = true,
    this.isDay = true,
  });

  final DateTime time;
  final double windSpeed;
  final double windDirection;
  final double? windGusts;
  final int? weatherCode;
  final double? uvIndex;
  final double? waveHeight;
  final double? wavePeriod;
  final double? seaSurfaceTemp;
  final double? currentVelocity;
  final bool hasMarineData;

  final bool isDay;

  factory ConditionsSnapshot.fromForecast(
    WeatherData weather,
    MarineData? marine,
  ) {
    final current = weather.current;
    return ConditionsSnapshot(
      time: current.time,
      windSpeed: current.windSpeed,
      windDirection: current.windDirection,
      windGusts: current.windGusts,
      weatherCode: current.weatherCode,
      uvIndex: weather.uvNow,
      waveHeight: marine?.current.waveHeight,
      wavePeriod: marine?.current.wavePeriod,
      seaSurfaceTemp: marine?.current.seaSurfaceTemperature,
      currentVelocity: marine?.current.oceanCurrentVelocity,
      hasMarineData: marine != null && marine.hasData,
      isDay: current.isDay,
    );
  }
}

class ActivityRating {
  const ActivityRating({
    required this.activity,
    required this.level,
    required this.reasons,
  });

  final SeaActivity activity;
  final RatingLevel level;

  final List<String> reasons;

  bool get isUnknown => level == RatingLevel.unknown;

  bool get isNight => level == RatingLevel.night;
}

class ActivityRater {
  const ActivityRater._();

  static ActivityRating rate(
    SeaActivity activity,
    ConditionsSnapshot conditions,
  ) {
    if (!conditions.isDay) {
      return _nightRating(activity);
    }
    if (!conditions.hasMarineData) {
      if (activity == SeaActivity.swimming) {
        return _rateSwimming(conditions);
      }
      return ActivityRating(
        activity: activity,
        level: RatingLevel.unknown,
        reasons: const [
          'No marine model data for this location — pick a coastal spot.',
        ],
      );
    }
    switch (activity) {
      case SeaActivity.swimming:
        return _rateSwimming(conditions);
      case SeaActivity.snorkeling:
        return _rateSnorkeling(conditions);
      case SeaActivity.freediving:
        return _rateFreediving(conditions);
      case SeaActivity.surfing:
        return _rateSurfing(conditions);
    }
  }

  static List<ActivityRating> rateAll(ConditionsSnapshot conditions) {
    final ratings = <ActivityRating>[];
    for (final activity in SeaActivity.values) {
      ratings.add(rate(activity, conditions));
    }
    return ratings;
  }

  static ActivityRating? bestOf(List<ActivityRating> ratings) {
    ActivityRating? best;
    for (final rating in ratings) {
      if (rating.isUnknown || rating.isNight) continue;
      if (best == null || rating.level.rank > best.level.rank) {
        best = rating;
      }
    }
    return best;
  }

  static ActivityRating _nightRating(SeaActivity activity) => ActivityRating(
    activity: activity,
    level: RatingLevel.night,
    reasons: const ['It\'s night — rest up and swim in daylight'],
  );

  static bool _stormy(int? code) => code != null && code >= 95;

  static String _windReason(ConditionsSnapshot conditions) {
    final from = compass16(conditions.windDirection);
    return 'Wind ${conditions.windSpeed.round()} km/h from $from'
        '${conditions.windGusts != null ? ' · gusts ${conditions.windGusts!.round()} km/h' : ''}';
  }

  static String _waveReason(double? h, double? period) {
    if (h == null) return 'Wave height unknown';
    final p = period != null ? ' · ${period.round()} s intervals' : '';
    return 'Waves ${h.toStringAsFixed(1)} m$p';
  }

  static String _seaTempReason(double? t, {double comfy = 22}) {
    if (t == null) return 'Sea temperature unknown';
    if (t >= comfy) return 'Sea ${t.round()}°C — no wetsuit needed';
    if (t >= 18) return 'Sea ${t.round()}°C — light wetsuit feels good';
    if (t >= 14) return 'Sea ${t.round()}°C — wetsuit recommended';
    return 'Sea ${t.round()}°C — cold; thick wetsuit & short sessions';
  }

  static String _uvReason(double? uv) {
    if (uv == null) return '';
    final advice = UvAdvice.current(uv);
    return 'UV ${advice.uvIndexLabel} — ${advice.shortPhrase}';
  }

  static RatingLevel _applyWind(RatingLevel level, double wind, double? gusts) {
    var result = level;
    if (wind > 40 || (gusts ?? 0) > 60) {
      if (result.rank > RatingLevel.poor.rank) result = RatingLevel.poor;
    }
    if (wind > 55 || (gusts ?? 0) > 75) {
      result = RatingLevel.dangerous;
    }
    return result;
  }

  static ActivityRating _rateSwimming(ConditionsSnapshot conditions) {
    final reasons = <String>[];
    if (_stormy(conditions.weatherCode)) {
      return ActivityRating(
        activity: SeaActivity.swimming,
        level: RatingLevel.dangerous,
        reasons: const ['Thunderstorm activity — stay out of the water'],
      );
    }

    var level = RatingLevel.excellent;
    final waves = conditions.waveHeight;
    if (waves != null) {
      if (waves > 0.6) level = RatingLevel.good;
      if (waves > 1.2) level = RatingLevel.fair;
      if (waves > 1.8) level = RatingLevel.poor;
      if (waves > 2.5) level = RatingLevel.dangerous;
      reasons.add(_waveReason(waves, conditions.wavePeriod));
    }
    if (conditions.windSpeed > 20) level = _worse(level, RatingLevel.good);
    if (conditions.windSpeed > 30) level = _worse(level, RatingLevel.fair);
    if (conditions.windSpeed > 40) level = _worse(level, RatingLevel.poor);
    level = _applyWind(level, conditions.windSpeed, conditions.windGusts);
    reasons.add(_windReason(conditions));
    if (conditions.seaSurfaceTemp != null) {
      reasons.add(_seaTempReason(conditions.seaSurfaceTemp, comfy: 22));
    }

    final uv = _uvReason(conditions.uvIndex);
    if (uv.isNotEmpty) reasons.add(uv);

    return ActivityRating(
      activity: SeaActivity.swimming,
      level: level,
      reasons: reasons,
    );
  }

  static ActivityRating _rateSnorkeling(ConditionsSnapshot conditions) {
    final reasons = <String>[];
    if (_stormy(conditions.weatherCode)) {
      return ActivityRating(
        activity: SeaActivity.snorkeling,
        level: RatingLevel.dangerous,
        reasons: const ['Thunderstorm activity — stay out of the water'],
      );
    }

    var level = RatingLevel.excellent;
    final waves = conditions.waveHeight;
    if (waves != null) {
      if (waves > 0.4) level = RatingLevel.good;
      if (waves > 0.8) level = RatingLevel.fair;
      if (waves > 1.4) level = RatingLevel.poor;
      if (waves > 2.0) level = RatingLevel.dangerous;
      reasons.add(_waveReason(waves, conditions.wavePeriod));
    }
    if (conditions.windSpeed > 15) level = _worse(level, RatingLevel.good);
    if (conditions.windSpeed > 25) level = _worse(level, RatingLevel.fair);
    if (conditions.windSpeed > 35) level = _worse(level, RatingLevel.poor);
    level = _applyWind(level, conditions.windSpeed, conditions.windGusts);
    reasons.add(_windReason(conditions));

    final drift = conditions.currentVelocity;
    if (drift != null && drift > 4) {
      level = _worse(level, RatingLevel.fair);
      reasons.add(
        'Ocean current ${drift.toStringAsFixed(1)} km/h — plan your exit point',
      );
    }

    if (conditions.seaSurfaceTemp != null) {
      reasons.add(_seaTempReason(conditions.seaSurfaceTemp, comfy: 24));
    }
    final uv = _uvReason(conditions.uvIndex);
    if (uv.isNotEmpty) reasons.add(uv);

    return ActivityRating(
      activity: SeaActivity.snorkeling,
      level: level,
      reasons: reasons,
    );
  }

  static ActivityRating _rateFreediving(ConditionsSnapshot conditions) {
    final reasons = <String>[];
    if (_stormy(conditions.weatherCode)) {
      return ActivityRating(
        activity: SeaActivity.freediving,
        level: RatingLevel.dangerous,
        reasons: const ['Thunderstorm activity — stay out of the water'],
      );
    }

    var level = RatingLevel.excellent;
    final waves = conditions.waveHeight;
    if (waves != null) {
      if (waves > 0.5) level = RatingLevel.good;
      if (waves > 1.0) level = RatingLevel.fair;
      if (waves > 1.6) level = RatingLevel.poor;
      if (waves > 2.5) level = RatingLevel.dangerous;
      reasons.add(_waveReason(waves, conditions.wavePeriod));
      final period = conditions.wavePeriod;
      if (period != null &&
          period >= 9 &&
          level.rank >= RatingLevel.good.rank) {
        reasons.add('Long ${period.round()} s swell — calm between sets');
      }
    }
    if (conditions.windSpeed > 12) level = _worse(level, RatingLevel.good);
    if (conditions.windSpeed > 25) level = _worse(level, RatingLevel.fair);
    if (conditions.windSpeed > 35) level = _worse(level, RatingLevel.poor);
    level = _applyWind(level, conditions.windSpeed, conditions.windGusts);
    reasons.add(_windReason(conditions));

    final drift = conditions.currentVelocity;
    if (drift != null) {
      if (drift > 2) level = _worse(level, RatingLevel.good);
      if (drift > 4) level = _worse(level, RatingLevel.fair);
      if (drift > 7) level = RatingLevel.dangerous;
      reasons.add(
        'Current ${drift.toStringAsFixed(1)} km/h — '
        'always dive with a buddy & surface marker',
      );
    }

    if (conditions.seaSurfaceTemp != null) {
      reasons.add(_seaTempReason(conditions.seaSurfaceTemp, comfy: 26));
    }

    return ActivityRating(
      activity: SeaActivity.freediving,
      level: level,
      reasons: reasons,
    );
  }

  static ActivityRating _rateSurfing(ConditionsSnapshot conditions) {
    final reasons = <String>[];
    if (_stormy(conditions.weatherCode)) {
      return ActivityRating(
        activity: SeaActivity.surfing,
        level: RatingLevel.dangerous,
        reasons: const ['Thunderstorm activity — stay out of the water'],
      );
    }

    final waves = conditions.waveHeight;
    var level = RatingLevel.fair;

    if (waves == null) {
      return ActivityRating(
        activity: SeaActivity.surfing,
        level: RatingLevel.unknown,
        reasons: const ['No wave data at this location'],
      );
    }

    if (waves < 0.3) {
      level = RatingLevel.poor;
      reasons.add('Waves ${waves.toStringAsFixed(1)} m — pretty much flat');
    } else if (waves < 0.6) {
      level = RatingLevel.fair;
      reasons.add(
        'Waves ${waves.toStringAsFixed(1)} m — small, fun for beginners',
      );
    } else if (waves < 1.2) {
      level = RatingLevel.good;
      reasons.add('Waves ${waves.toStringAsFixed(1)} m — clean rideable size');
    } else if (waves < 2.5) {
      level = RatingLevel.excellent;
      reasons.add('Waves ${waves.toStringAsFixed(1)} m — solid sessions');
    } else if (waves <= 4) {
      level = RatingLevel.fair;
      reasons.add(
        'Waves ${waves.toStringAsFixed(1)} m — big; experienced surfers only',
      );
    } else {
      return ActivityRating(
        activity: SeaActivity.surfing,
        level: RatingLevel.dangerous,
        reasons: ['Waves ${waves.toStringAsFixed(1)} m — dangerous surf'],
      );
    }

    final period = conditions.wavePeriod;
    if (period != null) {
      if (period >= 9) {
        reasons.add('Groundswell ${period.round()} s — clean lines');
      } else if (period < 6) {
        reasons.add('Windswell ${period.round()} s — choppy and disorganised');
      } else {
        reasons.add('Swell period ${period.round()} s');
      }
    }

    if (conditions.windSpeed > 12) level = _worse(level, RatingLevel.good);
    if (conditions.windSpeed > 25) level = _worse(level, RatingLevel.fair);
    if (conditions.windSpeed > 40) level = _worse(level, RatingLevel.poor);
    level = _applyWind(level, conditions.windSpeed, conditions.windGusts);
    reasons.add(_windReason(conditions));

    final uv = _uvReason(conditions.uvIndex);
    if (uv.isNotEmpty) reasons.add(uv);

    return ActivityRating(
      activity: SeaActivity.surfing,
      level: level,
      reasons: reasons,
    );
  }

  static RatingLevel _worse(RatingLevel current, RatingLevel cap) =>
      current.rank < cap.rank ? current : cap;
}
