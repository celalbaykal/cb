import 'package:flutter/material.dart';

import '../app.dart';
import '../models/installed_app.dart';
import '../models/tracked_app.dart';

/// Set (or edit) the daily limit and warning threshold for one tracked app.
/// Used both right after picking a new app and when tapping an existing one.
class EditAppLimitScreen extends StatefulWidget {
  final InstalledApp? newApp;
  final TrackedApp? existing;

  const EditAppLimitScreen({super.key, this.newApp, this.existing})
      : assert(newApp != null || existing != null);

  @override
  State<EditAppLimitScreen> createState() => _EditAppLimitScreenState();
}

class _EditAppLimitScreenState extends State<EditAppLimitScreen> {
  late double _limitMinutes;
  late double _warnMinutes;

  @override
  void initState() {
    super.initState();
    _limitMinutes = (widget.existing?.dailyLimitMinutes ?? 30).toDouble();
    _warnMinutes = (widget.existing?.warnBeforeMinutes ?? 5).toDouble();
  }

  String get _displayName => widget.existing?.displayName ?? widget.newApp!.displayName;
  String get _packageId => widget.existing?.packageId ?? widget.newApp!.packageId;

  @override
  Widget build(BuildContext context) {
    final monitor = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(_displayName)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Daily limit', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('${_limitMinutes.round()} minutes a day', style: Theme.of(context).textTheme.headlineSmall),
            Slider(
              value: _limitMinutes,
              min: 5,
              max: 300,
              divisions: 59,
              label: '${_limitMinutes.round()}m',
              onChanged: (v) => setState(() => _limitMinutes = v),
            ),
            const SizedBox(height: 24),
            Text('Warn me before', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('${_warnMinutes.round()} minutes left', style: Theme.of(context).textTheme.headlineSmall),
            Slider(
              value: _warnMinutes,
              min: 1,
              max: 30,
              divisions: 29,
              label: '${_warnMinutes.round()}m',
              onChanged: (v) => setState(() => _warnMinutes = v),
            ),
            const Spacer(),
            FilledButton(
              onPressed: () async {
                await monitor.upsertTrackedApp(TrackedApp(
                  packageId: _packageId,
                  displayName: _displayName,
                  dailyLimitMinutes: _limitMinutes.round(),
                  warnBeforeMinutes: _warnMinutes.round(),
                ));
                if (context.mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
