import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';

import '../core/models/forecast.dart';
import '../core/providers/location_provider.dart';
import '../core/providers/settings_provider.dart';
import '../core/services/open_meteo_service.dart';
import '../core/utils/unit_converter.dart';
import '../core/utils/weather_code_utils.dart';

/// Keys shared between Dart and native widget code.
/// Must exactly match the keys read in WeatherWidgetProvider.kt / WeatherWidget.swift.
class _WidgetKeys {
  static const appGroupId       = 'group.com.zantiqlabs.omniweather';
  static const qualifiedAndroid = 'com.zantiqlabs.omniweather';

  // Current conditions
  static const locationName   = 'widget_location_name';
  static const temperature    = 'widget_temperature';
  static const conditionText  = 'widget_condition';
  static const feelsLike      = 'widget_feels_like';
  static const precipProb     = 'widget_precip_prob';
  static const windLine       = 'widget_wind';
  static const lastUpdated    = 'widget_last_updated';
  static const weatherCode    = 'widget_weather_code';

  // 3-day strip (indices 0–2)
  static String dayName(int i) => 'widget_day${i}_name';
  static String dayIcon(int i) => 'widget_day${i}_icon';
  static String dayTemp(int i) => 'widget_day${i}_temp';
}

/// Returns a single emoji character for a WMO weather code.
String _weatherEmoji(int code) {
  if (code == 0)               return '☀️';
  if (code <= 2)               return '🌤️';
  if (code == 3)               return '☁️';
  if (code <= 49)              return '🌫️'; // fog/mist
  if (code <= 57)              return '🌧️'; // drizzle
  if (code <= 67)              return '🌧️'; // rain
  if (code <= 77)              return '🌨️'; // snow
  if (code <= 82)              return '🌦️'; // showers
  if (code <= 86)              return '🌨️'; // snow showers
  return '⛈️';                              // thunderstorm
}

class WeatherWidgetService {
  WeatherWidgetService(this._logger) {
    HomeWidget.setAppGroupId(_WidgetKeys.appGroupId);
  }

  final Logger _logger;

