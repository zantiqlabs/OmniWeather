import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/air_quality.dart';
import '../../providers/air_quality_provider.dart';

/// Collapsible card shown below CurrentConditionsCard.
///
/// Shows the European AQI with a colour-coded badge, key pollutant readings,
/// and the dominant pollen type for the current hour.
class AirQualityCard extends ConsumerStatefulWidget {
  const AirQualityCard({super.key});

  @override
  ConsumerState<AirQualityCard> createState() => _AirQualityCardState();
}

class _AirQualityCardState extends ConsumerState<AirQualityCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final aqAsync = ref.watch(airQualityProvider);

    return aqAsync.when(
      loading: () => const _AqShimmer(),
      error: (_, __) => const SizedBox.shrink(), // fail silently; don't block forecast
      data: (aqData) {
        if (aqData == null) return const SizedBox.shrink();
        final hour = aqData.currentHour();
        if (hour == null) return const SizedBox.shrink();
        return _buildCard(context, hour);
      },
    );
  }

  Widget _buildCard(BuildContext context, AirQualityHour hour) {
    final theme = Theme.of(context);
    final level = hour.aqiLevel;
    final aqiColor = Color(level.colorValue);
    final pollen = hour.dominantPollen;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row ─────────────────────────────────────────────────
              Row(
                children: [
                  Icon(Icons.air, size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Air Quality',
                    style: theme.textTheme.titleSmall,
                  ),
                  const Spacer(),
                  // AQI badge
                  _AqiBadge(level: level, aqi: hour.europeanAqi),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),

              // Compact summary always visible
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      level.label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: aqiColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (pollen != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.grass_outlined,
                          size: 14,
                          color: Color(pollen.level.colorValue),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${pollen.name} pollen: ${pollen.level.label}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Color(pollen.level.colorValue),
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              // ── Expanded detail ─────────────────────────────────────────────
              if (_expanded) ...[
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),
                // AQI progress bar
                _AqiBar(aqi: hour.europeanAqi ?? 0),
                const SizedBox(height: 16),
                // Pollutant grid
                _PollutantGrid(hour: hour),
                // Pollen section (if any pollen present)
                if (_anyPollen(hour)) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Text(
                    'Pollen',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _PollenRow(hour: hour),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool _anyPollen(AirQualityHour h) =>
      (h.grassPollen ?? 0) > 0 ||
      (h.birchPollen ?? 0) > 0 ||
      (h.alderPollen ?? 0) > 0 ||
      (h.mugwortPollen ?? 0) > 0 ||
      (h.ragweedPollen ?? 0) > 0;
}

// ── AQI badge ─────────────────────────────────────────────────────────────────

class _AqiBadge extends StatelessWidget {
  const _AqiBadge({required this.level, this.aqi});
  final AqiLevel level;
  final double? aqi;

  @override
  Widget build(BuildContext context) {
    final color = Color(level.colorValue);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            aqi != null ? 'AQI ${aqi!.toStringAsFixed(0)}' : 'AQI —',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── AQI segmented bar ─────────────────────────────────────────────────────────

class _AqiBar extends StatelessWidget {
  const _AqiBar({required this.aqi});
  final double aqi;

  // Band boundaries: 0, 20, 40, 60, 80, 100, 150 (cap for display)
  static const _bands = [
    (0xFF50C878, 'Good'),
    (0xFFB5D86E, 'Fair'),
    (0xFFFFD700, 'Moderate'),
    (0xFFFF8C00, 'Poor'),
    (0xFFE53935, 'Very Poor'),
    (0xFF8B1A8B, 'Extremely Poor'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Clamp to 150 for display purposes.
    final clamped = aqi.clamp(0, 150).toDouble();
    final progress = clamped / 150;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Segmented colour bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 8,
            child: Row(
              children: _bands.map((b) {
                return Expanded(
                  child: Container(color: Color(b.$1)),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 4),
        // Marker line
        LayoutBuilder(builder: (ctx, constraints) {
          final markerX =
              (progress * constraints.maxWidth).clamp(0.0, constraints.maxWidth);
          return Stack(
            children: [
              SizedBox(height: 20, width: constraints.maxWidth),
              Positioned(
                left: (markerX - 1).clamp(0.0, constraints.maxWidth - 2),
                top: 0,
                child: Container(
                  width: 2,
                  height: 12,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          );
        }),
        // Band labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: ['0', '20', '40', '60', '80', '100+'].map((l) {
            return Text(
              l,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 9,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ── Pollutant grid ────────────────────────────────────────────────────────────

class _PollutantGrid extends StatelessWidget {
  const _PollutantGrid({required this.hour});
  final AirQualityHour hour;

  @override
  Widget build(BuildContext context) {
    final items = <(String, double?)>[
      ('PM2.5 µg/m³', hour.pm25),
      ('PM10 µg/m³',  hour.pm10),
      ('O₃ µg/m³',    hour.ozone),
      ('NO₂ µg/m³',   hour.nitrogenDioxide),
    ];

    return Row(
      children: items.map((item) {
        return Expanded(
          child: _SmallStat(
            label: item.$1,
            value: item.$2 != null ? item.$2!.toStringAsFixed(0) : '—',
          ),
        );
      }).toList(),
    );
  }
}

// ── Pollen row ────────────────────────────────────────────────────────────────

class _PollenRow extends StatelessWidget {
  const _PollenRow({required this.hour});
  final AirQualityHour hour;

  @override
  Widget build(BuildContext context) {
    final items = <(String, double?)>[
      ('Grass',    hour.grassPollen),
      ('Birch',    hour.birchPollen),
      ('Alder',    hour.alderPollen),
      ('Mugwort',  hour.mugwortPollen),
      ('Ragweed',  hour.ragweedPollen),
    ];

    final visible = items.where((i) => (i.$2 ?? 0) >= 0).toList();

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: visible.map((item) {
        final level = PollenLevel.fromValue(item.$2 ?? 0);
        if (level == PollenLevel.none) return const SizedBox.shrink();
        return _PollenChip(name: item.$1, level: level);
      }).toList(),
    );
  }
}

class _PollenChip extends StatelessWidget {
  const _PollenChip({required this.name, required this.level});
  final String name;
  final PollenLevel level;

  @override
  Widget build(BuildContext context) {
    final color = Color(level.colorValue);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        '$name · ${level.label}',
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }
}

// ── Shared ────────────────────────────────────────────────────────────────────

class _SmallStat extends StatelessWidget {
  const _SmallStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 9,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _AqShimmer extends StatelessWidget {
  const _AqShimmer();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        height: 72,
        padding: const EdgeInsets.all(16),
        child: const Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Loading air quality…'),
          ],
        ),
      ),
    );
  }
}
