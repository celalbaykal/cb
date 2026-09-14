package com.screenguard.app

import android.app.AppOpsManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.os.Process
import java.util.Calendar

object UsageStatsHelper {

    fun hasPermission(context: Context): Boolean {
        val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = appOps.unsafeCheckOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            Process.myUid(),
            context.packageName,
        )
        return mode == AppOpsManager.MODE_ALLOWED
    }

    /**
     * Minutes used today (since local midnight) per package, computed from
     * raw foreground/background events rather than the coarser aggregate
     * UsageStats API, so a currently-open app's time counts up to "now".
     */
    fun getUsageForToday(context: Context): Map<String, Int> {
        val usm = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val calendar = Calendar.getInstance()
        calendar.set(Calendar.HOUR_OF_DAY, 0)
        calendar.set(Calendar.MINUTE, 0)
        calendar.set(Calendar.SECOND, 0)
        calendar.set(Calendar.MILLISECOND, 0)
        val startTime = calendar.timeInMillis
        val endTime = System.currentTimeMillis()

        val totalsMillis = mutableMapOf<String, Long>()
        val lastResumeTime = mutableMapOf<String, Long>()
        val events = usm.queryEvents(startTime, endTime)
        val event = UsageEvents.Event()

        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            val pkg = event.packageName ?: continue
            when (event.eventType) {
                UsageEvents.Event.ACTIVITY_RESUMED, UsageEvents.Event.MOVE_TO_FOREGROUND -> {
                    lastResumeTime[pkg] = event.timeStamp
                }
                UsageEvents.Event.ACTIVITY_PAUSED, UsageEvents.Event.MOVE_TO_BACKGROUND -> {
                    val resumedAt = lastResumeTime.remove(pkg)
                    if (resumedAt != null && event.timeStamp > resumedAt) {
                        totalsMillis[pkg] = (totalsMillis[pkg] ?: 0L) + (event.timeStamp - resumedAt)
                    }
                }
            }
        }
        // Anything still "resumed" (e.g. the app open right now) counts up to now.
        for ((pkg, resumedAt) in lastResumeTime) {
            if (endTime > resumedAt) {
                totalsMillis[pkg] = (totalsMillis[pkg] ?: 0L) + (endTime - resumedAt)
            }
        }

        return totalsMillis.mapValues { (_, millis) -> (millis / 60_000L).toInt() }
    }

    fun getInstalledApps(context: Context): List<Pair<String, String>> {
        val pm = context.packageManager
        val intent = Intent(Intent.ACTION_MAIN, null)
        intent.addCategory(Intent.CATEGORY_LAUNCHER)
        return pm.queryIntentActivities(intent, 0)
            .filter { it.activityInfo.packageName != context.packageName }
            .map { it.activityInfo.packageName to it.loadLabel(pm).toString() }
            .distinctBy { it.first }
            .sortedBy { it.second.lowercase() }
    }
}
