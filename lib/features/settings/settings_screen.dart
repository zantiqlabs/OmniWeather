import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers/settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // ── Appearance ─────────────────────────────────────────────────────
          _SectionHeader('Appearance'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Theme'),
                  const SizedBox(height: 10),
                  SegmentedButton<ThemeMode>(
                    expandedInsets: EdgeInsets.zero,
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        icon: Icon(Icons.brightness_auto),
                        label: Text('System'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: Icon(Icons.light_mode),
                        label: Text('Light'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: Icon(Icons.dark_mode),
                        label: Text('Dark'),
                      ),
                    ],
                    selected: {settings.themeMode},
                    onSelectionChanged: (s) => notifier.setThemeMode(s.first),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Forecast ───────────────────────────────────────────────────────
          _SectionHeader('Forecast'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Hourly detail interval'),
                  const SizedBox(height: 4),
                  Text(
                    'How many hours between slots when you expand a day.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [1, 2, 3, 4, 6, 8, 12].map((h) {
                      final selected = settings.forecastInterval == h;
                      return ChoiceChip(
                        label: Text('${h}h'),
                        selected: selected,
                        onSelected: (_) => notifier.setForecastInterval(h),
                        selectedColor:
                            Theme.of(context).colorScheme.primaryContainer,
                        labelStyle: TextStyle(
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Units ──────────────────────────────────────────────────────────
          _SectionHeader('Units'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Temperature
                  const Text('Temperature'),
                  const SizedBox(height: 10),
                  SegmentedButton<TemperatureUnit>(
                    expandedInsets: EdgeInsets.zero,
                    segments: const [
                      ButtonSegment(
                        value: TemperatureUnit.celsius,
                        label: Text('Celsius (°C)'),
                      ),
                      ButtonSegment(
                        value: TemperatureUnit.fahrenheit,
                        label: Text('Fahrenheit (°F)'),
                      ),
                    ],
                    selected: {settings.temperatureUnit},
                    onSelectionChanged: (s) =>
                        notifier.setTemperatureUnit(s.first),
                  ),

                  const SizedBox(height: 20),

                  // Wind speed — 4 options, needs full width
                  const Text('Wind speed'),
                  const SizedBox(height: 10),
                  SegmentedButton<WindUnit>(
                    expandedInsets: EdgeInsets.zero,
                    segments: const [
                      ButtonSegment(
                        value: WindUnit.kmh,
                        label: Text('km/h'),
                      ),
                      ButtonSegment(
                        value: WindUnit.mph,
                        label: Text('mph'),
                      ),
                      ButtonSegment(
                        value: WindUnit.ms,
                        label: Text('m/s'),
                      ),
                      ButtonSegment(
                        value: WindUnit.knots,
                        label: Text('knots'),
                      ),
                    ],
                    selected: {settings.windUnit},
                    onSelectionChanged: (s) => notifier.setWindUnit(s.first),
                  ),

                  const SizedBox(height: 20),

                  // Precipitation
                  const Text('Precipitation'),
                  const SizedBox(height: 10),
                  SegmentedButton<PrecipUnit>(
                    expandedInsets: EdgeInsets.zero,
                    segments: const [
                      ButtonSegment(
                        value: PrecipUnit.mm,
                        label: Text('Millimetres (mm)'),
                      ),
                      ButtonSegment(
                        value: PrecipUnit.inches,
                        label: Text('Inches (in)'),
                      ),
                    ],
                    selected: {settings.precipUnit},
                    onSelectionChanged: (s) =>
                        notifier.setPrecipUnit(s.first),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Lightning strikes ─────────────────────────────────────────────
          _SectionHeader('Lightning Strikes'),
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.bolt_outlined),
              title: const Text('Show lightning strikes'),
              subtitle: const Text(
                'Adds a Lightning tab. Powered by Blitzortung.org — '
                'free, no account required.',
              ),
              value: settings.showLightning,
              onChanged: (v) => notifier.setShowLightning(v),
            ),
          ),
          const SizedBox(height: 24),

          // ── About ──────────────────────────────────────────────────────────
          _SectionHeader('About'),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('OmniWeather'),
                  subtitle: Text('com.zantiqlabs.omniweather'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.cloud_outlined),
                  title: const Text('Weather data'),
                  subtitle: const Text('Open-Meteo (open-meteo.com)'),
                  trailing: const Icon(Icons.open_in_new, size: 16),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.bolt_outlined),
                  title: const Text('Lightning data'),
                  subtitle: const Text('Blitzortung.org (real-time, free)'),
                  trailing: const Icon(Icons.open_in_new, size: 16),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}