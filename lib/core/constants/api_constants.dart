/// API base URLs and endpoint constants.
///
/// Xweather credentials are loaded from flutter_secure_storage at runtime
/// (see AppSecrets). Never hardcode keys here.
class ApiConstants {
  ApiConstants._();

  // ── Open-Meteo ──────────────────────────────────────────────────────────────
  // Free, no key required for non-commercial use.
  static const String openMeteoBaseUrl = 'https://api.open-meteo.com/v1';
  static const String openMeteoArchiveUrl = 'https://archive-api.open-meteo.com/v1';

  // Geocoding endpoint (separate subdomain)
  static const String openMeteoGeocodingUrl = 'https://geocoding-api.open-meteo.com/v1';
  static const String openMeteoGeocodingSearch = '/search';

  // Forecast endpoint
  static const String openMeteoForecast = '/forecast';
  // Historical / archive endpoint
  static const String openMeteoArchive = '/archive';

  // Default variables requested for forecasts
  static const List<String> forecastHourlyVars = [
    'temperature_2m',
    'relative_humidity_2m',
    'apparent_temperature',
    'precipitation_probability',
    'precipitation',
    'rain',
    'showers',
    'snowfall',
    'weather_code',
    'cloud_cover',
    'wind_speed_10m',
    'wind_direction_10m',
    'wind_gusts_10m',
    'visibility',
    'uv_index',
  ];

  static const List<String> forecastDailyVars = [
    'weather_code',
    'temperature_2m_max',
    'temperature_2m_min',
    'apparent_temperature_max',
    'apparent_temperature_min',
    'sunrise',
    'sunset',
    'daylight_duration',
    'precipitation_sum',
    'rain_sum',
    'snowfall_sum',
    'precipitation_hours',
    'precipitation_probability_max',
    'wind_speed_10m_max',
    'wind_gusts_10m_max',
    'wind_direction_10m_dominant',
    'uv_index_max',
  ];

  static const List<String> historicalDailyVars = [
    'weather_code',
    'temperature_2m_max',
    'temperature_2m_min',
    'temperature_2m_mean',
    'apparent_temperature_max',
    'apparent_temperature_min',
    'apparent_temperature_mean',
    'sunrise',
    'sunset',
    'precipitation_sum',
    'rain_sum',
    'snowfall_sum',
    'precipitation_hours',
    'wind_speed_10m_max',
    'wind_gusts_10m_max',
    'wind_direction_10m_dominant',
  ];

  static const List<String> historicalHourlyVars = [
    'temperature_2m',
    'relative_humidity_2m',
    'precipitation',
    'weather_code',
    'wind_speed_10m',
    'wind_direction_10m',
  ];

  // ── Xweather ─────────────────────────────────────────────────────────────────
  // Requires clientId + clientSecret (stored in flutter_secure_storage).
  static const String xweatherBaseUrl = 'https://data.api.xweather.com';

  // Lightning endpoints
  static const String xweatherLightningSearch = '/lightning/search';
  static const String xweatherLightningClosest = '/lightning/closest';
  static const String xweatherLightningWithin  = '/lightning/within';
  static const String xweatherLightningFlash   = '/lightning/flash';

  // ── Misc ─────────────────────────────────────────────────────────────────────
  static const Duration defaultTimeout = Duration(seconds: 15);
  static const int defaultForecastDays = 14;
  static const int defaultHistoricalYears = 10;
  static const double defaultRadiusKm = 100.0;
}
