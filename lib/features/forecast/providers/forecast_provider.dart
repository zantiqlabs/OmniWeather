import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/forecast.dart';
import '../../../core/providers/location_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/services/open_meteo_service.dart';
import '../../../home_widget/weather_widget_service.dart';

/// Fetches and caches the forecast for the active location.
///
/// Riverpod's [AsyncNotifier] automatically handles loading / error states.
/// After every successful fetch the widget is updated so the home-screen
/// widget always reflects the currently selected location.
class ForecastNotifier extends AsyncNotifier<ForecastData?> {
  @override
  Future<ForecastData?> build() async {
    final location = ref.watch(locationProvider).activeLocation;
    if (location == null) return null;
    final forecast = await _fetchForecast(location.latitude, location.longitude);
    await _pushToWidget(forecast, location);
    return forecast;
  }

  Future<void> refresh() async {
    final location = ref.read(locationProvider).activeLocation;
    if (location == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final forecast =
          await _fetchForecast(location.latitude, location.longitude);
      await _pushToWidget(forecast, location);
      return forecast;
    });
  }

  Future<ForecastData> _fetchForecast(double lat, double lon) {
    return ref.read(openMeteoServiceProvider).getForecast(lat: lat, lon: lon);
  }

  /// Pushes fresh forecast data to the home-screen widget.
  /// Errors are swallowed so a widget failure never breaks the forecast UI.
  Future<void> _pushToWidget(ForecastData forecast, dynamic location) async {
    try {
      final current = forecast.hourly.firstOrNull;
      if (current == null) return;
      final settings = ref.read(settingsProvider);
      await ref.read(weatherWidgetServiceProvider).updateWidget(
            locationName: location.name,
            latitude:     location.latitude,
            longitude:    location.longitude,
            currentHour:  current,
            settings:     settings,
            daily:        forecast.daily,
          );
    } catch (_) {
      // Widget update is best-effort — don't surface errors to the user.
    }
  }
}

final forecastProvider =
    AsyncNotifierProvider<ForecastNotifier, ForecastData?>(
  ForecastNotifier.new,
);

/// Derives just the "current conditions" from the first hourly entry.
final currentConditionsProvider = Provider<HourlyForecast?>((ref) {
  return ref.watch(forecastProvider).valueOrNull?.hourly.firstOrNull;
});

/// Derives the daily forecast list.
final dailyForecastProvider = Provider<List<DailyForecast>>((ref) {
  return ref.watch(forecastProvider).valueOrNull?.daily ?? [];
});