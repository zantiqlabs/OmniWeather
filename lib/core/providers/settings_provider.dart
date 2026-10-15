import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

/// Persisted user preferences (units, theme).
class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() => const AppSettings();

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    state = AppSettings(
      temperatureUnit: TemperatureUnit.values.firstWhere(
        (e) => e.name == prefs.getString(AppConstants.keyTemperatureUnit),
        orElse: () => AppConstants.defaultTempUnit,
      ),
      windUnit: WindUnit.values.firstWhere(
        (e) => e.name == prefs.getString(AppConstants.keyWindUnit),
        orElse: () => AppConstants.defaultWindUnit,
      ),
      precipUnit: PrecipUnit.values.firstWhere(
        (e) => e.name == prefs.getString(AppConstants.keyPrecipUnit),
        orElse: () => AppConstants.defaultPrecipUnit,
      ),
      themeMode: _themeModeFromString(
        prefs.getString(AppConstants.keyThemeMode),
      ),
      forecastInterval: _validInterval(
        prefs.getInt(AppConstants.keyForecastInterval),
      ),
      showLightning: prefs.getBool(AppConstants.keyShowLightning) ?? false,
    );
  }

  Future<void> setTemperatureUnit(TemperatureUnit unit) async {
    state = state.copyWith(temperatureUnit: unit);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyTemperatureUnit, unit.name);
  }

  Future<void> setWindUnit(WindUnit unit) async {
    state = state.copyWith(windUnit: unit);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyWindUnit, unit.name);
  }

  Future<void> setPrecipUnit(PrecipUnit unit) async {
    state = state.copyWith(precipUnit: unit);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyPrecipUnit, unit.name);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyThemeMode, mode.name);
  }

  Future<void> setForecastInterval(int hours) async {
    state = state.copyWith(forecastInterval: hours);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.keyForecastInterval, hours);
  }

  Future<void> setShowLightning(bool show) async {
    state = state.copyWith(showLightning: show);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyShowLightning, show);
  }

  static ThemeMode _themeModeFromString(String? s) => ThemeMode.values
      .firstWhere((e) => e.name == s, orElse: () => ThemeMode.system);

  static const _validIntervals = [1, 2, 3, 4, 6, 8, 12];
  static int _validInterval(int? v) =>
      (_validIntervals.contains(v)) ? v! : AppConstants.defaultForecastInterval;
}

class AppSettings {
  const AppSettings({
    this.temperatureUnit   = AppConstants.defaultTempUnit,
    this.windUnit          = AppConstants.defaultWindUnit,
    this.precipUnit        = AppConstants.defaultPrecipUnit,
    this.themeMode         = ThemeMode.system,
    this.forecastInterval  = AppConstants.defaultForecastInterval,
    this.showLightning     = false,
  });

  final TemperatureUnit temperatureUnit;
  final WindUnit        windUnit;
  final PrecipUnit      precipUnit;
  final ThemeMode       themeMode;
  /// Hours between hourly slots in the expanded daily forecast detail.
  final int             forecastInterval;
  /// Whether the Lightning tab and Xweather credentials are shown.
  final bool            showLightning;

  AppSettings copyWith({
    TemperatureUnit? temperatureUnit,
    WindUnit?        windUnit,
    PrecipUnit?      precipUnit,
    ThemeMode?       themeMode,
    int?             forecastInterval,
    bool?            showLightning,
  }) => AppSettings(
    temperatureUnit:  temperatureUnit  ?? this.temperatureUnit,
    windUnit:         windUnit         ?? this.windUnit,
    precipUnit:       precipUnit       ?? this.precipUnit,
    themeMode:        themeMode        ?? this.themeMode,
    forecastInterval: forecastInterval ?? this.forecastInterval,
    showLightning:    showLightning    ?? this.showLightning,
  );
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);
