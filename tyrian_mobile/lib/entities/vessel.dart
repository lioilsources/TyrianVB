import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/game_config.dart' as config;
import '../game/tyrian_game.dart';
import '../systems/device.dart';
import '../systems/dev_type.dart';
import '../services/asset_library.dart';
import 'hostile.dart';
import 'collectable.dart';

/// Ported from Vessel.cls — the player's ship.
class Vessel extends PositionComponent
    with HasGameReference<TyrianGame>, CollisionCallbacks {
  String pilotName = 'Pilot';

  // Stats (VB6 Vessel.cls ResetVessel defaults)
  int hp = 125;
  int hpMax = 125;
  double shield = 100;
  double shieldMax = 100;
  double shieldRegen = 0.1;
  double genValue = 100;
  double genMax = 100;
  double genPower = 4;
  int credit = 0;
  int score = 0;
  int lvlNum = 1;
  bool fire = false;
  int dmgTaken = 0; // Damage flash counter

  // Weapons
  final List<Device> devices = [];
  bool guidedWeapon = false;
  Hostile? closestEnemy;
  int nextWeaponLevel = 0;

  // VB6 Vessel.WepLevScores — score thresholds for weapon tier unlocks
  static const wepLevScores = [0, 400000, 4000000, 14000000];

  // DPS tracking for random sector scaling (VB6 rocket.lastMaxDps)
  double lastMaxDps = 0;

  // Sprite
  Sprite? _sprite;
  bool visible = true;

  Vessel() : super(anchor: Anchor.center);

  Future<void> init() async {
    _sprite = AssetLibrary.instance.getSprite('vessel');
    if (_sprite != null) {
      size = _sprite!.srcSize;
    } else {
      size = Vector2(50, 40);
    }

    add(RectangleHitbox());

    // Default weapon: Bubble Gun
    equipWeapon(DevType.bubbleGun, WeaponSlot.frontGun);
  }

  void resetPosition() {
    position.setValues(config.gameWidth / 2, config.gameHeight * 0.75);
  }

  void resetVessel() {
    hp = hpMax;
    shield = shieldMax;
    genValue = genMax;
    dmgTaken = 0;
    fire = false;
    for (final d in devices) {
      d.clearProjectiles();
    }
  }

  /// Full reset for new game — clears score, credits, weapons, unlock tiers
  void newGame() {
    score = 0;
    credit = 0;
    nextWeaponLevel = 0;
    lastMaxDps = 0;
    for (final d in devices) {
      d.clearProjectiles();
    }
    devices.clear();
    guidedWeapon = false;
    equipWeapon(DevType.bubbleGun, WeaponSlot.frontGun);
    resetVessel();
  }

  /// Port of Vessel.AdjustPosition — move towards target
  void adjustPosition(double tx, double ty) {
    // Clamp to screen bounds
    final nx = tx.clamp(size.x / 2, config.gameWidth - size.x / 2);
    final ny = ty.clamp(size.y / 2, config.gameHeight - size.y / 2);
    position.setValues(nx, ny);

    // Update beam coordinates for beam weapons
    for (final d in devices) {
      if (d.beamActive > 0) {
        switch (d.slot) {
          case WeaponSlot.frontGun:
            d.sx = position.x;
            d.sy = position.y - size.y / 2 - 5;
          case WeaponSlot.leftGun:
            d.sx = position.x - size.x / 2;
            d.sy = position.y + 9;
          case WeaponSlot.rightGun:
            d.sx = position.x + size.x / 2;
            d.sy = position.y + 9;
          default:
            d.sx = position.x;
            d.sy = position.y;
        }

        if (closestEnemy != null && !closestEnemy!.isDead) {
          d.dx = closestEnemy!.hostCenter.x;
          d.dy = closestEnemy!.hostCenter.y;
        } else {
          // Shoot straight up
          d.dx = d.sx;
          d.dy = 0;
        }
      }
    }
  }

  /// Port of Vessel.step — per-frame update
  @override
  void update(double dt) {
    if (!visible) return;

    final scaledDt = dt * config.originalFps;

    // Regenerate power
    if (genValue < genMax) {
      genValue += genPower * scaledDt;
      if (genValue > genMax) genValue = genMax;
    }

    // Regenerate shield
    if (shield < shieldMax && genValue > 0) {
      shield += shieldRegen * scaledDt;
      if (shield > shieldMax) shield = shieldMax;
    }

    // Find closest enemy for guided weapons
    if (guidedWeapon) {
      _findClosestEnemy();
    }

    // Update weapons
    for (final d in devices) {
      d.updateCooldown(dt);

      // Fire if firing
      if (fire) {
        d.fire(
          position.x - size.x / 2,
          position.y - size.y / 2,
          position.x,
          size.x,
          parent!,
        );
      }

      // Update projectile positions and check collisions
      _updateProjectiles(d, dt);
    }

    // Beam damage — outside projectile loop (beams have 0 projectiles)
    for (final d in devices) {
      if (d.beamActive > 0) {
        _processBeamCollision(d);
      }
    }

    // Damage flash decay
    if (dmgTaken > 0) dmgTaken--;
  }

  void _findClosestEnemy() {
    double minDist = 10000;
    closestEnemy = null;

    int maxGuide = 0;
    for (final d in devices) {
      if (d.guide > maxGuide) maxGuide = d.guide;
    }
    if (maxGuide == 0) return;

    for (final fleet in game.activeFleets) {
      for (final hostile in fleet.hostiles) {
        if (hostile.isDead) continue;
        final dx = position.x - hostile.hostCenter.x;
        final dy = position.y - hostile.hostCenter.y;
        final dist = sqrt(dx * dx + dy * dy);
        if (dist < minDist) {
          minDist = dist;
          closestEnemy = hostile;
        }
      }
    }
  }

  void _updateProjectiles(Device d, double dt) {
    final toRemove = <int>[];
    for (int i = 0; i < d.projectiles.length; i++) {
      final p = d.projectiles[i];
      if (!p.active) {
        toRemove.add(i);
        continue;
      }

      // Guided projectile homing
      if (d.guide > 0 && closestEnemy != null && !closestEnemy!.isDead) {
        final dx = (p.position.x + p.size.x / 2) - closestEnemy!.hostCenter.x;
        final adjustment = dx.abs() > d.guide ? d.guide * dx.sign : dx;
        p.position.x -= adjustment * dt * config.originalFps;
      }

      // Check collision with enemies
      if (_checkProjectileCollisions(d, p)) {
        toRemove.add(i);
      }
    }

    // Remove hit projectiles (reverse order to preserve indices)
    for (int i = toRemove.length - 1; i >= 0; i--) {
      final idx = toRemove[i];
      if (idx < d.projectiles.length) {
        d.returnToPool(d.projectiles[idx]);
      }
    }
  }

  /// Port of Vessel.ProcessEnemies — collision detection
  bool _checkProjectileCollisions(Device d, projectile) {
    final px1 = projectile.position.x;
    final py1 = projectile.position.y;
    final px2 = projectile.x2;
    final py2 = projectile.y2;

    // Check against all fleets
    for (final fleet in game.activeFleets) {
      // Broad phase: fleet AABB
      if (py2 < fleet.minY || py1 > fleet.maxY) continue;
      if (px2 < fleet.minX || px1 > fleet.maxX) continue;

      // Narrow phase: per hostile
      for (final h in fleet.hostiles) {
        if (h.isDead) continue;
        if (_aabbOverlap(px1, py1, px2, py2,
            h.position.x, h.position.y, h.x2, h.y2)) {
          h.takeDamage(d.damage, game);
          if (h.isDead) {
            fleet.onHostileKilled(h, game);
          }
          return true; // Projectile consumed
        }
      }
    }

    // Check against structures
    for (final s in game.activeStructures) {
      if (_aabbOverlap(px1, py1, px2, py2,
          s.position.x, s.position.y, s.x2, s.y2)) {
        s.takeDamage(d.damage, game);
        addScore(d.damage);
        credit += d.damage;
        return true;
      }
    }

    return false;
  }

  void _processBeamCollision(Device d) {
    // Beam hits closest enemy continuously
    if (closestEnemy != null && !closestEnemy!.isDead) {
      closestEnemy!.takeDamage(d.damage, game);
      if (closestEnemy!.isDead) {
        closestEnemy!.parentFleet?.onHostileKilled(closestEnemy!, game);
      }
    }
  }

  bool _aabbOverlap(
      double ax1, double ay1, double ax2, double ay2,
      double bx1, double by1, double bx2, double by2) {
    return ax1 < bx2 && ax2 > bx1 && ay1 < by2 && ay2 > by1;
  }

  /// Take damage (from hostile collision or projectile)
  void takeDamage(int amount) {
    // Shield absorbs first
    if (shield > 0) {
      final absorbed = min(shield, amount.toDouble());
      shield -= absorbed;
      amount -= absorbed.toInt();
    }
    hp -= amount;
    dmgTaken = 4; // Flash frames

    if (hp <= 0) {
      hp = 0;
      game.triggerGameOver();
    }
  }

  // Weapon management
  Device? getDevice(WeaponSlot slot) {
    for (final d in devices) {
      if (d.slot == slot) return d;
    }
    return null;
  }

  Device equipWeapon(DevType type, WeaponSlot slot) {
    // Remove existing weapon in slot
    devices.removeWhere((d) {
      if (d.slot == slot) {
        d.clearProjectiles();
        return true;
      }
      return false;
    });

    final device = Device.fromType(type, slot);
    device.parentVessel = this;
    devices.add(device);

    // Check if any weapon has guidance
    guidedWeapon = devices.any((d) => d.guide > 0);

    return device;
  }

  void removeWeapon(WeaponSlot slot) {
    devices.removeWhere((d) {
      if (d.slot == slot) {
        d.clearProjectiles();
        return true;
      }
      return false;
    });
    guidedWeapon = devices.any((d) => d.guide > 0);
  }

  /// VB6 Vessel.AddScore — add score and check weapon unlock thresholds
  void addScore(int s) {
    score += s;
    if (nextWeaponLevel < wepLevScores.length &&
        score > wepLevScores[nextWeaponLevel]) {
      nextWeaponLevel++;
      const roman = ['', 'I', 'II', 'III', 'IV'];
      game.showMessage('Weapon level ${roman[nextWeaponLevel]} unlocked');
    }
  }

  /// VB6 Vessel.GeneratorLoad — power consumption as % of generation
  double get generatorLoad {
    if (genPower <= 0) return 999;
    double pps = 0;
    for (final d in devices) {
      if (d.cooldown > 0 && d.pwrNeed > 0) {
        pps += d.pwrNeed / d.cooldown;
      }
    }
    final genPerSec = genPower * config.originalFps;
    return genPerSec > 0 ? pps / genPerSec * 100 : 999;
  }

  /// VB6 Vessel.GenInfo — generator status string for ComCenter
  String get genInfo {
    final load = generatorLoad.round();
    var info = 'Cap ${genMax.toInt()} | Load $load%';
    for (final d in devices) {
      if (d.pwrNeed > genMax) {
        info += ' | ${d.name} off';
      }
    }
    if (load > 100) info += ' | low';
    return info;
  }

  /// Total DPS across all weapons
  double get totalDps {
    double total = 0;
    for (final d in devices) {
      total += d.dps;
    }
    return total;
  }

  @override
  void render(Canvas canvas) {
    if (!visible) return;

    if (_sprite != null) {
      _sprite!.render(canvas, size: size);
    } else {
      // Placeholder triangle
      final paint = Paint()..color = const Color(0xFF00FFFF);
      final path = Path()
        ..moveTo(size.x / 2, 0)
        ..lineTo(0, size.y)
        ..lineTo(size.x, size.y)
        ..close();
      canvas.drawPath(path, paint);
    }

    // Damage flash — red tint
    if (dmgTaken > 0) {
      final flashPaint = Paint()
        ..color = Color.fromARGB(100, 255, 0, 0)
        ..blendMode = BlendMode.srcATop;
      canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), flashPaint);
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Collectable) {
      other.applyEffect(this, game);
    }
  }
}
