import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme_provider.dart';
import 'features/ble/ui/ble_page.dart';
import 'features/dashboard/ui/dashboard_page.dart';
import 'features/gps/ui/gps_page.dart';
import 'features/security/security_home_page.dart';
import 'features/settings/ui/settings_page.dart';
import 'features/wifi/ui/wifi_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/dashboard',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => _HomeScaffold(
          navigationShell: navigationShell,
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                name: DashboardPage.routeName,
                builder: (context, state) => const DashboardPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/wifi',
                name: WifiPage.routeName,
                builder: (context, state) => const WifiPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/ble',
                name: BlePage.routeName,
                builder: (context, state) => const BlePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/gps',
                name: GpsPage.routeName,
                builder: (context, state) => const GpsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/security',
                name: SecurityHomePage.routeName,
                builder: (context, state) => const SecurityHomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                name: SettingsPage.routeName,
                builder: (context, state) => const SettingsPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class _HomeScaffold extends ConsumerWidget {
  const _HomeScaffold({
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  static const _destinations =
      <({String label, IconData icon, String routeName})>[
    (label: 'Dashboard', icon: Icons.speed, routeName: DashboardPage.routeName),
    (label: 'Wi-Fi', icon: Icons.wifi, routeName: WifiPage.routeName),
    (label: 'BLE', icon: Icons.bluetooth, routeName: BlePage.routeName),
    (label: 'GPS', icon: Icons.gps_fixed, routeName: GpsPage.routeName),
    (
      label: 'Säkerhet',
      icon: Icons.shield_outlined,
      routeName: SecurityHomePage.routeName
    ),
    (
      label: 'Settings',
      icon: Icons.settings,
      routeName: SettingsPage.routeName
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeControllerProvider);
    final themeName = themeState.maybeWhen(
      data: (data) => data.current.name,
      orElse: () => null,
    );
    final title =
        themeName == null ? 'SensorScope' : 'SensorScope • $themeName';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        destinations: _destinations
            .map(
              (destination) => NavigationDestination(
                icon: Icon(destination.icon),
                label: destination.label,
              ),
            )
            .toList(),
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}
