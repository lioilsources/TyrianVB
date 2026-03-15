import 'dart:math';
import 'package:flame/components.dart';
import '../game/game_config.dart' as config;
import '../game/tyrian_game.dart';
import '../services/sound_service.dart';
import '../entities/hostile.dart';
import '../entities/collectable.dart';
import '../entities/vessel.dart';
import '../systems/path_system.dart';
import '../systems/device.dart';

/// Ported from Fleet.cls — a wave/group of enemies.
class Fleet extends Component with HasGameReference<TyrianGame> {
  String caption;
  int id;
  bool showDamage;
  double enterTime; // seconds from sector start
  int count; // total enemies to spawn
  int kills = 0;
  CollType bonus;
  int bonusMoney;
  HostType hostType;
  int triggerSteps; // frames between spawns (converted to seconds internally)
  bool active = false;
  bool started = false;
  PathSystem path;
  PathAction defaultPathAction;

  // Fleet bounding box (for broad-phase collision)
  double minX = double.infinity;
  double minY = double.infinity;
  double maxX = double.negativeInfinity;
  double maxY = double.negativeInfinity;

  // Enemy weapon (VB6 Fleet.weap / weapCharge / weapCD)
  Device? weapon;
  int weapCharge = 0;   // frames between shots (recharge)
  int weapCD = 0;       // current cooldown counter
  int weapDamage = 0;   // enemy weapon damage
  double weapScale = 0.5; // projectile scale ratio (dmg/75 clamped 0.3-0.99)

  // Extra path appended to each hostile's path on spawn
  PathSystem? extraPath;

  // Alternative path params for replacement
  int altParam1 = 0;
  int altParam2 = 0;
  int altParam3 = 0;
  PathType? altParam4;

  // Last kill position for bonus drop (VB6: spawn at last killed hostile)
  double lastKillX = 0;
  double lastKillY = 0;

  // Active hostiles
  final List<Hostile> hostiles = [];

  // Internal state
  double _stepTimer = 0;
  int _spawned = 0;

  double get triggerInterval => triggerSteps * config.frameDelay / 1000.0;

  Fleet({
    required this.caption,
    required this.id,
    this.showDamage = true,
    required this.enterTime,
    required this.count,
    this.bonus = CollType.none,
    this.bonusMoney = 0,
    required this.hostType,
    this.triggerSteps = 20,
    required this.path,
    this.defaultPathAction = PathAction.destroy,
  });

  @override
  void update(double dt) {
    if (!active) return;
    // Client: entities managed by snapshot, skip spawning/firing
    if (game.coopRole == CoopRole.client) return;

    // Spawn enemies at intervals
    _stepTimer += dt;
    while (_stepTimer >= triggerInterval && _spawned < count) {
      _spawnHostile();
      _stepTimer -= triggerInterval;
      _spawned++;
    }

    // Fleet weapon firing (centralized — prevents multi-fire bug from parallel hostile updates)
    if (weapCharge > 0 && hostiles.isNotEmpty) {
      weapCD++;
      if (weapCD >= weapCharge) {
        final alive = hostiles.where((h) => !h.isDead && h.y2 > 0).toList();
        if (alive.isNotEmpty) {
          final shooter = alive[Random().nextInt(alive.length)];
          final xm = shooter.position.x + shooter.size.x / 2;
          if (xm > 0 && xm < config.gameWidth) {
            game.spawnEnemyProjectile(xm, shooter.y2 + 5, weapDamage, weapScale);
          }
        }
        weapCD = 0;
      }
    }

    // Clean up dead hostiles
    hostiles.removeWhere((h) {
      if (h.isDead) {
        game.addExplosion(
          h.position.x + h.size.x / 2,
          h.position.y + h.size.y / 2,
          2,
        );
        h.removeFromParent();
        return true;
      }
      return false;
    });

    // Update bounding box
    _updateBounds();

    // Check if fleet is depleted (all spawned, none alive)
    if (_spawned >= count && hostiles.isEmpty) {
      active = false;
      // VB6: bonus only drops when ALL enemies were killed (not path-destroyed)
      if (kills >= count) _spawnBonus();
    }
  }

  /// Set extra path appended to each hostile's main path (VB6 Fleet.SetExtraPath)
  PathSystem setExtraPath(PathSystem p) {
    extraPath = p;
    return p;
  }

