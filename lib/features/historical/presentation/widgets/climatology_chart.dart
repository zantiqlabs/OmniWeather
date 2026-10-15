import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/models/historical_weather.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/utils/unit_converter.dart';

/// Shows a bar + line chart comparing the same month across up to 5 years:
///  - Bars: total precipitation
///  - Lines: avg max temp and avg min temp
class ClimatologyChart extends StatelessWidget {
  const ClimatologyChart({
    super.key,
    required this.summaries,
    required this.settings,
    required this.monthName,
  });

  final List<MonthlyClimatology> summaries;
  final AppSettings settings;
  final String monthName;

  @override
  Widget build(BuildContext context) {
    if (summaries.isEmpty) {
      return const Center(child: Text('No historical data available.'));
    }

    final theme = Theme.of(context);
    final tempSymbol = UnitConverter.tempUnitSymbol(settings.temperatureUnit);
    final precipSymbol = UnitConverter.precipUnitSymbol(settings.precipUnit);

    // Sort oldest → newest
    final sorted = [...summaries]..sort((a, b) => a.year.compareTo(b.year));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Temperature ($monthName, last ${sorted.length} years)',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= sorted.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          sorted[idx].year.toString(),
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (value, _) => Text(
                        value.toStringAsFixed(0),
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  // Avg max temp
                  LineChartBarData(
                    color: Colors.orange,
                    spots: sorted.asMap().entries.map((e) {
                      final temp = UnitConverter.convertTemp(
                        e.value.avgTempMax,
                        settings.temperatureUnit,
                      );
                      return FlSpot(e.key.toDouble(), temp);
                    }).toList(),
                    isCurved: true,
                    dotData: FlDotData(show: true),
                  ),
                  // Avg min temp
                  LineChartBarData(
                    color: Colors.blue,
                    spots: sorted.asMap().entries.map((e) {
                      final temp = UnitConverter.convertTemp(
                        e.value.avgTempMin,
                        settings.temperatureUnit,
                      );
                      return FlSpot(e.key.toDouble(), temp);
                    }).toList(),
                    isCurved: true,
                    dotData: FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _Legend(color: Colors.orange, label: 'Avg high $tempSymbol'),
              const SizedBox(width: 16),
              _Legend(color: Colors.blue, label: 'Avg low $tempSymbol'),
            ],
          ),
          const SizedBox(height: 24),

          Text(
            'Precipitation ($monthName)',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= sorted.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          sorted[idx].year.toString(),
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (value, _) => Text(
                        value.toStringAsFixed(0),
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                barGroups: sorted.asMap().entries.map((e) {
                  final precip = UnitConverter.convertPrecip(
                    e.value.totalPrecipitation,
                    settings.precipUnit,
                  );
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: precip,
                        color: theme.colorScheme.primary.withOpacity(0.7),
                        width: 20,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'Total precipitation ($precipSymbol)',
              style: theme.textTheme.bodySmall,
            ),
          ),

          const SizedBox(height: 24),
          // Summary stats table
          _SummaryTable(summaries: sorted, settings: settings),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 16, height: 3, color: color),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _SummaryTable extends StatelessWidget {
  const _SummaryTable({required this.summaries, required this.settings});
  final List<MonthlyClimatology> summaries;
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tempSymbol = UnitConverter.tempUnitSymbol(settings.temperatureUnit);
    final precipSymbol = UnitConverter.precipUnitSymbol(settings.precipUnit);

    return Table(
      border: TableBorder.all(
        color: theme.colorScheme.outlineVariant,
        width: 0.5,
      ),
      columnWidths: const {
        0: FlexColumnWidth(1),
        1: FlexColumnWidth(1.2),
        2: FlexColumnWidth(1.2),
        3: FlexColumnWidth(1.2),
        4: FlexColumnWidth(0.8),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(color: theme.colorScheme.surfaceVariant),
          children: [
            _Cell('Year', header: true),
            _Cell('Max $tempSymbol', header: true),
            _Cell('Min $tempSymbol', header: true),
            _Cell('Precip $precipSymbol', header: true),
            _Cell('Rain days', header: true),
          ],
        ),
        ...summaries.map((s) {
          final maxT = UnitConverter.convertTemp(s.avgTempMax, settings.temperatureUnit);
          final minT = UnitConverter.convertTemp(s.avgTempMin, settings.temperatureUnit);
          final precip = UnitConverter.convertPrecip(s.totalPrecipitation, settings.precipUnit);
          return TableRow(children: [
            _Cell(s.year.toString()),
            _Cell(maxT.toStringAsFixed(1)),
            _Cell(minT.toStringAsFixed(1)),
            _Cell(precip.toStringAsFixed(1)),
            _Cell(s.rainyDays.toString()),
          ]);
        }),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell(this.text, {this.header = false});
  final String text;
  final bool header;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: header ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
