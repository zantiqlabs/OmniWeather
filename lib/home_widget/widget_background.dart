import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';

// ── Background widget update ──────────────────────────────────────────────────
//
// This function runs in a background Dart isolate, triggered by WorkManager
// via HomeWidgetBackgroundIntent. The full Flutter app is NOT running, so
// Riverpod providers are not available — we call Open-Meteo directly using
// dart:io's HttpClient (no extra packages needed).
//
// Location (lat/lon) and unit preferences are read from home_widget's shared
// preferences, where the foreground app saves them on every normal update.

@pragma('vm:entry-point')
Future<void> backgroundWidgetUpdate(Uri? uri) async {
  WidgetsFlutterBinding.ensureInitialized();
  await HomeWidget.setAppGroupId('group.com.zantiqlabs.omniweather');

  // Skip the network call if data is already fresh (updated within 20 minutes).
  // This avoids a redundant fetch when the user has recently opened the app.
  final lastUpdated = await HomeWidget.getWidgetData<String>('widget_last_updated');
  if (lastUpdated != null) {
    final last = DateTime.tryParse(lastUpdated);
    if (last != null && DateTime.now().toUtc().difference(last).inMinutes < 20) return;
  }

  // Read location saved by the foreground app
  final latStr  = await HomeWidget.getWidgetData<String>('widget_latitude');
  final lonStr  = await HomeWidget.getWidgetData<String>('widget_longitude');
  final locName = await HomeWidget.getWidgetData<String>('widget_location_name') ?? '—';
  if (latStr == null || lonStr == null) return;

  final lat = double.tryParse(latStr);
  final lon = double.tryParse(lonStr);
  if (lat == null || lon == null) return;

  // Read unit preferences (saved as widget data by foreground app)
  final tempUnitName = await HomeWidget.getWidgetData<String>('widget_temp_unit') ?? 'celsius';
  final windUnitName = await HomeWidget.getWidgetData<String>('widget_wind_unit') ?? 'kmh';

  try {
    // ── Fetch from Open-Meteo (no API key required) ───────────────────────
    final url = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=$lat&longitude=$lon'
      '&current=temperature_2m,apparent_temperature,'
      'precipitation_probability,wind_speed_10m,weather_code'
      '&daily=temperature_2m_max,temperature_2m_min,weather_code'
      '&forecast_days=4&timezone=auto',
    );

    final client   = HttpClient();
    final request  = await client.getUrl(url);
    final response = await request.close();
    if (response.statusCode != 200) { client.close(); return; }
    final body = await response.transform(utf8.decoder).join();
    client.close();

    final json    = jsonDecode(body) as Map<String, dynamic>;
    final current = json['current']  as Map<String, dynamic>;
    final daily   = json['daily']    as Map<String, dynamic>;

    // ── Unit conversion (mirrors UnitConverter in the main app) ───────────
    double tempC  = (current['temperature_2m']       as num).toDouble();
    double feelsC = (current['apparent_temperature'] as num).toDouble();
    final String tempSym;
    if (tempUnitName == 'fahrenheit') {
      tempC  = tempC  * 9 / 5 + 32;
      feelsC = feelsC * 9 / 5 + 32;
      tempSym = '°F';
    } else {
      tempSym = '°C';
    }

    double wind = (current['wind_speed_10m'] as num).toDouble(); // km/h from API
    final String windSym;
    switch (windUnitName) {
      case 'mph':
        wind    = wind * 0.621371;
        windSym = 'mph';
      case 'ms':
        wind    = wind / 3.6;
        windSym = 'm/s';
      default:
        windSym = 'km/h';
    }

    final weatherCode = (current['weather_code']             as num).toInt();
    final precip      = (current['precipitation_probability'] as num).toInt();

    // ── Build widget data saves ────────────────────────────────────────────
    final saves = <Future<bool?>>[
      HomeWidget.saveWidgetData('widget_location_name', locName),
      HomeWidget.saveWidgetData('widget_temperature',  '${tempC.round()}$tempSym'),
      HomeWidget.saveWidgetData('widget_condition',    _wmoDescription(weatherCode)),
      HomeWidget.saveWidgetData('widget_feels_like',   'Feels ${feelsC.round()}$tempSym'),
      HomeWidget.saveWidgetData('widget_precip_prob',  '💧 $precip%'),
      HomeWidget.saveWidgetData('widget_wind',         '💨 ${wind.round()} $windSym'),
      HomeWidget.saveWidgetData(
        'widget_last_updated',
        DateTime.now().toUtc().toIso8601String(),
      ),
    ];

    // ── 3-day forecast strip ───────────────────────────────────────────────
    final dates    = (daily['time']                as List).cast<String>();
    final maxTemps = (daily['temperature_2m_max']  as List).cast<num>();
    final minTemps = (daily['temperature_2m_min']  as List).cast<num>();
    final codes    = (daily['weather_code']         as List).cast<num>();

    final now        = DateTime.now();
    final dayLabels  = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    // Skip today's slot if past noon (mirrors WeatherWidgetService logic)
    final bool skipToday = dates.isNotEmpty &&
        DateTime.parse(dates[0]).day == now.day &&
        now.hour >= 12;
    final stripStart = skipToday ? 1 : 0;

    for (var i = 0; i < 3; i++) {
      final idx = stripStart + i;
      if (idx < dates.length) {
        final date  = DateTime.parse(dates[idx]);
        final label = (date.day == now.day)            ? 'Today'
                    : (date.day == now.add(const Duration(days: 1)).day) ? 'Tomorrow'
                    : dayLabels[date.weekday - 1];
        double hi = maxTemps[idx].toDouble();
        double lo = minTemps[idx].toDouble();
        if (tempUnitName == 'fahrenheit') {
          hi = hi * 9 / 5 + 32;
          lo = lo * 9 / 5 + 32;
        }
        saves.addAll([
          HomeWidget.saveWidgetData('widget_day${i}_name', label),
          HomeWidget.saveWidgetData('widget_day${i}_icon', _weatherEmoji(codes[idx].toInt())),
          HomeWidget.saveWidgetData('widget_day${i}_temp', '${hi.round()}/${lo.round()}$tempSym'),
        ]);
      } else {
        saves.addAll([
          HomeWidget.saveWidgetData('widget_day${i}_name', ''),
          HomeWidget.saveWidgetData('widget_day${i}_icon', ''),
          HomeWidget.saveWidgetData('widget_day${i}_temp', ''),
        ]);
      }
    }

    await Future.wait(saves);

    await HomeWidget.updateWidget(
      androidName: 'WeatherWidgetProvider',
      qualifiedAndroidName: 'com.zantiqlabs.omniweather.WeatherWidgetProvider',
    );
  } catch (_) {
    // Background task — swallow errors silently.
  }
}

// ── Helpers (mirrors WeatherWidgetService + WeatherCodeUtils) ─────────────────

String _wmoDescription(int code) {
  if (code == 0)  return 'Clear sky';
  if (code <= 2)  return 'Partly cloudy';
  if (code == 3)  return 'Overcast';
  if (code <= 49) return 'Foggy';
  if (code <= 57) return 'Drizzle';
  if (code <= 67) return 'Rain';
  if (code <= 77) return 'Snow';
  if (code <= 82) return 'Showers';
  if (code <= 86) return 'Snow showers';
  return 'Thunderstorm';
}

String _weatherEmoji(int code) {
  if (code == 0)  return '☀️';
  if (code <= 2)  return '🌤️';
  if (code == 3)  return '☁️';
  if (code <= 49) return '🌫️';
  if (code <= 67) return '🌧️';
  if (code <= 77) return '🌨️';
  if (code <= 82) return '🌦️';
  if (code <= 86) return '🌨️';
  return '⛈️';
}