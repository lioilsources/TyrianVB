import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/game_config.dart' as config;
import '../game/tyrian_game.dart';
import '../services/sound_service.dart';
import '../systems/device.dart';
import '../systems/dev_type.dart';
import '../services/asset_library.dart';
import '../game/platform_config.dart' as platform;
import 'hostile.dart';
import 'collectable.dart';

/// Ported from Vessel.cls — the player's ship.
class Vessel extends PositionComponent
    with HasGameReference<TyrianGame>, CollisionCallbacks {
  String pilotName = 'Pilot';
  int playerIndex; // 0=P1, 1=P2

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

  // Sprite / animation
  Sprite? _sprite;
  List<Sprite> _frames = [];
  int _frameIndex = 0;
  int _frameDir = 1; // +1 forward, -1 backward (ping-pong)
  double _frameTimer = 0;
  static const _frameDuration = 0.12; // seconds per frame
  bool visible = true;

  Vessel({this.playerIndex = 0}) : super(anchor: Anchor.center);

  Future<void> init() async {
    _loadFrames();

    add(RectangleHitbox());

    // Default weapon: Bubble Gun
    equipWeapon(DevType.bubbleGun, WeaponSlot.frontGun);
  }

  void _loadFrames() {
    _frames = List.of(AssetLibrary.instance.vesselFrames);
    if (_frames.isNotEmpty) {
      _sprite = _frames[0];
      _frameIndex = 0;
      _frameDir = 1;
    } else {
      _sprite = AssetLibrary.instance.getSprite('vessel');
    }
    if (_sprite != null) {
      size = _sprite!.srcSize;
    } else {
      size = Vector2(50, 40);
    }
  }

  /// Re-fetch sprites from AssetLibrary after a skin change.
  void refreshSprite() {
    _loadFrames();
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
    visible = true;
    for (final d in devices) {
      d.clearProjectiles();
    }
  }

  /// Full reset for new game — VB6 ResetVessel: all stats back to defaults
  void newGame() {
    score = 0;
    credit = 0;
    nextWeaponLevel = 0;
    lastMaxDps = 0;
    // Reset stat upgrades to VB6 defaults
    hpMax = 125;
    shieldMax = 100;
    shieldRegen = 0.1;
    genMax = 100;
    genPower = 4;
    lvlNum = 1;
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

    // Animate sprite frames (runs on both host and client)
    if (_frames.length > 1) {
      _frameTimer += dt;
      if (_frameTimer >= _frameDuration) {
        _frameTimer -= _frameDuration;
        _frameIndex += _frameDir;
        if (_frameIndex >= _frames.length - 1) {
          _frameIndex = _frames.length - 1;
          _frameDir = -1;
        } else if (_frameIndex <= 0) {
          _frameIndex = 0;
          _frameDir = 1;
        }
        _sprite = _frames[_frameIndex];
      }
    }

    // Client: positions set by snapshot, skip all game logic
    if (game.coopRole == CoopRole.client) return;

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

  /// VB6 TestDistance — finds closest enemy within guidance cone
  void _findClosestEnemy() {
    double minDist = 10000;
    closestEnemy = null;

    int maxGuide = 0;
    int maxSpeed = 0;
    for (final d in devices) {
      if (d.guide > maxGuide) maxGuide = d.guide;
      if (d.speed > maxSpeed) maxSpeed = d.speed;
    }
    if (maxGuide == 0) return;

    // VB6: grat = maxGuide / maxSpeed — guidance angle ratio
    final grat = maxSpeed > 0 ? maxGuide / maxSpeed : 0.0;

    for (final fleet in game.activeFleets) {
      for (final hostile in fleet.hostiles) {
        if (hostile.isDead) continue;
        final dx = (position.x - hostile.hostCenter.x).abs();
        final dy = position.y - hostile.hostCenter.y; // positive = enemy above
        if (dy <= 0) continue; // enemy below or at same Y — unreachable
        if (grat < dx / dy) continue; // outside guidance cone
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
          h.takeDamage(d.damage, game, attacker: this);
          if (h.isDead) {
            fleet.onHostileKilled(h, game, attacker: this);
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
      closestEnemy!.takeDamage(d.damage, game, attacker: this);
      if (closestEnemy!.isDead) {
        closestEnemy!.parentFleet?.onHostileKilled(closestEnemy!, game, attacker: this);
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
      if (amount <= 0) {
        SoundService.instance.play(SfxEvent.hitShield);
      }
    }
    if (amount > 0) {
      SoundService.instance.play(SfxEvent.hitHull);
    }
    hp -= amount;
    dmgTaken = 4; // Flash frames
    game.shaderPipeline.triggerAberration();

    if (hp <= 0) {
      hp = 0;
      if (game.isCoop) {
        visible = false;
        fire = false;
        game.checkCoopGameOver();
      } else {
        game.triggerGameOver();
      }
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
      SoundService.instance.play(SfxEvent.weaponUnlock);
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

  // P2 tint: modulate keeps alpha intact, tints RGB toward green
  static final _p2Paint = Paint()
    ..colorFilter = const ColorFilter.mode(Color(0xFF80FFA0), BlendMode.modulate);

  @override
  void render(Canvas canvas) {
    if (!visible) return;

    final paint = playerIndex == 1 ? _p2Paint : null;

    if (_sprite != null) {
      _sprite!.render(canvas, size: size, overridePaint: paint);
    } else {
      final color = playerIndex == 1 ? const Color(0xFF00FF80) : const Color(0xFF00FFFF);
      final p = Paint()..color = color;
      final path = Path()
        ..moveTo(size.x / 2, 0)
        ..lineTo(0, size.y)
        ..lineTo(size.x, size.y)
        ..close();
      canvas.drawPath(path, p);
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
