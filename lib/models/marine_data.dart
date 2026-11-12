class MarineData {
  const MarineData({
    required this.current,
    required this.hourly,
    required this.daily,
  });

  final MarineCurrent current;
  final MarineHourly hourly;
  final List<MarineDay> daily;

  factory MarineData.fromJson(Map<String, dynamic> json) {
    final current = MarineCurrent.fromJson(json['current'] as Map<String, dynamic>);
    // Batch marine responses may omit hourly/daily data.
    final hourlyRaw = json['hourly'] as Map<String, dynamic>?;
    final hourly = hourlyRaw == null
        ? MarineHourly.fromJson(const {'time': <String>[]})
        : MarineHourly.fromJson(hourlyRaw);
    final dailyRaw = json['daily'] as Map<String, dynamic>?;
    final daily = <MarineDay>[];
    if (dailyRaw != null) {
      final count = (dailyRaw['time'] as List).length;
      for (var i = 0; i < count; i++) {
        daily.add(MarineDay.fromIndexedJson(dailyRaw, i));
      }
    }
    return MarineData(current: current, hourly: hourly, daily: daily);
  }

  bool get hasData =>
      hourly.waveHeight.any((v) => v != null) ||
      hourly.seaLevelHeightMsl.any((v) => v != null) ||
      hourly.seaSurfaceTemperature.any((v) => v != null);
}

class MarineCurrent {
  const MarineCurrent({
    required this.time,
    required this.waveHeight,
    required this.waveDirection,
    required this.wavePeriod,
    required this.seaSurfaceTemperature,
    required this.oceanCurrentVelocity,
    required this.oceanCurrentDirection,
    required this.seaLevelMsl,
  });

  final DateTime time;
  final double? waveHeight;
  final double? waveDirection;
  final double? wavePeriod;
  final double? seaSurfaceTemperature;
  final double? oceanCurrentVelocity;
  final double? oceanCurrentDirection;
  final double? seaLevelMsl;

  factory MarineCurrent.fromJson(Map<String, dynamic> json) => MarineCurrent(
        time: DateTime.parse(json['time'] as String),
        waveHeight: _num(json['wave_height']),
        waveDirection: _num(json['wave_direction']),
        wavePeriod: _num(json['wave_period']),
        seaSurfaceTemperature: _num(json['sea_surface_temperature']),
        oceanCurrentVelocity: _num(json['ocean_current_velocity']),
        oceanCurrentDirection: _num(json['ocean_current_direction']),
        seaLevelMsl: _num(json['sea_level_height_msl']),
      );
}

class MarineHourly {
  const MarineHourly({
    required this.time,
    required this.waveHeight,
    required this.waveDirection,
    required this.wavePeriod,
    required this.seaSurfaceTemperature,
    required this.seaLevelHeightMsl,
    required this.oceanCurrentVelocity,
    required this.oceanCurrentDirection,
  });

  final List<DateTime> time;
  final List<double?> waveHeight;
  final List<double?> waveDirection;
  final List<double?> wavePeriod;
  final List<double?> seaSurfaceTemperature;
  final List<double?> seaLevelHeightMsl;
  final List<double?> oceanCurrentVelocity;
  final List<double?> oceanCurrentDirection;

  factory MarineHourly.fromJson(Map<String, dynamic> json) {
    final time = (json['time'] as List).map((e) => DateTime.parse(e as String)).toList();
    List<double?> doubles(String key) =>
        (json[key] as List?)?.map((e) => e == null ? null : (e as num).toDouble()).toList() ??
            List<double?>.filled(time.length, null);
    return MarineHourly(
      time: time,
      waveHeight: doubles('wave_height'),
      waveDirection: doubles('wave_direction'),
      wavePeriod: doubles('wave_period'),
      seaSurfaceTemperature: doubles('sea_surface_temperature'),
      seaLevelHeightMsl: doubles('sea_level_height_msl'),
      oceanCurrentVelocity: doubles('ocean_current_velocity'),
      oceanCurrentDirection: doubles('ocean_current_direction'),
    );
  }

  int get length => time.length;

  int indexOfNearestHour(DateTime at) {
    if (time.isEmpty) return -1;
    var best = 0;
    for (var i = 0; i < time.length; i++) {
      if (!time[i].isAfter(at)) {
        best = i;
      } else {
        break;
      }
    }
    return best;
  }

  double? seaLevelAt(DateTime at) {
    final i = indexOfNearestHour(at);
    return (i < 0 || i >= seaLevelHeightMsl.length) ? null : seaLevelHeightMsl[i];
  }
}

class MarineDay {
  const MarineDay({
    required this.date,
    required this.waveHeightMax,
    required this.waveDirectionDominant,
    required this.wavePeriodMax,
  });

  final DateTime date;
  final double? waveHeightMax;
  final double? waveDirectionDominant;
  final double? wavePeriodMax;

  factory MarineDay.fromIndexedJson(Map<String, dynamic> daily, int i) => MarineDay(
        date: DateTime.parse((daily['time'] as List)[i] as String),
        waveHeightMax: _numAt(daily['wave_height_max'], i),
        waveDirectionDominant: _numAt(daily['wave_direction_dominant'], i),
        wavePeriodMax: _numAt(daily['wave_period_max'], i),
      );
}

class TideEvent {
  const TideEvent({required this.time, required this.isHigh, required this.heightMsl});

  final DateTime time;
  final bool isHigh;
  final double heightMsl;

  String get label => isHigh ? 'High tide' : 'Low tide';
}

double? _num(dynamic v) => v == null ? null : (v as num).toDouble();
double? _numAt(dynamic list, int i) =>
    list == null ? null : (list[i] == null ? null : (list[i] as num).toDouble());
