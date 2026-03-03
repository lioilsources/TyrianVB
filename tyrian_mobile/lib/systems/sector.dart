import 'dart:math';
import 'package:flame/components.dart';
import '../game/game_config.dart' as config;
import '../game/tyrian_game.dart';
import '../entities/hostile.dart';
import '../entities/structure.dart';
import '../entities/collectable.dart';
import 'fleet.dart';
import 'path_system.dart';

/// Ported from Sector.cls — a game level containing fleets and structures.
class Sector extends Component with HasGameReference<TyrianGame> {
  String caption;
  int level;
  int sectorBonus;
  bool complete = false;
  double elapsed = 0;
  double completeTime = 0;

  final List<Fleet> fleets = [];
  final List<Structure> structures = [];

  int get activeFleetCount => fleets.where((f) => f.active).length;
  bool get isComplete => complete;

  Sector({
    required this.caption,
    required this.level,
    this.sectorBonus = 500,
  });

  @override
  void update(double dt) {
    elapsed += dt;

    // Activate fleets based on enter time
    for (final fleet in fleets) {
      if (!fleet.started && elapsed >= fleet.enterTime) {
        fleet.active = true;
        fleet.started = true;
        game.activeFleets.add(fleet);
        game.world.add(fleet);
      }
    }

    // Activate structures based on enter time
    for (final s in structures) {
      if (!s.activated && elapsed >= s.enterTime) {
        s.activated = true;
        game.activeStructures.add(s);
        game.world.add(s);
      }
    }

    // Check for sector completion (all fleets started and depleted)
    if (!complete && fleets.isNotEmpty && fleets.every((f) => f.started)) {
      if (fleets.every((f) => !f.active)) {
        completeTime += dt;
        if (completeTime >= config.delayOnComplete) {
          complete = true;
        }
      }
    }
  }

  /// Factory to create sector by index (ports VBA Sector.Setup case blocks)
  static Sector? create(int index, TyrianGame game) {
    if (index >= 0 && index < _sectorBuilders.length) {
      return _sectorBuilders[index](game);
    }
    // Random sector for indices beyond defined levels
    return _createRandom(index, game);
  }

  static final List<Sector Function(TyrianGame)> _sectorBuilders = [
    _sector0,
    _sector1,
    _sector2,
    _sector3,
    _sector4,
    _sector5,
    _sector6,
  ];

  /// VB6 Sector.AddAsteroids — staggered asteroid spawning with paths
  static void _addAsteroids(Sector s, double enterTime, int count, double x, double width) {
    final rng = Random();
    for (int i = 0; i < count; i++) {
      final ax = rng.nextDouble() * width + x;
      final ast = Structure(
        caption: 'Asteroid ${i + 1}',
        behavior: StructBehavior.byPath,
        structType: StructType.asteroid,
        hp: 100000,
        hpMax: 100000,
        imgName: 'asteroid${rng.nextInt(4) == 0 ? '' : (rng.nextInt(3) + 1).toString()}',
      );
      ast.enterTime = enterTime + i;
      ast.collisionDmg = s.level;
      // Linear path top to bottom
      final path = PathSystem();
      path.generate(
        (20.0 * 1000 / config.frameDelay).round(),
        ax, -50, ax, config.gameHeight + 100,
        PathType.linear,
      );
      ast.trace = path;
      s.structures.add(ast);
    }
  }

  /// VB6 Sector.SetAltParams
  static void _setAltParams(Fleet f, int p1, int p2, int p3, PathType p4) {
    f.altParam1 = p1;
    f.altParam2 = p2;
    f.altParam3 = p3;
    f.altParam4 = p4;
  }

