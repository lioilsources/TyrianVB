import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/game_config.dart' as config;
import '../game/tyrian_game.dart';
import '../systems/path_system.dart';
import '../services/asset_library.dart';
import '../game/platform_config.dart' as platform;

/// Structure behavior types from VBA
enum StructBehavior { fall, follow, fallAndFollow, byPath }

/// Structure type from VBA
enum StructType { basic, asteroid }

/// Ported from Structure.cls — obstacles/asteroids.
class Structure extends PositionComponent
    with HasGameReference<TyrianGame>, CollisionCallbacks {
  static int _nextId = 0;
  late final int id = _nextId++;

  String caption;
  StructBehavior behavior;
  StructType structType;
  int hp;
  int hpMax;
  int shield = 0;
  int shieldMax = 0;
  int hit = 0;
  int collisionDmg = 20;
  PathSystem? trace;
  double enterTime = 0;
  bool activated = false;

  double get x2 => position.x + size.x;
  double get y2 => position.y + size.y;

  Sprite? _sprite;
  final String? _imgName;
  String get imgName => _imgName ?? '';

  bool get isDead => hp <= 0;

  Structure({
    required this.caption,
    this.behavior = StructBehavior.fall,
    this.structType = StructType.basic,
    required this.hp,
    required this.hpMax,
    this.collisionDmg = 20,
    this.trace,
    String? imgName,
    Vector2? position,
  })  : _imgName = imgName,
        super(position: position ?? Vector2.zero());

  @override
  Future<void> onLoad() async {
    refreshSprite();
    add(RectangleHitbox());
  }

  void refreshSprite() {
    if (_imgName != null) {
      _sprite = AssetLibrary.instance.getSprite(_imgName);
    }
    if (_sprite != null) {
      size = _sprite!.srcSize;
    } else {
      size = Vector2(50, 50);
    }
  }

  @override
  void update(double dt) {
    if (isDead) return;
    // Client: positions set by snapshot, skip all game logic
    if (game.coopRole == CoopRole.client) return;

    final scaledDt = dt * config.originalFps;

    switch (behavior) {
      case StructBehavior.fall:
        position.y += config.structureFallSpeed / config.originalFps * scaledDt;
      case StructBehavior.follow:
        // Track nearest visible vessel X position
        final targetX1 = game.nearestVesselX(position.x, position.y);
        position.x += (targetX1 - position.x - size.x / 2) * 0.02 * scaledDt;
      case StructBehavior.fallAndFollow:
        position.y += config.structureFallSpeed / config.originalFps * scaledDt;
        final targetX2 = game.nearestVesselX(position.x, position.y);
        position.x += (targetX2 - position.x - size.x / 2) * 0.02 * scaledDt;
      case StructBehavior.byPath:
        if (trace != null && trace!.current != null) {
          position.setValues(trace!.current!.x, trace!.current!.y);
          trace!.advance();
        }
    }

    // Asteroid collision with player (VB6 Structure.cls:129-146)
    _checkPlayerCollision();

    // Remove if off screen
    if (position.y > config.gameHeight + size.y) {
      _remove();
    }

    if (hit > 0) hit--;
  }

  void takeDamage(int dmg, TyrianGame gameInstance) {
    hp -= dmg;
    if (hit == 0) hit = 2;
    if (hp <= 0) {
      gameInstance.addExplosion(
        position.x + size.x / 2,
        position.y + size.y / 2,
        size.x.toInt() ~/ 10,
      );
      _remove();
    }
  }

  void _checkPlayerCollision() {
    if (structType != StructType.asteroid) return;
    const cf = 0.7; // collision fraction — use 70% of sprite for body hits
    final smx = size.x * (1 - cf) / 2;
    final smy = size.y * (1 - cf) / 2;
    for (final vessel in game.allVessels) {
      if (!vessel.visible || vessel.dmgTaken > 0) continue; // invulnerability frames
      final vhx = vessel.size.x / 2 * cf;
      final vhy = vessel.size.y / 2 * cf;

      if (position.x + smx < vessel.position.x + vhx &&
          x2 - smx > vessel.position.x - vhx &&
          position.y + smy < vessel.position.y + vhy &&
          y2 - smy > vessel.position.y - vhy) {
        vessel.takeDamage(collisionDmg);
        // VB6: push player below asteroid
        vessel.position.y = y2 + vessel.size.y / 2;
      }
    }
  }

  void _remove() {
    game.activeStructures.remove(this);
    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    if (isDead) return;

    final bounds = Rect.fromLTWH(0, 0, size.x, size.y);

    if (_sprite != null) {
      _sprite!.render(canvas, size: size);
    } else {
      final paint = Paint()..color = const Color(0xFF888888);
      canvas.drawOval(bounds, paint);
    }
  }
}
