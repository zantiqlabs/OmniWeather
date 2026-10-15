import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/historical_weather.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/utils/unit_converter.dart';
import '../../../../core/utils/weather_code_utils.dart';

class HistoricalDayList extends StatelessWidget {
  const HistoricalDayList({
    super.key,
    required this.data,
    required this.settings,
  });

  final HistoricalData data;
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    if (data.days.isEmpty) {
      return const Center(child: Text('No data for this date range.'));
    }

    final dateFormat = DateFormat('EEE d MMM yyyy');
    final theme = Theme.of(context);
    final symbol = UnitConverter.tempUnitSymbol(settings.temperatureUnit);
    final precipUnit = UnitConverter.precipUnitSymbol(settings.precipUnit);

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: data.days.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final day = data.days[i];
        final maxTemp = UnitConverter.convertTemp(
          day.tempMax,
          settings.temperatureUnit,
        ).toStringAsFixed(1);
        final minTemp = UnitConverter.convertTemp(
          day.tempMin,
          settings.temperatureUnit,
        ).toStringAsFixed(1);
        final precip = UnitConverter.convertPrecip(
          day.precipitationSum,
          settings.precipUnit,
        ).toStringAsFixed(1);

        return ListTile(
          dense: true,
          leading: Icon(
            WeatherCodeUtils.icon(day.weatherCode),
            color: WeatherCodeUtils.color(day.weatherCode),
          ),
          title: Text(dateFormat.format(day.date)),
          subtitle: Text(WeatherCodeUtils.description(day.weatherCode)),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$minTemp / $maxTemp$symbol',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (day.precipitationSum > 0.1)
                Text(
                  '$precip$precipUnit',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
