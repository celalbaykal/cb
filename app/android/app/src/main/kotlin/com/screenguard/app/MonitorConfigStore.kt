package com.screenguard.app

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

data class TrackedAppConfig(
    val packageId: String,
    val dailyLimitMinutes: Int,
    val warnBeforeMinutes: Int,
)

// Shared config/state between the Flutter method channel (MainActivity) and
// the AccessibilityService, which keeps enforcing limits even when Flutter
// isn't running. Backed by SharedPreferences so both sides always agree.
object MonitorConfigStore {
    private const val PREFS = "screenguard_prefs"
    private const val KEY_APPS = "tracked_apps_json"
    private const val KEY_TOTAL_LIMIT = "total_daily_limit_minutes"
    private const val KEY_TOTAL_WARN = "total_warn_before_minutes"
    private const val KEY_PENDING_BLOCK = "pending_block_reason"
    private const val KEY_LAST_UNBLOCK = "last_unblock_millis"
    private const val KEY_WARNED_PREFIX = "warned_"

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun setTrackedApps(
        context: Context,
        apps: List<TrackedAppConfig>,
        totalLimitMinutes: Int,
        totalWarnBeforeMinutes: Int,
    ) {
        val arr = JSONArray()
        for (app in apps) {
            val obj = JSONObject()
            obj.put("packageId", app.packageId)
            obj.put("dailyLimitMinutes", app.dailyLimitMinutes)
            obj.put("warnBeforeMinutes", app.warnBeforeMinutes)
            arr.put(obj)
        }
        prefs(context).edit()
            .putString(KEY_APPS, arr.toString())
            .putInt(KEY_TOTAL_LIMIT, totalLimitMinutes)
            .putInt(KEY_TOTAL_WARN, totalWarnBeforeMinutes)
            .apply()
    }

    fun getTrackedApps(context: Context): List<TrackedAppConfig> {
        val raw = prefs(context).getString(KEY_APPS, null) ?: return emptyList()
        val arr = JSONArray(raw)
        val result = mutableListOf<TrackedAppConfig>()
        for (i in 0 until arr.length()) {
            val obj = arr.getJSONObject(i)
            result.add(
                TrackedAppConfig(
                    obj.getString("packageId"),
                    obj.getInt("dailyLimitMinutes"),
                    obj.getInt("warnBeforeMinutes"),
                )
            )
        }
        return result
    }

    fun getTotalDailyLimitMinutes(context: Context) = prefs(context).getInt(KEY_TOTAL_LIMIT, 120)

    fun getTotalWarnBeforeMinutes(context: Context) = prefs(context).getInt(KEY_TOTAL_WARN, 10)

    fun setPendingBlockReason(context: Context, reason: String) {
        prefs(context).edit().putString(KEY_PENDING_BLOCK, reason).apply()
    }

    fun consumePendingBlockReason(context: Context): String? {
        val p = prefs(context)
        val value = p.getString(KEY_PENDING_BLOCK, null)
        if (value != null) p.edit().remove(KEY_PENDING_BLOCK).apply()
        return value
    }

    // Called both when the block screen is acknowledged AND the moment a block
    // action is taken, so the reblock cooldown always starts immediately —
    // never only contingent on the user managing to acknowledge it.
    fun setLastUnblockNow(context: Context) {
        prefs(context).edit().putLong(KEY_LAST_UNBLOCK, System.currentTimeMillis()).apply()
    }

    fun isInReblockCooldown(context: Context, cooldownMinutes: Int): Boolean {
        val last = prefs(context).getLong(KEY_LAST_UNBLOCK, 0L)
        if (last == 0L) return false
        return System.currentTimeMillis() - last < cooldownMinutes * 60_000L
    }

    private fun todayStamp(): String = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())

    fun hasWarnedToday(context: Context, key: String): Boolean {
        return prefs(context).getString(KEY_WARNED_PREFIX + key, null) == todayStamp()
    }

    fun markWarnedToday(context: Context, key: String) {
        prefs(context).edit().putString(KEY_WARNED_PREFIX + key, todayStamp()).apply()
    }
}
