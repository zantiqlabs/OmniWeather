import 'package:flutter/material.dart';

// ── Moon phase ────────────────────────────────────────────────────────────────

enum MoonPhase {
  newMoon,
  waxingCrescent,
  firstQuarter,
  waxingGibbous,
  fullMoon,
  waningGibbous,
  lastQuarter,
  waningCrescent,
}

/// Utilities for WMO Weather Interpretation Codes used by Open-Meteo.
///
/// Reference: https://open-meteo.com/en/docs#weathervariables
class WeatherCodeUtils {
  WeatherCodeUtils._();

  static String description(int code) => switch (code) {
    0     => 'Clear sky',
    1     => 'Mainly clear',
    2     => 'Partly cloudy',
    3     => 'Overcast',
    45    => 'Fog',
    48    => 'Icy fog',
    51    => 'Light drizzle',
    53    => 'Drizzle',
    55    => 'Heavy drizzle',
    56    => 'Light freezing drizzle',
    57    => 'Freezing drizzle',
    61    => 'Light rain',
    63    => 'Rain',
    65    => 'Heavy rain',
    66    => 'Light freezing rain',
    67    => 'Freezing rain',
    71    => 'Light snow',
    73    => 'Snow',
    75    => 'Heavy snow',
    77    => 'Snow grains',
    80    => 'Light showers',
    81    => 'Showers',
    82    => 'Heavy showers',
    85    => 'Light snow showers',
    86    => 'Heavy snow showers',
    95    => 'Thunderstorm',
    96    => 'Thunderstorm with hail',
    99    => 'Thunderstorm with heavy hail',
    _     => 'Unknown',
  };

  /// Returns a daytime Material icon for the weather code.
  static IconData icon(int code) => switch (code) {
    0     => Icons.wb_sunny,
    1     => Icons.wb_sunny_outlined,
    2     => Icons.cloud_queue,
    3     => Icons.cloud,
    45 || 48 => Icons.foggy,
    51 || 53 || 55 || 56 || 57 => Icons.grain,
    61 || 63 || 65 || 66 || 67 => Icons.water_drop,
    71 || 73 || 75 || 77       => Icons.ac_unit,
    80 || 81 || 82             => Icons.umbrella,
    85 || 86                   => Icons.cloudy_snowing,
    95 || 96 || 99             => Icons.thunderstorm,
    _                          => Icons.help_outline,
  };

  /// Returns an icon that is night-aware for codes 0–2 (clear / mainly clear /
  /// partly cloudy).  All other codes are unaffected by time of day.
  ///
  /// Pass the hour's [time] plus that day's [sunrise] and [sunset] so the
  /// correct day/night determination is made.
  static IconData iconForHour(
    int      code,
    DateTime time,
    DateTime sunrise,
    DateTime sunset,
  ) {
    if (_isNight(time, sunrise, sunset) && _isClearOrPartly(code)) {
      return moonPhaseIcon(time);
    }
    return icon(code);
  }

  /// Returns a colour appropriate for the given time of day.
  static Color colorForHour(
    int      code,
    DateTime time,
    DateTime sunrise,
    DateTime sunset,
  ) {
    if (_isNight(time, sunrise, sunset) && _isClearOrPartly(code)) {
      return moonPhaseColor(time);
    }
    return color(code);
  }

  /// Returns a colour that matches the condition.
  static Color color(int code) => switch (code) {
    0     => const Color(0xFFFFD600),  // bright sun
    1     => const Color(0xFFFFE57F),
    2     => const Color(0xFF90A4AE),
    3     => const Color(0xFF78909C),
    45 || 48 => const Color(0xFFB0BEC5),
    51 || 53 || 55 || 56 || 57 => const Color(0xFF80DEEA),
    61 || 63 || 65 || 66 || 67 => const Color(0xFF1E88E5),
    71 || 73 || 75 || 77       => const Color(0xFFE0F7FA),
    80 || 81 || 82             => const Color(0xFF42A5F5),
    85 || 86                   => const Color(0xFFB3E5FC),
    95 || 96 || 99             => const Color(0xFF5C6BC0),
    _                          => const Color(0xFF9E9E9E),
  };

  /// Returns true if the code indicates precipitation.
  static bool hasPrecipitation(int code) =>
      (code >= 51 && code <= 67) ||
      (code >= 80 && code <= 86) ||
      (code >= 95 && code <= 99);