  // ---- Sector 0: System Perimeter (VB6 Level 1) ----
  // 10 fleets + 20 asteroids, 147 enemies total
  static Sector _sector0(TyrianGame game) {
    final w = config.gameWidth;
    final h = config.gameHeight;
    final s = Sector(caption: 'System Perimeter', level: 1, sectorBonus: 5000);

    s.fleets.add(Fleet.create(
      id: 0, enterTime: 1, caption: 'Merchant sentry',
      hostType: HostType.falcon1, count: 8, bonus: CollType.frontWepUpgrade,
      triggerSteps: 75, durationSec: 17, bonusMoney: 1000,
      srcX: 200, srcY: -45, dstX: 400, dstY: h + 5,
      pathType: PathType.linear,
    ));
    s.fleets.add(Fleet.create(
      id: 1, enterTime: 12, caption: 'Asteroid miner fleet',
      hostType: HostType.falcon1, count: 8, bonus: CollType.frontWepUpgrade,
      triggerSteps: 75, durationSec: 17,
      srcX: 300, srcY: -45, dstX: 500, dstY: h + 5,
      pathType: PathType.linear,
    ));
    s.fleets.add(Fleet.create(
      id: 2, enterTime: 23, caption: 'Asteroid miner fleet 2',
      hostType: HostType.falcon2, count: 8, bonus: CollType.rightWepUpgrade,
      triggerSteps: 75, durationSec: 17,
      srcX: w - 200, srcY: -45, dstX: w - 400, dstY: h + 5,
      pathType: PathType.sinus, amplitude: 20, cycles: 10,
    ));
    s.fleets.add(Fleet.create(
      id: 3, enterTime: 34, caption: 'Asteroid miner fleet 3',
      hostType: HostType.falcon2, count: 8, bonus: CollType.leftWepUpgrade,
      triggerSteps: 75, durationSec: 17,
      srcX: w - 300, srcY: -45, dstX: w - 500, dstY: h + 5,
      pathType: PathType.sinus, amplitude: 20, cycles: 10,
    ));
    s.fleets.add(Fleet.create(
      id: 4, enterTime: 52, caption: 'Asteroid miner escort',
      hostType: HostType.falcon3, count: 15, bonus: CollType.bonusCredit,
      triggerSteps: 72, durationSec: 27, bonusMoney: 1000,
      srcX: 300, srcY: -45, dstX: 1100, dstY: h + 5,
      pathType: PathType.cosinus, amplitude: 250, cycles: 10, amplMultiplier: 0.9991,
    ));
    s.fleets.add(Fleet.create(
      id: 5, enterTime: 85, caption: 'Asteroid hunters',
      hostType: HostType.falcon1, count: 30, bonus: CollType.generatorUpgrade,
      triggerSteps: 12, durationSec: 26,
      srcX: w - 400, srcY: -200, dstX: 300, dstY: h + 200,
      pathType: PathType.sinCos, amplitude: 180, cycles: 10,
    ));
    s.fleets.add(Fleet.create(
      id: 6, enterTime: 108, caption: '',
      hostType: HostType.falcon4, count: 10, bonus: CollType.leftWepUpgrade,
      triggerSteps: 10, durationSec: 27,
      srcX: 0, srcY: -400, dstX: w - 400, dstY: h + 5,
      pathType: PathType.sinCos, amplitude: 400, cycles: 10,
    ));
    s.fleets.add(Fleet.create(
      id: 7, enterTime: 123, caption: '',
      hostType: HostType.falcon4, count: 20, bonus: CollType.rightWepUpgrade,
      triggerSteps: 20, durationSec: 22,
      srcX: 0, srcY: -40, dstX: w - 100, dstY: h + 5,
      pathType: PathType.sinus, amplitude: 100, cycles: 10,
    ));
    s.fleets.add(Fleet.create(
      id: 8, enterTime: 152, caption: '',
      hostType: HostType.falcon5, count: 20, bonus: CollType.frontWepUpgrade,
      triggerSteps: 25, durationSec: 20,
      srcX: w, srcY: -40, dstX: 0, dstY: h + 5,
      pathType: PathType.sinus, amplitude: 100, cycles: 12,
    ));
    s.fleets.add(Fleet.create(
      id: 9, enterTime: 177, caption: '',
      hostType: HostType.falcon6, count: 20, bonus: CollType.bonusCredit,
      triggerSteps: 25, durationSec: 24, bonusMoney: 500,
      srcX: -50, srcY: 200, dstX: w + 10, dstY: 200,
      pathType: PathType.sinus, amplitude: 100, cycles: 12,
    ));
    _addAsteroids(s, 57, 20, (w / 5).roundToDouble(), (w / 2).roundToDouble());

    return s;
  }

