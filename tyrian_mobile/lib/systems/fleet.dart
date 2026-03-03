import 'package:flame/components.dart';
import '../game/game_config.dart' as config;
import '../game/tyrian_game.dart';
import '../entities/hostile.dart';
import '../entities/collectable.dart';
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

  // Weapon for enemies to fire
  Device? weapon;

  // Extra path appended to each hostile's path on spawn
  PathSystem? extraPath;

  // Alternative path params for replacement
  int altParam1 = 0;
  int altParam2 = 0;
  int altParam3 = 0;
  PathType? altParam4;

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

    // Spawn enemies at intervals
    _stepTimer += dt;
    while (_stepTimer >= triggerInterval && _spawned < count) {
      _spawnHostile();
      _stepTimer -= triggerInterval;
      _spawned++;
    }

    // Clean up dead hostiles
    hostiles.removeWhere((h) {
      if (h.isDead) {
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
      _spawnBonus();
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

  void onHostileKilled(Hostile h, TyrianGame gameInstance) {
    kills++;

    // Add score
    gameInstance.vessel.score += h.hpMax;
    gameInstance.vessel.credit += h.hpMax ~/ 10;
  }

  void _spawnBonus() {
    if (bonus == CollType.none && bonusMoney <= 0) return;

    // Spawn at fleet center
    final cx = (minX + maxX) / 2;
    final cy = (minY + maxY) / 2;

    if (cx.isInfinite || cy.isInfinite) return;

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
