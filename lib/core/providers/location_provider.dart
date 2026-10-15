import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../models/location.dart';

/// Manages the active location and the list of saved locations.
class LocationNotifier extends Notifier<LocationState> {
  @override
  LocationState build() => const LocationState();

  // ── Device location ───────────────────────────────────────────────────────

  Future<WeatherLocation?> requestDeviceLocation() async {
    state = state.copyWith(isLocating: true, locationError: null);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        state = state.copyWith(
          isLocating: false,
          locationError: 'Location permission denied.',
        );
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );

      final loc = WeatherLocation(
        id: 'device',
        name: 'My Location',
        latitude: position.latitude,
        longitude: position.longitude,
      );

      state = state.copyWith(
        isLocating: false,
        activeLocation: loc,
      );
      _persistActiveLocation(loc);
      return loc;
    } catch (e) {
      state = state.copyWith(
        isLocating: false,
        locationError: 'Could not determine location.',
      );
      return null;
    }
  }

  // ── Saved locations ───────────────────────────────────────────────────────

  Future<void> loadSavedLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getStringList(AppConstants.keySavedLocations) ?? [];
    // Deduplicate by id — keeps the first occurrence (oldest entry) and
    // silently drops any duplicates that accumulated before this fix.
    final seen = <String>{};
    final locations = json
        .map((s) => WeatherLocation.fromJson(
              jsonDecode(s) as Map<String, dynamic>,
            ))
        .where((l) => seen.add(l.id))
        .toList();

    // Restore last active location
    final lastJson = prefs.getString(AppConstants.keyLastLocation);
    WeatherLocation? last;
    if (lastJson != null) {
      last = WeatherLocation.fromJson(
        jsonDecode(lastJson) as Map<String, dynamic>,
      );
    }

    state = state.copyWith(
      savedLocations: locations,
      activeLocation: last ?? (locations.isNotEmpty ? locations.first : null),
    );
  }

  void setActiveLocation(WeatherLocation location) {
    state = state.copyWith(activeLocation: location);
    _persistActiveLocation(location);
  }

  Future<void> addLocation(WeatherLocation location) async {
    // Deduplicate by id — same city searched from any screen reuses the
    // existing entry instead of appending a duplicate.
    final existing = state.savedLocations.indexWhere((l) => l.id == location.id);
    if (existing != -1) {
      // Already saved — just make it active; no list change needed.
      return;
    }
    final updated = [...state.savedLocations, location];
    state = state.copyWith(savedLocations: updated);
    await _persistLocations(updated);
  }

  Future<void> removeLocation(String id) async {
    final updated = state.savedLocations.where((l) => l.id != id).toList();
    state = state.copyWith(savedLocations: updated);
    await _persistLocations(updated);
  }

  Future<void> toggleFavourite(String id) async {
    final updated = state.savedLocations.map((l) {
      if (l.id == id) return l.copyWith(isFavourite: !l.isFavourite);
      return l;
    }).toList();
    state = state.copyWith(savedLocations: updated);
    await _persistLocations(updated);
  }

  // ── Persistence ───────────────────────────────────────────────────────────

  Future<void> _persistLocations(List<WeatherLocation> locations) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      AppConstants.keySavedLocations,
      locations.map((l) => jsonEncode(l.toJson())).toList(),
    );
  }

  Future<void> _persistActiveLocation(WeatherLocation loc) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyLastLocation, jsonEncode(loc.toJson()));
  }
}

class LocationState {
  const LocationState({
    this.activeLocation,
    this.savedLocations = const [],
    this.isLocating = false,
    this.locationError,
  });

  final WeatherLocation? activeLocation;
  final List<WeatherLocation> savedLocations;
  final bool isLocating;
  final String? locationError;

  LocationState copyWith({
    WeatherLocation? activeLocation,
    List<WeatherLocation>? savedLocations,
    bool? isLocating,
    String? locationError,
  }) => LocationState(
    activeLocation: activeLocation ?? this.activeLocation,
    savedLocations: savedLocations ?? this.savedLocations,
    isLocating: isLocating ?? this.isLocating,
    locationError: locationError,
  );
}

final locationProvider =
    NotifierProvider<LocationNotifier, LocationState>(LocationNotifier.new);