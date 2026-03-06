import 'dart:io';
import 'package:flutter/material.dart';

import '../net/discovery.dart';
import '../net/coop_host.dart';
import '../net/coop_client.dart';

/// Lobby screen for WiFi co-op: host or join a game.
class CoopLobbyScreen extends StatefulWidget {
  final bool isHost;
  final String pilotName;
  final void Function(CoopHost host, String clientPilotName) onHostReady;
  final void Function(CoopClient client, String hostIp, int hostPort) onClientReady;
  final VoidCallback onCancel;

  const CoopLobbyScreen({
    super.key,
    required this.isHost,
    required this.pilotName,
    required this.onHostReady,
    required this.onClientReady,
    required this.onCancel,
  });

  @override
  State<CoopLobbyScreen> createState() => _CoopLobbyScreenState();
}

class _CoopLobbyScreenState extends State<CoopLobbyScreen> {
  // Host state
  CoopHost? _host;
  CoopDiscovery? _discovery;
  String? _localIp;
  bool _clientConnected = false;
  String? _clientPilotName;

  // Client state
  CoopClient? _client;
  bool _connecting = false;
  String? _connectedHostName;
  final _ipController = TextEditingController();
  final _portController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.isHost) {
      _startHosting();
    } else {
      _startDiscovery();
    }
  }

  Future<void> _startHosting() async {
    _host = CoopHost();
    final port = await _host!.start(widget.pilotName);

    _host!.onClientConnected = (pilotName) {
      if (mounted) {
        setState(() {
          _clientConnected = true;
          _clientPilotName = pilotName;
        });
      }
    };

    _host!.onClientDisconnected = () {
      if (mounted) {
        setState(() {
          _clientConnected = false;
          _clientPilotName = null;
        });
      }
    };

    // Get local IP for display
    _localIp = await _getLocalIp();

    // Start UDP beacon broadcast
    _discovery = CoopDiscovery();
    await _discovery!.startBroadcast(port, widget.pilotName);

    if (mounted) setState(() {});
  }

  Future<String> _getLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback) return addr.address;
        }
      }
    } catch (_) {}
    return '?.?.?.?';
  }

  Future<void> _startDiscovery() async {
    _discovery = CoopDiscovery();
    _discovery!.onHostsChanged = () {
      if (mounted) setState(() {});
    };
    await _discovery!.startListening();
  }

  Future<void> _connectToHost(String ip, int port) async {
    if (_connecting) return;
    setState(() => _connecting = true);

    _client = CoopClient();
    _client!.onConnected = (hostPilotName) {
      if (mounted) {
        setState(() {
          _connectedHostName = hostPilotName;
          _connecting = false;
        });
      }
    };
    _client!.onDisconnected = () {
      if (mounted) {
        setState(() {
          _connectedHostName = null;
          _connecting = false;
          _client = null;
        });
      }
    };

    final ok = await _client!.connect(ip, port, widget.pilotName);
    if (!ok && mounted) {
      setState(() {
        _connecting = false;
        _client = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connection failed')),
        );
      }
    }
  }

  @override
  void dispose() {
    _discovery?.dispose();
    // Don't dispose host/client — they'll be passed to game
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0a0a2e), Color(0xFF000010)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            Expanded(
              child: widget.isHost ? _buildHostView() : _buildClientView(),
            ),
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        widget.isHost ? 'HOSTING CO-OP' : 'JOIN CO-OP',
        style: const TextStyle(
          color: Colors.cyanAccent,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: 3,
        ),
      ),
    );
  }

  Widget _buildHostView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Connection info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(10),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white24),
            ),
            child: Column(
              children: [
                Text(
                  'IP: ${_localIp ?? '...'}',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  'Port: ${_host?.port ?? '...'}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Status
          if (!_clientConnected) ...[
            const CircularProgressIndicator(color: Colors.cyanAccent),
            const SizedBox(height: 16),
            const Text(
              'Waiting for Player 2...',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ] else ...[
            const Icon(Icons.check_circle, color: Colors.greenAccent, size: 48),
            const SizedBox(height: 12),
            Text(
              '${_clientPilotName ?? 'Player 2'} connected!',
              style: const TextStyle(color: Colors.greenAccent, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildClientView() {
    if (_connectedHostName != null) {
      return Column(
        children: [
          const Icon(Icons.check_circle, color: Colors.greenAccent, size: 48),
          const SizedBox(height: 12),
          Text(
            'Connected to $_connectedHostName!',
            style: const TextStyle(color: Colors.greenAccent, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Discovered hosts
          const Text(
            'Games found:',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _discovery != null && _discovery!.hosts.isNotEmpty
                ? ListView(
                    children: _discovery!.hosts.entries.map((entry) {
                      final ip = entry.key;
                      final info = entry.value;
                      return ListTile(
                        title: Text(
                          info.pilotName,
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          '$ip:${info.port}',
                          style: const TextStyle(color: Colors.white38, fontSize: 11),
                        ),
                        trailing: _connecting
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent),
                              )
                            : const Icon(Icons.play_arrow, color: Colors.cyanAccent),
                        onTap: () => _connectToHost(ip, info.port),
                      );
                    }).toList(),
                  )
                : const Center(
                    child: Text(
                      'Searching...',
                      style: TextStyle(color: Colors.white38),
                    ),
                  ),
          ),

          // Manual IP fallback
          const Divider(color: Colors.white24),
          const Text(
            'Manual connect:',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _ipController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'IP address',
                    hintStyle: TextStyle(color: Colors.white24),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent)),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: TextField(
                  controller: _portController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Port',
                    hintStyle: TextStyle(color: Colors.white24),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent)),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  final ip = _ipController.text.trim();
                  final port = int.tryParse(_portController.text.trim());
                  if (ip.isNotEmpty && port != null) {
                    _connectToHost(ip, port);
                  }
                },
                icon: const Icon(Icons.arrow_forward, color: Colors.cyanAccent),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                _discovery?.dispose();
                if (!_clientConnected && _host != null) {
                  _host!.dispose();
                }
                if (_connectedHostName == null && _client != null) {
                  _client!.dispose();
                }
                widget.onCancel();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white54,
                side: const BorderSide(color: Colors.white24),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('CANCEL'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _canProceed ? _proceed : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'START',
                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool get _canProceed {
    if (widget.isHost) return _clientConnected;
    return _connectedHostName != null;
  }

  void _proceed() {
    _discovery?.dispose();
    _discovery = null;

    if (widget.isHost) {
      widget.onHostReady(_host!, _clientPilotName ?? 'Player 2');
    } else {
      // Socket is already connected — IP/port not needed
      widget.onClientReady(_client!, '', 0);
    }
  }
}
