import 'dart:ui' as ui;
import 'package:flame/extensions.dart';
import 'package:flame/post_process.dart';
import 'package:flutter/painting.dart';

class BloomPass extends PostProcess {
  late ui.FragmentShader _thresholdShader;
  late ui.FragmentShader _blurShader;
  late ui.FragmentShader _compositeShader;

  bool enabled = false;
  double strength = 0.0;
  double threshold = 0.8;

  BloomPass() : super(pixelRatio: 1.0);

  @override
  Future<void> onLoad() async {
    final thresholdProg =
        await ui.FragmentProgram.fromAsset('shaders/bloom_threshold.frag');
    _thresholdShader = thresholdProg.fragmentShader();

    final blurProg =
        await ui.FragmentProgram.fromAsset('shaders/bloom_blur.frag');
    _blurShader = blurProg.fragmentShader();

    final compositeProg =
        await ui.FragmentProgram.fromAsset('shaders/bloom_composite.frag');
    _compositeShader = compositeProg.fragmentShader();
  }

  @override
  void postProcess(Vector2 size, Canvas canvas) {
    if (!enabled) {
      renderSubtree(canvas);
      return;
    }

    final scene = rasterizeSubtree();
    final w = scene.width.toDouble();
    final h = scene.height.toDouble();
    final imgSize = Size(w, h);

    // 1. Threshold — extract bright pixels
    _thresholdShader.setFloatUniforms((s) {
      s.setSize(imgSize);
      s.setFloat(threshold);
    });
    _thresholdShader.setImageSampler(0, scene);
    final thresholdImg = _renderShaderToImage(w, h, _thresholdShader);

    // 2. Horizontal blur
    _blurShader.setFloatUniforms((s) {
      s.setSize(imgSize);
      s.setFloat(1.0); // uDirection.x
      s.setFloat(0.0); // uDirection.y
    });
    _blurShader.setImageSampler(0, thresholdImg);
    final hBlurImg = _renderShaderToImage(w, h, _blurShader);
    thresholdImg.dispose();

    // 3. Vertical blur
    _blurShader.setFloatUniforms((s) {
      s.setSize(imgSize);
      s.setFloat(0.0); // uDirection.x
      s.setFloat(1.0); // uDirection.y
    });
    _blurShader.setImageSampler(0, hBlurImg);
    final vBlurImg = _renderShaderToImage(w, h, _blurShader);
    hBlurImg.dispose();

    // 4. Composite — original scene + blurred bloom
    _compositeShader.setFloatUniforms((s) {
      s.setSize(imgSize);
      s.setFloat(strength);
    });
    _compositeShader.setImageSampler(0, scene);
    _compositeShader.setImageSampler(1, vBlurImg);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..shader = _compositeShader,
    );
    vBlurImg.dispose();
  }

  /// Render a shader into an offscreen image at pixel dimensions [w] x [h].
  ui.Image _renderShaderToImage(
      double w, double h, ui.FragmentShader shader) {
    final recorder = ui.PictureRecorder();
    final c = Canvas(recorder);
    c.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..shader = shader);
    final picture = recorder.endRecording();
    final image = picture.toImageSync(w.ceil(), h.ceil());
    picture.dispose();
    return image;
  }
}
