import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/historical_weather.dart';
import '../../../core/providers/location_provider.dart';
import '../../../core/services/open_meteo_service.dart';

/// Parameters driving a historical data query.
class HistoricalQuery {
  const HistoricalQuery({
    required this.latitude,
    required this.longitude,
    required this.startDate,
    required this.endDate,
  });

  final double latitude;
  final double longitude;
  final DateTime startDate;
  final DateTime endDate;

  @override
  bool operator ==(Object other) =>
      other is HistoricalQuery &&
      other.latitude == latitude &&
      other.longitude == longitude &&
      other.startDate == startDate &&
      other.endDate == endDate;

  @override
  int get hashCode => Object.hash(latitude, longitude, startDate, endDate);
}

/// Fetches historical data for a given [HistoricalQuery].
final historicalDataProvider = FutureProvider.family<HistoricalData, HistoricalQuery>(
  (ref, query) async {
    return ref.read(openMeteoServiceProvider).getHistorical(
      lat: query.latitude,
      lon: query.longitude,
      start: query.startDate,
      end: query.endDate,
    );
  },
);

/// Fetches the multi-year climatology for the active location and selected month.
/// Used to power the "typical for this time of year" comparison charts.
final climatologyProvider = FutureProvider.family<List<HistoricalData>, int>(
  (ref, month) async {
    final location = ref.watch(locationProvider).activeLocation;
    if (location == null) return [];

    return ref.read(openMeteoServiceProvider).getHistoricalMultiYear(
      lat: location.latitude,
      lon: location.longitude,
      month: month,
      yearCount: AppConstants.historicalComparisonYears,
    );
  },
);

/// Convenience: derive a [MonthlyClimatology] summary from raw historical data.
List<MonthlyClimatology> buildClimatology(List<HistoricalData> datasets) {
  return datasets.map((data) {
    final days = data.days;
    if (days.isEmpty) {
      return MonthlyClimatology(
        month: data.startDate.month,
        year: data.startDate.year,
        avgTempMax: 0,
        avgTempMin: 0,
        avgTempMean: 0,
        totalPrecipitation: 0,
        maxPrecipitationDay: 0,
        rainyDays: 0,
        snowyDays: 0,
        avgWindSpeed: 0,
      );
    }
    return MonthlyClimatology(
      month: data.startDate.month,
      year: data.startDate.year,
      avgTempMax: days.map((d) => d.tempMax).reduce((a, b) => a + b) / days.length,
      avgTempMin: days.map((d) => d.tempMin).reduce((a, b) => a + b) / days.length,
      avgTempMean: days.map((d) => d.tempMean).reduce((a, b) => a + b) / days.length,
      totalPrecipitation: days.map((d) => d.precipitationSum).reduce((a, b) => a + b),
      maxPrecipitationDay: days.map((d) => d.precipitationSum).reduce((a, b) => a > b ? a : b),
      rainyDays: days.where((d) => d.rainSum > 1.0).length,
      snowyDays: days.where((d) => d.snowfallSum > 1.0).length,
      avgWindSpeed: days.map((d) => d.windSpeedMax).reduce((a, b) => a + b) / days.length,
    );
  }).toList();
}
