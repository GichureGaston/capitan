import 'package:material_ui/material_ui.dart';

class WeatherData {
  const WeatherData({
    required this.current,
    required this.hourly,
    required this.daily,
    required this.sunriseToday,
    required this.sunsetToday,
  });

  final WeatherCurrent current;
  final WeatherHourly hourly;
  final List<WeatherDay> daily;

  final DateTime? sunriseToday;
  final DateTime? sunsetToday;

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final current = WeatherCurrent.fromJson(
      json['current'] as Map<String, dynamic>,
    );
    final hourlyRaw = json['hourly'] as Map<String, dynamic>?;
    final hourly = hourlyRaw == null
        ? WeatherHourly.fromJson(const {'time': <String>[]})
        : WeatherHourly.fromJson(hourlyRaw);
    final dailyRaw = json['daily'] as Map<String, dynamic>?;
    final daily = <WeatherDay>[];
    if (dailyRaw != null) {
      final count = (dailyRaw['time'] as List).length;
      for (var i = 0; i < count; i++) {
        daily.add(WeatherDay.fromIndexedJson(dailyRaw, i));
      }
    }
    return WeatherData(
      current: current,
      hourly: hourly,
      daily: daily,
      sunriseToday: daily.isEmpty ? null : daily.first.sunrise,
      sunsetToday: daily.isEmpty ? null : daily.first.sunset,
    );
  }

  double? get uvNow => hourly.uvIndexAt(current.time);

  double? get uvMaxToday => daily.isEmpty ? null : daily.first.uvIndexMax;

  DateTime? get uvPeakTimeToday {
    final max = uvMaxToday;
    if (max == null || max < 0.5) return null;
    return hourly.timeOfMaxUv(current.time);
  }
}

class WeatherCurrent {
  const WeatherCurrent({
    required this.time,
    required this.temperature,
    required this.apparentTemperature,
    required this.humidity,
    required this.precipitation,
    required this.weatherCode,
    required this.cloudCover,
    required this.windSpeed,
    required this.windDirection,
    required this.windGusts,
    required this.isDay,
  });

  final DateTime time;
  final double temperature;
  final double apparentTemperature;
  final double humidity;
  final double precipitation;
  final int weatherCode;
  final double cloudCover;
  final double windSpeed;
  final double windDirection;
  final double windGusts;
  final bool isDay;

  factory WeatherCurrent.fromJson(Map<String, dynamic> json) => WeatherCurrent(
    time: DateTime.parse(json['time'] as String),
    temperature: _num(json['temperature_2m']),
    apparentTemperature: _num(json['apparent_temperature']),
    humidity: _num(json['relative_humidity_2m']),
    precipitation: _num(json['precipitation']),
    weatherCode: (json['weather_code'] as num?)?.toInt() ?? 0,
    cloudCover: _num(json['cloud_cover']),
    windSpeed: _num(json['wind_speed_10m']),
    windDirection: _num(json['wind_direction_10m']),
    windGusts: _num(json['wind_gusts_10m']),
    isDay: (json['is_day'] as num?)?.toInt() != 0,
  );
}

class WeatherHourly {
  const WeatherHourly({
    required this.time,
    required this.temperature,
    required this.humidity,
    required this.precipitationProbability,
    required this.weatherCode,
    required this.windSpeed,
    required this.windDirection,
    required this.windGusts,
    required this.uvIndex,
    required this.visibility,
  });

  final List<DateTime> time;
  final List<double?> temperature;
  final List<double?> humidity;
  final List<double?> precipitationProbability;
  final List<int> weatherCode;
  final List<double?> windSpeed;
  final List<double?> windDirection;
  final List<double?> windGusts;
  final List<double?> uvIndex;
  final List<double?> visibility;

