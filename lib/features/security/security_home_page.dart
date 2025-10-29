import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'consent_dialog.dart';
import 'models/incident.dart';
import 'security_controller.dart';
import 'security_settings_controller.dart';

class SecurityHomePage extends ConsumerStatefulWidget {
  const SecurityHomePage({super.key});

  static const routeName = 'security';

  @override
  ConsumerState<SecurityHomePage> createState() => _SecurityHomePageState();
}

class _SecurityHomePageState extends ConsumerState<SecurityHomePage> {
  bool _dialogInFlight = false;

  @override
  void initState() {
    super.initState();
    ref.listen<AsyncValue<SecuritySettings>>(securitySettingsProvider,
        (previous, next) {
      next.whenData((settings) {
        if (!settings.consentRecorded && !_dialogInFlight) {
          _promptForConsent();
        }
      });
    });
  }

  Future<void> _promptForConsent() async {
    if (!mounted) {
      return;
    }
    _dialogInFlight = true;
    final result = await showSecurityConsentDialog(context);
    final controller = ref.read(securitySettingsProvider.notifier);
    if (result == true) {
      await controller.setConsent(true);
      await controller.setEnabled(true);
    } else {
      await controller.setConsent(false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Säkerhetskontroller kräver samtycke för att aktiveras.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
    _dialogInFlight = false;
  }

  @override
  Widget build(BuildContext context) {
    final securityState = ref.watch(securityControllerProvider);
    final securityController = ref.read(securityControllerProvider.notifier);
    final settingsAsync = ref.watch(securitySettingsProvider);

    return SafeArea(
      child: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Kunde inte läsa in säkerhetsinställningar.\n$error',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (settings) {
          final incidents = securityState.visibleIncidents;
          final canRun = settings.canRunChecks && !securityState.isRunning;
          final exportEnabled = incidents.isNotEmpty;
          final emptyMessage = securityState.isRunning
              ? 'Kör kontroller...'
              : !_dialogInFlight && !settings.consentGranted
                  ? 'Säkerhetskontroller kräver samtycke. Aktivera i inställningarna.'
                  : !settings.enabled
                      ? 'Aktivera säkerhetskontroller i inställningarna.'
                      : !settings.hasActiveChecks
                          ? 'Aktivera minst en kontroll i inställningarna.'
                          : 'Inga incidenter. Kör kontroller via knappen nedan.';

          return Column(
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
                      selected: securityState.filter,
                      onSelected: securityController.setFilter,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: canRun
                                ? () async {
                                    await securityController.runChecks();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Kontroller kommer att läggas till i kommande steg.',
                                          ),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  }
                                : null,
                            child: securityState.isRunning
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Text('Kör kontroller'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: exportEnabled
                                ? () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Exportfunktionen läggs till i ett senare steg.',
                                        ),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                : null,
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
                    ? _EmptyState(message: emptyMessage)
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
          );
        },
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
        label: IncidentSeverity.critical.label,
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
  const _EmptyState({required this.message});

  final String message;

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
              message,
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
