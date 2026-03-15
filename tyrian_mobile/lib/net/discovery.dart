import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

/// UDP beacon for co-op host discovery.
/// Uses both broadcast (255.255.255.255) and multicast (239.42.42.42)
/// for maximum reliability across different WiFi configurations.
/// Beacon format: TYRIAN_COOP|tcp_port|pilotName
class CoopDiscovery {
  static const int discoveryPort = 5742;
  static const String _prefix = 'TYRIAN_COOP';
  static const String _multicastGroup = '239.42.42.42';

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
    final broadcastDest = InternetAddress('255.255.255.255');
    final multicastDest = InternetAddress(_multicastGroup);

    void sendBeacon() {
      try { _socket?.send(data, broadcastDest, discoveryPort); } catch (_) {}
      try { _socket?.send(data, multicastDest, discoveryPort); } catch (_) {}
    }

    print('Discovery: broadcasting on port $discoveryPort (tcp=$tcpPort, pilot=$pilotName)');
    sendBeacon();

    // Broadcast every 500ms for faster discovery
    _broadcastTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      sendBeacon();
    });
  }

  /// Start listening for host beacons (as client)
  Future<void> startListening() async {
    _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, discoveryPort,
        reuseAddress: true, reusePort: true);

    // Join multicast group for more reliable cross-device discovery
    try {
      _socket!.joinMulticast(InternetAddress(_multicastGroup));
      print('Discovery: listening on port $discoveryPort (multicast joined)');
    } catch (e) {
      print('Discovery: listening on port $discoveryPort (multicast failed: $e)');
    }

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

        print('Discovery: received beacon from $ip:$port ($pilotName)');
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