  /// Returns true if the code indicates a thunderstorm.
  static bool isThunderstorm(int code) => code == 95 || code == 96 || code == 99;

  // ── Night / moon helpers ───────────────────────────────────────────────────

  /// True when [time] falls outside [sunrise]…[sunset] for that day.
  static bool isNight(DateTime time, DateTime sunrise, DateTime sunset) =>
      _isNight(time, sunrise, sunset);

  /// Calculates the moon's phase for [date] using a known new-moon epoch.
  ///
  /// Reference epoch: 6 Jan 2000 18:14 UTC (verified new moon).
  /// Synodic period:  29.53058867 days.
  static MoonPhase moonPhaseForDate(DateTime date) {
    const double referenceMs = 947182440000.0; // 6 Jan 2000 18:14 UTC
    const double periodMs    = 29.53058867 * 24 * 3600 * 1000.0;

    double age = (date.millisecondsSinceEpoch - referenceMs) % periodMs;
    if (age < 0) age += periodMs;
    final days = age / (24 * 3600 * 1000.0);

    if (days < 1.85)  return MoonPhase.newMoon;
    if (days < 7.38)  return MoonPhase.waxingCrescent;
    if (days < 9.22)  return MoonPhase.firstQuarter;
    if (days < 14.77) return MoonPhase.waxingGibbous;
    if (days < 16.61) return MoonPhase.fullMoon;
    if (days < 22.15) return MoonPhase.waningGibbous;
    if (days < 24.0)  return MoonPhase.lastQuarter;
    return MoonPhase.waningCrescent;
  }

  /// Returns an appropriate Material icon for the current moon phase.
  static IconData moonPhaseIcon(DateTime date) {
    return switch (moonPhaseForDate(date)) {
      MoonPhase.newMoon        => Icons.circle_outlined,   // dark new moon
      MoonPhase.waxingCrescent => Icons.nightlight,        // D-shape crescent
      MoonPhase.firstQuarter   => Icons.brightness_3,      // right half lit
      MoonPhase.waxingGibbous  => Icons.brightness_2,      // mostly full, right
      MoonPhase.fullMoon       => Icons.nightlight_round,  // bright circle
      MoonPhase.waningGibbous  => Icons.brightness_2,      // mostly full, left
      MoonPhase.lastQuarter    => Icons.brightness_3,      // left half lit
      MoonPhase.waningCrescent => Icons.nights_stay,       // C-shape crescent
    };
  }

  /// A silvery colour scaled by illumination — dim for new, bright for full.
  static Color moonPhaseColor(DateTime date) {
    return switch (moonPhaseForDate(date)) {
      MoonPhase.newMoon        => const Color(0xFF455A64), // dark blue-grey
      MoonPhase.waxingCrescent => const Color(0xFF90A4AE),
      MoonPhase.firstQuarter   => const Color(0xFFB0BEC5),
      MoonPhase.waxingGibbous  => const Color(0xFFCFD8DC),
      MoonPhase.fullMoon       => const Color(0xFFF5F5DC), // bright ivory
      MoonPhase.waningGibbous  => const Color(0xFFCFD8DC),
      MoonPhase.lastQuarter    => const Color(0xFFB0BEC5),
      MoonPhase.waningCrescent => const Color(0xFF90A4AE),
    };
  }

  /// Human-readable label for a moon phase (shown in tooltips / accessibility).
  static String moonPhaseLabel(DateTime date) {
    return switch (moonPhaseForDate(date)) {
      MoonPhase.newMoon        => 'New Moon',
      MoonPhase.waxingCrescent => 'Waxing Crescent',
      MoonPhase.firstQuarter   => 'First Quarter',
      MoonPhase.waxingGibbous  => 'Waxing Gibbous',
      MoonPhase.fullMoon       => 'Full Moon',
      MoonPhase.waningGibbous  => 'Waning Gibbous',
      MoonPhase.lastQuarter    => 'Last Quarter',
      MoonPhase.waningCrescent => 'Waning Crescent',
    };
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  static bool _isNight(DateTime time, DateTime sunrise, DateTime sunset) =>
      time.isBefore(sunrise) || time.isAfter(sunset);

  // Codes where the icon is a sun (day) or moon (night).
  // Code 2 (partly cloudy) still gets the moon at night instead of a daytime
  // cloud icon — the cloud_queue icon doesn't look obviously "daytime".
  static bool _isClearOrPartly(int code) => code == 0 || code == 1 || code == 2;
}
