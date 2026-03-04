import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game/tyrian_game.dart';
import 'ui/com_center.dart';
import 'ui/osd_panel.dart';
import 'ui/high_scores.dart';
import 'services/save_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Force portrait for gameplay
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  // Immersive mode
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

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late TyrianGame _game;
  bool _showComCenter = true;
  bool _showHighScores = false;
  List<HighScoreEntry> _highScores = [];

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

      if (mounted) {
        setState(() {
          _showHighScores = true;
        });
      }
    };

    _game.onSectorComplete = () {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _game.advanceToNextSector();
          setState(() => _showComCenter = true);
        }
      });
    };

    _game.onOsdUpdate = () {
      if (mounted) setState(() {});
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
        if (mounted) setState(() {});
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Game canvas (always renders — starfield visible behind menus)
          GameWidget(game: _game),

          // OSD HUD overlay (during gameplay)
          if (_game.isLoaded &&
              !_showComCenter &&
              !_showHighScores &&
              _game.state != GameState.gameOver)
            OsdPanel(game: _game),

          // Pause overlay
          if (_game.isLoaded && _game.state == GameState.paused)
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: Colors.cyanAccent.withAlpha(100)),
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

          // ComCenter overlay
          if (_game.isLoaded && _showComCenter)
            ComCenterScreen(
              game: _game,
              onStart: () {
                setState(() => _showComCenter = false);
                if (_game.currentSector == null) {
                  _game.startGame();
                } else {
                  _game.resumeFromComCenter();
                }
              },
            ),

          // High Scores overlay
          if (_game.isLoaded && _showHighScores)
            HighScoresScreen(
              scores: _highScores,
              onClose: () {
                setState(() {
                  _showHighScores = false;
                  _showComCenter = true;
                });
                _game.vessel.newGame();
                _game.currentSectorIndex = 0;
                _game.state = GameState.comCenter;
              },
            ),

          // Game Over overlay
          if (_game.isLoaded && _game.state == GameState.gameOver && !_showHighScores)
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() => _showHighScores = true);
                      },
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
      ),
    );
  }
}
