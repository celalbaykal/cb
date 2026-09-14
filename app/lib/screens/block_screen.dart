import 'package:flutter/material.dart';

import '../app.dart';

/// Shown full-screen once the total daily limit is crossed. The only way
/// through is retyping the user's own message back exactly — the retyping
/// is the point, not just a gate, so there is no "skip" or back button.
class BlockScreen extends StatefulWidget {
  final String reason;

  const BlockScreen({super.key, required this.reason});

  @override
  State<BlockScreen> createState() => _BlockScreenState();
}

class _BlockScreenState extends State<BlockScreen> {
  final _controller = TextEditingController();
  bool _matches = false;

  void _onChanged(String value, String target) {
    setState(() => _matches = value.trim() == target.trim());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final monitor = AppScope.of(context);
    final message = monitor.settings.blockMessage;
    final scheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: scheme.surface,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.hourglass_bottom_rounded, size: 40, color: scheme.error),
                const SizedBox(height: 20),
                Text(
                  "You've hit today's limit",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    message,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.4),
                  ),
                ),
                const SizedBox(height: 28),
                Text('Type it back to continue', style: TextStyle(color: scheme.onSurfaceVariant)),
                const SizedBox(height: 8),
                TextField(
                  controller: _controller,
                  maxLines: 3,
                  onChanged: (v) => _onChanged(v, message),
                  decoration: const InputDecoration(hintText: 'Retype the message above'),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _matches
                        ? () async {
                            await monitor.acknowledgeBlock();
                            if (context.mounted) Navigator.of(context).pop();
                          }
                        : null,
                    child: const Text('Continue'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
