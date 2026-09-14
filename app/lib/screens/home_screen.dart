import 'package:flutter/material.dart';

import '../app.dart';
import '../services/platform_bridge.dart';
import '../widgets/ad_banner.dart';
import '../widgets/total_time_card.dart';
import '../widgets/tracked_app_tile.dart';
import 'edit_app_limit_screen.dart';
import 'manage_apps_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final monitor = AppScope.of(context);
    final isIOS = PlatformBridge.instance.isIOS;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ScreenGuard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: monitor,
        builder: (context, _) {
          return RefreshIndicator(
            onRefresh: monitor.refreshUsage,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                TotalTimeCard(
                  usedMinutes: monitor.usage.totalMinutes,
                  limitMinutes: monitor.settings.totalDailyLimitMinutes,
                ),
                if (isIOS) ...[
                  const SizedBox(height: 12),
                  Text(
                    "Apple doesn't allow apps to read exact usage minutes — your "
                    'limits below still enforce automatically, this total is best-effort.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Tracked apps', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ManageAppsScreen()),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Add'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (monitor.trackedApps.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'No apps tracked yet. Add one to set a daily limit for it.',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  )
                else
                  ...monitor.trackedApps.map(
                    (app) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TrackedAppTile(
                        app: app,
                        usedMinutes: monitor.usage.minutesByPackage[app.packageId] ?? 0,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => EditAppLimitScreen(existing: app),
                          ),
                        ),
                        onRemove: () => monitor.removeTrackedApp(app.packageId),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                const Center(child: AdBanner()),
              ],
            ),
          );
        },
      ),
    );
  }
}
