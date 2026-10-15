package com.zantiqlabs.omniweather

import android.content.Context
import android.net.Uri
import androidx.work.CoroutineWorker
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import java.util.concurrent.TimeUnit

/**
 * WorkManager worker that triggers a background Dart execution every 30 minutes
 * to refresh widget data from Open-Meteo without requiring the app to be open.
 *
 * The actual fetch logic lives in lib/home_widget/widget_background.dart
 * (backgroundWidgetUpdate). HomeWidgetBackgroundIntent sends a broadcast that
 * the home_widget plugin intercepts, spins up a background Dart isolate, and
 * calls the registered callback.
 */
class WidgetUpdateWorker(
    ctx: Context,
    params: WorkerParameters,
) : CoroutineWorker(ctx, params) {

    override suspend fun doWork(): Result {
        return try {
            HomeWidgetBackgroundIntent
                .getBroadcast(applicationContext, Uri.parse("homeWidget://backgroundUpdate"))
                .send()
            Result.success()
        } catch (e: Exception) {
            Result.failure()
        }
    }

    companion object {
        const val WORK_NAME = "OmniWeatherWidgetUpdate"
        private const val INTERVAL_MINUTES = 30L

        /** Enqueue (or keep existing) a periodic update. Call from onEnabled. */
        fun schedule(context: Context) {
            val request = PeriodicWorkRequestBuilder<WidgetUpdateWorker>(
                INTERVAL_MINUTES, TimeUnit.MINUTES,
            ).build()

            WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                WORK_NAME,
                ExistingPeriodicWorkPolicy.KEEP,   // don't reset the timer if already queued
                request,
            )
        }

        /** Cancel when the last widget instance is removed. */
        fun cancel(context: Context) {
            WorkManager.getInstance(context).cancelUniqueWork(WORK_NAME)
        }
    }
}