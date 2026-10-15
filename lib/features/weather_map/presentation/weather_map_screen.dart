import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/models/location.dart';
import '../../../core/providers/location_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/providers/tab_provider.dart';
import '../../../shared/widgets/location_search_delegate.dart';
import '../providers/map_weather_provider.dart';
import '../providers/rain_radar_provider.dart';
import 'widgets/weather_map_marker.dart';

/// How often to silently re-fetch the latest radar frame.
/// RainViewer publishes new frames roughly every 10 minutes, so 5 minutes
/// keeps the overlay reasonably fresh without hammering the API.
const _radarRefreshInterval = Duration(minutes: 5);

class WeatherMapScreen extends ConsumerStatefulWidget {
  const WeatherMapScreen({super.key});

  @override
  ConsumerState<WeatherMapScreen> createState() => _WeatherMapScreenState();
}

class _WeatherMapScreenState extends ConsumerState<WeatherMapScreen> {
  final _mapController = MapController();
  Timer? _debounce;

  // Default centre: roughly the middle of the UK
  static const _initialCenter = LatLng(54.0, -2.5);
  static const _initialZoom   = 6.0;

  // ── Radar state ─────────────────────────────────────────────────────────────

  bool   _radarEnabled = false;
  Timer? _radarRefreshTimer;

  void _toggleRadar() {
    setState(() => _radarEnabled = !_radarEnabled);
    if (_radarEnabled) {
      ref.read(rainRadarProvider.notifier).refresh();
      _startRefreshTimer();
    } else {
      _stopRefreshTimer();
    }
  }

  void _startRefreshTimer() {
    _radarRefreshTimer?.cancel();
    _radarRefreshTimer = Timer.periodic(_radarRefreshInterval, (_) {
      if (mounted) ref.read(rainRadarProvider.notifier).refresh();
    });
  }

  void _stopRefreshTimer() {
    _radarRefreshTimer?.cancel();
    _radarRefreshTimer = null;
  }

