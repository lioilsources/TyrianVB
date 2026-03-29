import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/game_config.dart' as config;
import '../game/tyrian_game.dart';
import '../systems/path_system.dart';
import '../systems/fleet.dart';
import '../systems/device.dart';
import '../services/asset_library.dart';
import '../game/platform_config.dart' as platform;
import 'vessel.dart';

/// Host types from VBA Objects.cls HostType enum
enum HostType {
  falcon1,  // HP 100
  falcon2,  // HP 120
  falcon3,  // HP 140
  falcon4,  // HP 160
  falcon5,  // HP 180
  falcon6,  // HP 200
  falconx,  // HP 1000
  falconx2, // HP 2000
  falconx3, // HP 3000
  falconxb, // HP 5000
  falconxt, // HP 10000
  bouncer,  // HP 100000
}

/// Ported from Hostile.cls — an enemy entity.
class Hostile extends PositionComponent with HasGameReference<TyrianGame> {
  String caption;
  int id;
  HostType hostType;
  int hp;
  int hpMax;
  int damage;
  int shield = 0;
  int shieldMax = 0;
  int hit = 0; // Flash counter
  double lastHitX = 0;
  double lastHitY = 0;
  int collisionDmg;
  PathSystem? trace;
  Device? weapon;
  Fleet? parentFleet;

  bool get isDead => hp <= 0;

  double get x2 => position.x + size.x;
  double get y2 => position.y + size.y;
  Vector2 get hostCenter => Vector2(position.x + size.x / 2, position.y + size.y / 2);

  Sprite? _sprite;
  Sprite? get sprite => _sprite;
  String get spriteName => _spriteNameForType(hostType);

  Hostile({
    required this.caption,
    required this.id,
    required this.hostType,
    required this.hp,
    required this.hpMax,
    this.damage = 10,
    int? collisionDmg,
    this.trace,
    Vector2? position,
  }) : collisionDmg = collisionDmg ?? getCollisionDmg(hostType),
       super(position: position ?? Vector2.zero());

  /// VB6 per-type collision damage (Objects.cls)
  static int getCollisionDmg(HostType type) {
    switch (type) {
      case HostType.falcon1: return 1;
      case HostType.falcon2: return 1;
      case HostType.falcon3: return 1;
      case HostType.falcon4: return 1;
      case HostType.falcon5: return 2;
      case HostType.falcon6: return 2;
      case HostType.falconx: return 4;
      case HostType.falconx2: return 6;
      case HostType.falconx3: return 8;
      case HostType.falconxb: return 10;
      case HostType.falconxt: return 12;
      case HostType.bouncer: return 20;
    }
  }

  @override
  Future<void> onLoad() async {
    _refreshSprite();
  }

  void _refreshSprite() {
    final spriteName = _spriteNameForType(hostType);
    _sprite = AssetLibrary.instance.getSprite(spriteName);
    if (_sprite != null) {
      size = _sprite!.srcSize * config.spriteScale;
    } else {
      size = Vector2(40, 40) * config.spriteScale; // Placeholder
    }
  }

  void refreshSprite() => _refreshSprite();

  static String _spriteNameForType(HostType type) {
    switch (type) {
      case HostType.falcon1: return 'falcon1';
      case HostType.falcon2: return 'falcon2';
      case HostType.falcon3: return 'falcon3';
      case HostType.falcon4: return 'falcon4';
      case HostType.falcon5: return 'falcon5';
      case HostType.falcon6: return 'falcon6';
      case HostType.falconx: return 'falconx';
      case HostType.falconx2: return 'falconx2';
      case HostType.falconx3: return 'falconx3';
      case HostType.falconxb: return 'falconxb';
      case HostType.falconxt: return 'falconxt';
      case HostType.bouncer: return 'bouncer';
    }
  }

  static int getHpMax(HostType type) {
    switch (type) {
      case HostType.falcon1: return 100;
      case HostType.falcon2: return 120;
      case HostType.falcon3: return 140;
      case HostType.falcon4: return 160;
      case HostType.falcon5: return 180;
      case HostType.falcon6: return 200;
      case HostType.falconx: return 1000;
      case HostType.falconx2: return 2000;
      case HostType.falconx3: return 3000;
      case HostType.falconxb: return 5000;
      case HostType.falconxt: return 10000;
      case HostType.bouncer: return 100000;
    }
  }

