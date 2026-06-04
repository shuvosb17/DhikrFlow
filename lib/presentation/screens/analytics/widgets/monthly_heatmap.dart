import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_helpers.dart';
import '../../../../domain/entities/analytics.dart';

/// A GitHub-style activity heatmap for a single month.
class MonthlyHeatmap extends StatelessWidget {
  const MonthlyHeatmap({
    super.key,
    required this.month,
    required this.dailyCounts,
  });

  final DateTime month;
  final List<DayCount> dailyCounts;

  @override
  Widget build(BuildContext context) {
    final maxCount =
        dailyCounts.fold<int>(0, (m, e) => e.count > m ? e.count : m);
    final base = context.colors.primary;

    // Leading empty cells so the 1st lands on the right weekday column.
    final firstWeekday = DateTime(month.year, month.month, 1).weekday; // 1=Mon
    final leading = firstWeekday - 1;

    final cells = <Widget>[];
    for (var i = 0; i < leading; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (final dc in dailyCounts) {
      final intensity = maxCount == 0 ? 0.0 : dc.count / maxCount;
      final color = dc.count == 0
          ? context.extras.surfaceAlt
          : base.withValues(alpha: 0.25 + intensity * 0.75);
      cells.add(
        Tooltip(
          message: '${DateHelpers.readable(dc.date)}: ${dc.count}',
          child: AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Text(
                '${dc.date.day}',
                style: context.text.labelSmall?.copyWith(
                  color: intensity > 0.5
                      ? Colors.white
                      : context.extras.textSecondary,
                  fontSize: 10,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const ['M', 'T', 'W', 'T', 'F', 'S', 'S']
              .map((d) => Expanded(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 6),
                        child: Text(d, style: TextStyle(fontSize: 11)),
                      ),
                    ),
                  ))
              .toList(),
        ),
        GridView.count(
          crossAxisCount: 7,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: cells,
        ),
      ],
    );
  }
}