  // ---- Sector 1: Inner Zone (VB6 Level 2) ----
  // 9 fleets, 173 enemies total, boss with extra path
  static Sector _sector1(TyrianGame game) {
    final w = config.gameWidth;
    final h = config.gameHeight;
    final s = Sector(caption: 'Inner Zone', level: 2, sectorBonus: 7500);

    s.fleets.add(Fleet.create(
      id: 0, enterTime: 2, caption: '',
      hostType: HostType.falcon3, count: 30, bonus: CollType.healthUpgrade,
      triggerSteps: 12, durationSec: 27,
      srcX: w - 100, srcY: -200, dstX: 300, dstY: h + 200,
      pathType: PathType.sinCos, amplitude: 180, cycles: 10,
    ));
    s.fleets.add(Fleet.create(
      id: 1, enterTime: 24, caption: '',
      hostType: HostType.falcon4, count: 30, bonus: CollType.leftWepUpgrade,
      triggerSteps: 12, durationSec: 27,
      srcX: 100, srcY: -200, dstX: w - 400, dstY: h + 200,
      pathType: PathType.sinCos, amplitude: 220, cycles: 10,
    ));
    s.fleets.add(Fleet.create(
      id: 2, enterTime: 46, caption: '',
      hostType: HostType.falcon5, count: 30, bonus: CollType.rightWepUpgrade,
      triggerSteps: 12, durationSec: 27,
      srcX: w - 100, srcY: -200, dstX: 300, dstY: h + 200,
      pathType: PathType.sinCos, amplitude: 180, cycles: 10,
    ));
    s.fleets.add(Fleet.create(
      id: 3, enterTime: 68, caption: '',
      hostType: HostType.falcon6, count: 30, bonus: CollType.shieldUpgrade,
      triggerSteps: 12, durationSec: 27,
      srcX: 100, srcY: -200, dstX: w - 400, dstY: h + 200,
      pathType: PathType.sinCos, amplitude: 220, cycles: 10,
    ));
    s.fleets.add(Fleet.create(
      id: 4, enterTime: 90, caption: '',
      hostType: HostType.falcon4, count: 10, bonus: CollType.generatorUpgrade,
      triggerSteps: 50, durationSec: 16,
      srcX: 200, srcY: -45, dstX: w - 200, dstY: h + 5,
      pathType: PathType.linear,
    ));
    s.fleets.add(Fleet.create(
      id: 5, enterTime: 94, caption: '',
      hostType: HostType.falcon4, count: 12, bonus: CollType.leftWepUpgrade,
      triggerSteps: 50, durationSec: 16,
      srcX: 300, srcY: -45, dstX: w - 100, dstY: h + 5,
      pathType: PathType.linear,
    ));
    s.fleets.add(Fleet.create(
      id: 6, enterTime: 100, caption: '',
      hostType: HostType.falcon5, count: 14, bonus: CollType.rightWepUpgrade,
      triggerSteps: 50, durationSec: 16,
      srcX: w - 200, srcY: -45, dstX: 200, dstY: h + 5,
      pathType: PathType.linear,
    ));

    // Boss: falconx2 with 4-segment extra path
    final bossFleet = Fleet.create(
      id: 7, enterTime: 100, caption: '',
      hostType: HostType.falconx2, count: 1, bonus: CollType.shieldUpgrade,
      triggerSteps: 12, durationSec: 12, bonusMoney: 1000,
      srcX: w, srcY: 0, dstX: 0, dstY: h,
      pathType: PathType.linear,
    );
    // Extra path: Cosinus→Linear→Linear→Linear, onExit=Stay
    final ep = PathSystem();
    ep.generate(300, 0, h, 0, -100, PathType.cosinus, amplitude: 100, cycles: 2);
    final seg2 = PathSystem();
    seg2.generate(400, -100, 0, 1300, h, PathType.linear);
    ep.addPath(seg2);
    final seg3 = PathSystem();
    seg3.generate(200, 1300, h, 680, 500, PathType.linear);
    ep.addPath(seg3);
    final seg4 = PathSystem();
    seg4.generate(2000, 680, 500, 680, 200, PathType.linear);
    ep.addPath(seg4);
    ep.onExit = PathAction.stay;
    bossFleet.setExtraPath(ep);
    s.fleets.add(bossFleet);

    s.fleets.add(Fleet.create(
      id: 8, enterTime: 104, caption: '',
      hostType: HostType.falcon6, count: 16, bonus: CollType.shieldUpgrade,
      triggerSteps: 50, durationSec: 16,
      srcX: w - 100, srcY: -45, dstX: 300, dstY: h + 5,
      pathType: PathType.linear,
    ));

    return s;
  }

