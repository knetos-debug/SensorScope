enum IncidentSeverity {
  info,
  warning,
  critical,
}

extension IncidentSeverityLabel on IncidentSeverity {
  String get label {
    switch (this) {
      case IncidentSeverity.info:
        return 'Info';
      case IncidentSeverity.warning:
        return 'Varning';
      case IncidentSeverity.critical:
        return 'Kritisk';
    }
  }
}

class Incident {
  Incident({
    required this.id,
    required this.type,
    required this.severity,
    required this.message,
    required this.timestamp,
    Map<String, dynamic> details = const <String, dynamic>{},
    this.recommendation,
  }) : details = Map.unmodifiable(details);

  final String id;
  final String type;
  final IncidentSeverity severity;
  final String message;
  final Map<String, dynamic> details;
  final DateTime timestamp;
  final String? recommendation;

  Incident copyWith({
    String? id,
    String? type,
    IncidentSeverity? severity,
    String? message,
    Map<String, dynamic>? details,
    DateTime? timestamp,
    String? recommendation,
  }) {
    return Incident(
      id: id ?? this.id,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      message: message ?? this.message,
      details: details != null ? Map.unmodifiable(details) : this.details,
      timestamp: timestamp ?? this.timestamp,
      recommendation: recommendation ?? this.recommendation,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'type': type,
      'severity': severity.name,
      'message': message,
      'details': Map<String, dynamic>.from(details),
      'timestamp': timestamp.toIso8601String(),
      if (recommendation != null) 'recommendation': recommendation,
    };
  }

  factory Incident.fromJson(Map<String, dynamic> json) {
    return Incident(
      id: json['id'] as String,
      type: json['type'] as String,
      severity: IncidentSeverity.values.firstWhere(
        (value) => value.name == json['severity'],
        orElse: () => IncidentSeverity.info,
      ),
      message: json['message'] as String,
      details: Map<String, dynamic>.from(
        json['details'] as Map? ?? <String, dynamic>{},
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      recommendation: json['recommendation'] as String?,
    );
  }
}
