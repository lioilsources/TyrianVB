import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/game_config.dart' as config;

/// Ported from Module.bas MoveStars + starField initialization.
/// Parallax starfield with 1000 stars, cone/tunnel expanding effect.
class Starfield extends Component with HasGameReference {
  static const int count = config.starCount;

  final List<_Star> _stars = [];
  final Random _rng = Random();

  @override
  Future<void> onLoad() async {
    _initStars();
  }

  /// Port of Module.bas lines 1487-1502 star initialization
  void _initStars() {
    _stars.clear();
    for (int i = 0; i < count; i++) {
      final x = (config.gameWidth * _rng.nextDouble()) - 2;
      final y = (3 * config.gameHeight * _rng.nextDouble()) + 1;

      // Speed based on distance from center (Module.bas formula)
      double r =
          ((x - config.gameWidth / 2).abs() / config.gameWidth * 1.85) *
                  _rng.nextDouble() +
              0.35;
      double speed = 3 * r * r;
      if (speed < 2.5) speed = speed / 2;
      if (speed < 0.01) speed = 0.01;

      // Brightness
      double brightness = r.clamp(0.0, 1.0);
      if (brightness >= 0.7) {
        brightness = 0.7 + _rng.nextDouble() * 0.3;
      }

      final size = speed > 1.5 ? 2.0 : 1.0;

      _stars.add(_Star(
        x: x,
        y: y,
        startX: x,
        speed: speed,
        brightness: brightness,
        size: size,
      ));
    }
  }

  /// Port of MoveStars (Module.bas line 1092)
  @override
  void update(double dt) {
    final scaledDt = dt * config.originalFps; // Convert to frame-equivalent

    for (final star in _stars) {
      star.y += star.speed * scaledDt;

      if (star.y < config.gameHeight) {
        double tmp = star.speed / 3;
        if (star.x < config.gameWidth / 2) tmp = -tmp;
        star.x += tmp * scaledDt;
      }

      if (star.y > config.gameHeight + 10) {
        star.x = star.startX;
        if (star.speed < 0.25 &&
            (star.x - config.gameWidth / 2).abs() < config.gameWidth * 0.24 &&
            _rng.nextDouble() < 0.5) {
          star.y = config.gameHeight * _rng.nextDouble() * 0.8;
        } else {
          star.y = -star.size;
        }
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint();
    for (final star in _stars) {
      if (star.y < 0 || star.y > config.gameHeight) continue;
      if (star.x < 0 || star.x > config.gameWidth) continue;

      final b = (star.brightness * 255).round().clamp(0, 255);
      paint.color = Color.fromARGB(255, b, b, b);
      canvas.drawRect(
        Rect.fromLTWH(star.x, star.y, star.size, star.size),
        paint,
      );
    }
  }
}

class _Star {
  double x;
  double y;
  final double startX;
  final double speed;
  final double brightness;
  final double size;

  _Star({
    required this.x,
    required this.y,
    required this.startX,
    required this.speed,
    required this.brightness,
    this.size = 1.0,
  });
}
