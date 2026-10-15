import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import 'app.dart';
import 'core/providers/location_provider.dart';
import 'core/providers/settings_provider.dart';
import 'home_widget/widget_background.dart';

void main() async {
  // Keep the native splash visible while we initialise.
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Register the Dart function that WorkManager calls in the background
  // to refresh widget data without the app being open.
  HomeWidget.registerBackgroundCallback(backgroundWidgetUpdate);

  // Bootstrap the ProviderContainer so we can await initialisation
  // before the first frame is painted.
  final container = ProviderContainer();
  await container.read(settingsProvider.notifier).init();
  await container.read(locationProvider.notifier).loadSavedLocations();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const OmniWeatherApp(),
    ),
  );

  // Remove the splash now that the first frame has been scheduled.
  FlutterNativeSplash.remove();
}