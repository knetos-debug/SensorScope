import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dashboard/data/sensor_controller.dart';
import '../../../core/logger.dart';
import '../../../widgets/live_indicator.dart';
import '../../../widgets/record_button.dart';
import 'sensor_card.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  static const routeName = 'dashboard';

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      ref.read(sensorControllerProvider.notifier).initialize();
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final readings = ref.watch(sensorReadingsProvider);
    final logging = ref.watch(csvLoggerProvider);
    final logger = ref.read(csvLoggerProvider.notifier);

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            sliver: SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const LiveIndicator(),
                  RecordButton(
                    isRecording: logging.isRecording,
                    onPressed: () {
                      if (logging.isRecording) {
                        logger.stopLogging();
                      } else {
                        final headers = <String>['timestamp'];
                        for (final reading in readings) {
                          final defaults = sensorAxisHeaders[reading.id] ?? [];
                          if (reading.axes.isEmpty) {
                            for (final axis in defaults) {
                              headers.add('${reading.title} $axis');
                            }
                          } else {
                            for (final axis in reading.axes) {
                              headers.add('${reading.title} ${axis.label}');
                            }
                          }
                        }
                        logger.startLogging(headers);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          SliverList.builder(
            itemBuilder: (context, index) {
              final reading = readings[index];
              return SensorCard(
                reading: reading,
                onToggle: (enabled) {
                  ref
                      .read(sensorControllerProvider.notifier)
                      .toggleSensor(reading.id, enabled);
                },
              );
            },
            itemCount: readings.length,
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}
