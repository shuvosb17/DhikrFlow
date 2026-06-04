import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_helpers.dart';
import '../../../../domain/entities/analytics.dart';

/// Bar chart of daily counts for the last 7 days.
class WeeklyBarChart extends StatelessWidget {
  const WeeklyBarChart({super.key, required this.data});

  final List<DayCount> data;

  @override
  Widget build(BuildContext context) {
    final maxY = data.fold<int>(0, (m, e) => e.count > m ? e.count : m);
    final top = (maxY <= 0 ? 10 : maxY * 1.25).toDouble();
    final primary = context.colors.primary;

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: top,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => context.colors.onSurface,
              getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                '${rod.toY.round()}',
                TextStyle(
                  color: context.colors.surface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: top / 4,
            getDrawingHorizontalLine: (_) => FlLine(
              color: context.extras.textSecondary.withValues(alpha: 0.12),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                interval: top / 4,
                getTitlesWidget: (value, _) => Text(
                  value.round().toString(),
                  style: context.text.labelSmall
                      ?.copyWith(color: context.extras.textSecondary),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, _) {
                  final i = value.toInt();
                  if (i < 0 || i >= data.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      DateHelpers.shortDayLabel(data[i].date),
                      style: context.text.labelSmall,
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < data.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: data[i].count.toDouble(),
                    width: 18,
                    color: DateHelpers.isToday(data[i].date)
                        ? primary
                        : primary.withValues(alpha: 0.45),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6)),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
