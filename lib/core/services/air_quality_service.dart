import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../models/air_quality.dart';
import 'weather_service_exception.dart';

/// Open-Meteo Air Quality API client.
///
/// Free, no API key required.
/// Endpoint: https://air-quality-api.open-meteo.com/v1/air-quality
///
/// Returns hourly European AQI, pollutants and pollen for the current day.
class AirQualityService {
  AirQualityService(this._dio, this._logger);

  final Dio _dio;
  final Logger _logger;

  static const _baseUrl = 'https://air-quality-api.open-meteo.com/v1/air-quality';

  static const _hourlyVars = [
    'european_aqi',
    'pm10',
    'pm2_5',
    'ozone',
    'nitrogen_dioxide',
    'alder_pollen',
    'birch_pollen',
    'grass_pollen',
    'mugwort_pollen',
    'ragweed_pollen',
  ];

  Future<AirQualityData> getAirQuality({
    required double lat,
    required double lon,
    String timezone = 'auto',
  }) async {
    try {
      final response = await _dio.get(
        _baseUrl,
        queryParameters: {
          'latitude': lat,
          'longitude': lon,
          'hourly': _hourlyVars.join(','),
          'timezone': timezone,
          'timeformat': 'iso8601',
          // Fetch today + tomorrow so we always have a current hour.
          'forecast_days': 2,
        },
        options: Options(
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );
      return _parse(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _logger.e('AirQuality fetch error', error: e);
      throw WeatherServiceException.fromDio(e);
    }
  }

  AirQualityData _parse(Map<String, dynamic> json) {
    final hourlyRaw = json['hourly'] as Map<String, dynamic>;
    final times = (hourlyRaw['time'] as List).cast<String>();

    final hourly = List.generate(times.length, (i) {
      return AirQualityHour(
        time:             DateTime.parse(times[i]),
        europeanAqi:      _d(hourlyRaw['european_aqi'], i),
        pm25:             _d(hourlyRaw['pm2_5'], i),
        pm10:             _d(hourlyRaw['pm10'], i),
        ozone:            _d(hourlyRaw['ozone'], i),
        nitrogenDioxide:  _d(hourlyRaw['nitrogen_dioxide'], i),
        alderPollen:      _d(hourlyRaw['alder_pollen'], i),
        birchPollen:      _d(hourlyRaw['birch_pollen'], i),
        grassPollen:      _d(hourlyRaw['grass_pollen'], i),
        mugwortPollen:    _d(hourlyRaw['mugwort_pollen'], i),
        ragweedPollen:    _d(hourlyRaw['ragweed_pollen'], i),
      );
    });

    return AirQualityData(
      latitude:  (json['latitude']  as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timezone:  json['timezone']   as String? ?? 'UTC',
      hourly:    hourly,
      fetchedAt: DateTime.now(),
    );
  }

  double? _d(dynamic list, int i) {
    if (list == null) return null;
    final v = (list as List)[i];
    if (v == null) return null;
    return (v as num).toDouble();
  }
}

final airQualityServiceProvider = Provider<AirQualityService>((ref) {
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));
  return AirQualityService(dio, Logger());
});
