import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import '../game/game_config.dart' as config;
import '../services/asset_library.dart';

/// Vertically scrolling parallax background from skin layer images.
/// Layers scroll at different speeds for depth effect.
/// Falls back gracefully when no layers are available (default skin).
class ParallaxBackground extends Component {
  List<ui.Image> _layers = [];
  List<double> _offsets = [];

  // Scroll speeds in VB6-frame units (multiplied by dt * originalFps)
  static const _speeds = [0.5, 1.0, 2.0, 3.5];

  void loadLayers() {
    _layers = AssetLibrary.instance.bgLayers;
    _offsets = List.filled(_layers.length, 0.0);
  }

  @override
  void update(double dt) {
    if (_layers.isEmpty) return;
    if (_offsets.length != _layers.length) {
      _offsets = List.filled(_layers.length, 0.0);
    }
    final scaledDt = dt * config.originalFps;
    for (int i = 0; i < _layers.length; i++) {
      _offsets[i] += _speeds[min(i, _speeds.length - 1)] * scaledDt;
      final imgH = _layers[i].height * (config.gameWidth / _layers[i].width);
      if (_offsets[i] >= imgH) _offsets[i] -= imgH;
    }
  }

  @override
  void render(ui.Canvas canvas) {
    if (_offsets.length != _layers.length) return;
    for (int i = 0; i < _layers.length; i++) {
      final img = _layers[i];
      final scale = config.gameWidth / img.width;
      final imgH = img.height * scale;
      final offset = _offsets[i];

      // Two copies for seamless vertical tiling
      _drawLayer(canvas, img, scale, offset - imgH);
      _drawLayer(canvas, img, scale, offset);
    }
  }

  void _drawLayer(ui.Canvas canvas, ui.Image img, double scale, double y) {
    canvas.save();
    canvas.translate(0, y);
    canvas.scale(scale);
    canvas.drawImage(img, ui.Offset.zero, ui.Paint());
    canvas.restore();
  }
}