  // ---- Sector 2: Planet Perimeter (VB6 Level 3) ----
  // 7 fleets + 20 asteroids, 196 enemies total
  static Sector _sector2(TyrianGame game) {
    final w = config.gameWidth;
    final h = config.gameHeight;
    final s = Sector(caption: 'Planet Perimeter', level: 3, sectorBonus: 10000);

    s.fleets.add(Fleet.create(
      id: 0, enterTime: 2, caption: '',
      hostType: HostType.falcon3, count: 50, bonus: CollType.generatorUpgrade,
      triggerSteps: 12, durationSec: 22,
      srcX: w + 100, srcY: -200, dstX: -100, dstY: h + 200,
      pathType: PathType.sinCos, amplitude: 180, cycles: 10,
    ));
    s.fleets.add(Fleet.create(
      id: 1, enterTime: 18, caption: '',
      hostType: HostType.falcon3, count: 50, bonus: CollType.shieldUpgrade,
      triggerSteps: 12, durationSec: 22,
      srcX: -100, srcY: -200, dstX: w + 100, dstY: h + 200,
      pathType: PathType.sinCos, amplitude: 180, cycles: 10,
    ));
    s.fleets.add(Fleet.create(
      id: 2, enterTime: 45, caption: '',
      hostType: HostType.falcon3, count: 30, bonus: CollType.rightWepUpgrade,
      triggerSteps: 70, durationSec: 20,
      srcX: -100, srcY: -45, dstX: w + 100, dstY: h + 5,
      pathType: PathType.cosinus, amplitude: 75, cycles: 11,
    ));
    s.fleets.add(Fleet.create(
      id: 3, enterTime: 55, caption: '',
      hostType: HostType.falconx, count: 8, bonus: CollType.none,
      triggerSteps: 12, durationSec: 85,
      srcX: w / 2 - 10, srcY: -200, dstX: w / 2 - 10, dstY: h + 200,
      pathType: PathType.sinCos, amplitude: 300, cycles: 8,
    ));
    s.fleets.add(Fleet.create(
      id: 4, enterTime: 70, caption: '',
      hostType: HostType.falcon4, count: 30, bonus: CollType.leftWepUpgrade,
      triggerSteps: 70, durationSec: 20,
      srcX: w + 100, srcY: -45, dstX: -100, dstY: h + 5,
      pathType: PathType.cosinus, amplitude: 75, cycles: 13,
    ));
    s.fleets.add(Fleet.create(
      id: 5, enterTime: 75, caption: '',
      hostType: HostType.falconx, count: 8, bonus: CollType.none,
      triggerSteps: 12, durationSec: 85,
      srcX: 690, srcY: -200, dstX: w / 2 - 10, dstY: h + 200,
      pathType: PathType.sinCos, amplitude: 300, cycles: 8,
    ));
    s.fleets.add(Fleet.create(
      id: 6, enterTime: 120, caption: '',
      hostType: HostType.falconx, count: 20, bonus: CollType.generatorUpgrade,
      triggerSteps: 12, durationSec: 75,
      srcX: w, srcY: -200, dstX: 0, dstY: h + 200,
      pathType: PathType.sinCos, amplitude: 300, cycles: 8,
    ));
    _addAsteroids(s, 125, 20, 50, w - 50);

    return s;
  }

