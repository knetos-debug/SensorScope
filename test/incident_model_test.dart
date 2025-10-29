import 'package:flutter_test/flutter_test.dart';
import 'package:sensorscope/features/security/models/incident.dart';

void main() {
  test('Incident serializes and deserializes correctly', () {
    final incident = Incident(
      id: 'inc_123',
      type: 'DNS_MISMATCH',
      severity: IncidentSeverity.warning,
      message: 'System vs DoH avvikelse',
      details: const {
        'host': 'example.com',
        'system_ips': ['1.1.1.1']
      },
      timestamp: DateTime.parse('2024-01-01T12:00:00Z'),
      recommendation: 'Byt nätverk.',
    );

    final json = incident.toJson();
    final restored = Incident.fromJson(json);

    expect(restored.id, equals(incident.id));
    expect(restored.type, equals(incident.type));
    expect(restored.severity, equals(incident.severity));
    expect(restored.message, equals(incident.message));
    expect(restored.details['host'], equals('example.com'));
    expect(restored.recommendation, equals('Byt nätverk.'));
    expect(restored.timestamp.toUtc(), equals(incident.timestamp.toUtc()));
  });
}
