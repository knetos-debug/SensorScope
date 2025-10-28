import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static const routeName = 'settings';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Settings',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Text(
            'Phase 2 roadmap will unlock more controls like sampling rate and theme. '
            'For now, permissions can be managed from Android Settings if needed.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
