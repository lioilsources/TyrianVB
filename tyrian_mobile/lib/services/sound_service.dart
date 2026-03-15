import 'package:flame_audio/flame_audio.dart';
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
class SoundService {
  static final instance = SoundService._();
  SoundService._();

  String _skinId = 'default';
  bool _muted = false;
  bool _ready = false;

  bool get muted => _muted;

  // Maps SfxEvent → asset path relative to assets/
  final Map<SfxEvent, String> _paths = {};

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
    // Set FlameAudio prefix to assets root so we can use skin paths directly
    FlameAudio.audioCache.prefix = 'assets/';
  }

  /// Load SFX paths for the given skin, falling back to default.
  Future<void> loadSkin(String skinId) async {
    _skinId = skinId;
    _paths.clear();
    _ready = false;

    for (final entry in _eventFileNames.entries) {
      // Path relative to assets/ — try skin-specific, fallback to default
      final skinPath = 'skins/$skinId/sfx/${entry.value}.ogg';
      final defaultPath = 'skins/default/sfx/${entry.value}.ogg';
      _paths[entry.key] = skinId == 'default' ? defaultPath : skinPath;
    }
    _ready = true;
  }

  /// Play a sound effect (fire-and-forget).
  void play(SfxEvent event) {
    if (_muted || !_ready) return;
    final path = _paths[event];
    if (path == null) return;

    _playPath(path).then((_) {}, onError: (_) {
      // If skin-specific file missing, try default fallback
      if (_skinId != 'default') {
        final fallback = 'skins/default/sfx/${_eventFileNames[event]}.ogg';
        _playPath(fallback).then((_) {}, onError: (_) {});
      }
    });
  }

  Future<void> _playPath(String path) async {
    await FlameAudio.play(path, volume: 1.0);
  }

  /// Toggle mute on/off and persist.
  Future<void> toggleMute() async {
    _muted = !_muted;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sfx_muted', _muted);
  }
}
