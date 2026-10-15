import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/lightning.dart';
import '../../../core/services/blitzortung_service.dart';

/// Manages a live Blitzortung WebSocket connection and maintains a rolling
/// 1-hour buffer of nearby lightning strikes.
///
/// Call [connect] once (from the Lightning screen's initState) with the
/// target location. The provider is autoDisposed when nothing watches it,
/// which closes the WebSocket automatically.
class LightningNotifier
    extends StateNotifier<AsyncValue<LightningData?>> {
  LightningNotifier(this._service) : super(const AsyncValue.loading());

  final BlitzortungService _service;

  StreamSubscription<LightningStrike>? _sub;
  Timer? _pruneTimer;
  final List<LightningStrike> _strikes = [];
  double? _lat;
  double? _lon;

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Connect to Blitzortung for [lat]/[lon]. Safe to call multiple times
  /// (re-connects if the location changes).
  void connect(double lat, double lon) {
    // Already connected to the same spot — nothing to do.
    if (_lat == lat && _lon == lon && _sub != null) return;

    _tearDown();
    _lat = lat;
    _lon = lon;
    _strikes.clear();

    // Emit empty data right away so the map renders before strikes arrive.
    _emit();

    _sub = _service
        .connect(lat: lat, lon: lon, radiusKm: AppConstants.defaultRadiusKm)
        .listen(
          _onStrike,
          onError: _onError,
          onDone: _onDone,
          cancelOnError: true,
        );

    // Prune strikes older than 1 hour every minute.
    _pruneTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) { _pruneOld(); _emit(); },
    );
  }

  // ── Internal ────────────────────────────────────────────────────────────────

  void _onStrike(LightningStrike strike) {
    if (!mounted) return;
    _strikes.add(strike);
    _pruneOld();
    _emit();
  }

  void _onError(Object e, StackTrace st) {
    if (!mounted) return;
    state = AsyncValue.error(e, st);
    _scheduleReconnect();
  }

  void _onDone() {
    if (!mounted) return;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted && _lat != null) connect(_lat!, _lon!);
    });
  }

  void _emit() {
    if (!mounted) return;
    state = AsyncValue.data(LightningData(
      strikes: List.unmodifiable(List<LightningStrike>.from(_strikes)),
      fetchedAt: DateTime.now(),
      queryLatitude:  _lat ?? 0,
      queryLongitude: _lon ?? 0,
      queryRadiusKm:  AppConstants.defaultRadiusKm,
    ));
  }

  void _pruneOld() {
    final cutoff = DateTime.now().subtract(const Duration(hours: 1));
    _strikes.removeWhere((s) => s.timestamp.isBefore(cutoff));
  }

  void _tearDown() {
    _sub?.cancel();
    _sub = null;
    _pruneTimer?.cancel();
    _pruneTimer = null;
  }

  @override
  void dispose() {
    _tearDown();
    _service.disconnect();
    super.dispose();
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final lightningProvider = StateNotifierProvider.autoDispose<
    LightningNotifier, AsyncValue<LightningData?>>(
  (ref) => LightningNotifier(ref.watch(blitzortungServiceProvider)),
);

/// True when there are CG strikes within the last 30 minutes.
final activeLightningAlertProvider = Provider.autoDispose<bool>((ref) {
  final data = ref.watch(lightningProvider).valueOrNull;
  if (data == null) return false;
  final cutoff = DateTime.now().subtract(const Duration(minutes: 30));
  return data.strikes.any(
    (s) => s.type == LightningType.cloudToGround && s.timestamp.isAfter(cutoff),
  );
});

/// Count of strikes in the rolling 1-hour window.
final recentStrikeCountProvider = Provider.autoDispose<int>((ref) {
  return ref.watch(lightningProvider).valueOrNull?.strikes.length ?? 0;
});