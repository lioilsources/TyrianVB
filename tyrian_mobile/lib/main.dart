import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game/tyrian_game.dart';
import 'ui/com_center.dart';
import 'ui/osd_panel.dart';
import 'ui/high_scores.dart';
import 'ui/skin_selector.dart';
import 'services/save_service.dart';
import 'services/sound_service.dart';
import 'net/coop_host.dart';
import 'net/coop_client.dart';
import 'net/discovery.dart';
import 'net/protocol.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(const TyrianApp());
}

class TyrianApp extends StatelessWidget {
  const TyrianApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tyrian',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

enum _ScreenState { mainMenu, game }

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late TyrianGame _game;
  _ScreenState _screen = _ScreenState.mainMenu;
  bool _showComCenter = false;
  bool _showHighScores = false;
  List<HighScoreEntry> _highScores = [];

  // Scanning state
  bool _scanning = false;
  String _scanStatus = 'Looking for games...';

  // Auto-host state (active from ComCenter through gameplay)
  CoopHost? _autoHost;
  CoopDiscovery? _autoDiscovery;

  // Client waiting overlay (P2 waiting for host to start)
  bool _clientWaiting = false;

  // Device name — loaded async, applied when game is ready
  String _pilotName = 'Pilot';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _game = TyrianGame();
    _setupGameCallbacks();
    _loadHighScores();
    _loadDeviceName();
    SoundService.instance.init();
    SoundService.instance.loadSkin('default');
  }

  Future<void> _loadDeviceName() async {
    try {
      final info = DeviceInfoPlugin();
      String name;
      if (Platform.isIOS) {
        final ios = await info.iosInfo;
        name = ios.name;
      } else if (Platform.isAndroid) {
        final android = await info.androidInfo;
        name = android.model;
      } else {
        return;
      }
      if (name.isNotEmpty) {
        _pilotName = name;
        if (_game.isLoaded) {
          _game.vessel.pilotName = name;
        }
      }
    } catch (_) {}
  }

  void _setupGameCallbacks() {
    _game.onLoaded = () {
      _game.vessel.pilotName = _pilotName;
      if (mounted) setState(() {});
    };

    _game.onShowComCenter = () {
      setState(() => _showComCenter = true);
    };

    _game.onGameOver = () async {
      final entry = HighScoreEntry(
        name: _game.vessel.pilotName,
        score: _game.vessel.credit,
        level: _game.currentSectorIndex + 1,
      );
      await SaveService.saveHighScore(entry);
      await _loadHighScores();

      if (_game.coopRole == CoopRole.host && _game.coopHost != null) {
        _game.coopHost!.sendEvent(EventType.gameOver);
      }

      if (mounted) {
        setState(() => _showHighScores = true);
      }
    };

    _game.onSectorComplete = () {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          if (_game.coopRole != CoopRole.client) {
            _game.advanceToNextSector();
            _game.openComCenter();
          } else {
            // P2: show waiting overlay while host shops
            setState(() => _clientWaiting = true);
          }
        }
      });
    };

    _game.onOsdUpdate = () {
      if (mounted) setState(() {});
    };

    // Co-op client: when host signals game start
    _game.onRemoteStart = () {
      if (mounted) {
        setState(() {
          _showComCenter = false;
          _clientWaiting = false;
        });
      }
    };

    // Co-op: remote peer disconnected
    _game.onDisconnected = () {
      if (mounted) {
        // Client in waiting state → return to menu
        if (_clientWaiting || _game.state == GameState.comCenter) {
          _returnToMainMenu();
        }
        // If playing, just show message (already done in setupCoopClient)
      }
    };
  }

  Future<void> _loadHighScores() async {
    _highScores = await SaveService.loadHighScores();
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (_game.state == GameState.playing) {
        _game.togglePause();
        if (_game.coopRole == CoopRole.host && _game.coopHost != null) {
          _game.coopHost!.sendEvent(EventType.paused);
        }
        if (mounted) setState(() {});
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeAutoHost();
    _game.disposeCoop();
    super.dispose();
  }

  // ==== PLAY button: scan then auto-host or join ====

  Future<void> _startPlayWithScan() async {
    if (_scanning) return;
    setState(() {
      _scanning = true;
      _scanStatus = 'Looking for games...';
    });

    final discovery = CoopDiscovery();
    await discovery.startListening();

    // Poll every 200ms for up to 3s
    for (int i = 0; i < 15; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) { discovery.dispose(); return; }

      if (discovery.hosts.isNotEmpty) {
        final entry = discovery.hosts.entries.first;
        final ip = entry.key;
        final hostInfo = entry.value;
        discovery.dispose();

        setState(() => _scanStatus = 'Found ${hostInfo.pilotName}! Connecting...');
        await Future.delayed(const Duration(milliseconds: 400));
        if (!mounted) return;

        setState(() => _scanning = false);
        await _joinAsClient(ip, hostInfo.port);
        return;
      }
    }

    // No host found → show choice: solo or manual IP
    discovery.dispose();
    if (!mounted) return;
    setState(() => _scanning = false);
    _showNoHostDialog();
  }

  /// Get the device's WiFi IP for display
  Future<String> _getLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      for (final iface in interfaces) {
        // Prefer WiFi interface (en0 on iOS, wlan0 on Android)
        if (iface.name.startsWith('en') || iface.name.startsWith('wlan')) {
          for (final addr in iface.addresses) {
            if (!addr.isLoopback) return addr.address;
          }
        }
      }
      // Fallback: any non-loopback address
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback) return addr.address;
        }
      }
    } catch (_) {}
    return '?';
  }

  void _showNoHostDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('No games found', style: TextStyle(color: Colors.cyanAccent)),
        content: const Text(
          'Start a new game (others can join later)\nor enter the host\'s IP to connect.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(ctx); _startAsAutoHost(); },
            child: const Text('START SOLO', style: TextStyle(color: Colors.cyanAccent)),
          ),
          TextButton(
            onPressed: () { Navigator.pop(ctx); _showManualIpDialog(); },
            child: const Text('ENTER IP', style: TextStyle(color: Colors.orangeAccent)),
          ),
        ],
      ),
    );
  }

  void _showManualIpDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Connect to host', style: TextStyle(color: Colors.cyanAccent)),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.url,
          style: const TextStyle(color: Colors.white, fontSize: 18),
          decoration: const InputDecoration(
            hintText: '192.168.x.x',
            hintStyle: TextStyle(color: Colors.white38),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              final ip = controller.text.trim();
              if (ip.isNotEmpty) {
                Navigator.pop(ctx);
                _joinAsClient(ip, CoopHost.defaultPort);
              }
            },
            child: const Text('CONNECT', style: TextStyle(color: Colors.cyanAccent)),
          ),
        ],
      ),
    );
  }

  Future<void> _startAsAutoHost() async {
    _game.resetForNewGame();

    _autoHost = CoopHost();
    final port = await _autoHost!.start(_game.vessel.pilotName);

    _game.setupAutoHost(_autoHost!);
    _game.hostIp = await _getLocalIp();
    print('Host: local IP = ${_game.hostIp}, TCP port = $port');

    // Wire up client-joined notification for UI
    _game.onClientJoined = () {
      if (mounted) setState(() {});
    };

    // Start UDP broadcast
    _autoDiscovery = CoopDiscovery();
    await _autoDiscovery!.startBroadcast(port, _game.vessel.pilotName);

    if (mounted) {
      setState(() {
        _screen = _ScreenState.game;
        _showComCenter = true;
      });
    }
  }

  Future<void> _joinAsClient(String ip, int port) async {
    _game.resetForNewGame();
    print('Joining $ip:$port');
    final client = CoopClient();
    final ok = await client.connect(ip, port, _game.vessel.pilotName);
    if (!ok) {
      // Connection failed → show feedback, then fall back to auto-host
      setState(() => _scanStatus = 'Connection failed, starting solo...');
      _scanning = true;
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() => _scanning = false);
        await _startAsAutoHost();
      }
      return;
    }

    await _game.setupCoopClient(client);

    if (mounted) {
      setState(() {
        _screen = _ScreenState.game;
        _clientWaiting = true;
      });
    }
  }

  void _disposeAutoHost() {
    _autoDiscovery?.dispose();
    _autoDiscovery = null;
    // Don't dispose _autoHost here — it's owned by _game.coopHost after setupAutoHost
    _autoHost = null;
  }

  void _returnToMainMenu() async {
    _disposeAutoHost();
    await _game.disposeCoop();
    _game.vessel.newGame();
    _game.currentSectorIndex = 0;
    _game.state = GameState.comCenter;
    if (mounted) {
      setState(() {
        _screen = _ScreenState.mainMenu;
        _showComCenter = false;
        _showHighScores = false;
        _clientWaiting = false;
      });
    }
  }

  /// After game over with co-op: revive vessels, return to ComCenter
  void _returnToCoopComCenter() {
    _game.vessel.resetVessel();
    _game.vessel.resetPosition();
    _game.vessel2?.resetVessel();
    _game.vessel2?.resetPosition();
    _game.state = GameState.comCenter;
    if (mounted) {
      setState(() {
        _showHighScores = false;
        _showComCenter = true;
      });
    }
  }

  /// ComCenter START button handler (host/solo)
  void _onComCenterStart() {
    setState(() => _showComCenter = false);
    if (_game.currentSector == null) {
      _game.startGame();
    } else {
      _game.vessel.resetVessel();
      _game.vessel2?.resetVessel();
      _game.resumeFromComCenter(); // handles P2 clone + gameStart event
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Game canvas (always renders — starfield visible behind menus)
          GameWidget(game: _game),

          // Main menu with skin selector
          if (_game.isLoaded && _screen == _ScreenState.mainMenu && !_scanning)
            SkinSelector(onPlay: () {
              _game.refreshSprites();
              _startPlayWithScan();
            }),

          // Scanning spinner overlay
          if (_scanning)
            _buildScanningOverlay(),

          // Game screen overlays
          if (_game.isLoaded && _screen == _ScreenState.game) ...[
            // OSD HUD
            if (!_showComCenter && !_showHighScores && !_clientWaiting &&
                _game.state != GameState.gameOver)
              OsdPanel(game: _game, onMuteToggle: () => setState(() {})),

            // Pause overlay
            if (_game.state == GameState.paused)
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.cyanAccent.withAlpha(100)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'PAUSED',
                        style: TextStyle(
                          color: Colors.cyanAccent,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          _game.togglePause();
                          if (_game.coopRole == CoopRole.host && _game.coopHost != null) {
                            _game.coopHost!.sendEvent(EventType.resumed);
                          }
                          setState(() {});
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyanAccent,
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('RESUME'),
                      ),
                    ],
                  ),
                ),
              ),

            // ComCenter (host/solo only — P2 never sees this)
            if (_showComCenter)
              ComCenterScreen(
                game: _game,
                onStart: _onComCenterStart,
              ),

            // Client waiting overlay (P2)
            if (_clientWaiting && !_showHighScores)
              _buildWaitingOverlay(),

            // High Scores
            if (_showHighScores)
              HighScoresScreen(
                scores: _highScores,
                onClose: _game.isCoop ? _returnToCoopComCenter : _returnToMainMenu,
              ),

            // Game Over
            if (_game.state == GameState.gameOver && !_showHighScores)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withAlpha(150)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'GAME OVER',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Credits: ${_game.vessel.credit}',
                        style: const TextStyle(color: Colors.greenAccent, fontSize: 18),
                      ),
                      if (_game.isCoop && _game.vessel2 != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'P2: ${_game.vessel2!.credit}',
                          style: const TextStyle(color: Color(0xFF00FF80), fontSize: 16),
                        ),
                      ],
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => setState(() => _showHighScores = true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyanAccent,
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('VIEW SCORES'),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildScanningOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.cyanAccent),
            const SizedBox(height: 16),
            Text(
              _scanStatus,
              style: const TextStyle(
                color: Colors.cyanAccent,
                fontSize: 16,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaitingOverlay() {
    return Container(
      color: Colors.black87,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.cyanAccent),
            SizedBox(height: 16),
            Text(
              'Waiting for host...',
              style: TextStyle(
                color: Colors.cyanAccent,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Game will start when host is ready',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