  void _spawnHostile() {
    final hpMax = Hostile.getHpMax(hostType);
    final clonedPath = path.clone();
    clonedPath.onExit = defaultPathAction;
    if (extraPath != null) {
      clonedPath.addPath(extraPath!);
    }
    final h = Hostile(
      caption: Hostile.hostCaption(hostType),
      id: _spawned,
      hostType: hostType,
      hp: hpMax,
      hpMax: hpMax,
      trace: clonedPath,
    );
    h.parentFleet = this;
    hostiles.add(h);
    game.world.add(h);
  }

  void _updateBounds() {
    minX = double.infinity;
    minY = double.infinity;
    maxX = double.negativeInfinity;
    maxY = double.negativeInfinity;

    for (final h in hostiles) {
      if (h.isDead) continue;
      if (h.position.x < minX) minX = h.position.x;
      if (h.position.y < minY) minY = h.position.y;
      if (h.x2 > maxX) maxX = h.x2;
      if (h.y2 > maxY) maxY = h.y2;
    }
  }

  void onHostileKilled(Hostile h, TyrianGame gameInstance, {Vessel? attacker}) {
    kills++;
    lastKillX = h.position.x + h.size.x / 2;
    lastKillY = h.position.y + h.size.y / 2;

    SoundService.instance.play(
      h.hpMax > 5000 ? SfxEvent.explosionLarge : SfxEvent.explosionSmall,
    );

    // Add score and credit to the vessel that got the kill
    final target = attacker ?? gameInstance.vessel;
    target.addScore(h.hpMax);
    target.credit += h.hpMax;
  }

  void _spawnBonus() {
    if (bonus == CollType.none && bonusMoney <= 0) return;

    // VB6: spawn at last killed hostile's position
    final cx = lastKillX;
    final cy = lastKillY;

    if (cx == 0 && cy == 0) return;

    final coll = Collectable(
      caption: _bonusCaption(),
      cType: bonus,
      value: bonusMoney,
      position: Vector2(cx, cy),
    );

    // Create falling path toward bottom
    final fallPath = PathSystem();
    fallPath.generate(
      200, cx, cy, cx, config.gameHeight + 50, PathType.linear,
    );
    coll.trace = fallPath;

    game.addCollectable(coll);
  }

  String _bonusCaption() {
    switch (bonus) {
      case CollType.frontWepUpgrade: return 'Weapon Up';
      case CollType.leftWepUpgrade: return 'Left Weapon Up';
      case CollType.rightWepUpgrade: return 'Right Weapon Up';
      case CollType.healthUpgrade: return 'Health';
      case CollType.shieldUpgrade: return 'Shield';
      case CollType.generatorUpgrade: return 'Generator Up';
      case CollType.bonusCredit: return 'Credits';
      case CollType.none: return '';
    }
  }

  /// VB6 Sector.AddWeapon — set enemy weapon for this fleet
  void addWeapon(int dmg, int recharge) {
    weapDamage = dmg;
    weapCharge = recharge;
    weapScale = (dmg / 75.0).clamp(0.3, 0.99);
  }

  /// Factory: create fleet with path
  static Fleet create({
    required int id,
    required double enterTime,
    required String caption,
    required HostType hostType,
    required int count,
    CollType bonus = CollType.none,
    int triggerSteps = 20,
    required double durationSec,
    required double srcX,
    required double srcY,
    required double dstX,
    required double dstY,
    PathType pathType = PathType.linear,
    double amplitude = 100,
    int cycles = 4,
    double amplMultiplier = 1.0,
    int bonusMoney = 0,
    PathAction defaultPathAction = PathAction.destroy,
    bool showDamage = true,
  }) {
    final steps = (durationSec * 1000 / config.frameDelay).round();
    final path = PathSystem();
    path.generate(steps, srcX, srcY, dstX, dstY, pathType,
        amplitude: amplitude, cycles: cycles, amplMultiplier: amplMultiplier);

    return Fleet(
      caption: caption,
      id: id,
      showDamage: showDamage,
      enterTime: enterTime,
      count: count,
      bonus: bonus,
      bonusMoney: bonusMoney,
      hostType: hostType,
      triggerSteps: triggerSteps,
      path: path,
      defaultPathAction: defaultPathAction,
    );
  }
}
