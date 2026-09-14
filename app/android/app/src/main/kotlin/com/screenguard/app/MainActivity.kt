package com.screenguard.app

import android.content.ComponentName
import android.content.Intent
import android.provider.Settings
import android.text.TextUtils
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.screenguard.app/native"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "hasUsagePermission" -> result.success(UsageStatsHelper.hasPermission(this))

                    "requestUsagePermission" -> {
                        startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                        result.success(null)
                    }

                    "hasAccessibilityPermission" -> result.success(isAccessibilityServiceEnabled())

                    "openAccessibilitySettings" -> {
                        startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                        result.success(null)
                    }

                    "getInstalledApps" -> {
                        val apps = UsageStatsHelper.getInstalledApps(this).map {
                            mapOf("packageId" to it.first, "displayName" to it.second)
                        }
                        result.success(apps)
                    }

                    "syncMonitoredApps" -> {
                        @Suppress("UNCHECKED_CAST")
                        val args = call.arguments as Map<String, Any?>
                        @Suppress("UNCHECKED_CAST")
                        val appsArg = args["apps"] as List<Map<String, Any?>>
                        val apps = appsArg.map {
                            TrackedAppConfig(
                                it["packageId"] as String,
                                (it["dailyLimitMinutes"] as Number).toInt(),
                                (it["warnBeforeMinutes"] as Number).toInt(),
                            )
                        }
                        val totalLimit = (args["totalDailyLimitMinutes"] as Number).toInt()
                        val totalWarn = (args["totalWarnBeforeMinutes"] as Number).toInt()
                        MonitorConfigStore.setTrackedApps(this, apps, totalLimit, totalWarn)
                        result.success(null)
                    }

                    "getTodayUsage" -> {
                        val usage = UsageStatsHelper.getUsageForToday(this)
                        result.success(
                            mapOf(
                                "minutesByPackage" to usage,
                                "totalMinutes" to usage.values.sum(),
                            )
                        )
                    }

                    "consumePendingBlockReason" ->
                        result.success(MonitorConfigStore.consumePendingBlockReason(this))

                    "acknowledgeBlock" -> {
                        MonitorConfigStore.setLastUnblockNow(this)
                        result.success(null)
                    }

                    // No installed-app enumeration concept on Android; the picker
                    // used there is iOS-only. Kept as a harmless no-op so the
                    // shared Dart call site doesn't need to branch on platform.
                    "pickMonitoredApps" -> result.success(null)

                    else -> result.notImplemented()
                }
            }
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val expected = ComponentName(this, AppMonitorAccessibilityService::class.java)
        val enabledServices = Settings.Secure.getString(
            contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false
        val splitter = TextUtils.SimpleStringSplitter(':')
        splitter.setString(enabledServices)
        while (splitter.hasNext()) {
            if (ComponentName.unflattenFromString(splitter.next()) == expected) return true
        }
        return false
    }
}
