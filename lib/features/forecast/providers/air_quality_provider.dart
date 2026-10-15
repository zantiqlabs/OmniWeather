import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/air_quality.dart';
import '../../../core/providers/location_provider.dart';
import '../../../core/services/air_quality_service.dart';

/// Fetches air quality data for the active location.
///
/// Mirrors the pattern of [ForecastNotifier]: auto-rebuilds when the
/// active location changes, exposes a [refresh] method, and returns null
/// when no location is set.
class AirQualityNotifier extends AsyncNotifier<AirQualityData?> {
  @override
  Future<AirQualityData?> build() async {
    final location = ref.watch(locationProvider).activeLocation;
    if (location == null) return null;
    return _fetch(location.latitude, location.longitude);
  }

  Future<void> refresh() async {
    final location = ref.read(locationProvider).activeLocation;
    if (location == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _fetch(location.latitude, location.longitude),
    );
  }

  Future<AirQualityData?> _fetch(double lat, double lon) {
    return ref.read(airQualityServiceProvider).getAirQuality(
          lat: lat,
          lon: lon,
        );
  }
}

final airQualityProvider =
    AsyncNotifierProvider<AirQualityNotifier, AirQualityData?>(
  AirQualityNotifier.new,
);

/// Convenience: the current AQI hour, or null while loading / no location.
final currentAirQualityProvider = Provider<AirQualityHour?>((ref) {
  return ref.watch(airQualityProvider).valueOrNull?.currentHour();
});
