import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../constants/api_constants.dart';
import '../models/forecast.dart';
import '../models/historical_weather.dart';
import '../models/location.dart';
import 'weather_service_exception.dart';

// ── Model selection ───────────────────────────────────────────────────────────

/// Returns the Open-Meteo forecast model to request for a given coordinate.
///
/// The UK Met Office UKV model (`ukmo_ukv`) offers ~2 km resolution over
/// Great Britain & Northern Ireland and is significantly more accurate than
/// the global default for UK forecasts.  Every other location uses
/// Open-Meteo's `best_match` blend, which picks the highest-resolution
/// available model for that region automatically.
///
/// UK bounding box (conservative — includes all inhabited islands):
///   lat 49.9 – 60.9 °N  ·  lon -8.2 – 1.8 °E
String _openMeteoModel(double lat, double lon) {
  if (lat >= 49.9 && lat <= 60.9 && lon >= -8.2 && lon <= 1.8) {
    return 'ukmo_seamless';
  }
  return 'best_match';
}

/// Low-level service for the Open-Meteo REST API.
///
/// Open-Meteo is free for non-commercial use, requires no API key, and
/// provides both a forecast endpoint and a separate archive endpoint.
class OpenMeteoService {
  OpenMeteoService(this._dio, this._logger);

  final Dio _dio;
  final Logger _logger;

  // ── Retry helper ─────────────────────────────────────────────────────────

