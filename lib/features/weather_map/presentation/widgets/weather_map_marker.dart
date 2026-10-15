import 'package:flutter/material.dart';

import '../../../../core/providers/settings_provider.dart';
import '../../../../core/utils/unit_converter.dart';
import '../../../../core/utils/weather_code_utils.dart';
import '../../providers/map_weather_provider.dart';

/// TV-style weather pin shown on the map.
///
/// Layout:
///   ┌──────────────────┐
///   │  ☁  14°          │  ← pill: icon + temperature
///   └────────┬─────────┘
///            │           ← tiny pointer
///        City Name       ← label below
class WeatherMapMarker extends StatelessWidget {
  const WeatherMapMarker({
    super.key,
    required this.data,
    required this.settings,
    this.onTap,
  });

  final MapWeatherData data;
  final AppSettings    settings;
  /// Called when the user taps the marker.  Null = not interactive.
  final VoidCallback?  onTap;

  @override
  Widget build(BuildContext context) {
    final temp    = UnitConverter.convertTemp(data.temperature, settings.temperatureUnit);
    final symbol  = UnitConverter.tempUnitSymbol(settings.temperatureUnit);
    final iconDat = WeatherCodeUtils.icon(data.weatherCode);
    final iconCol = WeatherCodeUtils.color(data.weatherCode);

    // Contrast-aware colours so the pill reads on both light and dark maps.
    const pillBg    = Color(0xF0FFFFFF);
    const pillText  = Color(0xFF1A1A2E);
    const shadow    = Color(0x33000000);

    return GestureDetector(
      onTap: onTap,
      child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Pill ──────────────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: pillBg,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(color: shadow, blurRadius: 4, offset: Offset(0, 2)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(iconDat, size: 16, color: iconCol),
              const SizedBox(width: 4),
              Text(
                '${temp.round()}$symbol',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: pillText,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),

        // ── Pointer ───────────────────────────────────────────────────────────
        CustomPaint(
          size: const Size(10, 5),
          painter: _PointerPainter(pillBg),
        ),

        // ── City label ────────────────────────────────────────────────────────
        Container(
          constraints: const BoxConstraints(maxWidth: 80),
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
          decoration: BoxDecoration(
            color: const Color(0xCC000000),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            data.cityName,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9,
              color: Colors.white,
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
          ),
        ),
      ],
    ), // Column
    ); // GestureDetector
  }
}

// ── Downward-pointing triangle ─────────────────────────────────────────────────

class _PointerPainter extends CustomPainter {
  const _PointerPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path  = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_PointerPainter old) => old.color != color;
}
