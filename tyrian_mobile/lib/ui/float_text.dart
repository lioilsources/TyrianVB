import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/game_config.dart' as config;
import '../game/platform_config.dart' as platform;

/// Ported from FloatText.cls — floating text that drifts upward and fades.
/// Used for "Complete", "Game Over", weapon unlock messages, etc.
class FloatText extends PositionComponent {
  final String text;
  final Color color;
  final double fontSize;
  final double duration; // seconds
  double _elapsed = 0;
  final bool stationary;
  final double driftSpeed; // pixels per second upward

  FloatText({
    required this.text,
    this.color = Colors.white,
    this.fontSize = 24,
    this.duration = 2.0,
    this.stationary = false,
    this.driftSpeed = 30,
    Vector2? position,
  }) : super(position: position ?? Vector2(config.gameWidth / 2, config.gameHeight / 2));

  @override
  void update(double dt) {
    _elapsed += dt;
    if (_elapsed >= duration) {
      removeFromParent();
      return;
    }
    if (!stationary) {
      position.y -= driftSpeed * dt;
    }
  }

  @override
  void render(Canvas canvas) {
    final alpha = ((1.0 - _elapsed / duration) * 255).round().clamp(0, 255);
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color.withAlpha(alpha),
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black.withAlpha(alpha),
              offset: const Offset(2, 2),
              blurRadius: 4,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );
  }
}