  // ---- Sector 3: Planet Patrol (VB6 Level 4) ----
  // 18 fleets, 150x swarm + 17 bosses, shared extra path
  static Sector _sector3(TyrianGame game) {
    final w = config.gameWidth;
    final h = config.gameHeight;
    final s = Sector(caption: 'Planet Patrol', level: 4, sectorBonus: 15000);

    // Boss 1: falconx2 with 4-segment extra path
    final boss1 = Fleet.create(
      id: 0, enterTime: 2, caption: '',
      hostType: HostType.falconx2, count: 1, bonus: CollType.none,
      triggerSteps: 12, durationSec: 19,
      srcX: w, srcY: 0, dstX: 0, dstY: h,
      pathType: PathType.linear,
    );
    final ep = PathSystem();
    ep.generate(350, 0, h, 0, -100, PathType.cosinus, amplitude: 500, cycles: 2);
    final seg2 = PathSystem();
    seg2.generate(500, -100, 0, w + 50, h + 50, PathType.linear);
    ep.addPath(seg2);
    final seg3 = PathSystem();
    seg3.generate(350, w - 100, h, w / 2 - 20, 500, PathType.linear);
    ep.addPath(seg3);
    final seg4 = PathSystem();
    seg4.generate(2400, w / 2 - 20, 500, w / 2 - 20, 20, PathType.linear);
    ep.addPath(seg4);
    ep.onExit = PathAction.stay;
    boss1.setExtraPath(ep);
    s.fleets.add(boss1);

    // Clone the extra path for all subsequent bosses
    final sharedEp = ep.clone();

    // Swarm: 150x falcon5
    s.fleets.add(Fleet.create(
      id: 1, enterTime: 4, caption: '',
      hostType: HostType.falcon5, count: 150, bonus: CollType.healthUpgrade,
      triggerSteps: 10, durationSec: 70,
      srcX: -180, srcY: -180, dstX: w + 180, dstY: h + 180,
      pathType: PathType.sinCos, amplitude: 160, cycles: 10,
    ));

    // Individual bosses: falconx at t=5,8,11,14
    for (final entry in [
      [2, 5.0, HostType.falconx, CollType.shieldUpgrade, 0],
      [3, 8.0, HostType.falconx, CollType.none, 0],
      [4, 11.0, HostType.falconx, CollType.generatorUpgrade, 0],
      [5, 14.0, HostType.falconx, CollType.none, 0],
    ]) {
      final f = Fleet.create(
        id: entry[0] as int, enterTime: entry[1] as double, caption: '',
        hostType: entry[2] as HostType, count: 1, bonus: entry[3] as CollType,
        triggerSteps: 12, durationSec: 12,
        srcX: w, srcY: 0, dstX: 0, dstY: h,
        pathType: PathType.linear,
      );
      f.setExtraPath(sharedEp.clone());
      s.fleets.add(f);
    }

    // falconx2 boss at t=17
    final f17 = Fleet.create(
      id: 6, enterTime: 17, caption: '',
      hostType: HostType.falconx2, count: 1, bonus: CollType.none,
      triggerSteps: 12, durationSec: 12,
      srcX: w, srcY: 0, dstX: 0, dstY: h,
      pathType: PathType.linear,
    );
    f17.setExtraPath(sharedEp.clone());
    s.fleets.add(f17);

    // falconx2 bosses at t=20,22,24,26,28,29,30 with bonus money
    for (final entry in [
      [7, 20.0, CollType.bonusCredit, 2500],
      [8, 22.0, CollType.none, 2500],
      [9, 24.0, CollType.none, 2500],
      [10, 26.0, CollType.shieldUpgrade, 2500],
      [11, 28.0, CollType.none, 2500],
      [12, 29.0, CollType.none, 2500],
      [13, 30.0, CollType.bonusCredit, 3000],
    ]) {
      final f = Fleet.create(
        id: entry[0] as int, enterTime: entry[1] as double, caption: '',
        hostType: HostType.falconx2, count: 1, bonus: entry[2] as CollType,
        triggerSteps: 12, durationSec: 14, bonusMoney: entry[3] as int,
        srcX: w, srcY: 0, dstX: 0, dstY: h,
        pathType: PathType.linear,
      );
      f.setExtraPath(sharedEp.clone());
      s.fleets.add(f);
    }

    // falconx3 bosses at t=31,32,33,34 with bonus money
    for (final entry in [
      [14, 31.0, CollType.shieldUpgrade, 3000],
      [15, 32.0, CollType.bonusCredit, 3000],
      [16, 33.0, CollType.shieldUpgrade, 3000],
      [17, 34.0, CollType.bonusCredit, 3000],
    ]) {
      final f = Fleet.create(
        id: entry[0] as int, enterTime: entry[1] as double, caption: '',
        hostType: HostType.falconx3, count: 1, bonus: entry[2] as CollType,
        triggerSteps: 12, durationSec: 16, bonusMoney: entry[3] as int,
        srcX: w, srcY: 0, dstX: 0, dstY: h,
        pathType: PathType.linear,
      );
      f.setExtraPath(sharedEp.clone());
      s.fleets.add(f);
    }

    return s;
  }

