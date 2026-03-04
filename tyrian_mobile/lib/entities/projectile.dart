import 'dart:ui' show Rect, Paint, Color;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../game/game_config.dart' as config;
import '../systems/device.dart';
import '../services/asset_library.dart';

/// Ported from Projectile.cls — a bullet/missile in flight.
/// Uses object pooling: deactivated projectiles are returned to Device._pool.
class Projectile extends PositionComponent with HasGameReference {
  String imgName;
  double speed; // negative = moving up (player), positive = down (enemy)
  double damage;
  double projScale;
  Device? parentDevice;
  bool active = true;

  // Bounds for collision
  double get x2 => position.x + size.x;
  double get y2 => position.y + size.y;

  Projectile({
    required this.imgName,
    required Vector2 position,
    required this.speed,
    required this.damage,
    double scale = 1.0,
    this.parentDevice,
  })  : projScale = scale,
        super(position: position);

  Sprite? _sprite;

  @override
  Future<void> onLoad() async {
    _sprite = AssetLibrary.instance.getSprite(imgName);
    if (_sprite != null) {
      size = _sprite!.srcSize * projScale;
    } else {
      size = Vector2(6, 12) * projScale;
    }
    // Center horizontally on spawn position
    position.x -= size.x / 2;

    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    if (!active) return;

    final scaledDt = dt * config.originalFps;
    position.y += speed * scaledDt;

    // Remove if off screen
    if (position.y < -size.y || position.y > config.gameHeight + size.y) {
      returnToPool();
    }
  }

  @override
  void render(canvas) {
    if (!active) return;
    if (_sprite != null) {
      _sprite!.render(canvas, size: size);
    } else {
      // Placeholder: small colored rect
      final paint = Paint()..color = const Color(0xFFFFFF00);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.x, size.y),
        paint,
      );
    }
  }

  void activate(double x, double y, double spd, double dmg, double scale) {
    position.setValues(x - size.x / 2, y);
    speed = spd;
    damage = dmg;
    projScale = scale;
    active = true;
    if (_sprite != null) {
      size = _sprite!.srcSize * projScale;
    }
  }

  void deactivate() {
    active = false;
    position.setValues(-1000, -1000);
  }

  void returnToPool() {
    if (parentDevice != null) {
      parentDevice!.returnToPool(this);
    } else {
      removeFromParent();
    }
  }
}
