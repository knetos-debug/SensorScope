import 'dart:ui';

import 'package:flutter/material.dart';

import '../data/sensor_controller.dart';
import '../../../widgets/sparkline_chart.dart';

class SensorCard extends StatelessWidget {
  const SensorCard({
    super.key,
    required this.reading,
    required this.onToggle,
  });

  final SensorReading reading;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reading.title,
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        reading.unit,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: reading.enabled,
                  onChanged: onToggle,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (reading.axes.isEmpty)
              Text(
                reading.status ?? 'No data',
                style: theme.textTheme.bodySmall,
              )
            else
              Wrap(
                spacing: 24,
                runSpacing: 8,
                children: reading.axes
                    .map(
                      (axis) => _AxisValueTile(
                        label: axis.label,
                        value: axis.value,
                      ),
                    )
                    .toList(),
              ),
            const SizedBox(height: 12),
            SparklineChart(points: reading.history),
            if (reading.status != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  reading.status!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.tertiary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AxisValueTile extends StatelessWidget {
  const _AxisValueTile({
    required this.label,
    required this.value,
  });

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelSmall),
        Text(
          value.toStringAsFixed(3),
          style: theme.textTheme.bodyLarge?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}
