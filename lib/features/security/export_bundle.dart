import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import 'models/incident.dart';

class IncidentExportService {
  Future<String> export(List<Incident> incidents) async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final exportDir = Directory(
      '${documentsDir.path}/Documents/SensorScope/security',
    );
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }

    final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
    final archive = Archive();

    final incidentsJson = const JsonEncoder.withIndent('  ').convert(
      incidents.map((incident) => incident.toJson()).toList(),
    );
    archive.addFile(_stringFile('incidents.json', incidentsJson));

    final summary = _buildSummary(incidents, timestamp);
    archive.addFile(_stringFile('summary.txt', summary));

    final environment = <String, dynamic>{
      'generated_at': DateTime.now().toIso8601String(),
      'os': Platform.operatingSystem,
      'os_version': Platform.operatingSystemVersion,
      'locale': Platform.localeName,
    };
    final environmentJson =
        const JsonEncoder.withIndent('  ').convert(environment);
    archive.addFile(_stringFile('environment.json', environmentJson));

    final zipEncoder = ZipEncoder();
    final zipData = zipEncoder.encode(archive);
    final filePath = '${exportDir.path}/SEC_$timestamp.zip';
    final file = File(filePath);
    await file.writeAsBytes(zipData!, flush: true);
    return file.path;
  }

  ArchiveFile _stringFile(String name, String contents) {
    final data = utf8.encode(contents);
    return ArchiveFile(name, data.length, data);
  }

  String _buildSummary(List<Incident> incidents, String timestamp) {
    final buffer = StringBuffer()
      ..writeln('SensorScope incidentrapport')
      ..writeln('Genererad: $timestamp')
      ..writeln('Antal incidenter: ${incidents.length}')
      ..writeln();

    final infoCount = incidents
        .where((incident) => incident.severity == IncidentSeverity.info)
        .length;
    final warningCount = incidents
        .where((incident) => incident.severity == IncidentSeverity.warning)
        .length;
    final criticalCount = incidents
        .where((incident) => incident.severity == IncidentSeverity.critical)
        .length;

    buffer
      ..writeln('Fördelning:')
      ..writeln('  Info: $infoCount')
      ..writeln('  Varning: $warningCount')
      ..writeln('  Kritisk: $criticalCount')
      ..writeln();

    if (incidents.isEmpty) {
      buffer.writeln('Inga incidenter registrerade.');
    } else {
      buffer.writeln('Senaste incidenter:');
      for (final incident in incidents.take(10)) {
        buffer.writeln(
          '- [${incident.severity.label}] ${incident.type}: ${incident.message}',
        );
      }
    }
    return buffer.toString();
  }
}
