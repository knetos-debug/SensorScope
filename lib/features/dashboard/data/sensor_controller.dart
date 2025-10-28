import 'dart:async';
import 'dart:math';

import 'package:battery_plus/battery_plus.dart';
import 'package:barometer/barometer.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:light_sensor/light_sensor.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../../core/logger.dart';
import '../../../core/permissions.dart';

class SensorReading {
  const SensorReading({
    required this.id,
    required this.title,
    required this.unit,
    required this.axes,
    required this.history,
    required this.enabled,
    this.status,
  });

  final String id;
  final String title;
  final String unit;
  final List<AxisValue> axes;
  final List<SparklinePoint> history;
  final bool enabled;
  final String? status;

  SensorReading copyWith({
    List<AxisValue>? axes,
    List<SparklinePoint>? history,
    bool? enabled,
    String? status,
  }) {
    return SensorReading(
      id: id,
      title: title,
      unit: unit,
      axes: axes ?? this.axes,
      history: history ?? this.history,
      enabled: enabled ?? this.enabled,
      status: status ?? this.status,
    );
  }
}

class AxisValue {
  const AxisValue({
    required this.label,
    required this.value,
  });

  final String label;
  final double value;
}

class SparklinePoint {
  const SparklinePoint(this.timestamp, this.value);

  final DateTime timestamp;
  final double value;
}

class SensorState {
  const SensorState({
    required this.readings,
  });

  final Map<String, SensorReading> readings;

  SensorState copyWithReading(SensorReading reading) {
    final next = Map<String, SensorReading>.from(readings);
    next[reading.id] = reading;
    return SensorState(readings: next);
  }
}

class SensorController extends StateNotifier<SensorState> {
  SensorController(this._logger)
      : super(
          SensorState(
            readings: Map<String, SensorReading>.fromEntries(
              _initialReadings.map(
                (reading) => MapEntry(reading.id, reading),
              ),
            ),
          ),
        );

  final CsvLogger _logger;
  final Map<String, StreamSubscription<dynamic>> _subscriptions = {};
  final Battery _battery = Battery();
  StreamSubscription<Position>? _gpsSubscription;

  Future<void> initialize() async {
    await permissionController.ensureSensors();
    await permissionController.ensureLocation();
    for (final entry in state.readings.entries) {
      if (entry.value.enabled) {
        await startSensor(entry.key);
      }
    }
  }

  SensorReading readingById(String id) {
    return state.readings[id]!;
  }

  Future<void> toggleSensor(String id, bool enabled) async {
    if (enabled) {
      await startSensor(id);
    } else {
      await stopSensor(id);
    }
    state = state.copyWithReading(readingById(id).copyWith(enabled: enabled));
  }

