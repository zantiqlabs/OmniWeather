import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/forecast.dart';
import '../../../core/models/location.dart';
import '../../../core/providers/location_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/utils/severe_weather_utils.dart';
import '../../../shared/widgets/location_search_delegate.dart';
import '../../../shared/widgets/severe_weather_banner.dart';
import '../providers/forecast_provider.dart';
import 'widgets/air_quality_card.dart';
import 'widgets/current_conditions_card.dart';
import 'widgets/daily_forecast_card.dart';
import 'widgets/hourly_forecast_strip.dart';

class ForecastScreen extends ConsumerWidget {
  const ForecastScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forecastAsync = ref.watch(forecastProvider);
    final settings      = ref.watch(settingsProvider);
    final locState      = ref.watch(locationProvider);
    final location      = locState.activeLocation;

    return Scaffold(
      appBar: AppBar(
        title: Text(location?.name ?? 'OmniWeather'),
        actions: [
          // GPS button
          _GpsButton(),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search location',
            onPressed: () => showSearch(
              context: context,
              delegate: LocationSearchDelegate(ref),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => ref.read(forecastProvider.notifier).refresh(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
        children: [
          // Horizontal saved-locations bar
          _LocationBar(),
          // Main content
          Expanded(
            child: forecastAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                    const SizedBox(height: 12),
                    Text(e.toString(), textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () =>
                          ref.read(forecastProvider.notifier).refresh(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (forecast) {
                if (forecast == null) {
                  return const Center(
                    child: Text('Choose a location to get started.'),
                  );
                }

                final current = _currentSlot(forecast.hourly);

                // Today's daily entry for night-icon lookups.
                final todayDate = DateTime.now();
                final todayForecast = forecast.daily.where((d) =>
                  d.date.year  == todayDate.year  &&
                  d.date.month == todayDate.month &&
                  d.date.day   == todayDate.day,
                ).firstOrNull;

                // Severe weather event in the next 24 h (may be null).
                final severeEvent =
                    SevereWeatherUtils.findFirst(forecast.hourly);

                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(forecastProvider.notifier).refresh(),
                  child: Column(
                    children: [
                      // Severe weather banner sits above the scroll area so it
                      // is always visible and doesn't scroll away.
                      if (severeEvent != null)
                        SevereWeatherBanner(event: severeEvent),
                      Expanded(
                        child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (current != null)
                        CurrentConditionsCard(
                          hourly: current,
                          settings: settings,
                          todayForecast: todayForecast,
                        ),
                      const SizedBox(height: 12),

                      // Air quality card (collapses on error silently).
                      const AirQualityCard(),
                      const SizedBox(height: 16),

                      Text(
                        'Next 48 hours',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      HourlyForecastStrip(
                        hourly: _upcomingHourly(forecast.hourly, current),
                        settings: settings,
                        daily: forecast.daily,
                      ),
                      const SizedBox(height: 20),

                      Text(
                        '14-day forecast',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap a day to expand hourly detail',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...forecast.daily.map((day) {
                        final slots = _slotsForDay(
                          forecast.hourly,
                          day.date,
                          settings.forecastInterval,
                        );
                        return DailyForecastCard(
                          day: day,
                          settings: settings,
                          hourlySlots: slots,
                        );
                      }),
                    ],
                  ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
        ), // Column
      ),   // SafeArea
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Returns the most recent hourly slot that is not in the future.
/// Falls back to the very first slot if all slots are in the future
/// (e.g. the device clock is well behind the forecast start).
HourlyForecast? _currentSlot(List<HourlyForecast> hourly) {
  final now = DateTime.now();
  HourlyForecast? best;
  for (final h in hourly) {
    if (!h.time.isAfter(now)) {
      best = h;
    } else {
      break; // list is chronological
    }
  }
  return best ?? hourly.firstOrNull;
}

/// Returns up to 48 hourly slots starting from the hour *after* [current].
/// This keeps the "Next 48 hours" strip in sync with the current-conditions
/// card: the card shows the current hour and the strip starts from the next.
List<HourlyForecast> _upcomingHourly(
  List<HourlyForecast> all,
  HourlyForecast?      current,
) {
  if (current == null) return all.take(48).toList();
  final nextTime = current.time.add(const Duration(hours: 1));
  return all.where((h) => !h.time.isBefore(nextTime)).take(48).toList();
}

/// Returns hourly points spaced [intervalHours] apart for [date].
/// e.g. interval=4 → 00:00, 04:00, 08:00, 12:00, 16:00, 20:00
List<HourlyForecast> _slotsForDay(
    List<HourlyForecast> all, DateTime date, int intervalHours) {
  final targetHours = List.generate(
    24 ~/ intervalHours,
    (i) => i * intervalHours,
  );
  return all
      .where((h) =>
          h.time.year == date.year &&
          h.time.month == date.month &&
          h.time.day == date.day &&
          targetHours.contains(h.time.hour))
      .toList();
}

// ── GPS button ────────────────────────────────────────────────────────────────

class _GpsButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLocating = ref.watch(
      locationProvider.select((s) => s.isLocating),
    );

    return IconButton(
      icon: isLocating
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.my_location),
      tooltip: 'Use my location',
      onPressed: isLocating
          ? null
          : () async {
              final loc = await ref
                  .read(locationProvider.notifier)
                  .requestDeviceLocation();
              if (loc == null && context.mounted) {
                final err = ref.read(locationProvider).locationError;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(err ?? 'Could not get location.'),
                  ),
                );
              }
            },
    );
  }
}

// ── Horizontal saved-locations bar ───────────────────────────────────────────

class _LocationBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locState = ref.watch(locationProvider);
    final saved    = locState.savedLocations;
    final active   = locState.activeLocation;

    if (saved.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    // Fixed-height ListView — fully owns the 48 dp row, no Material chip
    // minimum-height surprises.  8 dp vertical padding gives chips 32 dp.
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: saved.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => _LocationChip(
          loc:        saved[i],
          isActive:   saved[i].id == active?.id,
          colorScheme: colorScheme,
          onTap:      () => ref
              .read(locationProvider.notifier)
              .setActiveLocation(saved[i]),
          onLongPress: () => _confirmRemove(context, ref, saved[i]),
        ),
      ),
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    WeatherLocation loc,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove location?'),
        content: Text('Remove "${loc.name}" from saved locations?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(locationProvider.notifier).removeLocation(loc.id);
    }
  }
}

// ── Single location chip ──────────────────────────────────────────────────────
// Custom pill — avoids ChoiceChip's hidden minimum-height constraints that
// can exceed the parent SizedBox and trigger overflow warnings.

class _LocationChip extends StatelessWidget {
  const _LocationChip({
    required this.loc,
    required this.isActive,
    required this.colorScheme,
    required this.onTap,
    required this.onLongPress,
  });

  final WeatherLocation loc;
  final bool            isActive;
  final ColorScheme     colorScheme;
  final VoidCallback    onTap;
  final VoidCallback    onLongPress;

  @override
  Widget build(BuildContext context) {
    final bg       = isActive ? colorScheme.primaryContainer
                              : colorScheme.surfaceContainerHighest;
    final fg       = isActive ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurface;
    final fgMuted  = isActive ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurfaceVariant;

    return GestureDetector(
      onLongPress: onLongPress,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (loc.isFavourite) ...[
                  Icon(Icons.star, size: 12, color: fgMuted),
                  const SizedBox(width: 4),
                ],
                Text(
                  loc.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
