package com.screenguard.app

import android.accessibilityservice.AccessibilityService
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.view.accessibility.AccessibilityEvent
import androidx.core.app.NotificationCompat
import kotlin.math.abs

/**
 * Runs for as long as the user has the accessibility service enabled,
 * independent of whether the Flutter app is open. Watches which app is in
 * the foreground, compares today's usage (from [UsageStatsHelper]) against
 * the limits in [MonitorConfigStore], and enforces them:
 *  - per-app limit reached -> send the user Home, notify.
 *  - total daily limit reached -> send the user Home and bring MainActivity
 *    to the front with a pending-block flag, so Flutter shows BlockScreen.
 */
class AppMonitorAccessibilityService : AccessibilityService() {
    private val handler = Handler(Looper.getMainLooper())
    private var currentForegroundPackage: String? = null

    private val statusChannelId = "screenguard_status"
    private val alertsChannelId = "screenguard_alerts"
    private val statusNotificationId = 1000
    private val checkIntervalMillis = 20_000L
    private val reblockCooldownMinutes = 15

    private val periodicCheck = object : Runnable {
        override fun run() {
            checkLimits()
            handler.postDelayed(this, checkIntervalMillis)
        }
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        createNotificationChannels()
        handler.post(periodicCheck)
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        if (event.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            event.packageName?.let { currentForegroundPackage = it.toString() }
            checkLimits()
        }
    }

    override fun onInterrupt() {}

    override fun onDestroy() {
        handler.removeCallbacks(periodicCheck)
        super.onDestroy()
    }

    private fun checkLimits() {
        val context = applicationContext
        val usage = UsageStatsHelper.getUsageForToday(context)
        val trackedApps = MonitorConfigStore.getTrackedApps(context)
        val totalLimit = MonitorConfigStore.getTotalDailyLimitMinutes(context)
        val totalWarn = MonitorConfigStore.getTotalWarnBeforeMinutes(context)
        val totalUsed = usage.values.sum()

        for (app in trackedApps) {
            val used = usage[app.packageId] ?: 0
            when {
                used >= app.dailyLimitMinutes && currentForegroundPackage == app.packageId -> {
                    performGlobalAction(GLOBAL_ACTION_HOME)
                    notify(
                        alertsChannelId,
                        "Time's up",
                        "You reached today's limit for this app.",
                        100 + abs(app.packageId.hashCode()) % 100000,
                    )
                }
                used in (app.dailyLimitMinutes - app.warnBeforeMinutes) until app.dailyLimitMinutes -> {
                    val warnKey = "app_${app.packageId}"
                    if (!MonitorConfigStore.hasWarnedToday(context, warnKey)) {
                        MonitorConfigStore.markWarnedToday(context, warnKey)
                        notify(
                            alertsChannelId,
                            "Almost there",
                            "${app.dailyLimitMinutes - used} minutes left today for this app.",
                            200 + abs(app.packageId.hashCode()) % 100000,
                        )
                    }
                }
            }
        }

        if (totalLimit > 0) {
            if (totalUsed >= totalLimit) {
                val onCooldown = MonitorConfigStore.isInReblockCooldown(context, reblockCooldownMinutes)
                if (!onCooldown && !isCurrentForegroundExempt()) {
                    MonitorConfigStore.setPendingBlockReason(context, "total")
                    // Start the cooldown the moment we act, not only once the user
                    // manages to acknowledge the block screen. Without this, a user
                    // who can't reach BlockScreen in time (e.g. it keeps sending them
                    // Home before they can respond) would get re-blocked on every
                    // ~20s tick and every app switch, with no way out short of Safe
                    // Mode. This bounds it to firing at most once per cooldown window
                    // regardless of whether it was ever acknowledged.
                    MonitorConfigStore.setLastUnblockNow(context)
                    performGlobalAction(GLOBAL_ACTION_HOME)
                    launchBlockScreen()
                }
            } else if (totalUsed >= totalLimit - totalWarn) {
                if (!MonitorConfigStore.hasWarnedToday(context, "total")) {
                    MonitorConfigStore.markWarnedToday(context, "total")
                    notify(
                        alertsChannelId,
                        "Almost at today's limit",
                        "${totalLimit - totalUsed} minutes left today.",
                        1,
                    )
                }
            }
        }

        updateStatusNotification(totalUsed)
    }

    /**
     * Never force the user Home while they're in Settings (trying to grant
     * permissions or turn this very service off) or already in ScreenGuard
     * itself. An unknown foreground package is treated as exempt too, so a
     * brief gap in tracking never causes an unwanted action.
     */
    private fun isCurrentForegroundExempt(): Boolean {
        val pkg = currentForegroundPackage ?: return true
        return pkg == packageName || pkg.contains("settings", ignoreCase = true)
    }

    private fun launchBlockScreen() {
        val intent = Intent(this, MainActivity::class.java)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        intent.putExtra("showBlock", true)
        startActivity(intent)
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val nm = getSystemService(NotificationManager::class.java)
            nm.createNotificationChannel(
                NotificationChannel(statusChannelId, "Screen time status", NotificationManager.IMPORTANCE_LOW)
            )
            nm.createNotificationChannel(
                NotificationChannel(alertsChannelId, "Limit alerts", NotificationManager.IMPORTANCE_DEFAULT)
            )
        }
    }

    private fun notify(channelId: String, title: String, text: String, id: Int) {
        val nm = getSystemService(NotificationManager::class.java)
        val notification = NotificationCompat.Builder(this, channelId)
            .setContentTitle(title)
            .setContentText(text)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setAutoCancel(true)
            .build()
        nm.notify(id, notification)
    }

    private fun updateStatusNotification(totalUsedMinutes: Int) {
        val hours = totalUsedMinutes / 60
        val minutes = totalUsedMinutes % 60
        val text = if (hours > 0) "${hours}h ${minutes}m today" else "${minutes}m today"
        val notification = NotificationCompat.Builder(this, statusChannelId)
            .setContentTitle("ScreenGuard")
            .setContentText(text)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
        getSystemService(NotificationManager::class.java).notify(statusNotificationId, notification)
    }
}