  static String hostCaption(HostType type) {
    switch (type) {
      case HostType.falcon1: return 'Falcon I';
      case HostType.falcon2: return 'Falcon II';
      case HostType.falcon3: return 'Falcon III';
      case HostType.falcon4: return 'Falcon IV';
      case HostType.falcon5: return 'Falcon V';
      case HostType.falcon6: return 'Falcon VI';
      case HostType.falconx: return 'Falcon X';
      case HostType.falconx2: return 'Falcon X-II';
      case HostType.falconx3: return 'Falcon X-III';
      case HostType.falconxb: return 'Falcon XB';
      case HostType.falconxt: return 'Falcon XT';
      case HostType.bouncer: return 'Bouncer';
    }
  }

  @override
  void update(double dt) {
    if (isDead) return;
    // Client: positions set by snapshot, skip all game logic
    if (game.coopRole == CoopRole.client) return;

    // Follow path
    if (trace != null && trace!.current != null) {
      position.setValues(trace!.current!.x, trace!.current!.y);
      if (!trace!.advance()) {
        // Path ended
        _onPathEnd();
      }
    }

    // Hit flash decay
    if (hit > 0) hit--;

    // Check collision with player vessel
    _checkPlayerCollision();
  }

  void _onPathEnd() {
    switch (trace?.onExit ?? PathAction.destroy) {
      case PathAction.destroy:
        hp = 0; // Mark as dead (will be cleaned up by fleet)
      case PathAction.stay:
        break; // Stay at last position
      case PathAction.noop:
        break;
      case PathAction.freezeFleet:
        if (parentFleet != null) {
          for (final ho in parentFleet!.hostiles) {
            if (ho.isDead || ho.trace == null) continue;
            ho.trace!.finish();
            final last = ho.trace!.current;
            if (last != null) {
              ho.position.setValues(last.x, last.y);
            }
            ho.trace!.onExit = PathAction.stay;
          }
        }
      case PathAction.replacePath:
        if (parentFleet != null) {
          for (final ho in parentFleet!.hostiles) {
            if (ho.isDead) continue;
            ho.cyclePath(
              parentFleet!.altParam1,
              parentFleet!.altParam2,
              parentFleet!.altParam3,
              parentFleet!.altParam4 ?? PathType.cosinus,
            );
          }
        }
    }
  }

  /// VB6 Hostile.CyclePath — create oscillating out-and-back cyclic path
  void cyclePath(int steps, int dx, int dy, PathType pt) {
    final x = trace?.current?.x ?? position.x;
    final y = trace?.current?.y ?? position.y;
    final ampl = sqrt((dx * dx + dy * dy).toDouble());
    final newTrace = PathSystem();
    newTrace.generate(steps, x, y, x + dx, y + dy, pt,
        amplitude: ampl, cycles: 1);
    final returnPath = PathSystem();
    returnPath.generate(steps, x + dx, y + dy, x, y, pt,
        amplitude: -ampl, cycles: 1);
    newTrace.addPath(returnPath);
    newTrace.encycle();
    trace = newTrace;
  }

  void _checkPlayerCollision() {
    const cf = 0.7; // collision fraction — use 70% of sprite for body hits
    final hmx = size.x * (1 - cf) / 2;
    final hmy = size.y * (1 - cf) / 2;
    for (final vessel in game.allVessels) {
      if (!vessel.visible) continue;
      final vhx = vessel.size.x / 2 * cf;
      final vhy = vessel.size.y / 2 * cf;

      // AABB collision with player (shrunk hitboxes)
      if (vessel.dmgTaken > 0) continue; // invulnerability frames
      if (position.x + hmx < vessel.position.x + vhx &&
          x2 - hmx > vessel.position.x - vhx &&
          position.y + hmy < vessel.position.y + vhy &&
          y2 - hmy > vessel.position.y - vhy) {
        vessel.takeDamage(collisionDmg);
      }
    }
  }

  void takeDamage(int dmg, TyrianGame gameInstance, {Vessel? attacker}) {
    hp -= dmg;
    if (hit == 0) hit = 2;
    if (hp <= 0) hp = 0;
  }

  // Rendering is handled by HostileBatchRenderer — this is intentionally empty.
  @override
  void render(Canvas canvas) {}
}
