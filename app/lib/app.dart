import 'package:flutter/material.dart';

import 'screens/block_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/limit_monitor.dart';
import 'services/platform_bridge.dart';
import 'theme/app_theme.dart';

/// Exposes the single app-wide [LimitMonitor] to every screen without
/// threading it through constructors.
class AppScope extends InheritedNotifier<LimitMonitor> {
  const AppScope({super.key, required LimitMonitor monitor, required super.child})
      : super(notifier: monitor);

  static LimitMonitor of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found above this context');
    return scope!.notifier!;
  }
}

class ScreenGuardApp extends StatefulWidget {
  const ScreenGuardApp({super.key});

  @override
  State<ScreenGuardApp> createState() => _ScreenGuardAppState();
}

class _ScreenGuardAppState extends State<ScreenGuardApp> with WidgetsBindingObserver {
  final LimitMonitor _monitor = LimitMonitor();
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  bool _ready = false;
  bool _hasPermissions = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _monitor.load();
    final granted = await _checkPermissions();
    if (!mounted) return;
    setState(() {
      _hasPermissions = granted;
      _ready = true;
    });
    if (granted) {
      _monitor.startPolling();
      _checkPendingBlock();
    }
  }

  Future<bool> _checkPermissions() async {
    final hasUsage = await PlatformBridge.instance.hasUsagePermission();
    final hasAccessibility = await PlatformBridge.instance.hasAccessibilityPermission();
    return hasUsage && hasAccessibility;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _hasPermissions) {
      _monitor.refreshUsage();
      _checkPendingBlock();
    }
  }

  Future<void> _checkPendingBlock() async {
    final reason = await _monitor.checkPendingBlock();
    if (reason != null && _navigatorKey.currentState != null) {
      _navigatorKey.currentState!.push(MaterialPageRoute(
        builder: (_) => BlockScreen(reason: reason),
        fullscreenDialog: true,
      ));
    }
  }

  void onPermissionsGranted() {
    setState(() => _hasPermissions = true);
    _monitor.startPolling();
    _checkPendingBlock();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _monitor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      monitor: _monitor,
      child: MaterialApp(
        title: 'ScreenGuard',
        debugShowCheckedModeBanner: false,
        navigatorKey: _navigatorKey,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        home: !_ready
            ? const _SplashScreen()
            : _hasPermissions
                ? const HomeScreen()
                : OnboardingScreen(onFinished: onPermissionsGranted),
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
