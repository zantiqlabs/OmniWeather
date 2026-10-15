import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/constants/app_constants.dart';
import 'core/providers/settings_provider.dart';
import 'core/providers/tab_provider.dart';
import 'features/forecast/presentation/forecast_screen.dart';
import 'features/historical/presentation/historical_screen.dart';
import 'features/lightning/presentation/lightning_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/weather_map/presentation/weather_map_screen.dart';
import 'home_widget/weather_widget_binding.dart';

class OmniWeatherApp extends ConsumerWidget {
  const OmniWeatherApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode =
        ref.watch(settingsProvider.select((s) => s.themeMode));

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: themeMode,
      home: const _MainShell(),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppConstants.brandBlue,
      brightness: brightness,
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      textTheme: GoogleFonts.interTextTheme(
        ThemeData(brightness: brightness).textTheme,
      ),
      cardTheme: CardThemeData(
        elevation: isDark ? 2 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        elevation: 0,
      ),
    );
  }
}

// ── Main shell ────────────────────────────────────────────────────────────────

class _MainShell extends ConsumerStatefulWidget {
  const _MainShell();

  @override
  ConsumerState<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<_MainShell>
    with WidgetsBindingObserver, WeatherWidgetBinding {
  // All screens are always present so IndexedStack preserves their state.
  static const _screens = <Widget>[
    ForecastScreen(),
    HistoricalScreen(),
    LightningScreen(),
    WeatherMapScreen(),
    SettingsScreen(),
  ];

  // ── Index helpers ─────────────────────────────────────────────────────────

  /// Nav bar index → screen index.
  ///
  /// When lightning is hidden the nav is [Forecast, Historical, Map, Settings]
  /// (indices 0-3), which must map to screen indices [0, 1, 3, 4].
  int _navToScreen(int navIdx, bool showLightning) {
    if (showLightning) return navIdx;
    return navIdx < 2 ? navIdx : navIdx + 1;
  }

  /// Screen index → nav bar index.
  int _screenToNav(int screenIdx, bool showLightning) {
    if (showLightning) return screenIdx;
    if (screenIdx < 2) return screenIdx;
    if (screenIdx == 2) return 0; // lightning hidden → bounce to forecast
    return screenIdx - 1;
  }

  @override
  Widget build(BuildContext context) {
    final showLightning =
        ref.watch(settingsProvider.select((s) => s.showLightning));
    final screenIdx = ref.watch(activeTabProvider);

    // If currently on the lightning screen but it has just been hidden,
    // schedule a jump to Forecast on the next frame.
    if (!showLightning && screenIdx == 2) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(activeTabProvider.notifier).state = 0;
      });
    }

    final navIdx = _screenToNav(screenIdx, showLightning);

    final destinations = <NavigationDestination>[
      const NavigationDestination(
        icon: Icon(Icons.wb_cloudy_outlined),
        selectedIcon: Icon(Icons.wb_cloudy),
        label: 'Forecast',
      ),
      const NavigationDestination(
        icon: Icon(Icons.history_outlined),
        selectedIcon: Icon(Icons.history),
        label: 'Historical',
      ),
      if (showLightning)
        const NavigationDestination(
          icon: Icon(Icons.bolt_outlined),
          selectedIcon: Icon(Icons.bolt),
          label: 'Lightning',
        ),
      const NavigationDestination(
        icon: Icon(Icons.map_outlined),
        selectedIcon: Icon(Icons.map),
        label: 'Map',
      ),
      const NavigationDestination(
        icon: Icon(Icons.settings_outlined),
        selectedIcon: Icon(Icons.settings),
        label: 'Settings',
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: screenIdx,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navIdx.clamp(0, destinations.length - 1),
        onDestinationSelected: (i) => ref.read(activeTabProvider.notifier).state =
            _navToScreen(i, showLightning),
        destinations: destinations,
      ),
    );
  }
}
