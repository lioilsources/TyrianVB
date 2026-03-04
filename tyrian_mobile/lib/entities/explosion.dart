import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/game_config.dart' as config;
import '../game/tyrian_game.dart';

/// Ported from Explosion.cls — animated explosion effect.
/// Original used 4 sprite variations x 15 pre-scaled frames.
/// Here we use a scaling animation with colored circles.
class Explosion extends PositionComponent with HasGameReference<TyrianGame> {
  int step = 0;
  final int maxSteps = config.explosionSteps;
  final int explosionSize;

  // Explosion colors cycle
  static const _colors = [
    Color(0xFFFFFF00), // Yellow
    Color(0xFFFF8800), // Orange
    Color(0xFFFF4400), // Red-orange
    Color(0xFFFF0000), // Red
    Color(0xFFCC0000), // Dark red
  ];

  Explosion({
    required Vector2 position,
    int size = 2,
  })  : explosionSize = size,
        super(position: position, anchor: Anchor.center);

  @override
  void update(double dt) {
    step++;
    if (step >= maxSteps) {
      game.removeExplosion(this);
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final progress = step / maxSteps;
    final radius = (explosionSize + 1) * 8.0 * progress;
    final alpha = ((1.0 - progress) * 255).round().clamp(0, 255);
    final colorIndex = (progress * (_colors.length - 1)).floor();
    final color = _colors[colorIndex].withAlpha(alpha);

    final paint = Paint()..color = color;
    canvas.drawCircle(Offset.zero, radius, paint);

    // Inner bright core
    if (progress < 0.5) {
      final corePaint = Paint()..color = Colors.white.withAlpha(alpha);
      canvas.drawCircle(Offset.zero, radius * 0.3, corePaint);
    }
  }
}
