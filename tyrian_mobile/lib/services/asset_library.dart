import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/painting.dart';

import 'skin_registry.dart';

/// Replaces Library.cls — loads and caches all game sprites.
/// BMP+mask system is eliminated; all assets are PNG with alpha channel.
class AssetLibrary {
  AssetLibrary._();
  static final AssetLibrary instance = AssetLibrary._();

  final Map<String, Sprite> _sprites = {};
  final Map<String, ui.Image> _images = {};
  final List<Sprite> _vesselFrames = [];
  final List<ui.Image> _bgLayers = [];
  List<ui.Image> get bgLayers => _bgLayers;

  bool _loaded = false;
  String _skinId = 'default';

  String get skinId => _skinId;

  /// Switch to a different skin. Clears all caches and reloads.
  Future<void> loadSkin(String skinId) async {
    _sprites.clear();
    _images.clear();
    _bgLayers.clear();
    _loaded = false;
    _placeholder = null;
    // Clear Flame's image cache so it reloads from the new paths
    Flame.images.clearCache();
    _skinId = skinId;
    await loadAll();
  }

  /// Load preview images for all skins (for the skin selector screen).
  Future<Map<String, ui.Image>> loadPreviews() async {
    Flame.images.prefix = 'assets/';
    final previews = <String, ui.Image>{};
    for (final skin in kSkins) {
      try {
        final img = await Flame.images.load(skin.previewPath);
        previews[skin.id] = img;
      } catch (e) {
        print('Preview load failed for ${skin.id}: $e');
      }
    }
    return previews;
  }

  Future<void> loadAll() async {
    if (_loaded) return;

    // Flame expects images under assets/images/ by default.
    // We override the prefix so it loads from assets/ directly.
    Flame.images.prefix = 'assets/';

    String p(String name) => 'skins/$_skinId/sprites/$name.png';

    // Player — animated vessel frames (fall back to single vessel.png)
    _vesselFrames.clear();
    for (int i = 0; i < 4; i++) {
      final loaded = await _tryLoad('vessel_$i', p('vessel_$i'));
      if (loaded) _vesselFrames.add(_sprites['vessel_$i']!);
    }
    if (_vesselFrames.isEmpty) {
      await _load('vessel', p('vessel'));
    }

    // Enemies — falcon variants
    await _load('falcon', p('falcon'));
    for (int i = 1; i <= 6; i++) {
      await _load('falcon$i', p('falcon$i'));
    }
    await _load('falconx', p('falconx'));
    await _load('falconx2', p('falconx2'));
    await _load('falconx3', p('falconx3'));
    await _load('falconxb', p('falconxb'));
    await _load('falconxt', p('falconxt'));
    await _load('bouncer', p('bouncer'));

    // Structures
    await _load('asteroid', p('asteroid'));
    await _load('asteroid1', p('asteroid1'));
    await _load('asteroid2', p('asteroid2'));
    await _load('asteroid3', p('asteroid3'));

    // Projectiles
    await _load('bubble', p('bubble'));
    await _load('vulcan', p('vulcan'));
    await _load('blaster', p('blaster'));
    await _load('laser', p('laser'));
    await _load('starg', p('starg'));

    // Explosions (4 variations)
    for (int i = 1; i <= 4; i++) {
      await _load('explosion$i', p('explosion$i'));
    }

    // Background layers (optional — only AI skins have them)
    _bgLayers.clear();
    for (int i = 0; i < 4; i++) {
      final img = await _tryLoadImage('skins/$_skinId/backgrounds/layer_$i.png');
      if (img != null) _bgLayers.add(img);
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
    } catch (e) {
      print('Asset load failed [$name]: $e');
    }
  }

  /// Like _load but returns false on failure (no error log).
  Future<bool> _tryLoad(String name, String path) async {
    try {
      final image = await Flame.images.load(path);
      _images[name] = image;
      final sprite = Sprite(image);
      sprite.paint.filterQuality = FilterQuality.none;
      _sprites[name] = sprite;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Load a raw ui.Image, returning null on failure (silent).
  Future<ui.Image?> _tryLoadImage(String path) async {
    try {
      return await Flame.images.load(path);
    } catch (_) {
      return null;
    }
  }

  Sprite? getSprite(String name) => _sprites[name];

  /// Animated vessel frames (empty if skin uses single vessel.png).
  List<Sprite> get vesselFrames => _vesselFrames;

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
    return _placeholder ?? Sprite(Flame.images.fromCache('skins/$_skinId/sprites/vessel.png'));
  }
}
