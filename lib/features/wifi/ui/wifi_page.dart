import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/wifi_scanner.dart';

class WifiPage extends ConsumerStatefulWidget {
  const WifiPage({super.key});

  static const routeName = 'wifi';

  @override
  ConsumerState<WifiPage> createState() => _WifiPageState();
}

class _WifiPageState extends ConsumerState<WifiPage> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      ref.read(wifiScannerProvider.notifier).initialize();
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wifiScannerProvider);
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Wi-Fi Networks',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  onPressed: state.isScanning
                      ? null
                      : () => ref.read(wifiScannerProvider.notifier).refresh(),
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
              itemCount: state.networks.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final network = state.networks[index];
                return ListTile(
                  title: Text(network.ssid.isEmpty ? '<Hidden SSID>' : network.ssid),
                  subtitle: Text('RSSI ${network.rssi} dBm • CH ${network.channel} • ${network.frequency} MHz'),
                  trailing: Text('${network.rssi} dBm'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