  /// Retries [fn] up to 3 times with exponential backoff on 5xx responses.
  /// Other errors (4xx, network) are re-thrown immediately.
  Future<T> _withRetry<T>(Future<T> Function() fn) async {
    const maxAttempts = 3;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        return await fn();
      } on DioException catch (e) {
        final status = e.response?.statusCode ?? 0;
        final isServerError = status >= 500 && status < 600;
        if (!isServerError || attempt == maxAttempts - 1) rethrow;
        // 1 s → 2 s backoff
        final delay = Duration(seconds: 1 << attempt);
        _logger.w('OpenMeteo $status on attempt ${attempt + 1} — retrying in ${delay.inSeconds}s');
        await Future<void>.delayed(delay);
      }
    }
    throw StateError('unreachable');
  }

  // ── Forecast ──────────────────────────────────────────────────────────────

  /// Fetch up to [days] days of hourly + daily forecasts for [lat]/[lon].
  Future<ForecastData> getForecast({
    required double lat,
    required double lon,
    int days = ApiConstants.defaultForecastDays,
    String timezone = 'auto',
  }) async {
    try {
      final response = await _withRetry(() => _dio.get(
        '${ApiConstants.openMeteoBaseUrl}${ApiConstants.openMeteoForecast}',
        queryParameters: {
          'latitude': lat,
          'longitude': lon,
          'hourly': ApiConstants.forecastHourlyVars.join(','),
          'daily': ApiConstants.forecastDailyVars.join(','),
          'forecast_days': days,
          'timezone': timezone,
          'timeformat': 'iso8601',
          'models': _openMeteoModel(lat, lon),
        },
        options: Options(
          sendTimeout: ApiConstants.defaultTimeout,
          receiveTimeout: ApiConstants.defaultTimeout,
        ),
      ));
      return _parseForecastResponse(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _logger.e('OpenMeteo forecast error', error: e);
      throw WeatherServiceException.fromDio(e);
    }
  }

  // ── Historical archive ────────────────────────────────────────────────────

  /// Fetch historical daily data for [lat]/[lon] between [start] and [end].
  ///
  /// The archive API goes back to 1940 using ERA5 reanalysis. Results are
  /// cached aggressively since historical data does not change.
  Future<HistoricalData> getHistorical({
    required double lat,
    required double lon,
    required DateTime start,
    required DateTime end,
    String timezone = 'auto',
  }) async {
    assert(!end.isBefore(start), 'end must be >= start');
    try {
      final response = await _withRetry(() => _dio.get(
        '${ApiConstants.openMeteoArchiveUrl}${ApiConstants.openMeteoArchive}',
        queryParameters: {
          'latitude': lat,
          'longitude': lon,
          'start_date': _formatDate(start),
          'end_date': _formatDate(end),
          'daily': ApiConstants.historicalDailyVars.join(','),
          'timezone': timezone,
          'timeformat': 'iso8601',
        },
        options: Options(
          sendTimeout: ApiConstants.defaultTimeout,
          receiveTimeout: ApiConstants.defaultTimeout,
        ),
      ));
      return _parseHistoricalResponse(
        response.data as Map<String, dynamic>,
        start,
        end,
      );
    } on DioException catch (e) {
      _logger.e('OpenMeteo archive error', error: e);
      throw WeatherServiceException.fromDio(e);
    }
  }

  /// Convenience: fetch the same calendar date range across multiple years.
  ///
  /// Used to build the "typical weather" comparison chart. Returns one
  /// [HistoricalData] per year, newest first.
  Future<List<HistoricalData>> getHistoricalMultiYear({
    required double lat,
    required double lon,
    required int month,
    required int yearCount,
  }) async {
    final now = DateTime.now();
    final futures = <Future<HistoricalData>>[];

    for (var i = 1; i <= yearCount; i++) {
      final year = now.year - i;
      final start = DateTime(year, month, 1);
      final end = DateTime(year, month + 1, 0); // last day of month
      futures.add(getHistorical(lat: lat, lon: lon, start: start, end: end));
    }

    return Future.wait(futures);
  }

  // ── Geocoding ─────────────────────────────────────────────────────────────

  /// Search for locations by name using the Open-Meteo geocoding API.
  ///
  /// Returns up to [count] results ordered by relevance. The endpoint is
  /// separate from the weather API (`geocoding-api.open-meteo.com`) but
  /// equally free and key-free.
  Future<List<WeatherLocation>> geocode(String query, {int count = 10}) async {
    if (query.trim().isEmpty) return [];
    try {
      final response = await _dio.get(
        '${ApiConstants.openMeteoGeocodingUrl}${ApiConstants.openMeteoGeocodingSearch}',
        queryParameters: {
          'name': query.trim(),
          'count': count,
          'language': 'en',
          'format': 'json',
        },
        options: Options(
          sendTimeout: ApiConstants.defaultTimeout,
          receiveTimeout: ApiConstants.defaultTimeout,
        ),
      );
      return _parseGeocodingResponse(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _logger.e('OpenMeteo geocoding error', error: e);
      throw WeatherServiceException.fromDio(e);
    }
  }

  // ── Parsing ───────────────────────────────────────────────────────────────

  List<WeatherLocation> _parseGeocodingResponse(Map<String, dynamic> json) {
    final rawResults = json['results'];
    if (rawResults == null) return [];

    return (rawResults as List).map((r) {
      final m = r as Map<String, dynamic>;
      final id = m['id']?.toString() ?? '';
      final name = (m['name'] as String?) ?? '';

      // Build a readable region string from admin hierarchy
      final admin1 = m['admin1'] as String?;
      final admin2 = m['admin2'] as String?;
      final region = [admin2, admin1].whereType<String>().toSet().join(', ');

      return WeatherLocation(
        id: 'om_$id',
        name: name,
        latitude: (m['latitude'] as num).toDouble(),
        longitude: (m['longitude'] as num).toDouble(),
        country: m['country'] as String?,
        region: region.isEmpty ? null : region,
        timezone: m['timezone'] as String?,
      );
    }).toList();
  }

  ForecastData _parseForecastResponse(Map<String, dynamic> json) {
    final hourlyRaw = json['hourly'] as Map<String, dynamic>;
    final dailyRaw  = json['daily']  as Map<String, dynamic>;

    final times = (hourlyRaw['time'] as List).cast<String>();
    final hourly = List.generate(times.length, (i) {
      return HourlyForecast(
        time: DateTime.parse(times[i]),
        temperature: _d(hourlyRaw['temperature_2m'], i),
        apparentTemperature: _d(hourlyRaw['apparent_temperature'], i),
        relativeHumidity: _d(hourlyRaw['relative_humidity_2m'], i),
        precipitationProbability: _d(hourlyRaw['precipitation_probability'], i),
        precipitation: _d(hourlyRaw['precipitation'], i),
        weatherCode: _i(hourlyRaw['weather_code'], i),
        cloudCover: _d(hourlyRaw['cloud_cover'], i),
        windSpeed: _d(hourlyRaw['wind_speed_10m'], i),
        windDirection: _d(hourlyRaw['wind_direction_10m'], i),
        windGusts: _d(hourlyRaw['wind_gusts_10m'], i),
        visibility: _d(hourlyRaw['visibility'], i),
        uvIndex: _d(hourlyRaw['uv_index'], i),
      );
    });

    final dates = (dailyRaw['time'] as List).cast<String>();
    final daily = List.generate(dates.length, (i) {
      return DailyForecast(
        date: DateTime.parse(dates[i]),
        weatherCode: _i(dailyRaw['weather_code'], i),
        tempMax: _d(dailyRaw['temperature_2m_max'], i),
        tempMin: _d(dailyRaw['temperature_2m_min'], i),
        apparentTempMax: _d(dailyRaw['apparent_temperature_max'], i),
        apparentTempMin: _d(dailyRaw['apparent_temperature_min'], i),
        sunrise: DateTime.parse((dailyRaw['sunrise'] as List)[i] as String),
        sunset: DateTime.parse((dailyRaw['sunset'] as List)[i] as String),
        precipitationSum: _d(dailyRaw['precipitation_sum'], i),
        rainSum: _d(dailyRaw['rain_sum'], i),
        snowfallSum: _d(dailyRaw['snowfall_sum'], i),
        precipitationHours: _d(dailyRaw['precipitation_hours'], i),
        precipitationProbabilityMax: _d(dailyRaw['precipitation_probability_max'], i),
        windSpeedMax: _d(dailyRaw['wind_speed_10m_max'], i),
        windGustsMax: _d(dailyRaw['wind_gusts_10m_max'], i),
        windDirectionDominant: _d(dailyRaw['wind_direction_10m_dominant'], i),
        uvIndexMax: _d(dailyRaw['uv_index_max'], i),
      );
    });

    return ForecastData(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timezone: json['timezone'] as String,
      hourly: hourly,
      daily: daily,
      fetchedAt: DateTime.now(),
    );
  }

  HistoricalData _parseHistoricalResponse(
    Map<String, dynamic> json,
    DateTime start,
    DateTime end,
  ) {
    final dailyRaw = json['daily'] as Map<String, dynamic>;
    final dates = (dailyRaw['time'] as List).cast<String>();

    final days = List.generate(dates.length, (i) {
      return HistoricalDay(
        date: DateTime.parse(dates[i]),
        weatherCode: _i(dailyRaw['weather_code'], i),
        tempMax: _d(dailyRaw['temperature_2m_max'], i),
        tempMin: _d(dailyRaw['temperature_2m_min'], i),
        tempMean: _d(dailyRaw['temperature_2m_mean'], i),
        apparentTempMax: _d(dailyRaw['apparent_temperature_max'], i),
        apparentTempMin: _d(dailyRaw['apparent_temperature_min'], i),
        precipitationSum: _d(dailyRaw['precipitation_sum'], i),
        rainSum: _d(dailyRaw['rain_sum'], i),
        snowfallSum: _d(dailyRaw['snowfall_sum'], i),
        precipitationHours: _d(dailyRaw['precipitation_hours'], i),
        windSpeedMax: _d(dailyRaw['wind_speed_10m_max'], i),
        windGustsMax: _d(dailyRaw['wind_gusts_10m_max'], i),
        windDirectionDominant: _d(dailyRaw['wind_direction_10m_dominant'], i),
      );
    });

    return HistoricalData(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timezone: json['timezone'] as String,
      startDate: start,
      endDate: end,
      days: days,
      fetchedAt: DateTime.now(),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  double _d(dynamic list, int i) {
    final v = (list as List)[i];
    return v == null ? 0.0 : (v as num).toDouble();
  }

  int _i(dynamic list, int i) {
    final v = (list as List)[i];
    return v == null ? 0 : (v as num).toInt();
  }

  String _formatDate(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';
}

// Riverpod provider
final openMeteoServiceProvider = Provider<OpenMeteoService>((ref) {
  final dio = Dio(BaseOptions(
    connectTimeout: ApiConstants.defaultTimeout,
    receiveTimeout: ApiConstants.defaultTimeout,
  ));
  return OpenMeteoService(dio, Logger());
});