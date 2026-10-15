import 'package:freezed_annotation/freezed_annotation.dart';

part 'forecast.freezed.dart';
part 'forecast.g.dart';

/// A single hourly forecast data point.
@freezed
class HourlyForecast with _$HourlyForecast {
  const factory HourlyForecast({
    required DateTime time,
    required double temperature,
    required double apparentTemperature,
    required double relativeHumidity,
    required double precipitationProbability,
    required double precipitation,
    required int weatherCode,
    required double cloudCover,
    required double windSpeed,
    required double windDirection,
    required double windGusts,
    required double visibility,
    required double uvIndex,
  }) = _HourlyForecast;

  factory HourlyForecast.fromJson(Map<String, dynamic> json) =>
      _$HourlyForecastFromJson(json);
}

/// A single daily forecast summary.
@freezed
class DailyForecast with _$DailyForecast {
  const factory DailyForecast({
    required DateTime date,
    required int weatherCode,
    required double tempMax,
    required double tempMin,
    required double apparentTempMax,
    required double apparentTempMin,
    required DateTime sunrise,
    required DateTime sunset,
    required double precipitationSum,
    required double rainSum,
    required double snowfallSum,
    required double precipitationHours,
    required double precipitationProbabilityMax,
    required double windSpeedMax,
    required double windGustsMax,
    required double windDirectionDominant,
    required double uvIndexMax,
  }) = _DailyForecast;

  factory DailyForecast.fromJson(Map<String, dynamic> json) =>
      _$DailyForecastFromJson(json);
}

/// The full forecast response for a location.
@freezed
class ForecastData with _$ForecastData {
  const factory ForecastData({
    required double latitude,
    required double longitude,
    required String timezone,
    required List<HourlyForecast> hourly,
    required List<DailyForecast> daily,
    required DateTime fetchedAt,
  }) = _ForecastData;

  factory ForecastData.fromJson(Map<String, dynamic> json) =>
      _$ForecastDataFromJson(json);
}
