/// Air quality and pollen data from the Open-Meteo Air Quality API.
///
/// European AQI scale:
///   0-20   Good
///   20-40  Fair
///   40-60  Moderate
///   60-80  Poor
///   80-100 Very Poor
///   100+   Extremely Poor
class AirQualityData {
  const AirQualityData({
    required this.latitude,
    required this.longitude,
    required this.timezone,
    required this.hourly,
    required this.fetchedAt,
  });

  final double latitude;
  final double longitude;
  final String timezone;
  final List<AirQualityHour> hourly;
  final DateTime fetchedAt;

  /// Returns the entry closest to [now], or null if empty.
  AirQualityHour? currentHour() {
    if (hourly.isEmpty) return null;
    final now = DateTime.now();
    AirQualityHour? best;
    for (final h in hourly) {
      if (!h.time.isAfter(now)) {
        best = h;
      } else {
        break;
      }
    }
    return best ?? hourly.first;
  }
}

class AirQualityHour {
  const AirQualityHour({
    required this.time,
    this.europeanAqi,
    this.pm25,
    this.pm10,
    this.ozone,
    this.nitrogenDioxide,
    this.alderPollen,
    this.birchPollen,
    this.grassPollen,
    this.mugwortPollen,
    this.ragweedPollen,
  });

  final DateTime time;

  /// European Air Quality Index (0–500+).
  final double? europeanAqi;

  final double? pm25;
  final double? pm10;
  final double? ozone;
  final double? nitrogenDioxide;

  /// Pollen values in grains/m³.
  final double? alderPollen;
  final double? birchPollen;
  final double? grassPollen;
  final double? mugwortPollen;
  final double? ragweedPollen;

  AqiLevel get aqiLevel => AqiLevel.fromValue(europeanAqi ?? 0);

  /// Returns the highest pollen reading with its name, or null if all zero.
  ({String name, double value, PollenLevel level})? get dominantPollen {
    final candidates = <String, double?>{
      'Grass': grassPollen,
      'Birch': birchPollen,
      'Alder': alderPollen,
      'Mugwort': mugwortPollen,
      'Ragweed': ragweedPollen,
    };

    String? topName;
    double topVal = 0;
    for (final e in candidates.entries) {
      if ((e.value ?? 0) > topVal) {
        topVal = e.value!;
        topName = e.key;
      }
    }
    if (topName == null || topVal == 0) return null;
    return (name: topName, value: topVal, level: PollenLevel.fromValue(topVal));
  }
}

// ── AQI level ─────────────────────────────────────────────────────────────────

enum AqiLevel {
  good,
  fair,
  moderate,
  poor,
  veryPoor,
  extremelyPoor;

  static AqiLevel fromValue(double aqi) {
    if (aqi < 20) return AqiLevel.good;
    if (aqi < 40) return AqiLevel.fair;
    if (aqi < 60) return AqiLevel.moderate;
    if (aqi < 80) return AqiLevel.poor;
    if (aqi < 100) return AqiLevel.veryPoor;
    return AqiLevel.extremelyPoor;
  }

  String get label => switch (this) {
    AqiLevel.good           => 'Good',
    AqiLevel.fair           => 'Fair',
    AqiLevel.moderate       => 'Moderate',
    AqiLevel.poor           => 'Poor',
    AqiLevel.veryPoor       => 'Very Poor',
    AqiLevel.extremelyPoor  => 'Extremely Poor',
  };

  // Returns a CSS/Flutter hex colour appropriate for each band.
  // Green → yellow → orange → red → purple → maroon.
  int get colorValue => switch (this) {
    AqiLevel.good           => 0xFF50C878, // emerald green
    AqiLevel.fair           => 0xFFB5D86E, // yellow-green
    AqiLevel.moderate       => 0xFFFFD700, // gold
    AqiLevel.poor           => 0xFFFF8C00, // dark orange
    AqiLevel.veryPoor       => 0xFFE53935, // red
    AqiLevel.extremelyPoor  => 0xFF8B1A8B, // purple
  };
}

// ── Pollen level ──────────────────────────────────────────────────────────────

enum PollenLevel {
  none,
  low,
  moderate,
  high,
  veryHigh;

  /// Thresholds in grains/m³ (approximate European standard).
  static PollenLevel fromValue(double v) {
    if (v <= 0)   return PollenLevel.none;
    if (v < 10)   return PollenLevel.low;
    if (v < 30)   return PollenLevel.moderate;
    if (v < 80)   return PollenLevel.high;
    return PollenLevel.veryHigh;
  }

  String get label => switch (this) {
    PollenLevel.none     => 'None',
    PollenLevel.low      => 'Low',
    PollenLevel.moderate => 'Moderate',
    PollenLevel.high     => 'High',
    PollenLevel.veryHigh => 'Very High',
  };

  int get colorValue => switch (this) {
    PollenLevel.none     => 0xFF9E9E9E,
    PollenLevel.low      => 0xFF4CAF50,
    PollenLevel.moderate => 0xFFFFEB3B,
    PollenLevel.high     => 0xFFFF9800,
    PollenLevel.veryHigh => 0xFFF44336,
  };
}