  // ---- Sector 4: Planet Orbit (VB6 Level 5) ----
  // 13 fleets + 7 asteroids, 6 FreezeFleet + 7 ReplacePath
  static Sector _sector4(TyrianGame game) {
    final w = config.gameWidth;
    final s = Sector(caption: 'Planet Orbit', level: 5, sectorBonus: 20000);

    // 6 FreezeFleet fleets: fly to Y=100-600 and stop in formation
    s.fleets.add(Fleet.create(
      id: 0, enterTime: 2, caption: '',
      hostType: HostType.falcon6, count: 19, bonus: CollType.generatorUpgrade,
      triggerSteps: 25, durationSec: 12,
      srcX: -50, srcY: 100, dstX: w - 58, dstY: 100,
      pathType: PathType.linear,
      defaultPathAction: PathAction.freezeFleet,
    ));
    s.fleets.add(Fleet.create(
      id: 1, enterTime: 3, caption: '',
      hostType: HostType.falcon5, count: 19, bonus: CollType.bonusCredit,
      triggerSteps: 25, durationSec: 12, bonusMoney: 20000,
      srcX: w + 5, srcY: 200, dstX: 2, dstY: 200,
      pathType: PathType.linear,
      defaultPathAction: PathAction.freezeFleet,
    ));
    s.fleets.add(Fleet.create(
      id: 2, enterTime: 4, caption: '',
      hostType: HostType.falcon4, count: 19, bonus: CollType.bonusCredit,
      triggerSteps: 25, durationSec: 12, bonusMoney: 18000,
      srcX: -50, srcY: 300, dstX: w - 58, dstY: 300,
      pathType: PathType.linear,
      defaultPathAction: PathAction.freezeFleet,
    ));
    s.fleets.add(Fleet.create(
      id: 3, enterTime: 5, caption: '',
      hostType: HostType.falcon3, count: 19, bonus: CollType.bonusCredit,
      triggerSteps: 25, durationSec: 12, bonusMoney: 16000,
      srcX: w + 5, srcY: 400, dstX: 2, dstY: 400,
      pathType: PathType.linear,
      defaultPathAction: PathAction.freezeFleet,
    ));
    s.fleets.add(Fleet.create(
      id: 4, enterTime: 6, caption: '',
      hostType: HostType.falcon2, count: 19, bonus: CollType.bonusCredit,
      triggerSteps: 25, durationSec: 12, bonusMoney: 14000,
      srcX: -50, srcY: 500, dstX: w - 58, dstY: 500,
      pathType: PathType.linear,
      defaultPathAction: PathAction.freezeFleet,
    ));
    s.fleets.add(Fleet.create(
      id: 5, enterTime: 7, caption: '',
      hostType: HostType.falcon1, count: 19, bonus: CollType.bonusCredit,
      triggerSteps: 25, durationSec: 12, bonusMoney: 12000,
      srcX: w + 5, srcY: 600, dstX: 2, dstY: 600,
      pathType: PathType.linear,
      defaultPathAction: PathAction.freezeFleet,
    ));

    // ReplacePath fleets: fly to position then oscillate
    final rpFleet0 = Fleet.create(
      id: 6, enterTime: 15, caption: '',
      hostType: HostType.falconx3, count: 14, bonus: CollType.frontWepUpgrade,
      triggerSteps: 35, durationSec: 12,
      srcX: -50, srcY: 10, dstX: w - 90, dstY: 10,
      pathType: PathType.linear,
      defaultPathAction: PathAction.replacePath,
    );
    _setAltParams(rpFleet0, 50, 40, 0, PathType.cosinus);
    s.fleets.add(rpFleet0);

    for (final entry in [
      [7, 45.0, HostType.falcon6, CollType.healthUpgrade, 1, -50.0, 100.0, w - 66, 100.0, 30, 20],
      [8, 46.0, HostType.falcon5, CollType.shieldUpgrade, 20000, w + 5, 200.0, 2.0, 200.0, 30, 20],
      [9, 47.0, HostType.falcon4, CollType.bonusCredit, 18000, -50.0, 300.0, w - 58, 300.0, 30, 20],
      [10, 48.0, HostType.falcon3, CollType.bonusCredit, 16000, w + 5, 400.0, 2.0, 400.0, 30, 20],
      [11, 49.0, HostType.falcon2, CollType.bonusCredit, 14000, -50.0, 500.0, w - 58, 500.0, 30, 20],
      [12, 50.0, HostType.falcon1, CollType.bonusCredit, 12000, w + 5, 600.0, 2.0, 600.0, 30, 20],
    ]) {
      final f = Fleet.create(
        id: entry[0] as int, enterTime: entry[1] as double, caption: '',
        hostType: entry[2] as HostType, count: 19, bonus: entry[3] as CollType,
        triggerSteps: 25, durationSec: 12,
        bonusMoney: entry[4] as int,
        srcX: (entry[5] as double), srcY: (entry[6] as double),
        dstX: (entry[7] as double), dstY: (entry[8] as double),
        pathType: PathType.linear,
        defaultPathAction: PathAction.replacePath,
      );
      _setAltParams(f, entry[9] as int, entry[10] as int, 0, PathType.cosinus);
      s.fleets.add(f);
    }

    _addAsteroids(s, 57, 7, 50, w - 50);

    return s;
  }

