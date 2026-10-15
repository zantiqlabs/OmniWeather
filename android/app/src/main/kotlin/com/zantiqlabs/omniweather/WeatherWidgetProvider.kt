package com.zantiqlabs.omniweather

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

/**
 * Home screen widget — shows location, temperature, condition, feels-like,
 * precipitation probability, wind, and a 3-day forecast strip.
 *
 * Data is written from Dart via [home_widget]'s saveWidgetData() and
 * read here using HomeWidgetPlugin.getData().
 *
 * Layout:   res/layout/weather_widget.xml
 * Metadata: res/xml/weather_widget_info.xml
 */
class WeatherWidgetProvider : AppWidgetProvider() {

    /** First widget added — start the periodic background refresh. */
    override fun onEnabled(context: Context) {
        WidgetUpdateWorker.schedule(context)
    }

    /** Last widget removed — stop the periodic refresh to save battery. */
    override fun onDisabled(context: Context) {
        WidgetUpdateWorker.cancel(context)
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (widgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, widgetId)
        }
    }

    private fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        widgetId: Int
    ) {
        val d = HomeWidgetPlugin.getData(context)

        // Current conditions
        val locationName = d.getString("widget_location_name", "—") ?: "—"
        val temperature  = d.getString("widget_temperature",   "—") ?: "—"
        val condition    = d.getString("widget_condition",      "—") ?: "—"
        val feelsLike    = d.getString("widget_feels_like",    "") ?: ""
        val precip       = d.getString("widget_precip_prob",   "") ?: ""
        val wind         = d.getString("widget_wind",          "") ?: ""
        val lastUpdated  = d.getString("widget_last_updated",  "") ?: ""
        val updatedLabel = formatUpdated(lastUpdated)

        // 3-day strip
        val dayNames = (0..2).map { i -> d.getString("widget_day${i}_name", "") ?: "" }
        val dayIcons = (0..2).map { i -> d.getString("widget_day${i}_icon", "") ?: "" }
        val dayTemps = (0..2).map { i -> d.getString("widget_day${i}_temp", "") ?: "" }

        val views = RemoteViews(context.packageName, R.layout.weather_widget)

        // Current conditions row
        views.setTextViewText(R.id.widget_location,    locationName)
        views.setTextViewText(R.id.widget_temperature, temperature)
        views.setTextViewText(R.id.widget_condition,   condition)
        views.setTextViewText(R.id.widget_feels_like,  feelsLike)
        views.setTextViewText(R.id.widget_updated,     updatedLabel)
        views.setTextViewText(R.id.widget_precip,      precip)
        views.setTextViewText(R.id.widget_wind,        wind)

        // 3-day strip
        val nameIds = listOf(R.id.widget_day0_name, R.id.widget_day1_name, R.id.widget_day2_name)
        val iconIds = listOf(R.id.widget_day0_icon, R.id.widget_day1_icon, R.id.widget_day2_icon)
        val tempIds = listOf(R.id.widget_day0_temp, R.id.widget_day1_temp, R.id.widget_day2_temp)
        for (i in 0..2) {
            views.setTextViewText(nameIds[i], dayNames[i])
            views.setTextViewText(iconIds[i], dayIcons[i])
            views.setTextViewText(tempIds[i], dayTemps[i])
        }

        // Tapping the widget opens the app.
        val launchIntent = context.packageManager
            .getLaunchIntentForPackage(context.packageName)
        if (launchIntent != null) {
            val pendingIntent = android.app.PendingIntent.getActivity(
                context,
                0,
                launchIntent,
                android.app.PendingIntent.FLAG_UPDATE_CURRENT or
                    android.app.PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
        }

        appWidgetManager.updateAppWidget(widgetId, views)
    }

    private fun formatUpdated(iso: String): String {
        if (iso.isBlank()) return ""
        return try {
            // java.time requires API 26+ — use SimpleDateFormat to stay compatible
            // with API 21+. The Dart side now saves UTC (ends with Z), but we also
            // handle the legacy local-time format (no suffix) for safety.
            val cleaned = iso.trim()
            val (pattern, tz) = if (cleaned.endsWith("Z")) {
                "yyyy-MM-dd'T'HH:mm:ss" to java.util.TimeZone.getTimeZone("UTC")
            } else {
                "yyyy-MM-dd'T'HH:mm:ss" to java.util.TimeZone.getDefault()
            }
            val utcFmt = java.text.SimpleDateFormat(pattern, java.util.Locale.US).apply {
                timeZone = tz
            }
            // Strip fractional seconds and the trailing Z (already handled above)
            val normalized = cleaned.substringBefore(".").removeSuffix("Z")
            val date = utcFmt.parse(normalized) ?: return ""
            val localFmt = java.text.SimpleDateFormat("h:mm a", java.util.Locale.getDefault())
            "Updated ${localFmt.format(date)}"
        } catch (_: Throwable) {   // catch Throwable, not just Exception, to cover
            ""                      // NoClassDefFoundError on hypothetical API < 26 paths
        }
    }
}