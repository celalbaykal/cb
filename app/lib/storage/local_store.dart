import 'package:hive_flutter/hive_flutter.dart';

import '../models/app_settings.dart';
import '../models/tracked_app.dart';

/// All persistence for the app. Everything lives on-device in Hive boxes —
/// there is no backend. Kept behind this one class so a future sync layer
/// could wrap or replace it without touching call sites.
class LocalStore {
  LocalStore._();
  static final LocalStore instance = LocalStore._();

  static const _settingsBoxName = 'settings';
  static const _trackedAppsBoxName = 'tracked_apps';
  static const _settingsKey = 'settings';

  late Box _settingsBox;
  late Box _trackedAppsBox;

  Future<void> init() async {
    await Hive.initFlutter();
    _settingsBox = await Hive.openBox(_settingsBoxName);
    _trackedAppsBox = await Hive.openBox(_trackedAppsBoxName);
  }

  AppSettings getSettings() {
    final raw = _settingsBox.get(_settingsKey);
    if (raw == null) return const AppSettings();
    return AppSettings.fromMap(Map<String, dynamic>.from(raw as Map));
  }

  Future<void> saveSettings(AppSettings settings) {
    return _settingsBox.put(_settingsKey, settings.toMap());
  }

  List<TrackedApp> getTrackedApps() {
    return _trackedAppsBox.values
        .map((raw) => TrackedApp.fromMap(Map<String, dynamic>.from(raw as Map)))
        .toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
  }

  Future<void> upsertTrackedApp(TrackedApp app) {
    return _trackedAppsBox.put(app.packageId, app.toMap());
  }

  Future<void> removeTrackedApp(String packageId) {
    return _trackedAppsBox.delete(packageId);
  }

  /// Timestamp (per-day key) of the last time the block screen was
  /// acknowledged, used to enforce the re-block cooldown.
  DateTime? getLastUnblockTime() {
    final millis = _settingsBox.get('lastUnblockMillis') as int?;
    if (millis == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  Future<void> setLastUnblockTime(DateTime time) {
    return _settingsBox.put('lastUnblockMillis', time.millisecondsSinceEpoch);
  }
}
