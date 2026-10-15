import 'package:dio/dio.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:logger/logger.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/data/world_cities.dart';
import '../../../core/services/geonames_service.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

/// Lightweight weather snapshot for a map pin.
class MapWeatherData {
  const MapWeatherData({
    required this.cityKey,
    required this.cityName,
    required this.lat,
    required this.lng,
    required this.weatherCode,
    required this.temperature, // always °C — convert in the UI
    required this.fetchedAt,
  });

  final String   cityKey;
  final String   cityName;
  final double   lat;
  final double   lng;
  final int      weatherCode;
  final double   temperature;
  final DateTime fetchedAt;
}

// ── Internal pin reference ────────────────────────────────────────────────────

/// Minimal place descriptor used internally to drive weather fetches.
class _Pin {
  const _Pin({required this.key, required this.name, required this.lat, required this.lng});
  final String key;
  final String name;
  final double lat;
  final double lng;
}

// ── Model selection ───────────────────────────────────────────────────────────

/// Selects the best Open-Meteo forecast model for a coordinate.
/// UK coords use the high-resolution UKMO UKV model; elsewhere uses best_match.
String _openMeteoModel(double lat, double lon) {
  if (lat >= 49.9 && lat <= 60.9 && lon >= -8.2 && lon <= 1.8) {
    return 'ukmo_seamless';
  }
  return 'best_match';
}

// ── Visible city cap ──────────────────────────────────────────────────────────

const int _maxVisibleCities = 25;

// ── Static fallback: population threshold for zoom ───────────────────────────
// Used when Overpass is unreachable.

