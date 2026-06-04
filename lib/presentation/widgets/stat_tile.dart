import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'app_card.dart';

/// A compact metric tile: big value, small label, optional icon + accent.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.accent,
    this.caption,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? accent;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? context.colors.primary;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 12),
          ],
          Text(
            value,
            style: context.text.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: context.text.bodySmall
                ?.copyWith(color: context.extras.textSecondary),
          ),
          if (caption != null) ...[
            const SizedBox(height: 2),
            Text(
              caption!,
              style: context.text.labelSmall?.copyWith(color: color),
            ),
          ],
        ],
      ),
    );
  }
}
