import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../constants/api_constants.dart';
import '../models/lightning.dart';
import 'weather_service_exception.dart';
import 'app_secrets.dart';

/// Low-level service for the Xweather (formerly AerisWeather) REST API.
///
/// Credentials (clientId + clientSecret) are loaded from secure storage via
/// [AppSecrets] and never embedded in source code.
///
/// Free tier: 15,000 accesses/month. Only call while the lightning screen
/// is active — do not poll in the background.
class XweatherService {
  XweatherService(this._dio, this._secrets, this._logger);

  final Dio _dio;
  final AppSecrets _secrets;
  final Logger _logger;

  // ── Lightning ─────────────────────────────────────────────────────────────

  /// Fetch lightning strikes within [radiusKm] of [lat]/[lon] in the
  /// last [lookbackMinutes] minutes.
  Future<LightningData> getLightningNearby({
    required double lat,
    required double lon,
    double radiusKm = ApiConstants.defaultRadiusKm,
    int lookbackMinutes = 60,
  }) async {
    final creds = await _secrets.xweatherCredentials;
    if (creds == null) {
      throw const WeatherServiceException(
        type: ServiceErrorType.missingCredentials,
        message: 'Xweather credentials not configured. '
            'Please add your Client ID and Secret in Settings.',
      );
    }

    try {
      // Debug: log masked credentials so we can verify format without
      // exposing the full secret.
      _logger.d(
        'Xweather request — '
        'id="${creds.clientId}" '
        'secret="${creds.clientSecret.length > 4 ? '${creds.clientSecret.substring(0, 4)}…' : '???'}" '
        'id_len=${creds.clientId.length} secret_len=${creds.clientSecret.length}',
      );

      final response = await _dio.get(
        '${ApiConstants.xweatherBaseUrl}${ApiConstants.xweatherLightningWithin}',
        queryParameters: {
          'p': '${lat},${lon}',
          'radius': '${radiusKm}km',
          'from': '-${lookbackMinutes}minutes',
          'to': 'now',
          'limit': 500,
          'client_id': creds.clientId,
          'client_secret': creds.clientSecret,
        },
        options: Options(
          sendTimeout: ApiConstants.defaultTimeout,
          receiveTimeout: ApiConstants.defaultTimeout,
        ),
      );

      return _parseLightningResponse(response.data, lat, lon, radiusKm);
    } on DioException catch (e) {
      _logger.e('Xweather lightning error', error: e);
      throw WeatherServiceException.fromDio(e);
    }
  }

  /// Fetch the closest N lightning strikes to [lat]/[lon].
  Future<LightningData> getClosestLightning({
    required double lat,
    required double lon,
    int limit = 10,
    double radiusKm = ApiConstants.defaultRadiusKm,
  }) async {
    final creds = await _secrets.xweatherCredentials;
    if (creds == null) {
      throw const WeatherServiceException(
        type: ServiceErrorType.missingCredentials,
        message: 'Xweather credentials not configured.',
      );
    }

    try {
      final response = await _dio.get(
        '${ApiConstants.xweatherBaseUrl}${ApiConstants.xweatherLightningClosest}',
        queryParameters: {
          'p': '${lat},${lon}',
          'radius': '${radiusKm}km',
          'limit': limit,
          'client_id': creds.clientId,
          'client_secret': creds.clientSecret,
        },
        options: Options(
          sendTimeout: ApiConstants.defaultTimeout,
          receiveTimeout: ApiConstants.defaultTimeout,
        ),
      );

      return _parseLightningResponse(response.data, lat, lon, radiusKm);
    } on DioException catch (e) {
      _logger.e('Xweather closest lightning error', error: e);
      throw WeatherServiceException.fromDio(e);
    }
  }

  // ── Parsing ───────────────────────────────────────────────────────────────

  LightningData _parseLightningResponse(
    dynamic raw,
    double lat,
    double lon,
    double radiusKm,
  ) {
    final json = raw as Map<String, dynamic>;
    final List<dynamic> responseList = json['response'] as List? ?? [];

    final strikes = responseList.map((item) {
      final ob = item['ob'] as Map<String, dynamic>? ?? {};
      final loc = item['loc'] as Map<String, dynamic>? ?? {};

      final typeStr = (ob['type'] as String? ?? '').toUpperCase();
      final type = switch (typeStr) {
        'CG' => LightningType.cloudToGround,
        'CC' => LightningType.cloudToCloud,
        _    => LightningType.unknown,
      };

      return LightningStrike(
        id: ob['id'] as String? ?? '${DateTime.now().microsecondsSinceEpoch}',
        timestamp: DateTime.fromMillisecondsSinceEpoch(
          ((ob['timestamp'] as num?) ?? 0).toInt() * 1000,
        ),
        latitude: (loc['lat'] as num? ?? 0).toDouble(),
        longitude: (loc['long'] as num? ?? 0).toDouble(),
        type: type,
        peakCurrent: (ob['peakCurrent'] as num? ?? 0).toDouble(),
        strokeCount: (ob['strokeCount'] as num? ?? 1).toInt(),
        distanceKm: item['details'] != null
            ? ((item['details']['distanceKm'] as num?)?.toDouble())
            : null,
      );
    }).toList();

    return LightningData(
      strikes: strikes,
      fetchedAt: DateTime.now(),
      queryLatitude: lat,
      queryLongitude: lon,
      queryRadiusKm: radiusKm,
    );
  }
}

// Riverpod provider
final xweatherServiceProvider = Provider<XweatherService>((ref) {
  final dio = Dio(BaseOptions(
    connectTimeout: ApiConstants.defaultTimeout,
    receiveTimeout: ApiConstants.defaultTimeout,
  ));
  final secrets = ref.watch(appSecretsProvider);
  return XweatherService(dio, secrets, Logger());
});
