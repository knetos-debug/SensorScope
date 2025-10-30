import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'captive_portal.dart';
import 'dns_check.dart';
import 'gateway_watch.dart';
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

  Timer? _gatewayTimer;
  GatewayStatus? _gatewayBaseline;
  bool _gatewayActive = false;

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

      if (settings.gatewayWatchEnabled) {
        final monitorIncident = await _ensureGatewayMonitor();
        if (monitorIncident != null) {
          drafts.add(monitorIncident);
        }
      } else {
        _stopGatewayMonitor();
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

  Future<IncidentDraft?> _ensureGatewayMonitor() async {
    if (_gatewayActive && _gatewayBaseline != null) {
      return null;
    }
    final service = GatewayWatchService();
    final status = await service.readStatus();
    if (status == null) {
      _stopGatewayMonitor();
      return IncidentDraft(
        type: 'GATEWAY_INFO_UNAVAILABLE',
        severity: IncidentSeverity.info,
        message:
            'Gateway-information kan inte läsas på denna enhet. Gateway-övervakning avaktiverad.',
      );
    }
    _gatewayBaseline = status;
    _gatewayActive = true;
    _gatewayTimer ??= Timer.periodic(
      const Duration(seconds: 15),
      (_) => _pollGateway(),
    );
    return IncidentDraft(
      type: 'GATEWAY_BASELINE',
      severity: IncidentSeverity.info,
      message:
          'Gateway-övervakning startad. Baslinje: ${status.mac} @ ${status.ip}.',
      details: {
        'gateway_ip': status.ip,
        'gateway_mac': status.mac,
        'interface': status.interface,
      },
    );
  }

  Future<void> _pollGateway() async {
    if (!_gatewayActive) {
      return;
    }
    final baseline = _gatewayBaseline;
    if (baseline == null) {
      return;
    }
    final service = GatewayWatchService();
    final current = await service.readStatus();
    if (current == null) {
      addIncident(
        type: 'GATEWAY_INFO_UNAVAILABLE',
        severity: IncidentSeverity.warning,
        message: 'Gateway-information kunde inte läsas vid övervakning.',
        details: {'gateway_ip': baseline.ip},
      );
      _stopGatewayMonitor();
      return;
    }
    if (current.mac.toLowerCase() != baseline.mac.toLowerCase() ||
        current.ip != baseline.ip) {
      addIncident(
        type: 'GATEWAY_MAC_CHANGED',
        severity: IncidentSeverity.critical,
        message:
            'Gateway MAC ändrad (${baseline.mac} → ${current.mac} @ ${current.ip}).',
        details: {
          'old_mac': baseline.mac,
          'new_mac': current.mac,
          'gateway_ip': current.ip,
          'interface': current.interface,
        },
        recommendation:
            'Koppla från Wi-Fi och anslut igen. Om det fortsätter kan det vara ARP-spoofing.',
      );
      _gatewayBaseline = current;
    }
  }

  void _stopGatewayMonitor() {
    _gatewayActive = false;
    _gatewayTimer?.cancel();
    _gatewayTimer = null;
    _gatewayBaseline = null;
  }

  @override
  void dispose() {
    _stopGatewayMonitor();
    super.dispose();
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
