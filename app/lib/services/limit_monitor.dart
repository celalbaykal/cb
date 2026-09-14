import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_settings.dart';
import '../models/tracked_app.dart';
import '../models/usage_snapshot.dart';
import '../storage/local_store.dart';
import 'platform_bridge.dart';

/// Central, app-wide state: today's usage, the tracked apps, and settings.
/// Screens read from it and call its mutators; it takes care of persisting
/// to [LocalStore] and pushing config down to [PlatformBridge] so native
/// enforcement stays in sync.
class LimitMonitor extends ChangeNotifier {
  final LocalStore _store = LocalStore.instance;
  final PlatformBridge _bridge = PlatformBridge.instance;

  UsageSnapshot usage = UsageSnapshot.empty;
  List<TrackedApp> trackedApps = [];
  AppSettings settings = const AppSettings();

  Timer? _pollTimer;

  Future<void> load() async {
    trackedApps = _store.getTrackedApps();
    settings = _store.getSettings();
    await refreshUsage();
  }

  Future<void> refreshUsage() async {
    usage = await _bridge.getTodayUsage();
    notifyListeners();
  }

  void startPolling({Duration interval = const Duration(seconds: 30)}) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(interval, (_) => refreshUsage());
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> upsertTrackedApp(TrackedApp app) async {
    await _store.upsertTrackedApp(app);
    trackedApps = _store.getTrackedApps();
    notifyListeners();
    await _bridge.syncMonitoredApps(trackedApps, settings);
  }

  Future<void> removeTrackedApp(String packageId) async {
    await _store.removeTrackedApp(packageId);
    trackedApps = _store.getTrackedApps();
    notifyListeners();
    await _bridge.syncMonitoredApps(trackedApps, settings);
  }

  Future<void> updateSettings(AppSettings updated) async {
    settings = updated;
    await _store.saveSettings(updated);
    notifyListeners();
    await _bridge.syncMonitoredApps(trackedApps, settings);
  }

  /// Call on app resume / launch. Returns a reason string ('total' or a
  /// package id) if the native side flagged that a limit was crossed while
  /// this Flutter isolate wasn't in the foreground, so the UI can route to
  /// the block screen.
  Future<String?> checkPendingBlock() {
    return _bridge.consumePendingBlockReason();
  }

  Future<void> acknowledgeBlock() async {
    await _bridge.acknowledgeBlock();
    await _store.setLastUnblockTime(DateTime.now());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
