import 'package:material_ui/material_ui.dart';

class UvAdvice {
  UvAdvice({required this.uvIndex, required this.isMaxToday})
    : band = _bandFor(uvIndex);

  final double uvIndex;

  final bool isMaxToday;

  final UvBand band;

  factory UvAdvice.current(double uvIndex) =>
      UvAdvice(uvIndex: uvIndex, isMaxToday: false);

  factory UvAdvice.dailyMax(double uvIndex) =>
      UvAdvice(uvIndex: uvIndex, isMaxToday: true);

  static UvBand _bandFor(double uv) {
    if (uv < 3) return UvBand.low;
    if (uv < 6) return UvBand.moderate;
    if (uv < 8) return UvBand.high;
    if (uv < 11) return UvBand.veryHigh;
    return UvBand.extreme;
  }

  String get category {
    switch (band) {
      case UvBand.low:
        return 'Low';
      case UvBand.moderate:
        return 'Moderate';
      case UvBand.high:
        return 'High';
      case UvBand.veryHigh:
        return 'Very high';
      case UvBand.extreme:
        return 'Extreme';
    }
  }

  Color get color {
    switch (band) {
      case UvBand.low:
        return const Color(0xFF3E9B4F);
      case UvBand.moderate:
        return const Color(0xFFE6C229);
      case UvBand.high:
        return const Color(0xFFF77F00);
      case UvBand.veryHigh:
        return const Color(0xFFD62828);
      case UvBand.extreme:
        return const Color(0xFF8E24AA);
    }
  }

  String get headline {
    switch (band) {
      case UvBand.low:
        return 'Low burn risk — enjoy the water';
      case UvBand.moderate:
        return 'SPF 30+ sunscreen · hat for long sessions';
      case UvBand.high:
        return 'SPF 30-50 · reapply every 2 hours';
      case UvBand.veryHigh:
        return 'SPF 50 waterproof · reapply every 40-80 min';
      case UvBand.extreme:
        return 'SPF 50+ · full cover · avoid midday sun';
    }
  }

  List<String> get tips {
    final when = isMaxToday ? 'will peak' : 'is';
    switch (band) {
      case UvBand.low:
        return [
          'UV index $when $uvIndexLabel — no sunscreen needed for most skin types.',
          'Still wear polarised sunglasses; glare off the water strains eyes.',
        ];
      case UvBand.moderate:
        return [
          'UV index $when $uvIndexLabel — apply SPF 30+ before getting in.',
          'Reapply sunscreen every 2 hours and after towelling off.',
          'A hat and UV sunglasses help during surface intervals.',
        ];
      case UvBand.high:
        return [
          'UV index $when $uvIndexLabel — SPF 30-50, applied 20 min before you swim.',
          'Water reflects UV, so exposure builds faster while snorkelling or surfing.',
          'Reapply every 2 hours — every 40-80 minutes while in the water.',
          'Seek shade between 11:00 and 16:00.',
        ];
      case UvBand.veryHigh:
        return [
          'UV index $when $uvIndexLabel — use SPF 50 waterproof (sport) sunscreen.',
          'Reapply every 40-80 minutes in the water and after every swim.',
          'A long-sleeve rash guard or UPF swimwear beats sunscreen alone.',
          'Stay in shade between 11:00 and 16:00; keep surface intervals short.',
        ];
      case UvBand.extreme:
        return [
          'UV index $when $uvIndexLabel — extreme. Burn time can be under 15 minutes.',
          'SPF 50+, zinc on nose, ears and neck; lip balm with SPF.',
          'Full-body cover (rash guard + leggings) is strongly recommended.',
          'Plan water time before 10:00 or after 16:00 and stay shaded midday.',
        ];
    }
  }

  String get uvIndexLabel =>
      uvIndex >= 10 ? uvIndex.round().toString() : uvIndex.toStringAsFixed(1);

  String get shortPhrase {
    switch (band) {
      case UvBand.low:
        return 'sun risk low';
      case UvBand.moderate:
        return 'wear sunscreen';
      case UvBand.high:
        return 'sunscreen essential';
      case UvBand.veryHigh:
        return 'high sun risk';
      case UvBand.extreme:
        return 'extreme sun risk';
    }
  }
}

enum UvBand { low, moderate, high, veryHigh, extreme }
