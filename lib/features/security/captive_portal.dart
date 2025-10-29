import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'dns_check.dart';
import 'models/incident.dart';

class CaptivePortalCheckService {
  CaptivePortalCheckService({http.Client? client})
      : _client = client ?? http.Client();

  static final Uri _uri = Uri.parse('http://clients3.google.com/generate_204');
  static const _timeout = Duration(seconds: 3);
  static const _retryDelay = Duration(milliseconds: 250);

  final http.Client _client;

  Future<IncidentDraft?> run() async {
    try {
      for (var attempt = 0; attempt < 2; attempt++) {
        try {
          final response = await _client.get(_uri).timeout(_timeout);
          if (response.statusCode == 204) {
            return null;
          }
          final location = response.headers['location'];
          return IncidentDraft(
            type: 'CAPTIVE_PORTAL',
            severity: IncidentSeverity.warning,
            message:
                'Captive portal upptäcktes (status ${response.statusCode}).',
            details: <String, dynamic>{
              'status': response.statusCode,
              if (location != null) 'location': location,
              'headers': _truncateHeaders(response.headers),
            },
            recommendation:
                'Öppna webbläsaren för att logga in i nätverket eller byt nätverk.',
          );
        } on TimeoutException {
          if (attempt == 1) {
            return IncidentDraft(
              type: 'CAPTIVE_PORTAL_TIMEOUT',
              severity: IncidentSeverity.info,
              message: 'Captive portal-testet nådde inte generate_204 i tid.',
              details: <String, dynamic>{
                'status': 'timeout',
              },
              recommendation: 'Kontrollera nätverksanslutningen.',
            );
          }
        } on SocketException catch (error) {
          if (attempt == 1) {
            return IncidentDraft(
              type: 'CAPTIVE_PORTAL_NETWORK_ERROR',
              severity: IncidentSeverity.info,
              message:
                  'Captive portal-testet misslyckades på grund av nätverksfel.',
              details: <String, dynamic>{'error': error.message},
              recommendation: 'Kontrollera nätverksanslutningen.',
            );
          }
        }
        await Future<void>.delayed(_retryDelay);
      }
      return null;
    } finally {
      _client.close();
    }
  }

  Map<String, dynamic> _truncateHeaders(Map<String, String> headers) {
    const limit = 5;
    final entries = headers.entries.take(limit).map((entry) {
      final value = entry.value.length > 80
          ? '${entry.value.substring(0, 77)}...'
          : entry.value;
      return MapEntry(entry.key, value);
    });
    return Map<String, dynamic>.fromEntries(entries);
  }
}