  // ---- Sector 5: Industry Zone (VB6 Level 6) ----
  // 7 fleets, growing spiral + parallel linear waves
  static Sector _sector5(TyrianGame game) {
    final w = config.gameWidth;
    final h = config.gameHeight;
    final s = Sector(caption: 'Industry Zone', level: 6, sectorBonus: 25000);

    // Growing spiral: 28x falconx3
    s.fleets.add(Fleet.create(
      id: 0, enterTime: 3, caption: '',
      hostType: HostType.falconx3, count: 28, bonus: CollType.frontWepUpgrade,
      triggerSteps: 100, durationSec: 35, bonusMoney: 10000,
      srcX: w / 2, srcY: -55, dstX: w / 2, dstY: h + 5,
      pathType: PathType.cosinus, amplitude: 12, cycles: 10, amplMultiplier: 1.0025,
    ));

    // Parallel linear fleets
    s.fleets.add(Fleet.create(
      id: 1, enterTime: 15, caption: '',
      hostType: HostType.falcon1, count: 16, bonus: CollType.generatorUpgrade,
      triggerSteps: 22, durationSec: 12,
      srcX: 200, srcY: -45, dstX: w - 200, dstY: h + 5,
      pathType: PathType.linear,
    ));
    s.fleets.add(Fleet.create(
      id: 2, enterTime: 15, caption: '',
      hostType: HostType.falcon1, count: 16, bonus: CollType.bonusCredit,
      triggerSteps: 22, durationSec: 12,
      srcX: w - 200, srcY: -45, dstX: 200, dstY: h + 5,
      pathType: PathType.linear,
    ));
    s.fleets.add(Fleet.create(
      id: 3, enterTime: 30, caption: '',
      hostType: HostType.falcon2, count: 18, bonus: CollType.shieldUpgrade,
      triggerSteps: 22, durationSec: 12,
      srcX: 200, srcY: -45, dstX: w - 200, dstY: h + 5,
      pathType: PathType.linear,
    ));
    s.fleets.add(Fleet.create(
      id: 4, enterTime: 30, caption: '',
      hostType: HostType.falcon2, count: 18, bonus: CollType.healthUpgrade,
      triggerSteps: 22, durationSec: 12,
      srcX: w - 200, srcY: -45, dstX: 200, dstY: h + 5,
      pathType: PathType.linear,
    ));
    s.fleets.add(Fleet.create(
      id: 5, enterTime: 45, caption: '',
      hostType: HostType.falcon3, count: 20, bonus: CollType.bonusCredit,
      triggerSteps: 22, durationSec: 12, bonusMoney: 3000,
      srcX: 200, srcY: -45, dstX: w - 200, dstY: h + 5,
      pathType: PathType.linear,
    ));
    s.fleets.add(Fleet.create(
      id: 6, enterTime: 45, caption: '',
      hostType: HostType.falcon3, count: 20, bonus: CollType.bonusCredit,
      triggerSteps: 22, durationSec: 12, bonusMoney: 5000,
      srcX: w - 200, srcY: -45, dstX: 200, dstY: h + 5,
      pathType: PathType.linear,
    ));

    return s;
  }

