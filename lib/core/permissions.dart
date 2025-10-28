import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionController {
  Future<bool> ensureLocation() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  Future<bool> ensureBluetooth() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final scanStatus = await Permission.bluetoothScan.request();
      final connectStatus = await Permission.bluetoothConnect.request();
      return scanStatus.isGranted && connectStatus.isGranted;
    }
    return true;
  }

  Future<bool> ensureWifi() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.locationWhenInUse.request();
      return status.isGranted;
    }
    return true;
  }

  Future<bool> ensureSensors() async {
    final statuses = await <Permission>[
      Permission.activityRecognition,
      Permission.sensors,
    ].request();
    return statuses.values.every((status) => status.isGranted);
  }
}

final permissionController = PermissionController();
