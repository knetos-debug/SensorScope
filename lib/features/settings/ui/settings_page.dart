import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme_provider.dart';
import '../../../core/themes.dart';
import '../../security/consent_dialog.dart';
import '../../security/security_settings_controller.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  static const routeName = 'settings';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeAsync = ref.watch(themeControllerProvider);
    final controller = ref.read(themeControllerProvider.notifier);
    final securitySettingsAsync = ref.watch(securitySettingsProvider);
    final securityController = ref.read(securitySettingsProvider.notifier);

    return SafeArea(
      child: themeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Kunde inte läsa in tema-inställningar.\n$error',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (state) {
          final themes = controller.themes;
          return securitySettingsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Kunde inte läsa in säkerhetsinställningar.\n$error',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            data: (securitySettings) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
                children: [
                  _SecuritySettingsSection(
                    settings: securitySettings,
                    controller: securityController,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Teman',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  ...themes.map((themeDefinition) {
                    final isSelected = themeDefinition.id == state.current.id;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _ThemeOptionCard(
                        themeDefinition: themeDefinition,
                        isSelected: isSelected,
                        onTap: () => controller.setTheme(themeDefinition.id),
                      ),
                    );
                  }),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _ThemeOptionCard extends StatelessWidget {
  const _ThemeOptionCard({
    required this.themeDefinition,
    required this.isSelected,
    required this.onTap,
  });

  final AppThemeDefinition themeDefinition;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: isSelected ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      themeDefinition.name,
                      style: textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  AnimatedScale(
                    scale: isSelected ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                themeDefinition.description,
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _ColorSwatch(themeDefinition.backgroundColor),
                  const SizedBox(width: 8),
                  _ColorSwatch(themeDefinition.primaryColor),
                  const SizedBox(width: 8),
                  _ColorSwatch(themeDefinition.secondaryColor),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: isSelected ? null : onTap,
                child: Text(isSelected ? 'Aktivt tema' : 'Aktivera tema'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecuritySettingsSection extends StatelessWidget {
  const _SecuritySettingsSection({
    required this.settings,
    required this.controller,
  });

  final SecuritySettings settings;
  final SecuritySettingsController controller;

  Future<bool> _ensureConsent(BuildContext context) async {
    final result = await showSecurityConsentDialog(context);
    if (result == true) {
      await controller.setConsent(true);
      return true;
    }
    await controller.setConsent(false);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Säkerhetskontroller kräver samtycke för att aktiveras.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final masterEnabled = settings.enabled;
    final checksEnabled = settings.hasActiveChecks;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            SwitchListTile.adaptive(
              title: const Text('Aktivera säkerhetskontroller'),
              subtitle: const Text(
                'Tillåter SensorScope att köra nätverkstester och övervakning.',
              ),
              value: masterEnabled,
              onChanged: (value) async {
                if (!value) {
                  await controller.setEnabled(false);
                  return;
                }
                final consentOk = settings.consentGranted
                    ? true
                    : await _ensureConsent(context);
                if (consentOk) {
                  await controller.setEnabled(true);
                }
              },
            ),
            const Divider(height: 1),
            SwitchListTile.adaptive(
              title: const Text('DNS-jämförelse (DoH)'),
              subtitle: const Text(
                'Jämför systemets DNS-svar mot en säker resolver.',
              ),
              value: settings.dnsDiffEnabled,
              onChanged: masterEnabled
                  ? (value) => controller.setDnsDiffEnabled(value)
                  : null,
            ),
            SwitchListTile.adaptive(
              title: const Text('Captive portal-detektion'),
              subtitle: const Text(
                'Kontrollerar om nätverket fångar trafik bakom en portal.',
              ),
              value: settings.captivePortalEnabled,
              onChanged: masterEnabled
                  ? (value) => controller.setCaptivePortalEnabled(value)
                  : null,
            ),
            SwitchListTile.adaptive(
              title: const Text('Gateway-övervakning (MAC)'),
              subtitle: const Text(
                'Bevakar om gateway-adressens MAC förändras (ARP-spoofing).',
              ),
              value: settings.gatewayWatchEnabled,
              onChanged: masterEnabled
                  ? (value) => controller.setGatewayWatchEnabled(value)
                  : null,
            ),
            if (masterEnabled && !checksEnabled)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Aktivera minst en kontroll för att kunna köra säkerhetskontroller.',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch(this.color);

  final Color color;

  @override
  Widget build(BuildContext context) {
    final borderColor =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2);
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
    );
  }
}
