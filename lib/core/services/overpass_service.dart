import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

/// A place discovered from the OpenStreetMap Overpass API.
///
/// Uses OSM `place=*` tags: city > town > village > hamlet.
/// Completely free, no API key required, global coverage.
class OverpassPlace {
  const OverpassPlace({
    required this.name,
    required this.lat,
    required this.lng,
    required this.placeType,
  });

  final String name;
  final double lat;
  final double lng;

  /// OSM place tag value: 'city', 'town', 'village', 'hamlet', etc.
  final String placeType;

  /// Stable cache key (matches MapWeatherData.cityKey format).
  String get key => '${lat.toStringAsFixed(3)},${lng.toStringAsFixed(3)}';

  /// Rank used for sorting / prioritising within the visible cap.
  /// Higher = more important.
  int get rank => switch (placeType) {
    'city'     => 4,
    'town'     => 3,
    'village'  => 2,
    'suburb'   => 1,
    _          => 0,
  };
}

// ── Cache entry ───────────────────────────────────────────────────────────────

class _TileCacheEntry {
  _TileCacheEntry(this.places) : fetchedAt = DateTime.now();

  final List<OverpassPlace> places;
  final DateTime fetchedAt;

  // Place data is stable; cache for 4 hours.
  bool get isStale =>
      DateTime.now().difference(fetchedAt) > const Duration(hours: 4);
}

// ── Service ───────────────────────────────────────────────────────────────────

/// Queries the OpenStreetMap Overpass API for named places within a bounding
/// box.  Results are cached by geographic tile so that small pans / zooms
/// reuse existing data.
///
/// Multiple public mirrors are tried in order so that per-IP rate-limiting
/// on one host (HTTP 406 / 429) does not block all requests.
class OverpassService {
  OverpassService(this._dio, this._logger);

  final Dio    _dio;
  final Logger _logger;

  final _cache = <String, _TileCacheEntry>{};

  // Public Overpass mirrors — tried in order; first success wins.
  static const _mirrors = [
    'https://overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
    'https://overpass.openstreetmap.ru/api/interpreter',
    'https://overpass.openstreetmap.fr/api/interpreter',
    'https://overpass.nchc.org.tw/api/interpreter',
  ];

  // Per-mirror cooldown: don't retry a rate-limited mirror for 5 minutes.
  final _mirrorCooldown = <String, DateTime>{};

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Returns named places inside [bounds], filtered to the types appropriate
  /// for [zoom].  Sorted most-important first.
  Future<List<OverpassPlace>> getPlacesInBounds(
    LatLngBounds bounds,
    double zoom,
  ) async {
    final tileKey = _tileKey(bounds, zoom);
    final cached  = _cache[tileKey];
    if (cached != null && !cached.isStale) return cached.places;

    final filter = _placeFilter(zoom);
    final query =
        '[out:json][timeout:15]'
        '[bbox:${bounds.south},${bounds.west},${bounds.north},${bounds.east}];'
        '(node["place"~"^($filter)\$"]["name"];);'
        'out;';

    for (final mirror in _mirrors) {
      // Skip mirrors that are still cooling down.
      final coolUntil = _mirrorCooldown[mirror];
      if (coolUntil != null && DateTime.now().isBefore(coolUntil)) continue;

      try {
        final response = await _dio.post(
          mirror,
          data: 'data=${Uri.encodeComponent(query)}',
          options: Options(
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept':       '*/*',
            },
            sendTimeout:    const Duration(seconds: 20),
            receiveTimeout: const Duration(seconds: 20),
            responseType:   ResponseType.plain,
          ),
        );

        final body     = jsonDecode(response.data as String) as Map<String, dynamic>;
        final elements = (body['elements'] as List?) ?? [];
        final places   = elements
            .map((e) {
              final tags = e['tags'] as Map<String, dynamic>? ?? {};
              final name = tags['name'] as String?;
              if (name == null) return null;
              final lat = (e['lat'] as num?)?.toDouble();
              final lon = (e['lon'] as num?)?.toDouble();
              if (lat == null || lon == null) return null;
              return OverpassPlace(
                name:      name,
                lat:       lat,
                lng:       lon,
                placeType: tags['place'] as String? ?? 'village',
              );
            })
            .whereType<OverpassPlace>()
            .toList()
          ..sort((a, b) {
            final r = b.rank.compareTo(a.rank);
            return r != 0 ? r : a.name.compareTo(b.name);
          });

        _cache[tileKey] = _TileCacheEntry(places);
        return places;

      } on DioException catch (e) {
        final status = e.response?.statusCode;
        if (status == 406 || status == 429) {
          // Rate-limited — cool this mirror down and try the next one.
          _mirrorCooldown[mirror] = DateTime.now().add(const Duration(minutes: 5));
          _logger.w('Overpass mirror $mirror rate-limited ($status), trying next');
        } else {
          // Non-rate-limit error (timeout, network) — log and fall through.
          _logger.w('Overpass mirror $mirror failed ($status): ${e.message}');
        }
      }
    }

    // All mirrors exhausted — caller falls back to static list.
    _logger.w('All Overpass mirrors unavailable');
    return const [];
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  /// Which OSM place types to include at a given zoom.
  String _placeFilter(double zoom) {
    if (zoom < 6)  return 'city';
    if (zoom < 8)  return 'city|town';
    if (zoom < 10) return 'city|town|village';
    return 'city|town|village|hamlet|suburb';
  }

  /// Quantise [bounds] to a geographic tile whose size matches the zoom so
  /// that small pans within the same area share a cache entry.
  String _tileKey(LatLngBounds bounds, double zoom) {
    // Tile grain in degrees — coarser at low zoom (large viewport).
    final grain = zoom < 5  ? 20.0
                : zoom < 8  ?  5.0
                : zoom < 11 ?  1.0
                :              0.25;
    double q(double v) => (v / grain).floorToDouble() * grain;
    return '${q(bounds.south)},${q(bounds.west)},'
           '${q(bounds.north)},${q(bounds.east)}';
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final overpassServiceProvider = Provider<OverpassService>((ref) {
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 20),
  ));
  return OverpassService(dio, Logger());
});