  factory WeatherHourly.fromJson(Map<String, dynamic> json) {
    final time = (json['time'] as List)
        .map((e) => DateTime.parse(e as String))
        .toList();
    List<double?> doubles(String key) {
      final raw = json[key] as List?;
      if (raw == null) {
        return List<double?>.filled(time.length, null);
      }

      final values = <double?>[];
      for (final item in raw) {
        if (item == null) {
          values.add(null);
        } else {
          values.add((item as num).toDouble());
        }
      }
      return values;
    }

    List<int> weatherCodes() {
      final raw = json['weather_code'] as List?;
      if (raw == null) {
        return List<int>.filled(time.length, 0);
      }

      final values = <int>[];
      for (final item in raw) {
        if (item == null) {
          values.add(0);
        } else {
          values.add((item as num).toInt());
        }
      }
      return values;
    }

    final weatherCode = weatherCodes();
    return WeatherHourly(
      time: time,
      temperature: doubles('temperature_2m'),
      humidity: doubles('relative_humidity_2m'),
      precipitationProbability: doubles('precipitation_probability'),
      weatherCode: weatherCode,
      windSpeed: doubles('wind_speed_10m'),
      windDirection: doubles('wind_direction_10m'),
      windGusts: doubles('wind_gusts_10m'),
      uvIndex: doubles('uv_index'),
      visibility: doubles('visibility'),
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

  double? uvIndexAt(DateTime at) {
    final i = indexOfNearestHour(at);
    return (i < 0 || i >= uvIndex.length) ? null : uvIndex[i];
  }

  DateTime? timeOfMaxUv(DateTime from) {
    final start = indexOfNearestHour(from);
    if (start < 0) return null;
    var maxIdx = -1;
    double? maxVal;
    for (var i = start; i < time.length && time[i].day == from.day; i++) {
      final v = uvIndex[i];
      if (v != null && (maxVal == null || v > maxVal)) {
        maxVal = v;
        maxIdx = i;
      }
    }
    return maxIdx < 0 ? null : time[maxIdx];
  }
}

class WeatherDay {
  const WeatherDay({
    required this.date,
    required this.weatherCode,
    required this.tempMax,
    required this.tempMin,
    required this.uvIndexMax,
    required this.precipProbMax,
    required this.windSpeedMax,
    required this.windGustsMax,
    required this.windDirectionDominant,
    required this.sunrise,
    required this.sunset,
  });

  final DateTime date;
  final int weatherCode;
  final double? tempMax;
  final double? tempMin;
  final double? uvIndexMax;
  final double? precipProbMax;
  final double? windSpeedMax;
  final double? windGustsMax;
  final double? windDirectionDominant;
  final DateTime? sunrise;
  final DateTime? sunset;

  factory WeatherDay.fromIndexedJson(Map<String, dynamic> daily, int i) =>
      WeatherDay(
        date: DateTime.parse((daily['time'] as List)[i] as String),
        weatherCode: _intAt(daily['weather_code'], i),
        tempMax: _numAt(daily['temperature_2m_max'], i),
        tempMin: _numAt(daily['temperature_2m_min'], i),
        uvIndexMax: _numAt(daily['uv_index_max'], i),
        precipProbMax: _numAt(daily['precipitation_probability_max'], i),
        windSpeedMax: _numAt(daily['wind_speed_10m_max'], i),
        windGustsMax: _numAt(daily['wind_gusts_10m_max'], i),
        windDirectionDominant: _numAt(daily['wind_direction_10m_dominant'], i),
        sunrise: _dateAt(daily['sunrise'], i),
        sunset: _dateAt(daily['sunset'], i),
      );
}

double _num(dynamic v) {
  if (v == null) return 0;
  return (v as num).toDouble();
}

double? _numAt(dynamic list, int i) {
  if (list == null) return null;
  if (list[i] == null) return null;
  return (list[i] as num).toDouble();
}

int _intAt(dynamic list, int i) {
  if (list == null) return 0;
  if (list[i] == null) return 0;
  return (list[i] as num).toInt();
}

DateTime? _dateAt(dynamic list, int i) {
  if (list == null || list[i] == null) return null;
  return DateTime.parse(list[i] as String);
}

class WmoWeather {
  const WmoWeather._();

  static const _labels = <int, String>{
    0: 'Clear sky',
    1: 'Mainly clear',
    2: 'Partly cloudy',
    3: 'Overcast',
    45: 'Fog',
    48: 'Depositing rime fog',
    51: 'Light drizzle',
    53: 'Moderate drizzle',
    55: 'Dense drizzle',
    56: 'Light freezing drizzle',
    57: 'Dense freezing drizzle',
    61: 'Slight rain',
    63: 'Moderate rain',
    65: 'Heavy rain',
    66: 'Light freezing rain',
    67: 'Heavy freezing rain',
    71: 'Slight snowfall',
    73: 'Moderate snowfall',
    75: 'Heavy snowfall',
    77: 'Snow grains',
    80: 'Slight rain showers',
    81: 'Moderate rain showers',
    82: 'Violent rain showers',
    85: 'Slight snow showers',
    86: 'Heavy snow showers',
    95: 'Thunderstorm',
    96: 'Thunderstorm with slight hail',
    97: 'Heavy thunderstorm',
    99: 'Thunderstorm with heavy hail',
  };

  static String label(int code) => _labels[code] ?? 'Unknown';

  static IconData icon(int code, {required bool isDay}) {
    if (code == 0 || code == 1) {
      return isDay ? Icons.sunny : Icons.nightlight_round;
    }
    if (code == 2) return isDay ? Icons.wb_sunny : Icons.nights_stay;
    if (code == 3) return Icons.cloud;
    if (code == 45 || code == 48) return Icons.foggy;
    if (code >= 51 && code <= 57) return Icons.grain;
    if (code >= 61 && code <= 67) return Icons.water_drop;
    if (code >= 71 && code <= 77) return Icons.snowing;
    if (code >= 80 && code <= 82) return Icons.shower;
    if (code == 85 || code == 86) return Icons.snowing;
    if (code >= 95) return Icons.thunderstorm;
    return isDay ? Icons.sunny : Icons.nightlight_round;
  }
}
