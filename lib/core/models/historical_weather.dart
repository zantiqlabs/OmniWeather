import 'package:freezed_annotation/freezed_annotation.dart';

part 'historical_weather.freezed.dart';
part 'historical_weather.g.dart';

/// One day of historical weather data from the Open-Meteo archive API.
@freezed
class HistoricalDay with _$HistoricalDay {
  const factory HistoricalDay({
    required DateTime date,
    required int weatherCode,
    required double tempMax,
    required double tempMin,
    required double tempMean,
    required double apparentTempMax,
    required double apparentTempMin,
    required double precipitationSum,
    required double rainSum,
    required double snowfallSum,
    required double precipitationHours,
    required double windSpeedMax,
    required double windGustsMax,
    required double windDirectionDominant,
  }) = _HistoricalDay;

  factory HistoricalDay.fromJson(Map<String, dynamic> json) =>
      _$HistoricalDayFromJson(json);
}

/// Historical data for a specific location and date range.
@freezed
class HistoricalData with _$HistoricalData {
  const factory HistoricalData({
    required double latitude,
    required double longitude,
    required String timezone,
    required DateTime startDate,
    required DateTime endDate,
    required List<HistoricalDay> days,
    required DateTime fetchedAt,
  }) = _HistoricalData;

  factory HistoricalData.fromJson(Map<String, dynamic> json) =>
      _$HistoricalDataFromJson(json);
}

/// A statistical summary for a calendar month across multiple years,
/// used to power the "typical weather for this time of year" charts.
@freezed
class MonthlyClimatology with _$MonthlyClimatology {
  const factory MonthlyClimatology({
    required int month,           // 1–12
    required int year,
    required double avgTempMax,
    required double avgTempMin,
    required double avgTempMean,
    required double totalPrecipitation,
    required double maxPrecipitationDay,
    required int rainyDays,
    required int snowyDays,
    required double avgWindSpeed,
  }) = _MonthlyClimatology;

  factory MonthlyClimatology.fromJson(Map<String, dynamic> json) =>
      _$MonthlyClimatologyFromJson(json);
}
