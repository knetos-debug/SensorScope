import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sensorscope/features/security/dns_check.dart';
import 'package:sensorscope/features/security/models/incident.dart';

void main() {
  group('DnsCheckService', () {
    test('detects mismatch between system resolver and DoH', () async {
      final client = MockClient((request) async {
        final body = jsonEncode({
          'Answer': [
            {'data': '203.0.113.10'}
          ]
        });
        return http.Response(body, 200, headers: {
          'content-type': 'application/dns-json',
        });
      });

      Future<List<InternetAddress>> systemLookup(String host) async {
        return [
          InternetAddress('198.51.100.5'),
        ];
      }

      final service = DnsCheckService(
        client: client,
        hosts: const ['example.com'],
        systemLookup: systemLookup,
      );

      final incidents = await service.run();
      expect(incidents, hasLength(1));
      final incident = incidents.first;
      expect(incident.type, equals('DNS_MISMATCH'));
      expect(incident.severity, equals(IncidentSeverity.critical));
      expect(incident.details['system_ips'], contains('198.51.100.5'));
      expect(incident.details['doh_ips'], contains('203.0.113.10'));
    });
  });
}
