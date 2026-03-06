import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game/tyrian_game.dart';
import 'ui/com_center.dart';
import 'ui/osd_panel.dart';
import 'ui/high_scores.dart';
import 'ui/coop_lobby.dart';
import 'services/save_service.dart';
import 'net/coop_host.dart';
import 'net/coop_client.dart';
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

enum _ScreenState { mainMenu, coopChoice, lobby, game }

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late TyrianGame _game;
  _ScreenState _screen = _ScreenState.mainMenu;
  bool _showComCenter = false;
  bool _showHighScores = false;
  List<HighScoreEntry> _highScores = [];
  bool _lobbyIsHost = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _game = TyrianGame();
    _setupGameCallbacks();
    _loadHighScores();
  }

  void _setupGameCallbacks() {
    _game.onLoaded = () {
      if (mounted) setState(() {});
    };

    _game.onShowComCenter = () {
      setState(() => _showComCenter = true);
    };

    _game.onGameOver = () async {
      final entry = HighScoreEntry(
        name: _game.vessel.pilotName,
        score: _game.vessel.score,
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
          // Only host advances sector (client gets it via snapshots)
          if (_game.coopRole != CoopRole.client) {
            _game.advanceToNextSector();
          }
          setState(() => _showComCenter = true);
        }
      });
    };

    _game.onOsdUpdate = () {
      if (mounted) setState(() {});
    };

    // Co-op host: when both players are ready in ComCenter
    _game.onBothReady = () {
      if (mounted) {
        setState(() => _showComCenter = false);
        if (_game.currentSector == null) {
          _game.startGame();
        } else {
          _game.vessel.resetVessel();
          _game.vessel2?.resetVessel();
          _game.resumeFromComCenter();
        }
      }
    };

    // Co-op client: when host signals game start
    _game.onRemoteStart = () {
      if (mounted) {
        setState(() => _showComCenter = false);
      }
    };

    // Co-op: remote peer disconnected
    _game.onDisconnected = () {
      if (mounted) {
        // If in game, just show message (already done in setupCoopClient).
        // If in lobby/comcenter, return to menu.
        if (_game.state == GameState.comCenter || _screen != _ScreenState.game) {
          _returnToMainMenu();
        }
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
    _game.disposeCoop();
    super.dispose();
  }

  void _startSolo() {
    setState(() {
      _screen = _ScreenState.game;
      _showComCenter = true;
    });
  }

  void _openCoopChoice() {
    setState(() => _screen = _ScreenState.coopChoice);
  }

  void _openLobby(bool isHost) {
    setState(() {
      _lobbyIsHost = isHost;
      _screen = _ScreenState.lobby;
    });
  }

  void _onHostReady(CoopHost host, String clientPilotName) async {
    await _game.setupCoopHost(host, clientPilotName);
    if (mounted) {
      setState(() {
        _screen = _ScreenState.game;
        _showComCenter = true;
      });
    }
  }

  void _onClientReady(CoopClient client, String hostIp, int hostPort) async {
    await _game.setupCoopClient(client);

    if (mounted) {
      setState(() {
        _screen = _ScreenState.game;
        _showComCenter = true;
      });
    }
  }

  void _returnToMainMenu() async {
    await _game.disposeCoop();
    _game.vessel.newGame();
    _game.currentSectorIndex = 0;
    _game.state = GameState.comCenter;
    if (mounted) {
      setState(() {
        _screen = _ScreenState.mainMenu;
        _showComCenter = false;
        _showHighScores = false;
      });
    }
  }

  /// After co-op game over: revive vessels, return to ComCenter (keep connection alive)
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Game canvas (always renders — starfield visible behind menus)
          GameWidget(game: _game),

          // Main menu
          if (_game.isLoaded && _screen == _ScreenState.mainMenu)
            _buildMainMenu(),

          // Co-op choice: Host or Join
          if (_game.isLoaded && _screen == _ScreenState.coopChoice)
            _buildCoopChoice(),

          // Lobby
          if (_game.isLoaded && _screen == _ScreenState.lobby)
            CoopLobbyScreen(
              isHost: _lobbyIsHost,
              pilotName: _game.vessel.pilotName,
              onHostReady: _onHostReady,
              onClientReady: _onClientReady,
              onCancel: () => setState(() => _screen = _ScreenState.coopChoice),
            ),

          // Game screen overlays
          if (_game.isLoaded && _screen == _ScreenState.game) ...[
            // OSD HUD
            if (!_showComCenter && !_showHighScores && _game.state != GameState.gameOver)
              OsdPanel(game: _game),

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

            // ComCenter
            if (_showComCenter)
              ComCenterScreen(
                game: _game,
                onStart: () {
                  // Solo mode only — co-op uses READY sync
                  if (_game.isCoop) return;
                  setState(() => _showComCenter = false);
                  if (_game.currentSector == null) {
                    _game.startGame();
                  } else {
                    _game.resumeFromComCenter();
                  }
                },
              ),

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
                        'Score: ${_game.vessel.score}',
                        style: const TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      if (_game.isCoop && _game.vessel2 != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'P2 Score: ${_game.vessel2!.score}',
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

  Widget _buildMainMenu() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(200),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'TYRIAN',
              style: TextStyle(
                color: Colors.cyanAccent,
                fontSize: 40,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: _startSolo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'SOLO',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 3),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 200,
              child: OutlinedButton(
                onPressed: _openCoopChoice,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.cyanAccent,
                  side: const BorderSide(color: Colors.cyanAccent),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'CO-OP',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoopChoice() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(200),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'CO-OP',
              style: TextStyle(
                color: Colors.cyanAccent,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'WiFi LAN multiplayer',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: () => _openLobby(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'HOST GAME',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 200,
              child: OutlinedButton(
                onPressed: () => _openLobby(false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.cyanAccent,
                  side: const BorderSide(color: Colors.cyanAccent),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'JOIN GAME',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => setState(() => _screen = _ScreenState.mainMenu),
              child: const Text('BACK', style: TextStyle(color: Colors.white54)),
            ),
          ],
        ),
      ),
    );
  }
}
