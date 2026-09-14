import 'package:flutter/material.dart';

class TotalTimeCard extends StatelessWidget {
  final int usedMinutes;
  final int limitMinutes;

  const TotalTimeCard({
    super.key,
    required this.usedMinutes,
    required this.limitMinutes,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ratio = limitMinutes <= 0 ? 0.0 : (usedMinutes / limitMinutes).clamp(0.0, 1.0);
    final overLimit = limitMinutes > 0 && usedMinutes >= limitMinutes;
    final hours = usedMinutes ~/ 60;
    final minutes = usedMinutes % 60;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TODAY',
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m',
                  style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                    color: overLimit ? scheme.error : scheme.onSurface,
                  ),
                ),
                if (limitMinutes > 0) ...[
                  const SizedBox(width: 8),
                  Text(
                    'of ${limitMinutes ~/ 60}h ${limitMinutes % 60}m',
                    style: TextStyle(fontSize: 16, color: scheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: limitMinutes > 0 ? ratio : 0,
                minHeight: 10,
                backgroundColor: scheme.surfaceContainerHighest,
                color: overLimit ? scheme.error : scheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
