import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  static const String appName = 'OmniWeather';
  static const String packageName = 'com.zantiqlabs.omniweather';

  // Secure storage keys
  static const String keyXweatherClientId     = 'xweather_client_id';
  static const String keyXweatherClientSecret = 'xweather_client_secret';

  // Shared prefs keys
  static const String keyTemperatureUnit = 'temperature_unit';
  static const String keyWindUnit        = 'wind_unit';
  static const String keyPrecipUnit      = 'precip_unit';
  static const String keySavedLocations  = 'saved_locations';
  static const String keyLastLocation    = 'last_location';
  static const String keyThemeMode           = 'theme_mode';
  static const String keyForecastInterval    = 'forecast_interval';
  static const String keyShowLightning       = 'show_lightning';

  // Defaults
  static const TemperatureUnit defaultTempUnit      = TemperatureUnit.celsius;
  static const WindUnit        defaultWindUnit       = WindUnit.kmh;
  static const PrecipUnit      defaultPrecipUnit     = PrecipUnit.mm;
  /// Hours between slots in the expandable daily forecast detail.
  /// Must be a divisor of 24: 1, 2, 3, 4, 6, 8, 12.
  static const int             defaultForecastInterval = 4;

  // Map / lightning radius
  static const double defaultMapZoom = 8.0;
  static const double lightningMapZoom = 6.0;
  static const double defaultRadiusKm = 100.0;

  // Lightning polling
  /// Only poll when the user is actively viewing the lightning screen.
  static const Duration lightningPollInterval = Duration(minutes: 5);

  // Historical comparison: how many years back to show on the chart
  static const int historicalComparisonYears = 5;

  // Cache durations
  static const Duration forecastCacheDuration = Duration(minutes: 30);
  static const Duration lightningCacheDuration = Duration(minutes: 3);
  static const Duration historicalCacheDuration = Duration(hours: 24);

  // Colours used across the app (light-mode values; dark handled in theme)
  static const Color brandBlue    = Color(0xFF1A6FB5);
  static const Color brandAccent  = Color(0xFFFFB347);
  static const Color lightningYellow = Color(0xFFFFE033);
  static const Color rainBlue     = Color(0xFF4A90D9);
  static const Color snowWhite    = Color(0xFFE0EAF4);
}

enum TemperatureUnit { celsius, fahrenheit }
enum WindUnit        { kmh, mph, ms, knots }
enum PrecipUnit      { mm, inches }
