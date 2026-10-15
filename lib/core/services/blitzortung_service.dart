import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/lightning.dart';

/// Real-time lightning data from Blitzortung.org.
///
/// Free, no credentials required. Subscribes to the global feed and filters
/// strikes to within [radiusKm] of the requested location client-side.
class BlitzortungService {
  BlitzortungService(this._logger);

  final Logger _logger;

  // ws8 first — confirmed active in testing; ws1/ws7 as fallbacks.
  static const _servers = [
    'wss://ws8.blitzortung.org',
    'wss://ws1.blitzortung.org',
    'wss://ws7.blitzortung.org',
  ];

  int _serverIndex = 0;
  WebSocketChannel? _channel;

  // ── Public API ──────────────────────────────────────────────────────────────

  Stream<LightningStrike> connect({
    required double lat,
    required double lon,
    double radiusKm = 100.0,
  }) async* {
    disconnect();

    final url = _servers[_serverIndex % _servers.length];
    _logger.d('Blitzortung: connecting to $url');

    try {
      // IOWebSocketChannel lets us set HTTP headers on the WS upgrade request.
      // Blitzortung servers validate Origin — must match maps.blitzortung.org,
      // which is the page that actually hosts the live map and runs the JS client.
      // Without a matching Origin the handshake succeeds but the server streams nothing.
      _channel = IOWebSocketChannel.connect(
        Uri.parse(url),
        headers: {
          'Origin':  'https://maps.blitzortung.org',
          'Referer': 'https://maps.blitzortung.org/',
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 '
              '(KHTML, like Gecko) Chrome/120.0 Mobile Safari/537.36',
        },
      );

      // Wait for the TCP + WebSocket handshake to complete.
      await _channel!.ready;
      _logger.d('Blitzortung: handshake complete, sending subscription');

      // Subscribe to the global feed — filter to radius client-side.
      _channel!.sink.add(jsonEncode({
        'west':  -180.0,
        'east':   180.0,
        'north':   90.0,
        'south':  -90.0,
      }));

      _logger.d('Blitzortung: subscription sent — waiting for strikes');

      var msgCount    = 0;
      var totalFrames = 0;

      // If the server is connected but sends nothing after 15 s, warn in the
      // log. This distinguishes "silent rejection" from "no strikes nearby".
      final noDataTimer = Timer(const Duration(seconds: 15), () {
        if (totalFrames == 0) {
          _logger.w(
            'Blitzortung: 15 s with zero frames received. '
            'Server is connected but silent — Origin header may still be wrong.',
          );
        }
      });

      try {
        await for (final message in _channel!.stream) {
          totalFrames++;

          // Blitzortung sends text frames, but some servers send binary (UTF-8).
          String text;
          if (message is String) {
            text = message;
          } else if (message is List<int>) {
            try {
              text = utf8.decode(message);
            } catch (_) {
              continue;
            }
          } else {
            continue;
          }
          if (text.isEmpty) continue;

          // Log the first few raw messages so we can verify the format.
          if (msgCount < 5) {
            _logger.d(
              'Blitzortung raw[$msgCount]: '
              '${text.length > 140 ? '${text.substring(0, 140)}…' : text}',
            );
            msgCount++;
          }

          final strike = _parseMessage(text, lat, lon, radiusKm);
          if (strike != null) yield strike;
        }
      } finally {
        noDataTimer.cancel();
      }

      _logger.d(
        'Blitzortung: stream ended cleanly '
        '(total frames received: $totalFrames)',
      );
    } on WebSocketChannelException catch (e) {
      _logger.w('Blitzortung WebSocket error on $url: $e');
      _serverIndex++;
      rethrow;
    } catch (e) {
      _logger.w('Blitzortung error on $url: $e');
      _serverIndex++;
      rethrow;
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }

  // ── Parsing ─────────────────────────────────────────────────────────────────

  LightningStrike? _parseMessage(
    String raw,
    double centerLat,
    double centerLon,
    double radiusKm,
  ) {
    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return null;

      final latRaw  = json['lat'];
      final lonRaw  = json['lon'];
      final timeRaw = json['time'];
      if (latRaw == null || lonRaw == null || timeRaw == null) return null;

      final strikeLat = (latRaw  as num).toDouble();
      final strikeLon = (lonRaw  as num).toDouble();

      // Blitzortung timestamps are nanoseconds since Unix epoch.
      final timeNs    = (timeRaw as num).toInt();
      final timestamp = DateTime.fromMillisecondsSinceEpoch(timeNs ~/ 1000000);

      // Reject stale data that sometimes arrives on reconnect.
      if (DateTime.now().difference(timestamp).inHours > 2) return null;

      final distKm = _haversineKm(centerLat, centerLon, strikeLat, strikeLon);

      // Filter to the requested radius.
      if (distKm > radiusKm) return null;

      // pol: 0 = negative CG, 1 = positive CG; other values = intra-cloud.
      final pol  = json['pol'] as int? ?? 0;
      final type = (pol == 0 || pol == 1)
          ? LightningType.cloudToGround
          : LightningType.cloudToCloud;

      return LightningStrike(
        id: '${timeNs}_${strikeLat}_$strikeLon',
        timestamp: timestamp,
        latitude: strikeLat,
        longitude: strikeLon,
        type: type,
        peakCurrent: 0,
        strokeCount: 1,
        distanceKm: distKm,
      );
    } catch (e) {
      _logger.w(
        'Blitzortung parse error: $e  '
        'raw="${raw.length > 80 ? raw.substring(0, 80) : raw}"',
      );
      return null;
    }
  }

  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }
}

// ── Provider ─────────────────────────────────────────────────────────────────

final blitzortungServiceProvider = Provider<BlitzortungService>((ref) {
  final service = BlitzortungService(Logger());
  ref.onDispose(service.disconnect);
  return service;
});