int _populationThreshold(double zoom) {
  if (zoom < 4)  return 2000000;
  if (zoom < 5)  return 1000000;
  if (zoom < 6)  return  500000;
  if (zoom < 7)  return  200000;
  if (zoom < 8)  return   50000;  // regional: county cities
  if (zoom < 9)  return   20000;  // county: market towns
  if (zoom < 10) return    6000;  // local: small towns
  return 2000;                    // street: villages
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class MapWeatherNotifier extends Notifier<Map<String, MapWeatherData>> {
  final _weatherCache = <String, MapWeatherData>{};
  final _logger       = Logger();

  static const _weatherCacheDuration = Duration(minutes: 30);

  late final Dio _dio;

  @override
  Map<String, MapWeatherData> build() {
    _dio = Dio(BaseOptions(
      connectTimeout: ApiConstants.defaultTimeout,
      receiveTimeout: ApiConstants.defaultTimeout,
    ));
    return {};
  }

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Called (debounced) whenever the map viewport changes.
  Future<void> updateViewport(LatLngBounds bounds, double zoom) async {
    final pins = await _discoverPlaces(bounds, zoom);
    if (pins.isEmpty) {
      state = {};
      return;
    }
    await _ensureWeather(pins);
  }

  // ── Place discovery ─────────────────────────────────────────────────────────

  /// Try GeoNames first for live, comprehensive global data.
  /// Falls back to the bundled static list if GeoNames is unreachable.
  Future<List<_Pin>> _discoverPlaces(LatLngBounds bounds, double zoom) async {
    final geoNames = ref.read(geoNamesServiceProvider);
    final places   = await geoNames.getPlacesInBounds(bounds, zoom);

    if (places.isNotEmpty) {
      return places
          .take(_maxVisibleCities)
          .map((p) => _Pin(key: p.key, name: p.name, lat: p.lat, lng: p.lng))
          .toList();
    }

    // Fallback: bundled static city list with population filtering.
    _logger.i('GeoNames unavailable — using static city list');
    final minPop = _populationThreshold(zoom);
    final filtered = worldCities
        .where((c) =>
            c.population >= minPop &&
            bounds.contains(LatLng(c.lat, c.lng)))
        .toList()
      ..sort((a, b) => b.population.compareTo(a.population));
    return filtered
        .take(_maxVisibleCities)
        .map((c) => _Pin(key: c.key, name: c.name, lat: c.lat, lng: c.lng))
        .toList();
  }

  // ── Weather fetching ────────────────────────────────────────────────────────

  Future<void> _ensureWeather(List<_Pin> pins) async {
    final now     = DateTime.now();
    final toFetch = pins.where((p) {
      final hit = _weatherCache[p.key];
      return hit == null ||
             now.difference(hit.fetchedAt) > _weatherCacheDuration;
    }).toList();

    if (toFetch.isNotEmpty) {
      // Open-Meteo supports up to 50 locations per request.
      // Pins are split by forecast model so that UK pins use the high-res
      // UKMO UKV model and international pins use best_match.  Within each
      // group we send up to 50 at a time to stay inside the batch limit.
      const batchSize = 50;
      final byModel = <String, List<_Pin>>{
        'ukmo_seamless': [],
        'best_match':    [],
      };
      for (final p in toFetch) {
        byModel[_openMeteoModel(p.lat, p.lng)]!.add(p);
      }
      for (final entry in byModel.entries) {
        final model = entry.key;
        final group = entry.value;
        for (var i = 0; i < group.length; i += batchSize) {
          final batch = group.skip(i).take(batchSize).toList();
          await _fetchWeatherBatch(batch, model: model);
        }
      }
    }

    state = {
      for (final p in pins)
        if (_weatherCache.containsKey(p.key)) p.key: _weatherCache[p.key]!,
    };
  }

  /// Fetches weather for multiple pins in a single Open-Meteo request.
  /// Open-Meteo accepts comma-separated lat/lng and returns a JSON array,
  /// one entry per location, in the same order as the input coordinates.
  ///
  /// [model] must be the same for every pin in the batch (caller groups by
  /// model before calling).  Falls back to individual requests if the batch
  /// call fails.
  Future<void> _fetchWeatherBatch(List<_Pin> pins, {required String model}) async {
    if (pins.isEmpty) return;
    // Single-pin shortcut — Open-Meteo returns an object (not array) for
    // exactly one location, so route it through the existing single fetcher.
    if (pins.length == 1) {
      await _fetchWeather(pins.first);
      return;
    }

    try {
      final response = await _dio.get<dynamic>(
        '${ApiConstants.openMeteoBaseUrl}${ApiConstants.openMeteoForecast}',
        queryParameters: {
          'latitude':      pins.map((p) => p.lat).join(','),
          'longitude':     pins.map((p) => p.lng).join(','),
          'hourly':        'temperature_2m,weather_code',
          'forecast_days': 1,
          'timezone':      'auto',
          'timeformat':    'iso8601',
          'models':        model,
        },
      );

      final results = response.data as List<dynamic>;
      final now = DateTime.now();

      for (var i = 0; i < results.length && i < pins.length; i++) {
        final pin  = pins[i];
        final data = results[i] as Map<String, dynamic>;

        if (data['error'] == true) {
          _logger.w(
            'Open-Meteo batch error for ${pin.name}: ${data['reason']}',
          );
          continue;
        }

        final hourly = data['hourly'] as Map<String, dynamic>;
        final temps  = hourly['temperature_2m'] as List;
        final codes  = hourly['weather_code']   as List;
        final times  = (hourly['time'] as List).cast<String>();

        // Pick the slot closest to right now (last slot not in the future).
        var idx = times.length - 1;
        for (var j = 0; j < times.length; j++) {
          if (!DateTime.parse(times[j]).isBefore(now)) {
            idx = j > 0 ? j - 1 : 0;
            break;
          }
        }

        _weatherCache[pin.key] = MapWeatherData(
          cityKey:     pin.key,
          cityName:    pin.name,
          lat:         pin.lat,
          lng:         pin.lng,
          weatherCode: codes[idx] == null ? 0 : (codes[idx] as num).toInt(),
          temperature: temps[idx] == null ? 0.0 : (temps[idx] as num).toDouble(),
          fetchedAt:   DateTime.now(),
        );
      }
    } on DioException catch (e) {
      _logger.w(
        'Batch weather fetch failed '
        '(status ${e.response?.statusCode}) — '
        'falling back to individual requests. ${e.message}',
      );
      for (final pin in pins) {
        await _fetchWeather(pin);
      }
    } catch (e, st) {
      _logger.w('Batch weather parse failed: $e', error: e, stackTrace: st);
      for (final pin in pins) {
        await _fetchWeather(pin);
      }
    }
  }

  Future<void> _fetchWeather(_Pin pin) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.openMeteoBaseUrl}${ApiConstants.openMeteoForecast}',
        queryParameters: {
          'latitude':      pin.lat,
          'longitude':     pin.lng,
          'hourly':        'temperature_2m,weather_code',
          'forecast_days': 1,
          'timezone':      'auto',
          'timeformat':    'iso8601',
          'models':        _openMeteoModel(pin.lat, pin.lng),
        },
      );

      // Open-Meteo returns HTTP 200 even for API-level errors; check for
      // an 'error' key before attempting to parse the data.
      final data = response.data as Map<String, dynamic>;
      if (data['error'] == true) {
        _logger.w(
          'Open-Meteo error for ${pin.name} '
          '(${pin.lat}, ${pin.lng}): ${data['reason']}',
        );
        return;
      }

      final hourly = data['hourly'] as Map<String, dynamic>;
      final temps  = hourly['temperature_2m'] as List;
      final codes  = hourly['weather_code']   as List;
      final times  = (hourly['time'] as List).cast<String>();

      // Pick the slot closest to right now.
      // If all slots are in the past (end-of-day edge case), use the last one.
      final now = DateTime.now();
      var idx = times.length - 1; // default: last slot
      for (var i = 0; i < times.length; i++) {
        if (!DateTime.parse(times[i]).isBefore(now)) {
          idx = i > 0 ? i - 1 : 0;
          break;
        }
      }

      _weatherCache[pin.key] = MapWeatherData(
        cityKey:     pin.key,
        cityName:    pin.name,
        lat:         pin.lat,
        lng:         pin.lng,
        weatherCode: codes[idx] == null ? 0 : (codes[idx] as num).toInt(),
        temperature: temps[idx] == null ? 0.0 : (temps[idx] as num).toDouble(),
        fetchedAt:   DateTime.now(),
      );
    } on DioException catch (e) {
      _logger.w(
        'Weather fetch failed for ${pin.name} '
        '(${pin.lat}, ${pin.lng}) — '
        'status: ${e.response?.statusCode}, '
        'message: ${e.message}',
      );
    } catch (e, st) {
      _logger.w(
        'Weather parse failed for ${pin.name}: $e',
        error: e,
        stackTrace: st,
      );
    }
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final mapWeatherProvider =
    NotifierProvider<MapWeatherNotifier, Map<String, MapWeatherData>>(
  MapWeatherNotifier.new,
);