import 'package:flutter/material.dart';

import '../app.dart';
import '../models/installed_app.dart';
import '../models/tracked_app.dart';
import '../services/platform_bridge.dart';
import 'edit_app_limit_screen.dart';

/// Add a new app to track. Android lets you search the apps actually
/// installed on the device (there is no privacy barrier there). iOS has no
/// such list available to third-party apps at all — instead the user picks
/// apps/categories through Apple's own FamilyActivityPicker, and Apple never
/// reveals which ones were chosen back to our code, so we treat the whole
/// selection as one shared limit rather than pretending to show named apps.
class ManageAppsScreen extends StatefulWidget {
  const ManageAppsScreen({super.key});

  @override
  State<ManageAppsScreen> createState() => _ManageAppsScreenState();
}

class _ManageAppsScreenState extends State<ManageAppsScreen> {
  final _bridge = PlatformBridge.instance;
  List<InstalledApp> _installed = [];
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    if (_bridge.isAndroid) _loadInstalled();
  }

  Future<void> _loadInstalled() async {
    final apps = await _bridge.getInstalledApps();
    if (!mounted) return;
    setState(() {
      _installed = apps;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_bridge.isIOS) return _buildIOS(context);
    return _buildAndroid(context);
  }

  Widget _buildAndroid(BuildContext context) {
    final monitor = AppScope.of(context);
    final trackedIds = monitor.trackedApps.map((a) => a.packageId).toSet();
    final visible = _installed
        .where((a) => !trackedIds.contains(a.packageId))
        .where((a) => a.displayName.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Add an app')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search installed apps',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : visible.isEmpty
                    ? const Center(child: Text('No matching apps'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: visible.length,
                        itemBuilder: (context, index) {
                          final app = visible[index];
                          return ListTile(
                            title: Text(app.displayName),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => EditAppLimitScreen(newApp: app),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildIOS(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Choose apps to limit')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.apps_rounded, size: 40, color: scheme.primary),
            const SizedBox(height: 16),
            Text(
              "iOS only lets you pick apps through Apple's own picker, and it "
              "keeps which ones you chose private from every app, including "
              "this one — so all apps you select here share one daily limit.",
              style: TextStyle(color: scheme.onSurfaceVariant, height: 1.4),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () async {
                await _bridge.pickMonitoredAppsOnIOS();
                if (!context.mounted) return;
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const EditAppLimitScreen(
                    newApp: InstalledApp(packageId: 'ios_selection', displayName: 'Selected apps'),
                  ),
                ));
              },
              icon: const Icon(Icons.apps_rounded),
              label: const Text('Open Apple\'s app picker'),
            ),
          ],
        ),
      ),
    );
  }
}
