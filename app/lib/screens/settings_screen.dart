import 'package:flutter/material.dart';

import '../app.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late double _totalLimit;
  late double _warnBefore;
  late TextEditingController _messageController;

  @override
  void initState() {
    super.initState();
    final settings = AppScope.of(context).settings;
    _totalLimit = settings.totalDailyLimitMinutes.toDouble();
    _warnBefore = settings.warnBeforeMinutes.toDouble();
    _messageController = TextEditingController(text: settings.blockMessage);
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final monitor = AppScope.of(context);
    await monitor.updateSettings(monitor.settings.copyWith(
      totalDailyLimitMinutes: _totalLimit.round(),
      warnBeforeMinutes: _warnBefore.round(),
      blockMessage: _messageController.text.trim().isEmpty
          ? monitor.settings.blockMessage
          : _messageController.text.trim(),
    ));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [TextButton(onPressed: _save, child: const Text('Save'))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Total daily limit', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          Text('${(_totalLimit ~/ 60)}h ${(_totalLimit % 60).round()}m a day',
              style: Theme.of(context).textTheme.headlineSmall),
          Slider(
            value: _totalLimit,
            min: 15,
            max: 480,
            divisions: 31,
            label: '${_totalLimit.round()}m',
            onChanged: (v) => setState(() => _totalLimit = v),
          ),
          const SizedBox(height: 16),
          Text('Warn me before', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          Text('${_warnBefore.round()} minutes left', style: Theme.of(context).textTheme.headlineSmall),
          Slider(
            value: _warnBefore,
            min: 1,
            max: 30,
            divisions: 29,
            label: '${_warnBefore.round()}m',
            onChanged: (v) => setState(() => _warnBefore = v),
          ),
          const SizedBox(height: 24),
          Text('Your message to yourself', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            "Shown full-screen once you hit your total daily limit. You'll need "
            "to retype it exactly to keep using your phone — that's the point.",
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _messageController,
            maxLines: 3,
            maxLength: 140,
            decoration: const InputDecoration(hintText: 'e.g. Put the phone down and go for a walk.'),
          ),
        ],
      ),
    );
  }
}
