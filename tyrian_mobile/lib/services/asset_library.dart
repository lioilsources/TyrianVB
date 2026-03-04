import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/painting.dart';

/// Replaces Library.cls — loads and caches all game sprites.
/// BMP+mask system is eliminated; all assets are PNG with alpha channel.
class AssetLibrary {
  AssetLibrary._();
  static final AssetLibrary instance = AssetLibrary._();

  final Map<String, Sprite> _sprites = {};
  final Map<String, ui.Image> _images = {};

  bool _loaded = false;

  Future<void> loadAll() async {
    if (_loaded) return;

    // Flame expects images under assets/images/ by default.
    // We override the prefix so it loads from assets/ directly.
    Flame.images.prefix = 'assets/';

    // Player
    await _load('vessel', 'sprites/vessel.png');

    // Enemies — falcon variants
    await _load('falcon', 'sprites/falcon.png');
    for (int i = 1; i <= 6; i++) {
      await _load('falcon$i', 'sprites/falcon$i.png');
    }
    await _load('falconx', 'sprites/falconx.png');
    await _load('falconx2', 'sprites/falconx2.png');
    await _load('falconx3', 'sprites/falconx3.png');
    await _load('falconxb', 'sprites/falconxb.png');
    await _load('falconxt', 'sprites/falconxt.png');
    await _load('bouncer', 'sprites/bouncer.png');

    // Structures
    await _load('asteroid', 'sprites/asteroid.png');
    await _load('asteroid1', 'sprites/asteroid1.png');
    await _load('asteroid2', 'sprites/asteroid2.png');
    await _load('asteroid3', 'sprites/asteroid3.png');

    // Projectiles
    await _load('bubble', 'sprites/bubble.png');
    await _load('vulcan', 'sprites/vulcan.png');
    await _load('blaster', 'sprites/blaster.png');
    await _load('laser', 'sprites/laser.png');
    await _load('starg', 'sprites/starg.png');

    // Explosions (4 variations)
    for (int i = 1; i <= 4; i++) {
      await _load('explosion$i', 'sprites/explosion$i.png');
    }

    _loaded = true;
  }

  Future<void> _load(String name, String path) async {
    try {
      final image = await Flame.images.load(path);
      _images[name] = image;
      final sprite = Sprite(image);
      sprite.paint.filterQuality = FilterQuality.none;
      _sprites[name] = sprite;
    } catch (_) {
      // Asset not yet converted — will use placeholder
    }
  }

  Sprite? getSprite(String name) => _sprites[name];

  ui.Image? getImage(String name) => _images[name];

  /// Get sprite or a colored rectangle placeholder
  Sprite getOrPlaceholder(String name) {
    return _sprites[name] ?? _createPlaceholder();
  }

  static Sprite? _placeholder;
  Sprite _createPlaceholder() {
    if (_placeholder != null) return _placeholder!;
    // Use any loaded image as fallback; if none, this will be handled at render
    _placeholder = _sprites.values.isNotEmpty ? _sprites.values.first : null;
    return _placeholder ?? Sprite(Flame.images.fromCache('sprites/vessel.png'));
  }
}
