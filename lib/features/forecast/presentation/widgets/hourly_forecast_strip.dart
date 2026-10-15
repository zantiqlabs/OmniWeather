import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/forecast.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/utils/unit_converter.dart';
import '../../../../core/utils/weather_code_utils.dart';

// ── Public widget ─────────────────────────────────────────────────────────────

class HourlyForecastStrip extends StatefulWidget {
  const HourlyForecastStrip({
    super.key,
    required this.hourly,
    required this.settings,
    this.daily = const [],
  });

  final List<HourlyForecast> hourly;
  final AppSettings          settings;

  /// Daily forecasts — used to look up sunrise/sunset for night-aware icons.
  final List<DailyForecast>  daily;

  @override
  State<HourlyForecastStrip> createState() => _HourlyForecastStripState();
}

class _HourlyForecastStripState extends State<HourlyForecastStrip> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Scrollable tile row ──────────────────────────────────────────────
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: widget.hourly.length,
            separatorBuilder: (_, __) => const SizedBox(width: 4),
            itemBuilder: (context, i) {
              final h   = widget.hourly[i];
              final day = _dailyFor(h.time);
              return _HourTile(
                hour:       h,
                day:        day,
                settings:   widget.settings,
                isSelected: _selectedIndex == i,
                onTap: () => setState(() {
                  _selectedIndex = (_selectedIndex == i) ? null : i;
                }),
              );
            },
          ),
        ),

        // ── Expandable detail panel ──────────────────────────────────────────
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: _selectedIndex != null
              ? _HourDetailPanel(
                  hour:     widget.hourly[_selectedIndex!],
                  day:      _dailyFor(widget.hourly[_selectedIndex!].time),
                  settings: widget.settings,
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  DailyForecast? _dailyFor(DateTime time) {
    for (final d in widget.daily) {
      if (d.date.year  == time.year  &&
          d.date.month == time.month &&
          d.date.day   == time.day) {
        return d;
      }
    }
    return null;
  }
}

// ── Individual tile ───────────────────────────────────────────────────────────

class _HourTile extends StatelessWidget {
  const _HourTile({
    required this.hour,
    required this.day,
    required this.settings,
    required this.isSelected,
    required this.onTap,
  });

  final HourlyForecast  hour;
  final DailyForecast?  day;
  final AppSettings     settings;
  final bool            isSelected;
  final VoidCallback    onTap;

  @override
  Widget build(BuildContext context) {
    final theme     = Theme.of(context);
    final timeLabel = DateFormat('HH:mm').format(hour.time);
    final temp      = UnitConverter.convertTemp(
      hour.temperature, settings.temperatureUnit,
    ).toStringAsFixed(0);
    final symbol    = UnitConverter.tempUnitSymbol(settings.temperatureUnit);

    final IconData iconDat;
    final Color    iconCol;
    if (day != null) {
      iconDat = WeatherCodeUtils.iconForHour(
          hour.weatherCode, hour.time, day!.sunrise, day!.sunset);
      iconCol = WeatherCodeUtils.colorForHour(
          hour.weatherCode, hour.time, day!.sunrise, day!.sunset);
    } else {
      iconDat = WeatherCodeUtils.icon(hour.weatherCode);
      iconCol = WeatherCodeUtils.color(hour.weatherCode);
    }

    final bg = isSelected
        ? theme.colorScheme.primaryContainer.withOpacity(0.6)
        : theme.colorScheme.surfaceVariant.withOpacity(0.5);
    final border = isSelected
        ? Border.all(color: theme.colorScheme.primary.withOpacity(0.7), width: 1.5)
        : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: border,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(timeLabel, style: theme.textTheme.bodySmall),
            Icon(iconDat, size: 22, color: iconCol),
            Text(
              '$temp$symbol',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (hour.precipitationProbability > 20)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.water_drop, size: 10,
                      color: theme.colorScheme.primary),
                  Text(
                    '${hour.precipitationProbability.toStringAsFixed(0)}%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            // Down-chevron hint when selected
            if (isSelected)
              Icon(Icons.expand_less, size: 12,
                  color: theme.colorScheme.primary.withOpacity(0.7))
            else
              Icon(Icons.expand_more, size: 12,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3)),
          ],
        ),
      ),
    );
  }
}

// ── Detail panel ──────────────────────────────────────────────────────────────

class _HourDetailPanel extends StatelessWidget {
  const _HourDetailPanel({
    required this.hour,
    required this.day,
    required this.settings,
  });

  final HourlyForecast hour;
  final DailyForecast? day;
  final AppSettings    settings;

