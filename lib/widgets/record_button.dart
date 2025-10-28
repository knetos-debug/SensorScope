import 'package:flutter/material.dart';

class RecordButton extends StatelessWidget {
  const RecordButton({
    super.key,
    required this.isRecording,
    required this.onPressed,
  });

  final bool isRecording;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(isRecording ? Icons.stop : Icons.fiber_manual_record),
      label: Text(isRecording ? 'Stop Logging' : 'Start Logging'),
      style: FilledButton.styleFrom(
        backgroundColor: isRecording
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
