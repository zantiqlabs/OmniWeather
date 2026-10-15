import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/utils/severe_weather_utils.dart';

/// A dismissable banner shown at the top of the Forecast screen when a severe
/// weather event is found in the next 24 hours.
///
/// Uses [MaterialBanner] colours:
///   - SeverityLevel.advisory → amber
///   - SeverityLevel.warning  → red
///
/// Dismissed state is ephemeral (per-session). If the location or forecast
/// refreshes and a new event is found, the banner reappears.
class SevereWeatherBanner extends StatefulWidget {
  const SevereWeatherBanner({
    super.key,
    required this.event,
  });

  final SevereWeatherEvent event;

  @override
  State<SevereWeatherBanner> createState() => _SevereWeatherBannerState();
}

class _SevereWeatherBannerState extends State<SevereWeatherBanner> {
  bool _dismissed = false;

  @override
  void didUpdateWidget(SevereWeatherBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    // New event (different time or code) → re-show even if previously dismissed.
    if (oldWidget.event.time != widget.event.time ||
        oldWidget.event.code != widget.event.code) {
      _dismissed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    final isWarning = widget.event.level == SeverityLevel.warning;
    final theme     = Theme.of(context);

    final bgColor = isWarning
        ? theme.colorScheme.errorContainer
        : const Color(0xFFFFF3CD); // amber-ish advisory

    final fgColor = isWarning
        ? theme.colorScheme.onErrorContainer
        : const Color(0xFF856404);

    final timeStr = DateFormat('ha').format(widget.event.time).toLowerCase();

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: bgColor,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Text(
                widget.event.icon,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isWarning ? 'Weather Warning' : 'Weather Advisory',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: fgColor,
                      ),
                    ),
                    Text(
                      '${widget.event.headline} expected around $timeStr',
                      style: TextStyle(fontSize: 12, color: fgColor),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, size: 18, color: fgColor),
                tooltip: 'Dismiss',
                onPressed: () => setState(() => _dismissed = true),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
