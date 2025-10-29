import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/incident.dart';
import 'security_controller.dart';

class SecurityHomePage extends ConsumerWidget {
  const SecurityHomePage({super.key});

  static const routeName = 'security';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(securityControllerProvider);
    final controller = ref.read(securityControllerProvider.notifier);
    final incidents = state.visibleIncidents;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Säkerhetskontroller',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                _SeverityFilterBar(
                  selected: state.filter,
                  onSelected: controller.setFilter,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: state.isRunning
                            ? null
                            : () async {
                                await controller.runChecks();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Kontroller kommer att läggas till i kommande steg.',
                                      ),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                        child: state.isRunning
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Kör kontroller'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: incidents.isEmpty
                            ? null
                            : () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Exportfunktionen läggs till i ett senare steg.',
                                    ),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                        child: const Text('Exportera logg'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: incidents.isEmpty
                ? _EmptyState(isRunning: state.isRunning)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    itemCount: incidents.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final incident = incidents[index];
                      return _IncidentCard(incident: incident);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SeverityFilterBar extends StatelessWidget {
  const _SeverityFilterBar({
    required this.selected,
    required this.onSelected,
  });

  final IncidentSeverity? selected;
  final ValueChanged<IncidentSeverity?> onSelected;

  @override
  Widget build(BuildContext context) {
    final entries = <({IncidentSeverity? value, String label})>[
      (value: null, label: 'Alla'),
      (value: IncidentSeverity.info, label: IncidentSeverity.info.label),
      (value: IncidentSeverity.warning, label: IncidentSeverity.warning.label),
      (
        value: IncidentSeverity.critical,
        label: IncidentSeverity.critical.label
      ),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: entries
          .map(
            (entry) => FilterChip(
              label: Text(entry.label),
              selected: selected == entry.value,
              onSelected: (_) => onSelected(entry.value),
            ),
          )
          .toList(),
    );
  }
}

class _IncidentCard extends StatelessWidget {
  const _IncidentCard({required this.incident});

  final Incident incident;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final severityColor = _severityColor(incident.severity, theme);
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 6,
              height: double.infinity,
              decoration: BoxDecoration(
                color: severityColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${incident.type} (${incident.severity.label})',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      incident.message,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatTimestamp(incident.timestamp),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.textTheme.labelMedium?.color
                            ?.withValues(alpha: 0.7),
                      ),
                    ),
                    if (incident.recommendation != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        incident.recommendation!,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _severityColor(IncidentSeverity severity, ThemeData theme) {
    switch (severity) {
      case IncidentSeverity.info:
        return Colors.greenAccent.shade400;
      case IncidentSeverity.warning:
        return Colors.amber.shade600;
      case IncidentSeverity.critical:
        return Colors.redAccent.shade200;
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isRunning});

  final bool isRunning;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isRunning
                  ? 'Kör kontroller...'
                  : 'Inga incidenter. Kör kontroller via knappen nedan.',
              style: textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

String _formatTimestamp(DateTime timestamp) {
  final now = DateTime.now();
  final difference = now.difference(timestamp);
  if (difference.inSeconds < 60) {
    return 'För ${difference.inSeconds} s sedan';
  }
  if (difference.inMinutes < 60) {
    return 'För ${difference.inMinutes} min sedan';
  }
  if (difference.inHours < 24) {
    return 'För ${difference.inHours} h sedan';
  }
  return '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')} '
      '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
}
