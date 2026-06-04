import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../domain/entities/analytics.dart';

/// Pie chart of category distribution with a legend.
class CategoryPieChart extends StatelessWidget {
  const CategoryPieChart({super.key, required this.totals});

  final List<CategoryTotal> totals;

  @override
  Widget build(BuildContext context) {
    final grand = totals.fold<int>(0, (s, e) => s + e.count);
    if (grand == 0) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 44,
              sections: [
                for (final t in totals)
                  PieChartSectionData(
                    value: t.count.toDouble(),
                    color: t.category.color,
                    radius: 46,
                    title: '${(t.count / grand * 100).round()}%',
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            for (final t in totals)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: t.category.color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${t.category.name}  ·  ${Formatters.compact(t.count)}',
                    style: context.text.labelMedium,
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}