  /// Update the home widget using the current forecast + settings.
  ///
  /// Also persists [latitude], [longitude], and the active unit names so the
  /// WorkManager background task can re-fetch fresh data without the app open.
  Future<void> updateWidget({
    required String locationName,
    required double latitude,
    required double longitude,
    required HourlyForecast currentHour,
    required AppSettings settings,
    List<DailyForecast> daily = const [],
  }) async {
    try {
      final tempValue = UnitConverter.convertTemp(
        currentHour.temperature,
        settings.temperatureUnit,
      ).round();
      final feelsValue = UnitConverter.convertTemp(
        currentHour.apparentTemperature,
        settings.temperatureUnit,
      ).round();
      final unitSymbol     = UnitConverter.tempUnitSymbol(settings.temperatureUnit);
      final conditionText  = WeatherCodeUtils.description(currentHour.weatherCode);
      final windSpeed      = UnitConverter.convertWind(
        currentHour.windSpeed, settings.windUnit,
      ).round();
      final windSym        = UnitConverter.windUnitSymbol(settings.windUnit);
      final precipStr      = '💧 ${currentHour.precipitationProbability.toStringAsFixed(0)}%';
      final windStr        = '💨 $windSpeed $windSym';

      final saves = <Future>[
        // Location + unit prefs — read by the background WorkManager task
        HomeWidget.saveWidgetData(_WidgetKeys.locationName,  locationName),
        HomeWidget.saveWidgetData('widget_latitude',          latitude.toString()),
        HomeWidget.saveWidgetData('widget_longitude',         longitude.toString()),
        HomeWidget.saveWidgetData('widget_temp_unit',         settings.temperatureUnit.name),
        HomeWidget.saveWidgetData('widget_wind_unit',         settings.windUnit.name),
        HomeWidget.saveWidgetData(_WidgetKeys.temperature,   '$tempValue$unitSymbol'),
        HomeWidget.saveWidgetData(_WidgetKeys.conditionText, conditionText),
        HomeWidget.saveWidgetData(_WidgetKeys.feelsLike,     'Feels $feelsValue$unitSymbol'),
        HomeWidget.saveWidgetData(_WidgetKeys.precipProb,    precipStr),
        HomeWidget.saveWidgetData(_WidgetKeys.windLine,      windStr),
        HomeWidget.saveWidgetData(_WidgetKeys.weatherCode,   currentHour.weatherCode.toString()),
        // Save as UTC (ends with 'Z') so the Kotlin parser can unambiguously
        // convert to local display time with SimpleDateFormat.
        HomeWidget.saveWidgetData(_WidgetKeys.lastUpdated,   DateTime.now().toUtc().toIso8601String()),
      ];

      // 3-day forecast strip — use the next 3 entries (skip today if it's past noon)
      final dayFormat = DateFormat('EEE'); // Mon, Tue …
      final now       = DateTime.now();
      final strip     = daily.isNotEmpty
          ? (daily.first.date.day == now.day && now.hour >= 12
              ? daily.skip(1).take(3).toList()
              : daily.take(3).toList())
          : <DailyForecast>[];

      for (var i = 0; i < 3; i++) {
        if (i < strip.length) {
          final d     = strip[i];
          final label = (i == 0 && d.date.day == now.day) ? 'Today'
                      : (i == 0)                          ? 'Tomorrow'
                      : dayFormat.format(d.date);
          final high  = UnitConverter.convertTemp(d.tempMax, settings.temperatureUnit).round();
          final low   = UnitConverter.convertTemp(d.tempMin, settings.temperatureUnit).round();
          saves.addAll([
            HomeWidget.saveWidgetData(_WidgetKeys.dayName(i), label),
            HomeWidget.saveWidgetData(_WidgetKeys.dayIcon(i), _weatherEmoji(d.weatherCode)),
            HomeWidget.saveWidgetData(_WidgetKeys.dayTemp(i), '$high/$low$unitSymbol'),
          ]);
        } else {
          saves.addAll([
            HomeWidget.saveWidgetData(_WidgetKeys.dayName(i), ''),
            HomeWidget.saveWidgetData(_WidgetKeys.dayIcon(i), ''),
            HomeWidget.saveWidgetData(_WidgetKeys.dayTemp(i), ''),
          ]);
        }
      }

      await Future.wait(saves);

      await HomeWidget.updateWidget(
        androidName: 'WeatherWidgetProvider',
        iOSName: 'WeatherWidget',
        qualifiedAndroidName:
            '${_WidgetKeys.qualifiedAndroid}.WeatherWidgetProvider',
      );

      _logger.d('Home widget updated: $locationName $tempValue$unitSymbol');
    } catch (e) {
      _logger.w('Home widget update failed: $e');
    }
  }
}

final weatherWidgetServiceProvider = Provider<WeatherWidgetService>((ref) {
  return WeatherWidgetService(Logger());
});

// ── Widget refresh helper ─────────────────────────────────────────────────────

/// Fetches fresh data and pushes it to the widget.
/// Silently no-ops if no location is saved.
Future<void> refreshHomeWidget(WidgetRef ref) async {
  final location = ref.read(locationProvider).activeLocation;
  if (location == null) return;

  try {
    final forecast = await ref.read(openMeteoServiceProvider).getForecast(
          lat: location.latitude,
          lon: location.longitude,
        );
    final settings = ref.read(settingsProvider);
    final current  = forecast.hourly.firstOrNull;
    if (current == null) return;

    await ref.read(weatherWidgetServiceProvider).updateWidget(
          locationName: location.name,
          latitude: location.latitude,
          longitude: location.longitude,
          currentHour: current,
          settings: settings,
          daily: forecast.daily,
        );
  } catch (_) {
    // Background refresh — swallow errors.
  }
}