import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SfxEvent {
  fireBullet,
  fireBeam,
  hitShield,
  hitHull,
  explosionSmall,
  explosionLarge,
  pickup,
  weaponUnlock,
  sectorComplete,
  gameOver,
}

/// Fire-and-forget SFX playback with per-skin sound packs.
/// Uses just_audio which supports .ogg on all platforms (incl. Windows).
class SoundService {
  static final instance = SoundService._();
  SoundService._();

  static const _poolSize = 3;

  String _skinId = 'default';
  bool _muted = false;
  bool _ready = false;
  bool _disabled = false;

  bool get muted => _muted;

  // Maps SfxEvent → asset path (relative, prefixed with assets/)
  final Map<SfxEvent, String> _paths = {};
  // Player pool per event: round-robin for overlapping sounds
  final Map<SfxEvent, List<AudioPlayer>> _pools = {};
  final Map<SfxEvent, int> _poolIndex = {};
  // Paths that have failed — never retry
  final Set<String> _failedPaths = {};
  int _failCount = 0;

  static const _eventFileNames = {
    SfxEvent.fireBullet: 'fire_bullet',
    SfxEvent.fireBeam: 'fire_beam',
    SfxEvent.hitShield: 'hit_shield',
    SfxEvent.hitHull: 'hit_hull',
    SfxEvent.explosionSmall: 'explosion_small',
    SfxEvent.explosionLarge: 'explosion_large',
    SfxEvent.pickup: 'pickup',
    SfxEvent.weaponUnlock: 'weapon_unlock',
    SfxEvent.sectorComplete: 'sector_complete',
    SfxEvent.gameOver: 'game_over',
  };

  /// Load mute state from prefs. Call once at app start.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _muted = prefs.getBool('sfx_muted') ?? false;
  }

  /// Load SFX paths for the given skin, falling back to default.
  Future<void> loadSkin(String skinId) async {
    _skinId = skinId;
    _paths.clear();
    _failedPaths.clear();
    _failCount = 0;
    _disabled = false;
    _ready = false;

    // Dispose old players
    for (final pool in _pools.values) {
      for (final player in pool) {
        player.dispose();
      }
    }
    _pools.clear();
    _poolIndex.clear();

    for (final entry in _eventFileNames.entries) {
      final skinPath = 'assets/skins/$skinId/sfx/${entry.value}.ogg';
      final defaultPath = 'assets/skins/default/sfx/${entry.value}.ogg';
      _paths[entry.key] = skinId == 'default' ? defaultPath : skinPath;

      // Create player pool for this event
      final players = <AudioPlayer>[];
      for (int i = 0; i < _poolSize; i++) {
        players.add(AudioPlayer());
      }
      _pools[entry.key] = players;
      _poolIndex[entry.key] = 0;
    }

    _ready = true;

    // Preload in background — don't block skin loading
    _preloadAll();
  }

  Future<void> _preloadAll() async {
    for (final entry in _paths.entries) {
      if (!_ready) return; // skin changed mid-preload
      await _preload(entry.key, entry.value);
    }
  }

  Future<void> _preload(SfxEvent event, String path) async {
    final pool = _pools[event];
    if (pool == null) return;
    try {
      // Only preload the first player; others load lazily on play()
      await pool[0].setAsset(path).timeout(const Duration(seconds: 2));
      pool[0].setVolume(1.0);
    } catch (e) {
      _failedPaths.add(path);
      // Try default fallback
      if (_skinId != 'default') {
        final fallback = 'assets/skins/default/sfx/${_eventFileNames[event]}.ogg';
        _paths[event] = fallback;
        try {
          await pool[0].setAsset(fallback).timeout(const Duration(seconds: 2));
          pool[0].setVolume(1.0);
        } catch (_) {
          _failedPaths.add(fallback);
        }
      }
    }
  }

  /// Play a sound effect (fire-and-forget).
  void play(SfxEvent event) {
    if (_muted || !_ready || _disabled) return;
    final path = _paths[event];
    if (path == null || _failedPaths.contains(path)) return;

    final pool = _pools[event];
    if (pool == null || pool.isEmpty) return;

    final idx = _poolIndex[event] ?? 0;
    _poolIndex[event] = (idx + 1) % pool.length;
    final player = pool[idx];

    _playPlayer(player, path);
  }

  void _playPlayer(AudioPlayer player, String path) async {
    try {
      // If player has no source yet, set it first
      if (player.audioSource == null) {
        await player.setAsset(path).timeout(const Duration(seconds: 2));
        player.setVolume(_muted ? 0.0 : 1.0);
      }
      await player.seek(Duration.zero);
      player.play();
      _failCount = 0;
    } catch (_) {
      _failedPaths.add(path);
      _failCount++;
      if (_failCount >= 5) {
        _disabled = true;
        print('SoundService: too many failures, audio disabled');
      }
    }
  }

  /// Toggle mute on/off and persist.
  Future<void> toggleMute() async {
    _muted = !_muted;
    // Mute/unmute all active players
    for (final pool in _pools.values) {
      for (final player in pool) {
        player.setVolume(_muted ? 0.0 : 1.0);
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sfx_muted', _muted);
  }
}
