import '../models/forecast.dart';

/// WMO weather code severity classification.
///
/// Codes from https://open-meteo.com/en/docs — "WMO Weather interpretation codes"
enum SeverityLevel { none, advisory, warning }

class SevereWeatherEvent {
  const SevereWeatherEvent({
    required this.level,
    required this.headline,
    required this.time,
    required this.code,
  });

  final SeverityLevel level;
  final String headline;
  final DateTime time;
  final int code;

  String get icon => switch (code) {
    95 || 96 || 99 => '⛈',
    75 || 77        => '❄️',
    71 || 73        => '🌨',
    65 || 67        => '🌧',
    82              => '🌊',
    85 || 86        => '🌨',
    _               => '⚠️',
  };
}

class SevereWeatherUtils {
  SevereWeatherUtils._();

  /// Scans the next [lookAheadHours] of [hourly] and returns the most severe
  /// upcoming event. Returns null if nothing significant is forecast.
  static SevereWeatherEvent? findFirst(
    List<HourlyForecast> hourly, {
    int lookAheadHours = 24,
  }) {
    final now = DateTime.now();
    final cutoff = now.add(Duration(hours: lookAheadHours));

    SevereWeatherEvent? best;

    for (final h in hourly) {
      if (h.time.isBefore(now)) continue;
      if (h.time.isAfter(cutoff)) break;

      final event = _classify(h);
      if (event == null) continue;

      if (best == null || event.level.index > best.level.index) {
        best = event;
        // Short-circuit on highest severity.
        if (best.level == SeverityLevel.warning) break;
      }
    }
    return best;
  }

  static SevereWeatherEvent? _classify(HourlyForecast h) {
    final code = h.weatherCode;
    final time = h.time;

    // ── WARNING level ────────────────────────────────────────────────────────
    // Thunderstorms with heavy hail or significant discharge
    if (code == 99) {
      return SevereWeatherEvent(
        level: SeverityLevel.warning,
        headline: 'Thunderstorm with heavy hail',
        time: time,
        code: code,
      );
    }
    // Thunderstorm with slight or moderate hail
    if (code == 96) {
      return SevereWeatherEvent(
        level: SeverityLevel.warning,
        headline: 'Thunderstorm with hail',
        time: time,
        code: code,
      );
    }
    // Violent rain showers
    if (code == 82) {
      return SevereWeatherEvent(
        level: SeverityLevel.warning,
        headline: 'Violent rain showers',
        time: time,
        code: code,
      );
    }
    // Heavy snowfall
    if (code == 77) {
      return SevereWeatherEvent(
        level: SeverityLevel.warning,
        headline: 'Heavy snow grains',
        time: time,
        code: code,
      );
    }

    // ── ADVISORY level ───────────────────────────────────────────────────────
    // Thunderstorm (no hail)
    if (code == 95) {
      return SevereWeatherEvent(
        level: SeverityLevel.advisory,
        headline: 'Thunderstorm',
        time: time,
        code: code,
      );
    }
    // Heavy rain / freezing rain
    if (code == 65 || code == 67) {
      return SevereWeatherEvent(
        level: SeverityLevel.advisory,
        headline: code == 67 ? 'Heavy freezing rain' : 'Heavy rain',
        time: time,
        code: code,
      );
    }
    // Heavy snow showers
    if (code == 86) {
      return SevereWeatherEvent(
        level: SeverityLevel.advisory,
        headline: 'Heavy snow showers',
        time: time,
        code: code,
      );
    }
    // Moderate/heavy snowfall
    if (code == 73 || code == 75) {
      return SevereWeatherEvent(
        level: SeverityLevel.advisory,
        headline: code == 75 ? 'Heavy snowfall' : 'Moderate snowfall',
        time: time,
        code: code,
      );
    }

    return null;
  }
}
