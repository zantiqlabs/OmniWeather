import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import 'weather_widget_service.dart';

/// Mixin applied to the root [ConsumerStatefulWidget]'s state so the home
/// widget is refreshed whenever the app returns to the foreground.
///
/// Usage:
/// ```dart
/// class _MainShellState extends ConsumerState<_MainShell>
///     with WidgetsBindingObserver, WeatherWidgetBinding {
/// ```
mixin WeatherWidgetBinding<T extends ConsumerStatefulWidget>
    on ConsumerState<T>, WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Handle widget tap → deep-link into the app.
    HomeWidget.widgetClicked.listen(_onWidgetClicked);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh the widget data when the user brings the app back to the
      // foreground — covers the case where forecast data has aged.
      refreshHomeWidget(ref);
    }
  }

  void _onWidgetClicked(Uri? uri) {
    // Currently a no-op; could deep-link to a specific screen in future.
    // e.g. uri?.pathSegments.first == 'forecast' → navigate to forecast tab.
  }
}
