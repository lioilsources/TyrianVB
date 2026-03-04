import 'package:flame/components.dart';
import '../game/game_config.dart' as config;
import '../game/tyrian_game.dart';
import 'dev_type.dart';
import '../entities/projectile.dart';
import '../entities/vessel.dart';
import '../entities/hostile.dart';

/// Ported from Device.cls — a weapon instance equipped on a vessel or hostile.
class Device {
  String name;
  String displayName;
  String imgName;
  int price;
  double upgCost;
  int level = 0;
  WeaponSlot slot;
  int damage;
  int speed;
  int guide;
  double pwrNeed;
  double pwrGen;
  double cooldown; // seconds
  int beam;
  int beamActive = 0;
  int seqs;
  int xShift = 0;
  int xShiftMax;
  int xShiftDir = 1;
  bool scaleProjectile;
  double minProjScale;
  double maxProjScale;

  // Beam coordinates
  double sx = 0, sy = 0, dx = 0, dy = 0;

  // Cooldown timer
  double cd = 0;

  // Active projectiles
  final List<Projectile> projectiles = [];

  // Object pool for projectile reuse
  final List<Projectile> _pool = [];

  // Parent references
  Vessel? parentVessel;
  Hostile? parentHostile;

  Device({
    required this.name,
    required this.displayName,
    required this.imgName,
    required this.slot,
    this.damage = 10,
    this.speed = 5,
    this.guide = 0,
    this.pwrNeed = 1.0,
    this.pwrGen = 0.0,
    this.cooldown = 0.25,
    this.beam = 0,
    this.seqs = 0,
    this.xShiftMax = 0,
    this.price = 100,
    this.upgCost = 0.1,
    this.scaleProjectile = false,
    this.minProjScale = 1.0,
    this.maxProjScale = 1.0,
  });

  /// Create a Device from a DevType template
  factory Device.fromType(DevType type, WeaponSlot slot) {
    return Device(
      name: type.name,
      displayName: type.name,
      imgName: type.imgName,
      slot: slot,
      damage: type.damage,
      speed: type.speed,
      guide: type.guide,
      pwrNeed: type.pwrNeed,
      pwrGen: type.pwrGen,
      cooldown: type.cooldownSeconds,
      beam: type.beam,
      seqs: type.seqs,
      xShiftMax: type.xShiftMax,
      price: type.price,
      upgCost: type.upgCost,
      scaleProjectile: type.scaleProjectile,
      minProjScale: type.minProjScale,
      maxProjScale: type.maxProjScale,
    );
  }

  /// Port of Device.Create — fire weapon, create projectile or activate beam
  void fire(double vesselX, double vesselY, double vesselXm, double vesselWidth,
      Component world) {
    if (cd > 0) return;

    // Check power
    if (parentVessel != null && pwrNeed > parentVessel!.genValue) return;

    // Consume power
    if (parentVessel != null) {
      parentVessel!.genValue -= pwrNeed;
    }

    cd = cooldown;

    if (beam > 0) {
      beamActive = seqs;
      return;
    }

    // Calculate spawn position based on slot
    double px, py;
    switch (slot) {
      case WeaponSlot.frontGun:
        px = vesselXm;
        py = vesselY - 5;
      case WeaponSlot.leftGun:
        px = vesselX;
        py = vesselY + 9;
      case WeaponSlot.rightGun:
        px = vesselX + vesselWidth;
        py = vesselY + 9;
      default:
        px = vesselXm;
        py = vesselY;
    }

    // Apply xShift wave effect (VB6: step of 7 per shot)
    if (xShiftMax != 0) {
      px += xShift;
      xShift += xShiftDir * 7;
      if (xShift.abs() >= xShiftMax) xShiftDir = -xShiftDir;
    }

    // Scale based on level
    double scale = minProjScale;
    if (scaleProjectile && config.maxWeapLevel > 0) {
      scale = minProjScale +
          (maxProjScale - minProjScale) / config.maxWeapLevel * level;
    }

    // Get or create projectile
    Projectile proj;
    if (_pool.isNotEmpty) {
      proj = _pool.removeLast();
      proj.activate(px, py, -speed.toDouble(), damage.toDouble(), scale);
    } else {
      proj = Projectile(
        imgName: imgName,
        position: Vector2(px, py),
        speed: -speed.toDouble(),
        damage: damage.toDouble(),
        scale: scale,
        parentDevice: this,
      );
      world.add(proj);
    }
    projectiles.add(proj);
  }

  /// Update cooldown timer
  void updateCooldown(double dt) {
    if (cd > 0) {
      cd -= dt;
      if (cd < 0) cd = 0;
    }
    if (beamActive > 0) {
      beamActive--;
    }
  }

  /// Return projectile to pool
  void returnToPool(Projectile p) {
    projectiles.remove(p);
    p.deactivate();
    _pool.add(p);
  }

  static const maxLevel = 25;

  static const _roman = [
    '', 'I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X',
    'XI', 'XII', 'XIII', 'XIV', 'XV', 'XVI', 'XVII', 'XVIII', 'XIX', 'XX',
    'XXI', 'XXII', 'XXIII', 'XXIV', 'XXV',
  ];

  /// Port of Device.Upgrade
  void upgrade() {
    if (level >= maxLevel) {
      // VB6: max level converts to credit/score bonus based on sector level
      if (parentVessel != null) {
        final sectorLevel = parentVessel!.lvlNum;
        int bonus;
        if (sectorLevel <= 1) {
          bonus = 25000;
        } else if (sectorLevel >= 40) {
          bonus = 5000000;
        } else {
          bonus = sectorLevel * 125000;
        }
        parentVessel!.addScore(bonus);
        parentVessel!.credit += bonus;
        (parentVessel! as HasGameReference<TyrianGame>)
            .game
            .showMessage('Max. level! Sold for \$$bonus');
      }
      return;
    }
    damage = (damage * config.upgDamageMultiplier).round();
    pwrNeed *= config.upgPwrNeedMultiplier;
    cooldown /= config.upgCooldownDivisor;
    level++;
    price = (price * (1 + upgCost)).round();
    // VB6: update displayName with roman numeral
    displayName = '$name ${_roman[level]}';

    if (pwrGen > 0 && parentVessel != null) {
      pwrGen *= config.upgPwrGenMultiplier;
      parentVessel!.genMax *= config.upgGenMaxMultiplier;
    }
  }

  /// Calculate DPS (VB6: beam weapons multiply by seqs)
  double get dps {
    if (cooldown <= 0) return 0;
    if (beam > 0) return damage * seqs / cooldown;
    return damage / cooldown;
  }

  /// Cleanup all projectiles
  void clearProjectiles() {
    for (final p in projectiles) {
      p.removeFromParent();
    }
    projectiles.clear();
    for (final p in _pool) {
      p.removeFromParent();
    }
    _pool.clear();
  }
}
