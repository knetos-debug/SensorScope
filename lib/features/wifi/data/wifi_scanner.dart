import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wifi_scan/wifi_scan.dart';

import '../../../core/permissions.dart';

class WifiNetwork {
  const WifiNetwork({
    required this.ssid,
    required this.bssid,
    required this.rssi,
    required this.channel,
    required this.frequency,
  });

  final String ssid;
  final String bssid;
  final int rssi;
  final int channel;
  final int frequency;
}

class WifiScannerState {
  const WifiScannerState({
    required this.networks,
    this.isScanning = false,
    this.error,
  });

  final List<WifiNetwork> networks;
  final bool isScanning;
  final String? error;

  WifiScannerState copyWith({
    List<WifiNetwork>? networks,
    bool? isScanning,
    String? error,
  }) {
    return WifiScannerState(
      networks: networks ?? this.networks,
      isScanning: isScanning ?? this.isScanning,
      error: error,
    );
  }
}

class WifiScanner extends StateNotifier<WifiScannerState> {
  WifiScanner()
      : super(const WifiScannerState(networks: [], isScanning: false));

  StreamSubscription<List<WiFiScanResult>>? _subscription;

  Future<void> initialize() async {
    final granted = await permissionController.ensureWifi();
    if (!granted) {
      state = state.copyWith(error: 'Wi-Fi permission denied');
      return;
    }
    _subscription ??= WiFiScan.instance.onScannedResultsAvailable.listen(
      (results) {
        final mapped = results
            .map(
              (result) => WifiNetwork(
                ssid: result.ssid,
                bssid: result.bssid,
                rssi: result.level,
                channel: result.channel,
                frequency: result.frequency,
              ),
            )
            .toList(growable: false);
        state = state.copyWith(networks: mapped, isScanning: false, error: null);
      },
    );
    await refresh();
  }

  Future<void> refresh() async {
    state = state.copyWith(isScanning: true, error: null);
    final canScan = await WiFiScan.instance.canStartScan();
    if (canScan != CanStartScan.yes) {
      state = state.copyWith(
        isScanning: false,
        error: 'Scan throttled by platform (${canScan.name})',
      );
      return;
    }
    await WiFiScan.instance.startScan();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final wifiScannerProvider =
    StateNotifierProvider<WifiScanner, WifiScannerState>((ref) {
  final scanner = WifiScanner();
  ref.onDispose(scanner.dispose);
  return scanner;
});