  @override
  Widget build(BuildContext context) {
    final theme   = Theme.of(context);
    final cs      = theme.colorScheme;
    final timeStr = DateFormat('HH:mm · EEEE d MMM').format(hour.time);

    // Formatted values
    final temp      = _tempStr(hour.temperature);
    final feelsLike = _tempStr(hour.apparentTemperature);
    final windSpd   = UnitConverter.convertWind(
        hour.windSpeed, settings.windUnit).round();
    final windGust  = UnitConverter.convertWind(
        hour.windGusts, settings.windUnit).round();
    final windSym   = UnitConverter.windUnitSymbol(settings.windUnit);
    final compass   = UnitConverter.degreesToCompass(hour.windDirection);
    final precip    = UnitConverter.convertPrecip(
        hour.precipitation, settings.precipUnit);
    final precipSym = UnitConverter.precipUnitSymbol(settings.precipUnit);
    final visKm     = (hour.visibility / 1000).toStringAsFixed(1);

    // Night-aware icon
    final IconData iconDat;
    final Color    iconCol;
    if (day != null) {
      iconDat = WeatherCodeUtils.iconForHour(
          hour.weatherCode, hour.time, day!.sunrise, day!.sunset);
      iconCol = WeatherCodeUtils.colorForHour(
          hour.weatherCode, hour.time, day!.sunrise, day!.sunset);
    } else {
      iconDat = WeatherCodeUtils.icon(hour.weatherCode);
      iconCol = WeatherCodeUtils.color(hour.weatherCode);
    }

    return Container(
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: cs.primary.withOpacity(0.25),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: time + condition icon + description
          Row(
            children: [
              Icon(iconDat, size: 20, color: iconCol),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${WeatherCodeUtils.description(hour.weatherCode)}  ·  $timeStr',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Detail grid — 2 columns
          _DetailGrid(rows: [
            _DetailRow(
              left:  _DetailItem(
                icon: Icons.thermostat,
                label: 'Temperature',
                value: temp,
              ),
              right: _DetailItem(
                icon: Icons.device_thermostat,
                label: 'Feels like',
                value: feelsLike,
              ),
            ),
            _DetailRow(
              left:  _DetailItem(
                icon: Icons.water_drop,
                label: 'Precip chance',
                value: '${hour.precipitationProbability.toStringAsFixed(0)}%',
                valueColor: hour.precipitationProbability > 50
                    ? cs.primary : null,
              ),
              right: _DetailItem(
                icon: Icons.umbrella,
                label: 'Precipitation',
                value: precip < 0.05
                    ? 'None'
                    : '${precip.toStringAsFixed(1)} $precipSym',
              ),
            ),
            _DetailRow(
              left:  _DetailItem(
                icon: Icons.air,
                label: 'Wind ($compass)',
                value: '$windSpd $windSym',
              ),
              right: _DetailItem(
                icon: Icons.wind_power,
                label: 'Gusts',
                value: '$windGust $windSym',
              ),
            ),
            _DetailRow(
              left:  _DetailItem(
                icon: Icons.water,
                label: 'Humidity',
                value: '${hour.relativeHumidity.toStringAsFixed(0)}%',
              ),
              right: _DetailItem(
                icon: Icons.cloud,
                label: 'Cloud cover',
                value: '${hour.cloudCover.toStringAsFixed(0)}%',
              ),
            ),
            _DetailRow(
              left:  _DetailItem(
                icon: Icons.visibility,
                label: 'Visibility',
                value: '$visKm km',
              ),
              right: _DetailItem(
                icon: Icons.wb_sunny_outlined,
                label: 'UV Index',
                value: '${hour.uvIndex.toStringAsFixed(0)}  ${_uvLabel(hour.uvIndex)}',
                valueColor: _uvColor(hour.uvIndex, cs),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  String _tempStr(double celsius) {
    final v = UnitConverter.convertTemp(celsius, settings.temperatureUnit)
        .toStringAsFixed(0);
    return '$v${UnitConverter.tempUnitSymbol(settings.temperatureUnit)}';
  }

  static String _uvLabel(double uv) {
    if (uv < 3)  return 'Low';
    if (uv < 6)  return 'Moderate';
    if (uv < 8)  return 'High';
    if (uv < 11) return 'Very High';
    return 'Extreme';
  }

  static Color? _uvColor(double uv, ColorScheme cs) {
    if (uv < 3)  return null;
    if (uv < 6)  return const Color(0xFFF9A825); // amber
    if (uv < 8)  return const Color(0xFFE65100); // deep orange
    return cs.error;
  }
}

// ── Layout helpers ────────────────────────────────────────────────────────────

class _DetailItem {
  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });
  final IconData icon;
  final String   label;
  final String   value;
  final Color?   valueColor;
}

class _DetailRow {
  const _DetailRow({required this.left, required this.right});
  final _DetailItem left;
  final _DetailItem right;
}

class _DetailGrid extends StatelessWidget {
  const _DetailGrid({required this.rows});
  final List<_DetailRow> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: rows.map((row) => _buildRow(context, row)).toList(),
    );
  }

  Widget _buildRow(BuildContext context, _DetailRow row) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: _buildCell(context, row.left)),
          const SizedBox(width: 8),
          Expanded(child: _buildCell(context, row.right)),
        ],
      ),
    );
  }

  Widget _buildCell(BuildContext context, _DetailItem item) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(item.icon, size: 14, color: cs.onSurfaceVariant.withOpacity(0.7)),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  color: cs.onSurfaceVariant.withOpacity(0.65),
                ),
              ),
              Text(
                item.value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: item.valueColor ?? cs.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}