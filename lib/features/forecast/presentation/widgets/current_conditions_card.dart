import 'package:flutter/material.dart';

import '../../../../core/models/forecast.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/utils/unit_converter.dart';
import '../../../../core/utils/weather_code_utils.dart';

class CurrentConditionsCard extends StatelessWidget {
  const CurrentConditionsCard({
    super.key,
    required this.hourly,
    required this.settings,
    this.todayForecast,
  });

  final HourlyForecast  hourly;
  final AppSettings     settings;
  /// Today's daily forecast — used to determine sunrise/sunset for night icons.
  final DailyForecast?  todayForecast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tempStr = UnitConverter.convertTemp(
      hourly.temperature,
      settings.temperatureUnit,
    ).toStringAsFixed(0);
    final feelsStr = UnitConverter.convertTemp(
      hourly.apparentTemperature,
      settings.temperatureUnit,
    ).toStringAsFixed(0);
    final unitSymbol = UnitConverter.tempUnitSymbol(settings.temperatureUnit);
    final windStr = UnitConverter.convertWind(
      hourly.windSpeed,
      settings.windUnit,
    ).toStringAsFixed(0);
    final windUnit   = UnitConverter.windUnitSymbol(settings.windUnit);
    final compassDir = UnitConverter.degreesToCompass(hourly.windDirection);

    // Night-aware icon: use moon phase if we have sunrise/sunset for today.
    final IconData conditionIcon;
    final Color    conditionColor;
    final today = todayForecast;
    if (today != null) {
      conditionIcon  = WeatherCodeUtils.iconForHour(
          hourly.weatherCode, hourly.time, today.sunrise, today.sunset);
      conditionColor = WeatherCodeUtils.colorForHour(
          hourly.weatherCode, hourly.time, today.sunrise, today.sunset);
    } else {
      conditionIcon  = WeatherCodeUtils.icon(hourly.weatherCode);
      conditionColor = WeatherCodeUtils.color(hourly.weatherCode);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Main temp + condition ────────────────────────────────────────
            Row(
              children: [
                Icon(
                  conditionIcon,
                  size: 48,
                  color: conditionColor,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$tempStr$unitSymbol',
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        today != null &&
                                WeatherCodeUtils.isNight(hourly.time,
                                    today.sunrise, today.sunset) &&
                                (hourly.weatherCode == 0 ||
                                    hourly.weatherCode == 1 ||
                                    hourly.weatherCode == 2)
                            ? '${WeatherCodeUtils.description(hourly.weatherCode)}'
                              ' · ${WeatherCodeUtils.moonPhaseLabel(hourly.time)}'
                            : WeatherCodeUtils.description(hourly.weatherCode),
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        'Feels like $feelsStr$unitSymbol',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            // ── Detail grid — each item gets equal width via Expanded ────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailItem(
                  icon: Icons.water_drop_outlined,
                  label: 'Humidity',
                  value: '${hourly.relativeHumidity.toStringAsFixed(0)}%',
                ),
                _DetailItem(
                  icon: Icons.water_drop,
                  label: 'Precip.',
                  value:
                      '${hourly.precipitationProbability.toStringAsFixed(0)}%',
                ),
                _DetailItem(
                  icon: Icons.air,
                  label: 'Wind',
                  value: '$windStr $windUnit',
                  sub: compassDir,
                ),
                _DetailItem(
                  icon: Icons.wb_sunny_outlined,
                  label: 'UV Index',
                  value: _uvLabel(hourly.uvIndex),
                  sub: hourly.uvIndex.toStringAsFixed(1),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _uvLabel(double uv) {
    if (uv < 3) return 'Low';
    if (uv < 6) return 'Moderate';
    if (uv < 8) return 'High';
    if (uv < 11) return 'Very High';
    return 'Extreme';
  }
}

class _DetailItem extends StatelessWidget {
  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
    this.sub,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodyMedium,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            maxLines: 1,
          ),
          if (sub != null)
            Text(
              sub!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