  // ---- Sector 6+: Random (VB6 Level 7+) ----
  static Sector _sector6(TyrianGame game) {
    return _createRandom(6, game);
  }

  // ---- Random Sector Generation ----
  static Sector _createRandom(int index, TyrianGame game) {
    final rng = Random(index * 42);
    final level = 7 + (index - 7);
    final s = Sector(
      caption: 'Sector ${index + 1} — Unknown Space',
      level: level,
      sectorBonus: 500 + index * 200,
    );

    final numFleets = 3 + rng.nextInt(3);
    final hostTypes = HostType.values;

    for (int i = 0; i < numFleets; i++) {
      // Scale difficulty with level
      final minType = (index - 4).clamp(0, hostTypes.length - 4);
      final maxType = (index - 1).clamp(3, hostTypes.length - 1);
      final typeIndex = minType + rng.nextInt(maxType - minType + 1);
      final ht = hostTypes[typeIndex.clamp(0, hostTypes.length - 1)];

      final cnt = 2 + rng.nextInt(6);
      final dur = 5.0 + rng.nextDouble() * 8.0;
      final enter = i * 5.0 + rng.nextDouble() * 3.0;
      final pathTypes = PathType.values;
      final pt = pathTypes[rng.nextInt(pathTypes.length)];
      final amp = 60.0 + rng.nextDouble() * 200.0;
      final cyc = 1 + rng.nextInt(5);

      final bonusTypes = CollType.values;
      final bon = bonusTypes[rng.nextInt(bonusTypes.length)];

      s.fleets.add(Fleet.create(
        id: i,
        enterTime: enter,
        caption: '${cnt}x ${Hostile.hostCaption(ht)}',
        hostType: ht,
        count: cnt,
        triggerSteps: 15 + rng.nextInt(30),
        durationSec: dur,
        srcX: rng.nextDouble() * config.gameWidth,
        srcY: -40.0 - rng.nextDouble() * 60,
        dstX: rng.nextDouble() * config.gameWidth,
        dstY: config.gameHeight + 40.0 + rng.nextDouble() * 60,
        pathType: pt,
        amplitude: amp,
        cycles: cyc,
        bonus: bon,
        bonusMoney: 100 + rng.nextInt(500),
        showDamage: true,
      ));
    }

    // Random asteroids
    if (rng.nextBool()) {
      for (int i = 0; i < 3 + rng.nextInt(5); i++) {
        s.structures.add(Structure(
          caption: 'Asteroid',
          behavior: StructBehavior.fall,
          structType: StructType.asteroid,
          hp: 999999,
          hpMax: 999999,
          imgName: 'asteroid${rng.nextInt(4) == 0 ? '' : (rng.nextInt(3) + 1).toString()}',
          position: Vector2(
            rng.nextDouble() * config.gameWidth,
            -(rng.nextDouble() * 600 + 100),
          ),
        ));
      }
    }

    return s;
  }
}
