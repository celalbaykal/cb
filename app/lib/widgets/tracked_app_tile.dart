import 'package:flutter/material.dart';

import '../models/tracked_app.dart';

class TrackedAppTile extends StatelessWidget {
  final TrackedApp app;
  final int usedMinutes;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const TrackedAppTile({
    super.key,
    required this.app,
    required this.usedMinutes,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final overLimit = usedMinutes >= app.dailyLimitMinutes;
    final ratio = app.dailyLimitMinutes <= 0
        ? 0.0
        : (usedMinutes / app.dailyLimitMinutes).clamp(0.0, 1.0);

    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(app.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: scheme.surfaceContainerHighest,
              color: overLimit ? scheme.error : scheme.primary,
            ),
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${usedMinutes}m / ${app.dailyLimitMinutes}m',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: overLimit ? scheme.error : scheme.onSurfaceVariant,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: onRemove,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}
