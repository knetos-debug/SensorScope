import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../features/dashboard/data/sensor_controller.dart';

class SparklineChart extends StatelessWidget {
  const SparklineChart({
    super.key,
    required this.points,
  });

  final List<SparklinePoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return Container(
        height: 60,
        alignment: Alignment.centerLeft,
        child: Text(
          'Awaiting samples…',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }

    final spots = points
        .map((point) => FlSpot(
              point.timestamp.millisecondsSinceEpoch.toDouble(),
              point.value,
            ))
        .toList();
    final minX = spots.first.x;
    final maxX = spots.last.x;
    final minY = spots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 80,
      child: LineChart(
        LineChartData(
          titlesData: const FlTitlesData(show: false),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          minX: minX,
          maxX: maxX,
          minY: minY,
          maxY: maxY == minY ? minY + 1 : maxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Theme.of(context).colorScheme.tertiary,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Theme.of(context).colorScheme.tertiary.withOpacity(0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
