import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

const _documentsFolderName = 'Documents';
const _appFolderName = 'SensorScope';

class LoggingState {
  const LoggingState({
    required this.isRecording,
    this.filePath,
    this.headers = const <String>[],
  });

  final bool isRecording;
  final String? filePath;
  final List<String> headers;

  LoggingState copyWith({
    bool? isRecording,
    String? filePath,
    List<String>? headers,
  }) {
    return LoggingState(
      isRecording: isRecording ?? this.isRecording,
      filePath: filePath ?? this.filePath,
      headers: headers ?? this.headers,
    );
  }
}

class CsvLogger extends StateNotifier<LoggingState> {
  CsvLogger() : super(const LoggingState(isRecording: false));

  IOSink? _sink;

  Future<void> startLogging(List<String> headers) async {
    if (state.isRecording) {
      return;
    }
    final directory = await _ensureDirectory();
    final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
    final file = File('${directory.path}/$timestamp.csv');
    _sink = file.openWrite(mode: FileMode.append);
    _sink!.writeln(headers.join(','));
    state = state.copyWith(
      isRecording: true,
      filePath: file.path,
      headers: headers,
    );
  }

  Future<void> append(Map<String, dynamic> values) async {
    final sink = _sink;
    if (!state.isRecording || sink == null) {
      return;
    }
    final ordered = state.headers
        .map((header) => values[header]?.toString() ?? '')
        .join(',');
    sink.writeln(ordered);
    await sink.flush();
  }

  Future<void> stopLogging() async {
    await _sink?.flush();
    await _sink?.close();
    _sink = null;
    state = state.copyWith(isRecording: false);
  }

  Future<Directory> _ensureDirectory() async {
    final base = await getApplicationDocumentsDirectory();
    final directory = Directory(
      '${base.path}/$_documentsFolderName/$_appFolderName',
    );
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }
}

final csvLoggerProvider = StateNotifierProvider<CsvLogger, LoggingState>((ref) {
  return CsvLogger();
});
