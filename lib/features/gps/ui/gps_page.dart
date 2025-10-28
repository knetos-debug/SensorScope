import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/gps_tracker.dart';

class GpsPage extends ConsumerStatefulWidget {
  const GpsPage({super.key});

  static const routeName = 'gps';

  @override
  ConsumerState<GpsPage> createState() => _GpsPageState();
}

class _GpsPageState extends ConsumerState<GpsPage> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      ref.read(gpsTrackerProvider.notifier).initialize();
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gpsTrackerProvider);
    final position = state.position;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'GPS Status',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            if (position == null)
              Text(state.status)
            else ...[
              _InfoRow(label: 'Latitude', value: position.latitude.toStringAsFixed(6)),
              _InfoRow(label: 'Longitude', value: position.longitude.toStringAsFixed(6)),
              _InfoRow(label: 'Altitude', value: '${position.altitude.toStringAsFixed(1)} m'),
              _InfoRow(label: 'Speed', value: '${position.speed.toStringAsFixed(2)} m/s'),
              _InfoRow(label: 'Accuracy', value: '${position.accuracy.toStringAsFixed(1)} m'),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
          ),
        ],
      ),
    );
  }
}
