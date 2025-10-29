import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/incident.dart';

final _random = Random();

class SecurityState {
  const SecurityState({
    this.incidents = const <Incident>[],
    this.filter,
    this.isRunning = false,
  });

  final List<Incident> incidents;
  final IncidentSeverity? filter;
  final bool isRunning;

  List<Incident> get visibleIncidents {
    final sorted = List<Incident>.from(incidents)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    if (filter == null) {
      return sorted;
    }
    return sorted.where((incident) => incident.severity == filter).toList();
  }

  SecurityState copyWith({
    List<Incident>? incidents,
    IncidentSeverity? filter,
    bool filterSpecified = false,
    bool? isRunning,
  }) {
    return SecurityState(
      incidents: incidents ?? this.incidents,
      filter: filterSpecified ? filter : this.filter,
      isRunning: isRunning ?? this.isRunning,
    );
  }
}

class SecurityController extends StateNotifier<SecurityState> {
  SecurityController() : super(const SecurityState());

  void addIncident({
    required String type,
    required IncidentSeverity severity,
    required String message,
    Map<String, dynamic> details = const <String, dynamic>{},
    String? recommendation,
  }) {
    final incident = Incident(
      id: _generateId(),
      type: type,
      severity: severity,
      message: message,
      details: details,
      timestamp: DateTime.now(),
      recommendation: recommendation,
    );
    state = state.copyWith(
      incidents: List<Incident>.from(state.incidents)..add(incident),
    );
  }

  void clearIncidents() {
    state = state.copyWith(incidents: <Incident>[]);
  }

  void setFilter(IncidentSeverity? severity) {
    state = state.copyWith(filter: severity, filterSpecified: true);
  }

  Future<void> runChecks() async {
    if (state.isRunning) {
      return;
    }
    state = state.copyWith(isRunning: true);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    state = state.copyWith(isRunning: false);
  }
}

final securityControllerProvider =
    StateNotifierProvider<SecurityController, SecurityState>(
  (ref) => SecurityController(),
);

String _generateId() {
  final timestamp = DateTime.now().microsecondsSinceEpoch;
  final suffix = _random.nextInt(1 << 32).toRadixString(16).padLeft(8, '0');
  return 'inc_$timestamp$suffix';
}
