import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';

class WeeklyBlockedChartCard extends StatelessWidget {
  final List<int> countsMonToSun;

  const WeeklyBlockedChartCard({
    super.key,
    required this.countsMonToSun,
  }) : assert(countsMonToSun.length == 7);

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isDark = context.isDarkTheme;
    final interruptions = countsMonToSun.fold<int>(0, (sum, value) => sum + value);
    final protectedHours = ((interruptions * 1.25) / 60).round();

    return Container(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppShadows.soft(isDark),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This week you avoided $interruptions interruptions.',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: tokens.textPrimary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'During your Quiet Hours.',
            style: AppTypography.secondaryBody.copyWith(
              color: tokens.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: WeeklyBlockedChart(counts: countsMonToSun),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: tokens.secondarySurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: tokens.outline),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Text(
              'You protected $protectedHours hours of personal time this week.',
              style: AppTypography.secondaryBodyStrong.copyWith(
                color: tokens.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WeeklyBlockedChart extends StatelessWidget {
  final List<int> counts;

  const WeeklyBlockedChart({
    super.key,
    required this.counts,
  }) : assert(counts.length == 7);

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    const lineColor = Color(0xFF9DB233);
    final axisColor = context.isDarkTheme
        ? tokens.textSecondary.withOpacity(0.9)
        : const Color(0xFF9A9A9A);
    final gridColor = context.isDarkTheme
        ? tokens.divider.withOpacity(0.8)
        : const Color(0xFFE9E9E9);
    final maxValue = counts.isEmpty ? 0 : counts.reduce(max);
    final maxY = max(4, maxValue).toDouble() + 1;

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: 6,
        minY: 0,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) => FlLine(
            color: gridColor,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              reservedSize: 28,
              getTitlesWidget: (v, meta) {
                if (v % 1 != 0) return const SizedBox.shrink();
                return Text(
                  v.toInt().toString(),
                  style: TextStyle(fontSize: 12, color: axisColor),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (v, meta) {
                const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                final i = v.toInt();
                if (i < 0 || i > 6) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    labels[i],
                    style: TextStyle(fontSize: 12, color: axisColor),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            color: lineColor,
            barWidth: 4,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: lineColor.withOpacity(0.12),
            ),
            spots: List.generate(
              7,
              (i) => FlSpot(i.toDouble(), counts[i].toDouble()),
            ),
          ),
        ],
      ),
    );
  }
}
