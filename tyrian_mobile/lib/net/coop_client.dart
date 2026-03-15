import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'protocol.dart';

/// TCP client for co-op. Connects to a host, sends input, receives snapshots.
class CoopClient {
  Socket? _socket;
  final MessageFramer _framer = MessageFramer();

  bool get isConnected => _socket != null;

  // Latest snapshot received from host (client reads this each frame)
  GameSnapshot? latestSnapshot;

  // Callbacks
  void Function(String hostPilotName)? onConnected;
  void Function()? onDisconnected;
  void Function(int eventType, double x, double y, String text)? onGameEvent;
  void Function(Uint8List payload)? onShopState;

  /// Connect to host at given IP and port
  Future<bool> connect(String host, int port, String pilotName) async {
    print('Client: connecting to $host:$port');
    try {
      _socket = await Socket.connect(host, port,
          timeout: const Duration(seconds: 5));
      _socket!.setOption(SocketOption.tcpNoDelay, true);

      _socket!.listen(
        (data) => _onData(Uint8List.fromList(data)),
        onDone: _onDone,
        onError: (_) => _onDone(),
        cancelOnError: false,
      );

      // Send handshake
      _socket!.add(encodeLobbyHandshake(pilotName));
      print('Client: connected');
      return true;
    } catch (e) {
      print('Client: connect failed: $e');
      return false;
    }
  }

  void _onData(Uint8List data) {
    final messages = _framer.addData(data);
    for (final (type, payload) in messages) {
      try {
        switch (type) {
          case MsgType.gameStateSnapshot:
            latestSnapshot = decodeGameSnapshot(payload);

          case MsgType.lobbyHandshake:
            final hs = decodeLobbyHandshake(payload);
            onConnected?.call(hs.pilotName);

          case MsgType.gameEvent:
            final ev = decodeGameEvent(payload);
            onGameEvent?.call(ev.eventType, ev.x, ev.y, ev.text);

          case MsgType.shopState:
            onShopState?.call(payload);
        }
      } catch (e) {
        print('CoopClient._onData error: $e');
      }
    }
  }

  void _onDone() {
    _socket = null;
    onDisconnected?.call();
  }

  /// Send player input to host (called every frame)
  void sendInput(double dx, double dy, bool fire) {
    _socket?.add(encodeClientInput(dx, dy, fire));
  }

  /// Send ready signal to host
  void sendReady() {
    _socket?.add(encodeReadySignal());
  }

  /// Send shop action to host
  void sendShopAction(int action, String weaponName, int slot) {
    _socket?.add(encodeShopAction(action, weaponName, slot));
  }

  /// Disconnect from host
  Future<void> dispose() async {
    _socket?.destroy();
    _socket = null;
  }
}
