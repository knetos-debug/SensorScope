import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/permissions.dart';

class GpsState {
  const GpsState({
    this.position,
    this.status = 'Awaiting fix',
  });

  final Position? position;
  final String status;

  GpsState copyWith({
    Position? position,
    String? status,
  }) {
    return GpsState(
      position: position ?? this.position,
      status: status ?? this.status,
    );
  }
}

class GpsTracker extends StateNotifier<GpsState> {
  GpsTracker() : super(const GpsState());

  StreamSubscription<Position>? _subscription;

  Future<void> initialize() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      state = state.copyWith(status: 'Location services disabled');
      return;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      state = state.copyWith(status: 'Location permission denied');
      return;
    }
    await permissionController.ensureLocation();
    _subscription ??= Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 1,
      ),
    ).listen((position) {
      state = GpsState(position: position, status: 'Tracking');
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final gpsTrackerProvider =
    StateNotifierProvider<GpsTracker, GpsState>((ref) {
  final tracker = GpsTracker();
  ref.onDispose(tracker.dispose);
  return tracker;
});
