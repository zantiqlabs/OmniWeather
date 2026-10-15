import 'package:dio/dio.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

/// A place returned by the GeoNames citiesJSON endpoint.
class GeoNamesPlace {
  const GeoNamesPlace({
    required this.name,
    required this.lat,
    required this.lng,
    required this.population,
    required this.featureCode,
  });

  final String name;
  final double lat;
  final double lng;
  final int    population;

  /// GeoNames feature code, e.g. PPLC (capital), PPLA (admin seat), PPL, etc.
  final String featureCode;

  /// Stable cache key matching MapWeatherData.cityKey format.
  String get key => '${lat.toStringAsFixed(3)},${lng.toStringAsFixed(3)}';

  /// Higher = more important; used for sort-stable ordering.
  int get rank => switch (featureCode) {
    'PPLC'             => 6, // national capital
    'PPLA'             => 5, // 1st-order admin seat (state/region capital)
    'PPLA2'            => 4, // 2nd-order admin seat
    'PPLA3' || 'PPLA4' => 3, // 3rd / 4th-order admin seat
    'PPL'              => 2, // general populated place
    _                  => 1,
  };
}

// ── Cache entry ───────────────────────────────────────────────────────────────

class _TileCacheEntry {
  _TileCacheEntry(this.places) : fetchedAt = DateTime.now();
  final List<GeoNamesPlace> places;
  final DateTime            fetchedAt;

  // Place data is stable; cache for 4 hours.
  bool get isStale =>
      DateTime.now().difference(fetchedAt) > const Duration(hours: 4);
}

// ── Service ───────────────────────────────────────────────────────────────────

/// Queries the GeoNames citiesJSON endpoint for populated places in a bounding
/// box.  Results are cached by geographic tile so that small pans / zooms
/// reuse existing data.
///
/// Free-tier account (zantiqlabs) — no API key, just a username parameter.
/// Credits: 30 000 / day, 2 000 / hour.  Each request costs 1 credit.
class GeoNamesService {
  GeoNamesService(this._dio, this._logger);

  final Dio    _dio;
  final Logger _logger;

  static const _username = 'zantiqlabs';
  static const _baseUrl  = 'https://secure.geonames.org/citiesJSON';

  // Fetch up to this many rows from GeoNames per request.
  // We cap at _maxVisibleCities in the provider, but fetching more gives
  // us a larger pool to sort / deduplicate from.
  static const _maxRows = 50;

  final _cache = <String, _TileCacheEntry>{};

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Returns populated places inside [bounds], sorted most-important first.
  Future<List<GeoNamesPlace>> getPlacesInBounds(
    LatLngBounds bounds,
    double zoom,
  ) async {
    final tileKey = _tileKey(bounds, zoom);
    final cached  = _cache[tileKey];
    if (cached != null && !cached.isStale) return cached.places;

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        _baseUrl,
        queryParameters: {
          'north':    bounds.north,
          'south':    bounds.south,
          'east':     bounds.east,
          'west':     bounds.west,
          'maxRows':  _maxRows,
          'username': _username,
        },
      );

      final data     = response.data ?? {};
      final geonames = (data['geonames'] as List?) ?? [];

      if (geonames.isEmpty) {
        _logger.i('GeoNames returned 0 places for tile $tileKey');
        return const [];
      }

      final places = geonames
          .map((e) {
            final name = e['name'] as String?;
            if (name == null) return null;
            // GeoNames returns lat/lng as strings in some styles.
            final lat = double.tryParse(e['lat']?.toString() ?? '');
            final lng = double.tryParse(e['lng']?.toString() ?? '');
            if (lat == null || lng == null) return null;
            return GeoNamesPlace(
              name:        name,
              lat:         lat,
              lng:         lng,
              population:  (e['population'] as num?)?.toInt() ?? 0,
              featureCode: e['fcode'] as String? ?? 'PPL',
            );
          })
          .whereType<GeoNamesPlace>()
          .toList()
        ..sort((a, b) {
          final r = b.rank.compareTo(a.rank);
          return r != 0 ? r : b.population.compareTo(a.population);
        });

      _cache[tileKey] = _TileCacheEntry(places);
      _logger.i('GeoNames: ${places.length} places for tile $tileKey');
      return places;

    } on DioException catch (e) {
      _logger.w(
        'GeoNames request failed (${e.response?.statusCode}): ${e.message}',
      );
      return const [];
    } catch (e, st) {
      _logger.w('GeoNames parse error: $e', error: e, stackTrace: st);
      return const [];
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  /// Quantise [bounds] to a geographic tile so that small pans share a cache
  /// entry.  Grain is coarser at low zoom (large viewport).
  String _tileKey(LatLngBounds bounds, double zoom) {
    final grain = zoom < 5  ? 20.0
                : zoom < 8  ?  5.0
                : zoom < 11 ?  1.0
                :              0.25;
    double q(double v) => (v / grain).floorToDouble() * grain;
    return '${q(bounds.south)},${q(bounds.west)},${q(bounds.north)},${q(bounds.east)}';
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final geoNamesServiceProvider = Provider<GeoNamesService>((ref) {
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));
  return GeoNamesService(dio, Logger());
});
