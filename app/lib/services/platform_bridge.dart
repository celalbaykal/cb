import 'dart:io';

import 'package:flutter/services.dart';

import '../models/app_settings.dart';
import '../models/installed_app.dart';
import '../models/tracked_app.dart';
import '../models/usage_snapshot.dart';

/// Everything that can't be done in pure Dart goes through this one
/// MethodChannel. Android implements it with UsageStatsManager + an
/// AccessibilityService (see android/.../AppMonitorAccessibilityService.kt).
/// iOS implements it with the Screen Time API (FamilyControls /
/// DeviceActivity / ManagedSettings) — see ios/Runner/ScreenTimeManager.swift.
///
/// Enforcement (closing apps, shielding apps, showing the block screen) is
/// owned entirely by the native side so it keeps working even when this
/// Flutter isolate isn't running. Dart only configures limits and reads back
/// state for the UI.
class PlatformBridge {
  PlatformBridge._();
  static final PlatformBridge instance = PlatformBridge._();

  static const _channel = MethodChannel('com.screenguard.app/native');

  bool get isAndroid => Platform.isAndroid;
  bool get isIOS => Platform.isIOS;

  /// Android: "Usage Access" special permission, needed to read usage stats.
  /// iOS: Screen Time ("Family Controls") authorization status.
  Future<bool> hasUsagePermission() async {
    final result = await _channel.invokeMethod<bool>('hasUsagePermission');
    return result ?? false;
  }

  Future<void> requestUsagePermission() async {
    await _channel.invokeMethod('requestUsagePermission');
  }

  /// Android only: whether the AppMonitorAccessibilityService is enabled.
  /// Always reports true on iOS, where there is no equivalent step.
  Future<bool> hasAccessibilityPermission() async {
    if (isIOS) return true;
    final result =
        await _channel.invokeMethod<bool>('hasAccessibilityPermission');
    return result ?? false;
  }

  Future<void> openAccessibilitySettings() async {
    await _channel.invokeMethod('openAccessibilitySettings');
  }

  /// Android: full list of launchable apps on the device, so the user can
  /// pick which ones to track from within our own UI.
  /// iOS: returns an empty list — Apple does not let third-party apps
  /// enumerate installed apps. Use [pickMonitoredAppsOnIOS] instead, which
  /// presents Apple's own FamilyActivityPicker.
  Future<List<InstalledApp>> getInstalledApps() async {
    if (isIOS) return const [];
    final result = await _channel.invokeMethod<List<dynamic>>('getInstalledApps');
    return (result ?? [])
        .map((raw) => InstalledApp.fromMap(Map<String, dynamic>.from(raw as Map)))
        .toList();
  }

  /// iOS only: presents Apple's native FamilyActivityPicker so the user can
  /// choose which apps/categories to limit. Returns once the picker closes;
  /// the selection itself is stored natively (Apple never exposes the real
  /// app identifiers back to third-party code, only opaque tokens).
  Future<void> pickMonitoredAppsOnIOS() async {
    if (!isIOS) return;
    await _channel.invokeMethod('pickMonitoredApps');
  }

  /// Pushes the current limit configuration down to the native enforcement
  /// layer. Call this any time tracked apps or the total limit change.
  Future<void> syncMonitoredApps(
    List<TrackedApp> apps,
    AppSettings settings,
  ) async {
    await _channel.invokeMethod('syncMonitoredApps', {
      'apps': apps.map((a) => a.toMap()).toList(),
      'totalDailyLimitMinutes': settings.totalDailyLimitMinutes,
      'totalWarnBeforeMinutes': settings.warnBeforeMinutes,
      'blockMessage': settings.blockMessage,
    });
  }

  /// Android: live minutes-used-today per package, read straight from
  /// UsageStatsManager.
  /// iOS: Apple does not expose per-app usage minutes to third-party code at
  /// all (only "a threshold was crossed" events reach our extension), so this
  /// returns whatever coarse data the extension persisted, which may be
  /// empty. The Home screen adapts its wording for this on iOS.
  Future<UsageSnapshot> getTodayUsage() async {
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('getTodayUsage');
    if (result == null) return UsageSnapshot.empty;
    return UsageSnapshot.fromMap(Map<String, dynamic>.from(result));
  }

  /// Checks whether the native side flagged a block since we last asked
  /// (e.g. set when the accessibility service detects the total daily limit
  /// was crossed and sends the user Home). Consuming it clears the flag.
  Future<String?> consumePendingBlockReason() async {
    return _channel.invokeMethod<String>('consumePendingBlockReason');
  }

  /// Called once the user has retyped their personal message correctly.
  /// Clears the native block flag and starts the re-block cooldown.
  Future<void> acknowledgeBlock() async {
    await _channel.invokeMethod('acknowledgeBlock');
  }
}
