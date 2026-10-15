import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Controls which main screen is currently visible (screen / stack index, 0–4).
///
/// Screen indices (fixed — matches IndexedStack order in _MainShell):
///   0 = Forecast
///   1 = Historical
///   2 = Lightning
///   3 = Map
///   4 = Settings
///
/// Any widget can switch tabs by writing:
///   ref.read(activeTabProvider.notifier).state = 0; // → Forecast
final activeTabProvider = StateProvider<int>((ref) => 0);
