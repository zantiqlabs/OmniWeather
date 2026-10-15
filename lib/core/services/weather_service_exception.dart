import 'package:dio/dio.dart';

enum ServiceErrorType {
  network,
  timeout,
  serverError,
  notFound,
  rateLimited,
  missingCredentials,
  parseError,
  unknown,
}

class WeatherServiceException implements Exception {
  const WeatherServiceException({
    required this.type,
    required this.message,
    this.statusCode,
  });

  final ServiceErrorType type;
  final String message;
  final int? statusCode;

  factory WeatherServiceException.fromDio(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const WeatherServiceException(
        type: ServiceErrorType.timeout,
        message: 'The request timed out. Check your connection and try again.',
      );
    }
    if (e.type == DioExceptionType.connectionError) {
      return const WeatherServiceException(
        type: ServiceErrorType.network,
        message: 'No network connection.',
      );
    }
    final code = e.response?.statusCode;
    if (code == 401 || code == 403) {
      return WeatherServiceException(
        type: ServiceErrorType.missingCredentials,
        message: 'Invalid or missing API credentials. '
            'Go to Settings and check your Xweather Client ID and Secret.',
        statusCode: code,
      );
    }
    if (code == 429) {
      return const WeatherServiceException(
        type: ServiceErrorType.rateLimited,
        message: 'API rate limit reached. Please wait before retrying.',
        statusCode: 429,
      );
    }
    if (code == 404) {
      return WeatherServiceException(
        type: ServiceErrorType.notFound,
        message: 'Location or resource not found.',
        statusCode: code,
      );
    }
    if (code != null && code >= 500) {
      return WeatherServiceException(
        type: ServiceErrorType.serverError,
        message: 'Server error ($code). Try again shortly.',
        statusCode: code,
      );
    }
    return WeatherServiceException(
      type: ServiceErrorType.unknown,
      message: e.message ?? 'An unexpected error occurred.',
      statusCode: code,
    );
  }

  @override
  String toString() => 'WeatherServiceException($type): $message';
}
