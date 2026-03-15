import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'protocol.dart';

/// TCP server for co-op host. Manages a single client connection.
class CoopHost {
  static const int defaultPort = 5743;

  ServerSocket? _server;
  Socket? _client;
  final MessageFramer _framer = MessageFramer();

  int get port => _server?.port ?? 0;
  bool get hasClient => _client != null;
  bool get isRunning => _server != null;

  // Callbacks
  void Function(double dx, double dy, bool fire)? onClientInput;
  Future<void> Function(String pilotName)? onClientConnected;
  void Function()? onClientDisconnected;
  void Function()? onClientReady;
  void Function(int action, int slot, String weaponName)? onShopAction;

  String _hostPilotName = 'Host';

  /// Start listening on fixed port (fallback to random if busy)
  Future<int> start(String hostPilotName) async {
    _hostPilotName = hostPilotName;
    try {
      _server = await ServerSocket.bind(InternetAddress.anyIPv4, defaultPort);
    } catch (_) {
      _server = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
    }
    _server!.listen(_onConnection);
    print('Host: TCP server on port ${_server!.port}');
    return _server!.port;
  }

  void _onConnection(Socket socket) {
    if (_client != null) {
      // Only one client allowed
      socket.destroy();
      return;
    }

    print('Host: client connected from ${socket.remoteAddress.address}');
    _client = socket;
    socket.setOption(SocketOption.tcpNoDelay, true);

    socket.listen(
      (data) => _onData(Uint8List.fromList(data)),
      onDone: _onClientDone,
      onError: (_) => _onClientDone(),
      cancelOnError: false,
    );
  }

  Future<void> _onData(Uint8List data) async {
    final messages = _framer.addData(data);
    for (final (type, payload) in messages) {
      try {
        switch (type) {
          case MsgType.clientInput:
            final input = decodeClientInput(payload);
            onClientInput?.call(input.dx, input.dy, input.fire);

          case MsgType.lobbyHandshake:
            final hs = decodeLobbyHandshake(payload);
            // Send our handshake back
            _client?.add(encodeLobbyHandshake(_hostPilotName));
            await onClientConnected?.call(hs.pilotName);

          case MsgType.readySignal:
            onClientReady?.call();

          case MsgType.shopAction:
            final sa = decodeShopAction(payload);
            onShopAction?.call(sa.action, sa.slot, sa.weaponName);
        }
      } catch (e) {
        print('CoopHost._onData error: $e');
      }
    }
  }

  void _onClientDone() {
    _client = null;
    _framer.addData(Uint8List(0)); // Reset framer
    onClientDisconnected?.call();
  }

  /// Send a pre-encoded framed message to the client
  void send(Uint8List framedMessage) {
    _client?.add(framedMessage);
  }

  /// Send game state snapshot (already framed by protocol.dart)
  void sendSnapshot(Uint8List framedSnapshot) {
    _client?.add(framedSnapshot);
  }

  /// Send a game event to client
  void sendEvent(int eventType, {double x = 0, double y = 0, String text = ''}) {
    _client?.add(encodeGameEvent(eventType, x: x, y: y, text: text));
  }

  /// Shut down server and disconnect client
  Future<void> dispose() async {
    _client?.destroy();
    _client = null;
    await _server?.close();
    _server = null;
  }
}
