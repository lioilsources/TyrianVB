import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/painting.dart';
import '../game/tyrian_game.dart';

/// A temporary visual component that plays a pixel-explosion shader effect
/// at a fixed world position. Used for boss death spectacles.
///
/// The entity sprite is captured once at creation time, then the shader
/// scatters its pixels outward each frame until the animation completes.
class PixelExplosionOverlay extends PositionComponent
    with HasGameReference<TyrianGame> {
  final ui.Image _snapshot;
  final double _hitUvX;
  final double _hitUvY;
  final double _duration;
  final double _spread;

  ui.FragmentShader? _shader;
  double _time = 0;

  PixelExplosionOverlay({
    required ui.Image snapshot,
    required Vector2 position,
    required Vector2 size,
    double hitUvX = 0.5,
    double hitUvY = 0.5,
    double duration = 0.8,
    double spread = 2.0,
  })  : _snapshot = snapshot,
        _hitUvX = hitUvX,
        _hitUvY = hitUvY,
        _duration = duration,
        _spread = spread,
        super(position: position, size: size);

  @override
  Future<void> onLoad() async {
    final prog =
        await ui.FragmentProgram.fromAsset('shaders/pixel_explosion.frag');
    _shader = prog.fragmentShader();
  }

  @override
  void update(double dt) {
    _time += dt;
    if (_time >= _duration) {
      _snapshot.dispose();
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    if (_shader == null) return;

    final t = (_time / _duration).clamp(0.0, 1.0);
    final w = size.x;
    final h = size.y;

    _shader!.setFloat(0, w);        // uSize.x
    _shader!.setFloat(1, h);        // uSize.y
    _shader!.setFloat(2, t);        // uTime
    _shader!.setFloat(3, _hitUvX);  // uHitX
    _shader!.setFloat(4, _hitUvY);  // uHitY
    _shader!.setFloat(5, _spread);  // uSpread
    _shader!.setImageSampler(0, _snapshot);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..shader = _shader!,
    );
  }
}

/// Capture a Flame [Sprite] to a [ui.Image] for use in shader effects.
ui.Image captureSprite(Sprite sprite, double width, double height) {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  sprite.render(canvas, size: Vector2(width, height));
  final picture = recorder.endRecording();
  final image = picture.toImageSync(width.ceil(), height.ceil());
  picture.dispose();
  return image;
}
