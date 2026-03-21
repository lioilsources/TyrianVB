import 'dart:io';
import 'dart:math' show pi;
import 'dart:ui' show Canvas;
import 'package:flame/components.dart' show Vector2;

/// Platform detection — resolved once at startup.
final bool isDesktop =
    Platform.isMacOS || Platform.isWindows || Platform.isLinux;

/// Desktop always runs landscape; mobile always portrait.
final bool isLandscape = isDesktop;

/// Sprite rotation to compensate camera -90° in landscape.
final double spriteRotation = isLandscape ? pi / 2 : 0.0;

/// Apply +90° canvas rotation in landscape so sprites face the right way.
/// Call inside render() between canvas.save() and canvas.restore().
void landscapeRotate(Canvas canvas, Vector2 size) {
  if (!isLandscape) return;
  canvas.translate(size.x / 2, size.y / 2);
  canvas.rotate(pi / 2);
  canvas.translate(-size.y / 2, -size.x / 2);
}
