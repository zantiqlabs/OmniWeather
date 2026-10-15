import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/forecast.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/utils/unit_converter.dart';
import '../../../../core/utils/weather_code_utils.dart';

class DailyForecastCard extends StatefulWidget {
  const DailyForecastCard({
    super.key,
    required this.day,
    required this.settings,
    required this.hourlySlots,
  });

  final DailyForecast        day;
  final AppSettings          settings;
  /// Up to 5 hourly points for this day (04:00, 08:00, 12:00, 16:00, 20:00).
  final List<HourlyForecast> hourlySlots;

  @override
  State<DailyForecastCard> createState() => _DailyForecastCardState();
}

class _DailyForecastCardState extends State<DailyForecastCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme      = Theme.of(context);
    final dateFormat = DateFormat('EEE d MMM');
    final symbol     = UnitConverter.tempUnitSymbol(widget.settings.temperatureUnit);
    final maxTemp    = UnitConverter.convertTemp(
        widget.day.tempMax, widget.settings.temperatureUnit)
        .toStringAsFixed(0);
    final minTemp    = UnitConverter.convertTemp(
        widget.day.tempMin, widget.settings.temperatureUnit)
        .toStringAsFixed(0);

    final canExpand = widget.hourlySlots.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: canExpand
            ? () => setState(() => _expanded = !_expanded)
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Summary row ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Date
                  SizedBox(
                    width: 88,
                    child: Text(
                      dateFormat.format(widget.day.date),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  // Weather icon
                  Icon(
                    WeatherCodeUtils.icon(widget.day.weatherCode),
                    color: WeatherCodeUtils.color(widget.day.weatherCode),
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  // Description
                  Expanded(
                    child: Text(
                      WeatherCodeUtils.description(widget.day.weatherCode),
                      style: theme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Precipitation sum
                  if (widget.day.precipitationSum > 0.1) ...[
                    Icon(
                      Icons.water_drop,
                      size: 13,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${UnitConverter.convertPrecip(widget.day.precipitationSum, widget.settings.precipUnit).toStringAsFixed(1)}'
                      '${UnitConverter.precipUnitSymbol(widget.settings.precipUnit)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  // Min / Max
                  Text(
                    '$minTemp$symbol',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '/',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '$maxTemp$symbol',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Expand chevron
                  if (canExpand) ...[
                    const SizedBox(width: 6),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ── Expanded detail ──────────────────────────────────────────────
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: _expanded
                  ? _ExpandedDetail(
                      day: widget.day,
                      slots: widget.hourlySlots,
                      settings: widget.settings,
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Expanded content ──────────────────────────────────────────────────────────

class _ExpandedDetail extends StatelessWidget {
  const _ExpandedDetail({
    required this.day,
    required this.slots,
    required this.settings,
  });

  final DailyForecast        day;
  final List<HourlyForecast> slots;
  final AppSettings          settings;

  @override
  Widget build(BuildContext context) {
    final theme     = Theme.of(context);
    final divColor  = theme.dividerColor;
    final timeFormat = DateFormat('HH:mm');
    final sunFormat  = DateFormat('HH:mm');

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
        border: Border(
          top: BorderSide(color: divColor, width: 0.5),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Hourly slots ──────────────────────────────────────────────
          ...slots.map((h) => _HourSlotRow(
                hour:    timeFormat.format(h.time),
                hourly:  h,
                settings: settings,
                sunrise: day.sunrise,
                sunset:  day.sunset,
              )),

          // ── Sunrise / sunset ──────────────────────────────────────────
          const SizedBox(height: 8),
          Divider(color: divColor, height: 1),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.wb_sunny,
                  size: 15, color: Colors.orange.shade400),
              const SizedBox(width: 4),
              Text(
                sunFormat.format(day.sunrise),
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(width: 20),
              Icon(Icons.nights_stay,
                  size: 15, color: Colors.indigo.shade300),
              const SizedBox(width: 4),
              Text(
                sunFormat.format(day.sunset),
                style: theme.textTheme.bodySmall,
              ),
              const Spacer(),
              // UV max
              Icon(Icons.wb_sunny_outlined,
                  size: 13, color: theme.colorScheme.primary),
              const SizedBox(width: 4),
              Text(
                'UV ${day.uvIndexMax.toStringAsFixed(1)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HourSlotRow extends StatelessWidget {
  const _HourSlotRow({
    required this.hour,
    required this.hourly,
    required this.settings,
    required this.sunrise,
    required this.sunset,
  });

  final String         hour;
  final HourlyForecast hourly;
  final AppSettings    settings;
  final DateTime       sunrise;
  final DateTime       sunset;

  @override
  Widget build(BuildContext context) {
    final theme   = Theme.of(context);
    final symbol  = UnitConverter.tempUnitSymbol(settings.temperatureUnit);
    final temp    = UnitConverter.convertTemp(
        hourly.temperature, settings.temperatureUnit)
        .toStringAsFixed(0);
    final wind    = UnitConverter.convertWind(
        hourly.windSpeed, settings.windUnit)
        .toStringAsFixed(0);
    final windUnit = UnitConverter.windUnitSymbol(settings.windUnit);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          // Time
          SizedBox(
            width: 46,
            child: Text(
              hour,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Icon — night-aware
          Icon(
            WeatherCodeUtils.iconForHour(
                hourly.weatherCode, hourly.time, sunrise, sunset),
            size: 18,
            color: WeatherCodeUtils.colorForHour(
                hourly.weatherCode, hourly.time, sunrise, sunset),
          ),
          const SizedBox(width: 8),
          // Description
          Expanded(
            child: Text(
              WeatherCodeUtils.description(hourly.weatherCode),
              style: theme.textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Temperature
          Text(
            '$temp$symbol',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(width: 8),
          // Precipitation probability — fixed width keeps all rows grid-aligned.
          SizedBox(
            width: 52,
            child: hourly.precipitationProbability >= 10
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.water_drop,
                          size: 11, color: theme.colorScheme.primary),
                      const SizedBox(width: 2),
                      Text(
                        '${hourly.precipitationProbability.toStringAsFixed(0)}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  )
                : null,
          ),
          // Wind
          Icon(Icons.air, size: 13,
              color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 3),
          Text(
            '$wind $windUnit',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
