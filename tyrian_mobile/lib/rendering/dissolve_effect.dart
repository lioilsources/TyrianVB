import 'dart:ui' as ui;
import 'package:flutter/painting.dart';

/// Per-entity dissolve shader effect.
///
/// Usage: call [begin] to start a dissolve animation, then in the entity's
/// render method, call [renderWith] instead of the normal sprite render.
/// The effect rasterizes the entity to an offscreen image, applies the
/// dissolve fragment shader, and draws the result to the canvas.
class DissolveEffect {
  ui.FragmentShader? _shader;
  bool _loaded = false;

  double amount = 0; // 0 = fully visible, 1 = fully dissolved
  double edgeWidth = 0.05;
  double edgeR = 1.0;
  double edgeG = 0.5;
  double edgeB = 0.0; // orange glow by default

  bool _active = false;
  double _speed = 1.0; // units per second
  VoidCallback? onComplete;

  bool get isActive => _active;

  Future<void> load() async {
    if (_loaded) return;
    final prog = await ui.FragmentProgram.fromAsset('shaders/dissolve.frag');
    _shader = prog.fragmentShader();
    _loaded = true;
  }

  /// Start a dissolve animation over [duration] seconds.
  void begin({double duration = 1.0, VoidCallback? onComplete}) {
    amount = 0;
    _speed = 1.0 / duration;
    _active = true;
    this.onComplete = onComplete;
  }

  /// Reverse dissolve (materialize).
  void reverse({double duration = 1.0}) {
    amount = 1.0;
    _speed = -1.0 / duration;
    _active = true;
  }

  void update(double dt) {
    if (!_active) return;
    amount += _speed * dt;
    if (amount >= 1.0) {
      amount = 1.0;
      _active = false;
      onComplete?.call();
    } else if (amount <= 0.0) {
      amount = 0.0;
      _active = false;
    }
  }

  /// Render [drawContent] through the dissolve shader.
  ///
  /// [drawContent] should draw the entity at (0,0) onto the provided canvas.
  /// [width] and [height] are the entity's pixel dimensions.
  void renderWith(
    Canvas canvas,
    double width,
    double height,
    void Function(Canvas c) drawContent,
  ) {
    if (!_loaded || _shader == null) {
      // Shader not ready — fall through to normal render
      drawContent(canvas);
      return;
    }

    if (amount <= 0.001 && !_active) {
      // No dissolve — normal render
      drawContent(canvas);
      return;
    }

    if (amount >= 0.999) {
      // Fully dissolved — draw nothing
      return;
    }

    // Rasterize entity to offscreen image
    final w = width.ceil();
    final h = height.ceil();
    if (w <= 0 || h <= 0) return;

    final recorder = ui.PictureRecorder();
    final offCanvas = Canvas(recorder);
    drawContent(offCanvas);
    final picture = recorder.endRecording();
    final entityImage = picture.toImageSync(w, h);
    picture.dispose();

    // Configure shader
    _shader!.setFloat(0, width);   // uSize.x
    _shader!.setFloat(1, height);  // uSize.y
    _shader!.setFloat(2, amount);  // uAmount
    _shader!.setFloat(3, edgeWidth); // uEdgeWidth
    _shader!.setFloat(4, edgeR);   // uEdgeR
    _shader!.setFloat(5, edgeG);   // uEdgeG
    _shader!.setFloat(6, edgeB);   // uEdgeB
    _shader!.setImageSampler(0, entityImage);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, width, height),
      Paint()..shader = _shader!,
    );
    entityImage.dispose();
  }
}

/// Per-entity pixel explosion shader effect (for boss deaths).
///
/// Similar to DissolveEffect but scatters pixels outward from a hit point.
class PixelExplosionEffect {
  ui.FragmentShader? _shader;
  bool _loaded = false;

  double time = 0; // 0 → 1 animation progress
  double hitX = 0.5; // UV coordinates of hit point
  double hitY = 0.5;
  double spread = 2.0;

  bool _active = false;
  double _duration = 0.8;
  VoidCallback? onComplete;

  bool get isActive => _active;

  Future<void> load() async {
    if (_loaded) return;
    final prog =
        await ui.FragmentProgram.fromAsset('shaders/pixel_explosion.frag');
    _shader = prog.fragmentShader();
    _loaded = true;
  }

  /// Start the pixel explosion from [hitUvX], [hitUvY] over [duration] seconds.
  void begin({
    double hitUvX = 0.5,
    double hitUvY = 0.5,
    double duration = 0.8,
    double spread = 2.0,
    VoidCallback? onComplete,
  }) {
    time = 0;
    hitX = hitUvX;
    hitY = hitUvY;
    _duration = duration;
    this.spread = spread;
    _active = true;
    this.onComplete = onComplete;
  }

  void update(double dt) {
    if (!_active) return;
    time += dt / _duration;
    if (time >= 1.0) {
      time = 1.0;
      _active = false;
      onComplete?.call();
    }
  }

  /// Render [drawContent] through the pixel explosion shader.
  void renderWith(
    Canvas canvas,
    double width,
    double height,
    void Function(Canvas c) drawContent,
  ) {
    if (!_loaded || _shader == null || !_active) {
      if (!_active && time >= 1.0) return; // finished — draw nothing
      drawContent(canvas);
      return;
    }

    // Rasterize entity to offscreen image
    final w = width.ceil();
    final h = height.ceil();
    if (w <= 0 || h <= 0) return;

    final recorder = ui.PictureRecorder();
    final offCanvas = Canvas(recorder);
    drawContent(offCanvas);
    final picture = recorder.endRecording();
    final entityImage = picture.toImageSync(w, h);
    picture.dispose();

    _shader!.setFloat(0, width);    // uSize.x
    _shader!.setFloat(1, height);   // uSize.y
    _shader!.setFloat(2, time);     // uTime
    _shader!.setFloat(3, hitX);     // uHitX
    _shader!.setFloat(4, hitY);     // uHitY
    _shader!.setFloat(5, spread);   // uSpread
    _shader!.setImageSampler(0, entityImage);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, width, height),
      Paint()..shader = _shader!,
    );
    entityImage.dispose();
  }
}
