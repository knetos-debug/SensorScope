import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ble_scanner.dart';

class BlePage extends ConsumerStatefulWidget {
  const BlePage({super.key});

  static const routeName = 'ble';

  @override
  ConsumerState<BlePage> createState() => _BlePageState();
}

class _BlePageState extends ConsumerState<BlePage> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      ref.read(bleScannerProvider.notifier).initialize();
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bleScannerProvider);
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Bluetooth Low Energy',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  onPressed: state.isScanning
                      ? null
                      : () => ref.read(bleScannerProvider.notifier).refresh(),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                state.error!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
            ),
          Expanded(
            child: ListView.separated(
              itemCount: state.devices.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final device = state.devices[index];
                return ListTile(
                  leading: const Icon(Icons.bluetooth),
                  title: Text(device.name),
                  subtitle: Text(device.id),
                  trailing: Text('${device.rssi} dBm'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
