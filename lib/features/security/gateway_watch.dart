import 'dart:io';

class GatewayStatus {
  const GatewayStatus({
    required this.ip,
    required this.mac,
    required this.interface,
  });

  final String ip;
  final String mac;
  final String interface;
}

class GatewayWatchService {
  Future<GatewayStatus?> readStatus() async {
    try {
      final route = await _readDefaultRoute();
      if (route == null) {
        return null;
      }
      final mac = await _readMacForIp(route.gatewayIp);
      if (mac == null || mac == '00:00:00:00:00:00') {
        return null;
      }
      return GatewayStatus(
        ip: route.gatewayIp,
        mac: mac,
        interface: route.interface,
      );
    } on FileSystemException {
      return null;
    }
  }

  Future<_RouteEntry?> _readDefaultRoute() async {
    final file = File('/proc/net/route');
    if (!await file.exists()) {
      return null;
    }
    final lines = await file.readAsLines();
    for (var i = 1; i < lines.length; i++) {
      final columns = lines[i].trim().split(RegExp(r'\s+'));
      if (columns.length < 3) {
        continue;
      }
      final destination = columns[1];
      final gatewayHex = columns[2];
      if (destination == '00000000' && gatewayHex.length == 8) {
        final interface = columns[0];
        final gatewayIp = _hexToIp(gatewayHex);
        if (gatewayIp != null) {
          return _RouteEntry(interface: interface, gatewayIp: gatewayIp);
        }
      }
    }
    return null;
  }

  Future<String?> _readMacForIp(String ip) async {
    final file = File('/proc/net/arp');
    if (!await file.exists()) {
      return null;
    }
    final lines = await file.readAsLines();
    for (var i = 1; i < lines.length; i++) {
      final columns = lines[i].trim().split(RegExp(r'\s+'));
      if (columns.length < 6) {
        continue;
      }
      if (columns[0] == ip) {
        final mac = columns[3];
        if (mac.isNotEmpty) {
          return mac.toLowerCase();
        }
      }
    }
    return null;
  }

  String? _hexToIp(String hex) {
    if (hex.length != 8) {
      return null;
    }
    final octets = <int>[];
    for (var i = 0; i < 8; i += 2) {
      final pair = hex.substring(i, i + 2);
      final value = int.tryParse(pair, radix: 16);
      if (value == null) {
        return null;
      }
      octets.add(value);
    }
    // Value stored in little endian order.
    return '${octets[3]}.${octets[2]}.${octets[1]}.${octets[0]}';
  }
}

class _RouteEntry {
  const _RouteEntry({required this.interface, required this.gatewayIp});

  final String interface;
  final String gatewayIp;
}