  // ── Map event handling ──────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scheduleUpdate());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _radarRefreshTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  void _onMapEvent(MapEvent event) {
    if (event is MapEventMoveEnd           ||
        event is MapEventFlingAnimationEnd  ||
        event is MapEventScrollWheelZoom    ||
        event is MapEventRotateEnd) {
      _scheduleUpdate();
    }
  }

  void _scheduleUpdate() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), _fetchForViewport);
  }

  void _fetchForViewport() {
    if (!mounted) return;
    try {
      final camera = _mapController.camera;
      ref.read(mapWeatherProvider.notifier).updateViewport(
        camera.visibleBounds,
        camera.zoom,
      );
    } catch (_) {}
  }

  Future<void> _goToDeviceLocation() async {
    final loc =
        await ref.read(locationProvider.notifier).requestDeviceLocation();
    if (!mounted || loc == null) return;
    _mapController.move(LatLng(loc.latitude, loc.longitude), _initialZoom);
    _fetchForViewport();
  }

  void _panMapTo(double lat, double lon) {
    try {
      _mapController.move(LatLng(lat, lon), _mapController.camera.zoom);
    } catch (_) {
      try {
        _mapController.move(LatLng(lat, lon), _initialZoom);
      } catch (_) {}
    }
  }

  // ── Marker tap → forecast screen ───────────────────────────────────────────

  void _openForecast(MapWeatherData data) {
    final loc = WeatherLocation(
      id:        'map_${data.cityKey}',
      name:      data.cityName,
      latitude:  data.lat,
      longitude: data.lng,
    );
    ref.read(locationProvider.notifier).setActiveLocation(loc);
    ref.read(activeTabProvider.notifier).state = 0;
  }

  // ── Radar info strip ────────────────────────────────────────────────────────

  Widget _buildRadarInfo(RainRadarData? radarData, bool isLoading) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withAlpha(230),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(
            Icons.water_drop_outlined,
            size: 14,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: isLoading
                ? Row(
                    children: [
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 1.5),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Fetching radar…',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  )
                : Text(
                    radarData?.latestFrame != null
                        ? 'Rain radar · ${radarData!.latestFrame!.label(DateTime.now())}'
                        : 'Rain radar · unavailable',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
          ),
          // Manual refresh
          if (!isLoading)
            IconButton(
              icon: const Icon(Icons.refresh, size: 16),
              tooltip: 'Refresh radar',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: () =>
                  ref.read(rainRadarProvider.notifier).refresh(),
            ),
        ],
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final weatherData   = ref.watch(mapWeatherProvider);
    final settings      = ref.watch(settingsProvider);
    final locationState = ref.watch(locationProvider);
    final radarAsync    = ref.watch(rainRadarProvider);

    final radarData  = radarAsync.valueOrNull;
    final radarUrl   = radarData?.tileUrlTemplate;
    final radarFrame = radarData?.latestFrame;

    ref.listen(locationProvider, (previous, next) {
      final loc = next.activeLocation;
      if (loc == null) return;
      final prevLoc = previous?.activeLocation;
      if (prevLoc?.latitude  == loc.latitude &&
          prevLoc?.longitude == loc.longitude) return;
      _panMapTo(loc.latitude, loc.longitude);
      _scheduleUpdate();
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather Map'),
        actions: [
          // Radar toggle
          IconButton(
            icon: Icon(
              Icons.water_drop_outlined,
              color: _radarEnabled
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            tooltip: _radarEnabled ? 'Hide radar' : 'Show rain radar',
            onPressed: _toggleRadar,
          ),
          // Search location
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search location',
            onPressed: () => showSearch(
              context: context,
              delegate: LocationSearchDelegate(ref),
            ),
          ),
          // GPS
          IconButton(
            icon: locationState.isLocating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location),
            tooltip: 'My location',
            onPressed: locationState.isLocating ? null : _goToDeviceLocation,
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialCenter,
              initialZoom:   _initialZoom,
              minZoom: 2,
              maxZoom: 14,
              onMapEvent: _onMapEvent,
            ),
            children: [
              // ── Base tile layer ─────────────────────────────────────────────
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.zantiqlabs.omniweather',
              ),

              // ── Rain radar overlay ──────────────────────────────────────────
              // Shows the single most-recent radar frame as a static overlay.
              // The key changes only when a new frame path arrives (i.e. every
              // ~10 min), so tiles are never re-fetched during normal use.
              // RainViewer radar tiles are natively available up to zoom 6;
              // flutter_map will overzoom/scale them at higher levels.
              if (_radarEnabled && radarUrl != null && radarFrame != null)
                Opacity(
                  opacity: 0.65,
                  child: TileLayer(
                    key: ValueKey(radarFrame.path),
                    urlTemplate: radarUrl,
                    userAgentPackageName: 'com.zantiqlabs.omniweather',
                    minNativeZoom: 0,
                    maxNativeZoom: 6,
                  ),
                ),

              // ── Weather markers ─────────────────────────────────────────────
              MarkerLayer(
                markers: [
                  for (final entry in weatherData.entries)
                    Marker(
                      point:  LatLng(entry.value.lat, entry.value.lng),
                      width:  90,
                      height: 60,
                      child:  WeatherMapMarker(
                        data:     entry.value,
                        settings: settings,
                        onTap:    () => _openForecast(entry.value),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // ── Radar info strip ────────────────────────────────────────────────
          if (_radarEnabled)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildRadarInfo(radarData, radarAsync.isLoading),
            ),

          // ── Attribution ─────────────────────────────────────────────────────
          Positioned(
            bottom: _radarEnabled ? 40 : 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xCCFFFFFF),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _radarEnabled
                    ? '© OpenStreetMap · RainViewer'
                    : '© OpenStreetMap contributors',
                style: const TextStyle(fontSize: 9, color: Color(0xFF555555)),
              ),
            ),
          ),

          // ── Loading indicator while initial weather data arrives ──────────
          if (weatherData.isEmpty)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}