  Future<void> startSensor(String id) async {
    if (_subscriptions.containsKey(id) || id == 'gps' && _gpsSubscription != null) {
      return;
    }
    switch (id) {
      case 'accelerometer':
        _subscriptions[id] = accelerometerEvents.listen((event) {
          _emit(id, {
            'X': event.x,
            'Y': event.y,
            'Z': event.z,
          });
        });
        break;
      case 'gyroscope':
        _subscriptions[id] = gyroscopeEvents.listen((event) {
          _emit(id, {
            'X': event.x,
            'Y': event.y,
            'Z': event.z,
          });
        });
        break;
      case 'magnetometer':
        _subscriptions[id] = magnetometerEvents.listen((event) {
          _emit(id, {
            'X': event.x,
            'Y': event.y,
            'Z': event.z,
          });
        });
        break;
      case 'compass':
        final stream = FlutterCompass.events;
        if (stream == null) {
          _updateStatus(id, 'Compass not available');
          return;
        }
        _subscriptions[id] = stream.listen((event) {
          final heading = event.heading;
          if (heading != null) {
            _emit(id, {'Heading': heading});
          }
        });
        break;
      case 'light':
        _subscriptions[id] = LightSensor.lightSensorStream.listen((lux) {
          _emit(id, {'Lux': lux.toDouble()});
        });
        break;
      case 'barometer':
        _subscriptions[id] = Barometer().pressureStream.listen((event) {
          final dynamic sample = event;
          final value = sample is num
              ? sample.toDouble()
              : (sample?.hectPascal as num?)?.toDouble() ??
                  (sample?.pressure as num?)?.toDouble() ??
                  (sample?.value as num?)?.toDouble() ??
                  0.0;
          _emit(id, {'Pressure': value});
        });
        break;
      case 'battery':
        _subscriptions[id] = Stream.periodic(const Duration(seconds: 5)).asyncMap((_) async {
          final level = await _battery.batteryLevel;
          final status = await _battery.batteryState;
          return (level, status);
        }).listen((event) {
          _emit(
            id,
            {
              'Level %': event.$1.toDouble(),
            },
            status: event.$2.name,
          );
        });
        break;
      case 'gps':
        final permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          final requested = await Geolocator.requestPermission();
          if (requested == LocationPermission.denied ||
              requested == LocationPermission.deniedForever) {
            _updateStatus(id, 'GPS permission denied');
            return;
          }
        }
        _gpsSubscription = Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 1,
          ),
        ).listen((event) {
          _emit(id, {
            'Lat': event.latitude,
            'Lon': event.longitude,
            'Speed m/s': event.speed,
            'Alt m': event.altitude,
          });
        });
        break;
    }
  }

  Future<void> stopSensor(String id) async {
    if (id == 'gps') {
      await _gpsSubscription?.cancel();
      _gpsSubscription = null;
      return;
    }
    final subscription = _subscriptions.remove(id);
    await subscription?.cancel();
  }

  Future<void> disposeAll() async {
    for (final subscription in _subscriptions.values) {
      await subscription.cancel();
    }
    await _gpsSubscription?.cancel();
  }

  void _emit(String id, Map<String, num> numericValues, {String? status}) {
    final previous = readingById(id);
    final axisValues = numericValues.entries
        .map(
          (entry) => AxisValue(
            label: entry.key,
            value: entry.value.toDouble(),
          ),
        )
        .toList(growable: false);
    final magnitude = axisValues.isEmpty
        ? 0
        : sqrt(axisValues
            .map((axis) => axis.value * axis.value)
            .reduce((value, element) => value + element));
    final now = DateTime.now();
    final history = <SparklinePoint>[...previous.history, SparklinePoint(now, magnitude)]
      ..removeWhere((point) => now.difference(point.timestamp).inSeconds > 10);
    final updated = previous.copyWith(
      axes: axisValues,
      history: history,
      status: status ?? previous.status,
    );
    state = state.copyWithReading(updated);
    if (_logger.state.isRecording) {
      final row = <String, dynamic>{
        'timestamp': now.millisecondsSinceEpoch,
      };
      for (final axis in axisValues) {
        row['${previous.title} ${axis.label}'] = axis.value;
      }
      _logger.append(row);
    }
  }

  void _updateStatus(String id, String message) {
    final previous = readingById(id);
    state = state.copyWithReading(previous.copyWith(status: message));
  }
}

final sensorControllerProvider =
    StateNotifierProvider<SensorController, SensorState>((ref) {
  final logger = ref.read(csvLoggerProvider.notifier);
  final controller = SensorController(logger);
  ref.onDispose(controller.disposeAll);
  return controller;
});

final sensorReadingsProvider = Provider<List<SensorReading>>((ref) {
  final state = ref.watch(sensorControllerProvider);
  return state.readings.values.toList(growable: false);
});

final List<SensorReading> _initialReadings = [
  const SensorReading(
    id: 'accelerometer',
    title: 'Accelerometer',
    unit: 'm/s²',
    axes: [],
    history: [],
    enabled: true,
  ),
  const SensorReading(
    id: 'gyroscope',
    title: 'Gyroscope',
    unit: '°/s',
    axes: [],
    history: [],
    enabled: true,
  ),
  const SensorReading(
    id: 'magnetometer',
    title: 'Magnetometer',
    unit: 'µT',
    axes: [],
    history: [],
    enabled: false,
  ),
  const SensorReading(
    id: 'compass',
    title: 'Compass',
    unit: '°',
    axes: [],
    history: [],
    enabled: true,
  ),
  const SensorReading(
    id: 'light',
    title: 'Ambient Light',
    unit: 'lux',
    axes: [],
    history: [],
    enabled: true,
  ),
  const SensorReading(
    id: 'barometer',
    title: 'Barometer',
    unit: 'hPa',
    axes: [],
    history: [],
    enabled: true,
  ),
  const SensorReading(
    id: 'battery',
    title: 'Battery',
    unit: '%',
    axes: [],
    history: [],
    enabled: true,
  ),
  const SensorReading(
    id: 'gps',
    title: 'GPS',
    unit: 'coord',
    axes: [],
    history: [],
    enabled: true,
  ),
];

const Map<String, List<String>> sensorAxisHeaders = {
  'accelerometer': ['X', 'Y', 'Z'],
  'gyroscope': ['X', 'Y', 'Z'],
  'magnetometer': ['X', 'Y', 'Z'],
  'compass': ['Heading'],
  'light': ['Lux'],
  'barometer': ['Pressure'],
  'battery': ['Level %'],
  'gps': ['Lat', 'Lon', 'Speed m/s', 'Alt m'],
};
