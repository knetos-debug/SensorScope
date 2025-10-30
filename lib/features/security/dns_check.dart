import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'models/incident.dart';

class IncidentDraft {
  IncidentDraft({
    required this.type,
    required this.severity,
    required this.message,
    this.details = const <String, dynamic>{},
    this.recommendation,
  });

  final String type;
  final IncidentSeverity severity;
  final String message;
  final Map<String, dynamic> details;
  final String? recommendation;
}

class DnsCheckService {
  DnsCheckService({http.Client? client}) : _client = client ?? http.Client();

  static const _hosts = <String>['example.com', 'google.com'];
  static const _timeout = Duration(seconds: 3);
  static const _retryDelay = Duration(milliseconds: 250);

  final http.Client _client;

  Future<List<IncidentDraft>> run() async {
    final findings = <IncidentDraft>[];
    try {
      for (final host in _hosts) {
        final result = await _checkHost(host);
        if (result != null) {
          findings.add(result);
        }
      }
    } finally {
      _client.close();
    }
    return findings;
  }

  Future<IncidentDraft?> _checkHost(String host) async {
    final systemIps = await _lookupSystem(host);
    final dohResponse = await _lookupDoh(host);

    if (systemIps.ips.isEmpty && dohResponse.ips.isEmpty) {
      return IncidentDraft(
        type: 'DNS_NO_DATA',
        severity: IncidentSeverity.info,
        message: 'DNS-kontroll för $host misslyckades – inga svar erhölls.',
        details: {
          'host': host,
          'system_error': systemIps.error,
          'doh_error': dohResponse.error,
        },
        recommendation: 'Kontrollera nätverksanslutningen och försök igen.',
      );
    }

    if (systemIps.ips.isEmpty || dohResponse.ips.isEmpty) {
      return IncidentDraft(
        type: 'DNS_PARTIAL_DATA',
        severity: IncidentSeverity.warning,
        message: systemIps.ips.isEmpty
            ? 'Systemresolver saknar svar för $host medan DoH returnerade resultat.'
            : 'DoH-resolver svarade inte för $host medan systemresolvern gjorde det.',
        details: {
          'host': host,
          'system_ips': systemIps.ips,
          'system_error': systemIps.error,
          'doh_ips': dohResponse.ips,
          'doh_error': dohResponse.error,
        },
        recommendation:
            'Byt nätverk eller försök igen. Om problemet kvarstår kan brandvägg eller portal blockera DNS.',
      );
    }

    final systemSet = systemIps.ips.toSet();
    final dohSet = dohResponse.ips.toSet();
    final intersection = systemSet.intersection(dohSet);

    if (intersection.isEmpty) {
      return IncidentDraft(
        type: 'DNS_MISMATCH',
        severity: IncidentSeverity.critical,
        message:
            'DNS-avvikelse ($host). Systemresolver gav ${systemIps.ips.join(', ')}; DoH gav ${dohResponse.ips.join(', ')}.',
        details: {
          'host': host,
          'system_ips': systemIps.ips,
          'doh_ips': dohResponse.ips,
        },
        recommendation:
            'Byt nätverk eller aktivera VPN. Om detta återkommer, kontakta nätverksansvarig.',
      );
    }

    if (systemSet.length != dohSet.length || systemSet != dohSet) {
      return IncidentDraft(
        type: 'DNS_MISMATCH',
        severity: IncidentSeverity.warning,
        message:
            'DNS-avvikelse ($host). Systemresolver gav ${systemIps.ips.join(', ')}; DoH gav ${dohResponse.ips.join(', ')}.',
        details: {
          'host': host,
          'system_ips': systemIps.ips,
          'doh_ips': dohResponse.ips,
        },
        recommendation:
            'Byt nätverk eller aktivera VPN. Om detta återkommer, kontakta nätverksansvarig.',
      );
    }

    return null;
  }

  Future<_LookupResult> _lookupSystem(String host) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final addresses = await InternetAddress.lookup(host)
            .timeout(_timeout, onTimeout: () => <InternetAddress>[]);
        final ips = addresses
            .where((address) => address.type == InternetAddressType.IPv4)
            .map((address) => address.address)
            .toList();
        if (ips.isNotEmpty) {
          return _LookupResult.success(ips);
        }
        if (attempt == 1) {
          return const _LookupResult.failure('Inga IPv4-adresser från system');
        }
      } on SocketException catch (error) {
        if (attempt == 1) {
          return _LookupResult.failure(error.message);
        }
      } on TimeoutException {
        if (attempt == 1) {
          return const _LookupResult.failure('Systemresolver timeout');
        }
      }
      await Future<void>.delayed(_retryDelay);
    }
    return const _LookupResult.failure('Okänt fel från systemresolver');
  }

  Future<_LookupResult> _lookupDoh(String host) async {
    final uri = Uri.https(
      'cloudflare-dns.com',
      '/dns-query',
      {'name': host, 'type': 'A'},
    );

    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final response = await _client.get(
          uri,
          headers: {'accept': 'application/dns-json'},
        ).timeout(_timeout);
        if (response.statusCode != 200) {
          if (attempt == 1) {
            return _LookupResult.failure(
              'DoH felkod ${response.statusCode}',
            );
          }
          await Future<void>.delayed(_retryDelay);
          continue;
        }
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final answers = (body['Answer'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .map((entry) => entry['data'] as String?)
                .whereType<String>()
                .where((value) =>
                    RegExp(r'^(\d{1,3}\.){3}\d{1,3}$').hasMatch(value))
                .toSet()
                .toList() ??
            <String>[];
        if (answers.isNotEmpty) {
          answers.sort();
          return _LookupResult.success(answers);
        }
        if (attempt == 1) {
          return const _LookupResult.failure('DoH saknar A-poster');
        }
      } on TimeoutException {
        if (attempt == 1) {
          return const _LookupResult.failure('DoH timeout');
        }
      } on SocketException catch (error) {
        if (attempt == 1) {
          return _LookupResult.failure(error.message);
        }
      } on FormatException {
        if (attempt == 1) {
          return const _LookupResult.failure('DoH svarade med ogiltigt JSON');
        }
      }
      await Future<void>.delayed(_retryDelay);
    }
    return const _LookupResult.failure('Okänt DoH-fel');
  }
}

class _LookupResult {
  const _LookupResult.success(this.ips) : error = null;
  const _LookupResult.failure(this.error) : ips = const <String>[];

  final List<String> ips;
  final String? error;
}
