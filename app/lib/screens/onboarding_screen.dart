import 'package:flutter/material.dart';

import '../services/platform_bridge.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinished;

  const OnboardingScreen({super.key, required this.onFinished});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with WidgetsBindingObserver {
  final _bridge = PlatformBridge.instance;
  bool _usageGranted = false;
  bool _accessibilityGranted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshStatus();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    final usage = await _bridge.hasUsagePermission();
    final accessibility = await _bridge.hasAccessibilityPermission();
    if (!mounted) return;
    setState(() {
      _usageGranted = usage;
      _accessibilityGranted = accessibility;
    });
    if (_usageGranted && _accessibilityGranted) {
      widget.onFinished();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Icon(Icons.hourglass_bottom_rounded, size: 48, color: scheme.primary),
              const SizedBox(height: 20),
              Text(
                'Two permissions to get started',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'ScreenGuard needs these to see your app usage and to be able to '
                'step in — send you home or show your reminder — once you hit a limit '
                'you set. Nothing leaves your phone.',
                style: TextStyle(color: scheme.onSurfaceVariant, height: 1.4),
              ),
              const SizedBox(height: 32),
              _PermissionStep(
                title: 'Usage access',
                description: 'Lets the app read how long you\'ve used each app today.',
                granted: _usageGranted,
                onTap: () => _bridge.requestUsagePermission(),
              ),
              const SizedBox(height: 16),
              _PermissionStep(
                title: 'Accessibility service',
                description:
                    'Lets the app notice which app is open right now, so it can act '
                    'the moment a limit is reached — this runs entirely on your device.',
                granted: _accessibilityGranted,
                onTap: () => _bridge.openAccessibilitySettings(),
              ),
              const Spacer(),
              Center(
                child: TextButton(
                  onPressed: _refreshStatus,
                  child: const Text('I\'ve granted these — check again'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionStep extends StatelessWidget {
  final String title;
  final String description;
  final bool granted;
  final VoidCallback onTap;

  const _PermissionStep({
    required this.title,
    required this.description,
    required this.granted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(
          granted ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
          color: granted ? scheme.primary : scheme.outline,
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(description, style: TextStyle(color: scheme.onSurfaceVariant)),
        ),
        trailing: granted ? null : FilledButton(onPressed: onTap, child: const Text('Grant')),
      ),
    );
  }
}
