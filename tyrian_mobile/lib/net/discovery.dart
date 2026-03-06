import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

/// UDP broadcast beacon for co-op host discovery.
/// Beacon format: TYRIAN_COOP|tcp_port|pilotName
class CoopDiscovery {
  static const int discoveryPort = 5742;
  static const String _prefix = 'TYRIAN_COOP';

  RawDatagramSocket? _socket;
  Timer? _broadcastTimer;

  /// Discovered hosts: IP → (port, pilotName, lastSeen)
  final Map<String, ({int port, String pilotName, DateTime lastSeen})> hosts = {};

  // Callbacks
  void Function()? onHostsChanged;

  /// Start broadcasting as host
  Future<void> startBroadcast(int tcpPort, String pilotName) async {
    _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    _socket!.broadcastEnabled = true;

    final beacon = '$_prefix|$tcpPort|$pilotName';
    final data = Uint8List.fromList(beacon.codeUnits);

    _broadcastTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      try {
        _socket?.send(data, InternetAddress('255.255.255.255'), discoveryPort);
      } catch (_) {}
    });
  }

  /// Start listening for host beacons (as client)
  Future<void> startListening() async {
    _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, discoveryPort,
        reuseAddress: true, reusePort: true);

    _socket!.listen((event) {
      if (event == RawSocketEvent.read) {
        final dg = _socket!.receive();
        if (dg == null) return;

        final msg = String.fromCharCodes(dg.data);
        if (!msg.startsWith(_prefix)) return;

        final parts = msg.split('|');
        if (parts.length < 3) return;

        final port = int.tryParse(parts[1]);
        if (port == null) return;

        final pilotName = parts[2];
        final ip = dg.address.address;

        hosts[ip] = (port: port, pilotName: pilotName, lastSeen: DateTime.now());
        onHostsChanged?.call();
      }
    });

    // Periodically prune stale hosts (>5s without beacon)
    _broadcastTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      final cutoff = DateTime.now().subtract(const Duration(seconds: 5));
      final stale = hosts.entries.where((e) => e.value.lastSeen.isBefore(cutoff)).map((e) => e.key).toList();
      if (stale.isNotEmpty) {
        for (final key in stale) {
          hosts.remove(key);
        }
        onHostsChanged?.call();
      }
    });
  }

  /// Stop broadcasting/listening
  void dispose() {
    _broadcastTimer?.cancel();
    _broadcastTimer = null;
    _socket?.close();
    _socket = null;
    hosts.clear();
  }
}
