import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecuritySettings {
  const SecuritySettings({
    required this.consentGranted,
    required this.consentRecorded,
    required this.enabled,
    required this.dnsDiffEnabled,
    required this.captivePortalEnabled,
    required this.gatewayWatchEnabled,
  });

  final bool consentGranted;
  final bool consentRecorded;
  final bool enabled;
  final bool dnsDiffEnabled;
  final bool captivePortalEnabled;
  final bool gatewayWatchEnabled;

  bool get hasActiveChecks =>
      dnsDiffEnabled || captivePortalEnabled || gatewayWatchEnabled;

  bool get canRunChecks => consentGranted && enabled && hasActiveChecks;

  SecuritySettings copyWith({
    bool? consentGranted,
    bool? consentRecorded,
    bool? enabled,
    bool? dnsDiffEnabled,
    bool? captivePortalEnabled,
    bool? gatewayWatchEnabled,
  }) {
    return SecuritySettings(
      consentGranted: consentGranted ?? this.consentGranted,
      consentRecorded: consentRecorded ?? this.consentRecorded,
      enabled: enabled ?? this.enabled,
      dnsDiffEnabled: dnsDiffEnabled ?? this.dnsDiffEnabled,
      captivePortalEnabled: captivePortalEnabled ?? this.captivePortalEnabled,
      gatewayWatchEnabled: gatewayWatchEnabled ?? this.gatewayWatchEnabled,
    );
  }
}

const _consentKey = 'security_consent';
const _enabledKey = 'security_enabled';
const _dnsKey = 'security_dns_compare';
const _captiveKey = 'security_captive_portal';
const _gatewayKey = 'security_gateway_watch';

class SecuritySettingsController extends AsyncNotifier<SecuritySettings> {
  SharedPreferences? _prefs;

  Future<SharedPreferences> _ensurePrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  @override
  Future<SecuritySettings> build() async {
    final prefs = await _ensurePrefs();
    final consentRecorded = prefs.containsKey(_consentKey);
    final consentGranted = prefs.getBool(_consentKey) ?? false;
    final enabled = prefs.getBool(_enabledKey) ?? false;
    final dnsEnabled = prefs.getBool(_dnsKey) ?? true;
    final captiveEnabled = prefs.getBool(_captiveKey) ?? true;
    final gatewayEnabled = prefs.getBool(_gatewayKey) ?? true;

    return SecuritySettings(
      consentGranted: consentGranted,
      consentRecorded: consentRecorded,
      enabled: enabled,
      dnsDiffEnabled: dnsEnabled,
      captivePortalEnabled: captiveEnabled,
      gatewayWatchEnabled: gatewayEnabled,
    );
  }

  Future<SecuritySettings> _loadCurrent() async {
    final current = state.value;
    if (current != null) {
      return current;
    }
    return future;
  }

  Future<void> setConsent(bool granted) async {
    final prefs = await _ensurePrefs();
    final current = await _loadCurrent();
    final updated = current.copyWith(
      consentGranted: granted,
      consentRecorded: true,
      enabled: granted ? current.enabled : false,
    );
    state = AsyncData(updated);
    await prefs.setBool(_consentKey, granted);
    if (!granted) {
      await prefs.setBool(_enabledKey, false);
    }
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await _ensurePrefs();
    final current = await _loadCurrent();
    final updated = current.copyWith(enabled: enabled);
    state = AsyncData(updated);
    await prefs.setBool(_enabledKey, enabled);
  }

  Future<void> setDnsDiffEnabled(bool enabled) async {
    final prefs = await _ensurePrefs();
    final current = await _loadCurrent();
    final updated = current.copyWith(dnsDiffEnabled: enabled);
    state = AsyncData(updated);
    await prefs.setBool(_dnsKey, enabled);
  }

  Future<void> setCaptivePortalEnabled(bool enabled) async {
    final prefs = await _ensurePrefs();
    final current = await _loadCurrent();
    final updated = current.copyWith(captivePortalEnabled: enabled);
    state = AsyncData(updated);
    await prefs.setBool(_captiveKey, enabled);
  }

  Future<void> setGatewayWatchEnabled(bool enabled) async {
    final prefs = await _ensurePrefs();
    final current = await _loadCurrent();
    final updated = current.copyWith(gatewayWatchEnabled: enabled);
    state = AsyncData(updated);
    await prefs.setBool(_gatewayKey, enabled);
  }
}

final securitySettingsProvider =
    AsyncNotifierProvider<SecuritySettingsController, SecuritySettings>(
  SecuritySettingsController.new,
);
