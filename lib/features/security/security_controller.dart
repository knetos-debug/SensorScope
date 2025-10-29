import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'captive_portal.dart';
import 'dns_check.dart';
import 'models/incident.dart';
import 'security_settings_controller.dart';

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

  Future<void> runChecks(SecuritySettings settings) async {
    if (state.isRunning) {
      return;
    }
    state = state.copyWith(isRunning: true);
    try {
      final drafts = <IncidentDraft>[];

      if (settings.dnsDiffEnabled) {
        final dnsService = DnsCheckService();
        drafts.addAll(await dnsService.run());
      }

      if (settings.captivePortalEnabled) {
        final captiveService = CaptivePortalCheckService();
        final incident = await captiveService.run();
        if (incident != null) {
          drafts.add(incident);
        }
      }

      if (drafts.isEmpty) {
        addIncident(
          type: 'SECURITY_OK',
          severity: IncidentSeverity.info,
          message: 'Säkerhetskontroller slutfördes utan avvikelse.',
        );
      } else {
        for (final draft in drafts) {
          addIncident(
            type: draft.type,
            severity: draft.severity,
            message: draft.message,
            details: draft.details,
            recommendation: draft.recommendation,
          );
        }
      }
    } finally {
      state = state.copyWith(isRunning: false);
    }
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
