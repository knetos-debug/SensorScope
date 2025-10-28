import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/permissions.dart';

class BleDevice {
  const BleDevice({
    required this.id,
    required this.name,
    required this.rssi,
  });

  final String id;
  final String name;
  final int rssi;
}

class BleScannerState {
  const BleScannerState({
    required this.devices,
    this.isScanning = false,
    this.error,
  });

  final List<BleDevice> devices;
  final bool isScanning;
  final String? error;

  BleScannerState copyWith({
    List<BleDevice>? devices,
    bool? isScanning,
    String? error,
  }) {
    return BleScannerState(
      devices: devices ?? this.devices,
      isScanning: isScanning ?? this.isScanning,
      error: error,
    );
  }
}

class BleScanner extends StateNotifier<BleScannerState> {
  BleScanner()
      : super(const BleScannerState(devices: [], isScanning: false));

  StreamSubscription<List<ScanResult>>? _subscription;

  Future<void> initialize() async {
    final granted = await permissionController.ensureBluetooth();
    if (!granted) {
      state = state.copyWith(error: 'Bluetooth permission denied');
      return;
    }
    _subscription ??= FlutterBluePlus.scanResults.listen((results) {
      final devices = results
          .map(
            (result) => BleDevice(
              id: result.device.remoteId.str,
              name: result.device.platformName.isNotEmpty
                  ? result.device.platformName
                  : 'Unknown',
              rssi: result.rssi,
            ),
          )
          .toList(growable: false);
      state = state.copyWith(devices: devices, isScanning: false, error: null);
    });
    await refresh();
  }

  Future<void> refresh() async {
    state = state.copyWith(isScanning: true, error: null);
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
  }

  @override
  void dispose() {
    _subscription?.cancel();
    FlutterBluePlus.stopScan();
    super.dispose();
  }
}

final bleScannerProvider =
    StateNotifierProvider<BleScanner, BleScannerState>((ref) {
  final scanner = BleScanner();
  ref.onDispose(scanner.dispose);
  return scanner;
});
