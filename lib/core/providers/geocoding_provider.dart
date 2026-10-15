import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/location.dart';
import '../services/open_meteo_service.dart';

/// Geocoding search results for a query string.
///
/// Keyed by the trimmed query so identical searches share their cache.
/// Results are automatically invalidated when the family falls out of use.
///
/// Usage:
/// ```dart
/// final results = ref.watch(geocodingProvider('London'));
/// ```
final geocodingProvider =
    FutureProvider.autoDispose.family<List<WeatherLocation>, String>(
  (ref, query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    final service = ref.read(openMeteoServiceProvider);
    return service.geocode(trimmed);
  },
);
