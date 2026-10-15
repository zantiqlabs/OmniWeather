import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Data model ────────────────────────────────────────────────────────────────

class RainRadarFrame {
  const RainRadarFrame({
    required this.path,
    required this.time,
  });

  /// Tile path prefix returned by the RainViewer API, e.g.
  /// "/v2/radar/1728000000"
  final String path;

  /// Unix timestamp (seconds) of this frame.
  final int time;

  /// Human-readable "last updated" label relative to [now].
  String label(DateTime now) {
    final frameTime = DateTime.fromMillisecondsSinceEpoch(time * 1000);
    final diffMin = now.difference(frameTime).inMinutes;
    if (diffMin < 1)  return 'Just now';
    if (diffMin < 60) return '${diffMin}m ago';
    final h = diffMin ~/ 60;
    return '${h}h ${diffMin % 60}m ago';
  }
}

class RainRadarData {
  const RainRadarData({required this.host, required this.latestFrame});

  /// CDN host, e.g. "https://tilecache.rainviewer.com"
  final String host;

  /// The single most-recent radar frame (null if API returned nothing).
  final RainRadarFrame? latestFrame;

  bool get hasData => latestFrame != null;

  /// XYZ tile URL template for the latest frame, ready for flutter_map's TileLayer.
  ///
  /// Color scheme 6 = NEXRAD Level-III palette (blue→green→yellow→red).
  /// smooth=1, snow=1 (last two path segments).
  String? get tileUrlTemplate => latestFrame == null
      ? null
      : '$host${latestFrame!.path}/256/{z}/{x}/{y}/6/1_1.png';
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class RainRadarNotifier extends AsyncNotifier<RainRadarData> {
  static const _apiUrl =
      'https://api.rainviewer.com/public/weather-maps.json';

  late final Dio _dio;

  @override
  Future<RainRadarData> build() async {
    _dio = Dio();
    return _fetch();
  }

  /// Re-fetches the latest radar frame.  Called on radar toggle and by the
  /// periodic refresh timer in [WeatherMapScreen].
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _fetch());
  }

  Future<RainRadarData> _fetch() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(_apiUrl);
      final data  = response.data!;
      final host  = data['host'] as String;
      final radar = data['radar'] as Map<String, dynamic>;

      final past = (radar['past'] as List? ?? [])
          .cast<Map<String, dynamic>>();

      // We only need the single most-recent past frame — the current radar
      // snapshot.  Nowcast frames are skipped since this is a static view.
      if (past.isEmpty) {
        return RainRadarData(host: host, latestFrame: null);
      }

      final latest = past.last;
      return RainRadarData(
        host: host,
        latestFrame: RainRadarFrame(
          path: latest['path'] as String,
          time: latest['time'] as int,
        ),
      );
    } catch (_) {
      return const RainRadarData(host: 'https://tilecache.rainviewer.com',
                                 latestFrame: null);
    }
  }
}

final rainRadarProvider =
    AsyncNotifierProvider<RainRadarNotifier, RainRadarData>(
  RainRadarNotifier.new,
);