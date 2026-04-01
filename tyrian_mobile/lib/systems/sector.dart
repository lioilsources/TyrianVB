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

    // Fleet acceleration: skip dead time (VB6: max 2-second buffer before next fleet)
    if (fleets.any((f) => f.started)) {
      final allStartedDead = fleets.where((f) => f.started).every((f) => !f.active);
      if (allStartedDead) {
        final nextUnstarted = fleets.where((f) => !f.started).toList();
        if (nextUnstarted.isNotEmpty) {
          final target = nextUnstarted.first.enterTime;
          if (target > elapsed + 2) {
            elapsed = target - 2; // VB6: snap to 2s before next fleet
          }
        }
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
    final hs = config.gameHeight / config.scrHeight;
    final s = Sector(caption: 'System Perimeter', level: 1, sectorBonus: 5000);

    s.fleets.add(Fleet.create(
      id: 0, enterTime: 1, caption: 'Merchant sentry',
      hostType: HostType.falcon1, count: 8, bonus: CollType.frontWepUpgrade,
      triggerSteps: 75, durationSec: 17 * hs, bonusMoney: 1000,
      srcX: 200, srcY: -45 * hs, dstX: 400, dstY: h + 5,
      pathType: PathType.linear,
    ));
    s.fleets.add(Fleet.create(
      id: 1, enterTime: 12, caption: 'Asteroid miner fleet',
      hostType: HostType.falcon1, count: 8, bonus: CollType.frontWepUpgrade,
      triggerSteps: 75, durationSec: 17 * hs,
      srcX: 300, srcY: -45 * hs, dstX: 500, dstY: h + 5,
      pathType: PathType.linear,
    ));
    s.fleets.add(Fleet.create(
      id: 2, enterTime: 23, caption: 'Asteroid miner fleet 2',
      hostType: HostType.falcon2, count: 8, bonus: CollType.rightWepUpgrade,
      triggerSteps: 75, durationSec: 17 * hs,
      srcX: w - 200, srcY: -45 * hs, dstX: w - 400, dstY: h + 5,
      pathType: PathType.sinus, amplitude: 20 * hs, cycles: 10,
    ));
    s.fleets.add(Fleet.create(
      id: 3, enterTime: 34, caption: 'Asteroid miner fleet 3',
      hostType: HostType.falcon2, count: 8, bonus: CollType.leftWepUpgrade,
      triggerSteps: 75, durationSec: 17 * hs,
      srcX: w - 300, srcY: -45 * hs, dstX: w - 500, dstY: h + 5,
      pathType: PathType.sinus, amplitude: 20 * hs, cycles: 10,
    ));
    final f4 = Fleet.create(
      id: 4, enterTime: 52, caption: 'Asteroid miner escort',
      hostType: HostType.falcon3, count: 15, bonus: CollType.bonusCredit,
      triggerSteps: 72, durationSec: 27 * hs, bonusMoney: 1000,
      srcX: 300, srcY: -45 * hs, dstX: w - 40, dstY: h + 5,
      pathType: PathType.cosinus, amplitude: 130, cycles: 10, amplMultiplier: 0.9991,
    );
    f4.addWeapon(10, 300);
    s.fleets.add(f4);
    s.fleets.add(Fleet.create(
      id: 5, enterTime: 85, caption: 'Asteroid hunters',
      hostType: HostType.falcon1, count: 30, bonus: CollType.generatorUpgrade,
      triggerSteps: 12, durationSec: 26 * hs,
      srcX: w - 400, srcY: -200 * hs, dstX: 300, dstY: h + 200,
      pathType: PathType.sinCos, amplitude: 180 * hs, cycles: 10,
    ));
    s.fleets.add(Fleet.create(
      id: 6, enterTime: 108, caption: '',
      hostType: HostType.falcon4, count: 10, bonus: CollType.leftWepUpgrade,
      triggerSteps: 10, durationSec: 27 * hs,
      srcX: 0, srcY: -400 * hs, dstX: w - 400, dstY: h + 5,
      pathType: PathType.sinCos, amplitude: 200 * hs, cycles: 10,
    ));
    final f7 = Fleet.create(
      id: 7, enterTime: 123, caption: '',
      hostType: HostType.falcon4, count: 20, bonus: CollType.rightWepUpgrade,
      triggerSteps: 20, durationSec: 22 * hs,
      srcX: 0, srcY: -40 * hs, dstX: w - 100, dstY: h + 5,
      pathType: PathType.sinus, amplitude: 100 * hs, cycles: 10,
    );
    f7.addWeapon(15, 300);
    s.fleets.add(f7);
    final f8 = Fleet.create(
      id: 8, enterTime: 152, caption: '',
      hostType: HostType.falcon5, count: 20, bonus: CollType.frontWepUpgrade,
      triggerSteps: 25, durationSec: 20 * hs,
      srcX: w, srcY: -40 * hs, dstX: 0, dstY: h + 5,
      pathType: PathType.sinus, amplitude: 100 * hs, cycles: 12,
    );
    f8.addWeapon(15, 275);
    s.fleets.add(f8);
    final f9 = Fleet.create(
      id: 9, enterTime: 177, caption: '',
      hostType: HostType.falcon6, count: 20, bonus: CollType.bonusCredit,
      triggerSteps: 25, durationSec: 24 * hs, bonusMoney: 500,
      srcX: -50, srcY: 200 * hs, dstX: w + 10, dstY: 200 * hs,
      pathType: PathType.sinus, amplitude: 100 * hs, cycles: 12,
    );
    f9.addWeapon(18, 175);
    s.fleets.add(f9);
    _addAsteroids(s, 57, 20, (w / 5).roundToDouble(), (w / 2).roundToDouble());

    return s;
  }

  // ---- Sector 1: Inner Zone (VB6 Level 2) ----
  // 9 fleets, 173 enemies total, boss with extra path
  static Sector _sector1(TyrianGame game) {
    final w = config.gameWidth;
    final h = config.gameHeight;
    final hs = config.gameHeight / config.scrHeight;
    final s = Sector(caption: 'Inner Zone', level: 2, sectorBonus: 7500);

    final s1f0 = Fleet.create(
      id: 0, enterTime: 2, caption: '',
      hostType: HostType.falcon3, count: 30, bonus: CollType.healthUpgrade,
      triggerSteps: 12, durationSec: 27 * hs,
      srcX: w - 100, srcY: -200 * hs, dstX: 300, dstY: h + 200,
      pathType: PathType.sinCos, amplitude: 180 * hs, cycles: 10,
    );
    s1f0.addWeapon(20, 400);
    s.fleets.add(s1f0);
    final s1f1 = Fleet.create(
      id: 1, enterTime: 24, caption: '',
      hostType: HostType.falcon4, count: 30, bonus: CollType.leftWepUpgrade,
      triggerSteps: 12, durationSec: 27 * hs,
      srcX: 100, srcY: -200 * hs, dstX: w - 400, dstY: h + 200,
      pathType: PathType.sinCos, amplitude: 220 * hs, cycles: 10,
    );
    s1f1.addWeapon(20, 400);
    s.fleets.add(s1f1);
    final s1f2 = Fleet.create(
      id: 2, enterTime: 46, caption: '',
      hostType: HostType.falcon5, count: 30, bonus: CollType.rightWepUpgrade,
      triggerSteps: 12, durationSec: 27 * hs,
      srcX: w - 100, srcY: -200 * hs, dstX: 300, dstY: h + 200,
      pathType: PathType.sinCos, amplitude: 180 * hs, cycles: 10,
    );
    s1f2.addWeapon(20, 350);
    s.fleets.add(s1f2);
    final s1f3 = Fleet.create(
      id: 3, enterTime: 68, caption: '',
      hostType: HostType.falcon6, count: 30, bonus: CollType.shieldUpgrade,
      triggerSteps: 12, durationSec: 27 * hs,
      srcX: 100, srcY: -200 * hs, dstX: w - 400, dstY: h + 200,
      pathType: PathType.sinCos, amplitude: 220 * hs, cycles: 10,
    );
    s1f3.addWeapon(20, 350);
    s.fleets.add(s1f3);
    final s1f4 = Fleet.create(
      id: 4, enterTime: 90, caption: '',
      hostType: HostType.falcon4, count: 10, bonus: CollType.generatorUpgrade,
      triggerSteps: 50, durationSec: 16 * hs,
      srcX: 200, srcY: -45 * hs, dstX: w - 200, dstY: h + 5,
      pathType: PathType.linear,
    );
    s1f4.addWeapon(20, 350);
    s.fleets.add(s1f4);
    final s1f5 = Fleet.create(
      id: 5, enterTime: 94, caption: '',
      hostType: HostType.falcon4, count: 12, bonus: CollType.leftWepUpgrade,
      triggerSteps: 50, durationSec: 16 * hs,
      srcX: 300, srcY: -45 * hs, dstX: w - 100, dstY: h + 5,
      pathType: PathType.linear,
    );
    s1f5.addWeapon(20, 300);
    s.fleets.add(s1f5);
    final s1f6 = Fleet.create(
      id: 6, enterTime: 100, caption: '',
      hostType: HostType.falcon5, count: 14, bonus: CollType.rightWepUpgrade,
      triggerSteps: 50, durationSec: 16 * hs,
      srcX: w - 200, srcY: -45 * hs, dstX: 200, dstY: h + 5,
      pathType: PathType.linear,
    );
    s.fleets.add(s1f6);

    // Boss: falconx2 with 4-segment extra path
    final bossFleet = Fleet.create(
      id: 7, enterTime: 100, caption: '',
      hostType: HostType.falconx2, count: 1, bonus: CollType.shieldUpgrade,
      triggerSteps: 12, durationSec: 12 * hs, bonusMoney: 1000,
      srcX: w, srcY: 0, dstX: 0, dstY: h,
      pathType: PathType.linear,
    );
    // Extra path: Cosinus→Linear→Linear→Linear, onExit=Stay
    final ep = PathSystem();
    ep.generate(300, 0, h, 0, -100 * hs, PathType.cosinus, amplitude: 100, cycles: 2);
    final seg2 = PathSystem();
    seg2.generate(400, -100 * hs, 0, w + 100, h, PathType.linear);
    ep.addPath(seg2);
    final seg3 = PathSystem();
    seg3.generate(200, w + 100, h, w * 0.58, h * 0.48, PathType.linear);
    ep.addPath(seg3);
    final seg4 = PathSystem();
    seg4.generate(2000, w * 0.58, h * 0.48, w * 0.58, h * 0.19, PathType.linear);
    ep.addPath(seg4);
    ep.onExit = PathAction.stay;
    bossFleet.setExtraPath(ep);
    bossFleet.addWeapon(30, 120);
    s.fleets.add(bossFleet);

    s.fleets.add(Fleet.create(
      id: 8, enterTime: 104, caption: '',
      hostType: HostType.falcon6, count: 16, bonus: CollType.shieldUpgrade,
      triggerSteps: 50, durationSec: 16 * hs,
      srcX: w - 100, srcY: -45 * hs, dstX: 300, dstY: h + 5,
      pathType: PathType.linear,
    ));

    return s;
  }

  // ---- Sector 2: Planet Perimeter (VB6 Level 3) ----
  // 7 fleets + 20 asteroids, 196 enemies total
  static Sector _sector2(TyrianGame game) {
    final w = config.gameWidth;
    final h = config.gameHeight;
    final hs = config.gameHeight / config.scrHeight;
    final s = Sector(caption: 'Planet Perimeter', level: 3, sectorBonus: 10000);

    final s2f0 = Fleet.create(
      id: 0, enterTime: 2, caption: '',
      hostType: HostType.falcon3, count: 50, bonus: CollType.generatorUpgrade,
      triggerSteps: 12, durationSec: 22 * hs,
      srcX: w + 100, srcY: -200 * hs, dstX: -100, dstY: h + 200,
      pathType: PathType.sinCos, amplitude: 180 * hs, cycles: 10,
    );
    s2f0.addWeapon(33, 450);
    s.fleets.add(s2f0);
    final s2f1 = Fleet.create(
      id: 1, enterTime: 18, caption: '',
      hostType: HostType.falcon3, count: 50, bonus: CollType.shieldUpgrade,
      triggerSteps: 12, durationSec: 22 * hs,
      srcX: -100, srcY: -200 * hs, dstX: w + 100, dstY: h + 200,
      pathType: PathType.sinCos, amplitude: 180 * hs, cycles: 10,
    );
    s2f1.addWeapon(33, 450);
    s.fleets.add(s2f1);
    final s2f2 = Fleet.create(
      id: 2, enterTime: 45, caption: '',
      hostType: HostType.falcon3, count: 30, bonus: CollType.rightWepUpgrade,
      triggerSteps: 70, durationSec: 20 * hs,
      srcX: -100, srcY: -45 * hs, dstX: w + 100, dstY: h + 5,
      pathType: PathType.cosinus, amplitude: 75 * hs, cycles: 11,
    );
    s2f2.addWeapon(33, 300);
    s.fleets.add(s2f2);
    final s2f3 = Fleet.create(
      id: 3, enterTime: 55, caption: '',
      hostType: HostType.falconx, count: 8, bonus: CollType.none,
      triggerSteps: 12, durationSec: 85 * hs,
      srcX: w / 2 - 10, srcY: -200 * hs, dstX: w / 2 - 10, dstY: h + 200,
      pathType: PathType.sinCos, amplitude: 300 * hs, cycles: 8,
    );
    s2f3.addWeapon(40, 350);
    s.fleets.add(s2f3);
    final s2f4 = Fleet.create(
      id: 4, enterTime: 70, caption: '',
      hostType: HostType.falcon4, count: 30, bonus: CollType.leftWepUpgrade,
      triggerSteps: 70, durationSec: 20 * hs,
      srcX: w + 100, srcY: -45 * hs, dstX: -100, dstY: h + 5,
      pathType: PathType.cosinus, amplitude: 75 * hs, cycles: 13,
    );
    s2f4.addWeapon(33, 250);
    s.fleets.add(s2f4);
    final s2f5 = Fleet.create(
      id: 5, enterTime: 75, caption: '',
      hostType: HostType.falconx, count: 8, bonus: CollType.none,
      triggerSteps: 12, durationSec: 85 * hs,
      srcX: w * 0.59, srcY: -200 * hs, dstX: w / 2 - 10, dstY: h + 200,
      pathType: PathType.sinCos, amplitude: 300 * hs, cycles: 8,
    );
    s2f5.addWeapon(40, 350);
    s.fleets.add(s2f5);
    final s2f6 = Fleet.create(
      id: 6, enterTime: 120, caption: '',
      hostType: HostType.falconx, count: 20, bonus: CollType.generatorUpgrade,
      triggerSteps: 12, durationSec: 75 * hs,
      srcX: w, srcY: -200 * hs, dstX: 0, dstY: h + 200,
      pathType: PathType.sinCos, amplitude: 300 * hs, cycles: 8,
    );
    s2f6.addWeapon(40, 350);
    s.fleets.add(s2f6);
    _addAsteroids(s, 125, 20, 50, w - 50);

    return s;
  }

  // ---- Sector 3: Planet Patrol (VB6 Level 4) ----
  // 18 fleets, 150x swarm + 17 bosses, shared extra path
  static Sector _sector3(TyrianGame game) {
    final w = config.gameWidth;
    final h = config.gameHeight;
    final hs = config.gameHeight / config.scrHeight;
    final s = Sector(caption: 'Planet Patrol', level: 4, sectorBonus: 15000);

    // Boss 1: falconx2 with 4-segment extra path
    final boss1 = Fleet.create(
      id: 0, enterTime: 2, caption: '',
      hostType: HostType.falconx2, count: 1, bonus: CollType.none,
      triggerSteps: 12, durationSec: 19 * hs,
      srcX: w, srcY: 0, dstX: 0, dstY: h,
      pathType: PathType.linear,
    );
    final ep = PathSystem();
    ep.generate(350, 0, h, 0, -100 * hs, PathType.cosinus, amplitude: 500 * hs, cycles: 2);
    final seg2 = PathSystem();
    seg2.generate(500, -100 * hs, 0, w + 50, h + 50 * hs, PathType.linear);
    ep.addPath(seg2);
    final seg3 = PathSystem();
    seg3.generate(350, w - 100, h, w / 2 - 20, 500 * hs, PathType.linear);
    ep.addPath(seg3);
    final seg4 = PathSystem();
    seg4.generate(2400, w / 2 - 20, 500 * hs, w / 2 - 20, 20 * hs, PathType.linear);
    ep.addPath(seg4);
    ep.onExit = PathAction.stay;
    boss1.setExtraPath(ep);
    s.fleets.add(boss1);

    // Clone the extra path for all subsequent bosses
    final sharedEp = ep.clone();

    // Swarm: 150x falcon5
    final swarm = Fleet.create(
      id: 1, enterTime: 4, caption: '',
      hostType: HostType.falcon5, count: 150, bonus: CollType.healthUpgrade,
      triggerSteps: 10, durationSec: 70 * hs,
      srcX: -180, srcY: -180 * hs, dstX: w + 180, dstY: h + 180,
      pathType: PathType.sinCos, amplitude: 160 * hs, cycles: 10,
    );
    swarm.addWeapon(35, 500);
    s.fleets.add(swarm);

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
        triggerSteps: 12, durationSec: 12 * hs,
        srcX: w, srcY: 0, dstX: 0, dstY: h,
        pathType: PathType.linear,
      );
      f.setExtraPath(sharedEp.clone());
      f.addWeapon(40, 350);
      s.fleets.add(f);
    }

    // falconx2 boss at t=17
    final f17 = Fleet.create(
      id: 6, enterTime: 17, caption: '',
      hostType: HostType.falconx2, count: 1, bonus: CollType.none,
      triggerSteps: 12, durationSec: 12 * hs,
      srcX: w, srcY: 0, dstX: 0, dstY: h,
      pathType: PathType.linear,
    );
    f17.setExtraPath(sharedEp.clone());
    f17.addWeapon(40, 350);
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
        triggerSteps: 12, durationSec: 14 * hs, bonusMoney: entry[3] as int,
        srcX: w, srcY: 0, dstX: 0, dstY: h,
        pathType: PathType.linear,
      );
      f.setExtraPath(sharedEp.clone());
      f.addWeapon(40, 300);
      s.fleets.add(f);
    }

    // falconx3 bosses at t=31,32,33,34 with bonus money
    // VB6: recharge 275,275,250,250
    final x3Recharges = [275, 275, 250, 250];
    for (int idx = 0; idx < 4; idx++) {
      final entry = [
        [14, 31.0, CollType.shieldUpgrade, 3000],
        [15, 32.0, CollType.bonusCredit, 3000],
        [16, 33.0, CollType.shieldUpgrade, 3000],
        [17, 34.0, CollType.bonusCredit, 3000],
      ][idx];
      final f = Fleet.create(
        id: entry[0] as int, enterTime: entry[1] as double, caption: '',
        hostType: HostType.falconx3, count: 1, bonus: entry[2] as CollType,
        triggerSteps: 12, durationSec: 16 * hs, bonusMoney: entry[3] as int,
        srcX: w, srcY: 0, dstX: 0, dstY: h,
        pathType: PathType.linear,
      );
      f.setExtraPath(sharedEp.clone());
      f.addWeapon(40, x3Recharges[idx]);
      s.fleets.add(f);
    }

    return s;
  }

  // ---- Sector 4: Planet Orbit (VB6 Level 5) ----
  // 13 fleets + 7 asteroids, 6 FreezeFleet + 7 ReplacePath
  static Sector _sector4(TyrianGame game) {
    final w = config.gameWidth;
    final hs = config.gameHeight / config.scrHeight;
    final s = Sector(caption: 'Planet Orbit', level: 5, sectorBonus: 20000);

    // 6 FreezeFleet fleets: fly to formation rows scaled to screen height
    // VB6: dmg 15,14,13,12,11,10 recharge 300 all
    final freezeData = [
      [0, 2.0, HostType.falcon6, CollType.generatorUpgrade, 0, -50.0, 100.0 * hs, w - 58, 100.0 * hs, 15],
      [1, 3.0, HostType.falcon5, CollType.bonusCredit, 20000, w + 5, 200.0 * hs, 2.0, 200.0 * hs, 14],
      [2, 4.0, HostType.falcon4, CollType.bonusCredit, 18000, -50.0, 300.0 * hs, w - 58, 300.0 * hs, 13],
      [3, 5.0, HostType.falcon3, CollType.bonusCredit, 16000, w + 5, 400.0 * hs, 2.0, 400.0 * hs, 12],
      [4, 6.0, HostType.falcon2, CollType.bonusCredit, 14000, -50.0, 500.0 * hs, w - 58, 500.0 * hs, 11],
      [5, 7.0, HostType.falcon1, CollType.bonusCredit, 12000, w + 5, 600.0 * hs, 2.0, 600.0 * hs, 10],
    ];
    for (final fd in freezeData) {
      final ff = Fleet.create(
        id: fd[0] as int, enterTime: fd[1] as double, caption: '',
        hostType: fd[2] as HostType, count: 19, bonus: fd[3] as CollType,
        triggerSteps: 25, durationSec: 12 * hs, bonusMoney: fd[4] as int,
        srcX: (fd[5] as double), srcY: (fd[6] as double),
        dstX: (fd[7] as double), dstY: (fd[8] as double),
        pathType: PathType.linear,
        defaultPathAction: PathAction.freezeFleet,
      );
      ff.addWeapon(fd[9] as int, 300);
      s.fleets.add(ff);
    }

    // ReplacePath fleets: fly to position then oscillate
    final rpFleet0 = Fleet.create(
      id: 6, enterTime: 15, caption: '',
      hostType: HostType.falconx3, count: 14, bonus: CollType.frontWepUpgrade,
      triggerSteps: 35, durationSec: 12 * hs,
      srcX: -50, srcY: 10 * hs, dstX: w - 90, dstY: 10 * hs,
      pathType: PathType.linear,
      defaultPathAction: PathAction.replacePath,
    );
    _setAltParams(rpFleet0, 50, 40, 0, PathType.cosinus);
    rpFleet0.addWeapon(50, 225);
    s.fleets.add(rpFleet0);

    // VB6: dmg 20,19,18,17,16,15 recharge 275 all
    final rpData = [
      [7, 45.0, HostType.falcon6, CollType.healthUpgrade, 1, -50.0, 100.0 * hs, w - 66, 100.0 * hs, 30, 20, 20],
      [8, 46.0, HostType.falcon5, CollType.shieldUpgrade, 20000, w + 5, 200.0 * hs, 2.0, 200.0 * hs, 30, 20, 19],
      [9, 47.0, HostType.falcon4, CollType.bonusCredit, 18000, -50.0, 300.0 * hs, w - 58, 300.0 * hs, 30, 20, 18],
      [10, 48.0, HostType.falcon3, CollType.bonusCredit, 16000, w + 5, 400.0 * hs, 2.0, 400.0 * hs, 30, 20, 17],
      [11, 49.0, HostType.falcon2, CollType.bonusCredit, 14000, -50.0, 500.0 * hs, w - 58, 500.0 * hs, 30, 20, 16],
      [12, 50.0, HostType.falcon1, CollType.bonusCredit, 12000, w + 5, 600.0 * hs, 2.0, 600.0 * hs, 30, 20, 15],
    ];
    for (final entry in rpData) {
      final f = Fleet.create(
        id: entry[0] as int, enterTime: entry[1] as double, caption: '',
        hostType: entry[2] as HostType, count: 19, bonus: entry[3] as CollType,
        triggerSteps: 25, durationSec: 12 * hs,
        bonusMoney: entry[4] as int,
        srcX: (entry[5] as double), srcY: (entry[6] as double),
        dstX: (entry[7] as double), dstY: (entry[8] as double),
        pathType: PathType.linear,
        defaultPathAction: PathAction.replacePath,
      );
      _setAltParams(f, entry[9] as int, entry[10] as int, 0, PathType.cosinus);
      f.addWeapon(entry[11] as int, 275);
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
    final hs = config.gameHeight / config.scrHeight;
    final s = Sector(caption: 'Industry Zone', level: 6, sectorBonus: 25000);

    // Growing spiral: 28x falconx3
    final spiral = Fleet.create(
      id: 0, enterTime: 3, caption: '',
      hostType: HostType.falconx3, count: 28, bonus: CollType.frontWepUpgrade,
      triggerSteps: 100, durationSec: 35 * hs, bonusMoney: 10000,
      srcX: w / 2, srcY: -55 * hs, dstX: w / 2, dstY: h + 5,
      pathType: PathType.cosinus, amplitude: 12, cycles: 10, amplMultiplier: 1.0025,
    );
    spiral.addWeapon(45, 250);
    s.fleets.add(spiral);

    // Parallel linear fleets — VB6: all addWeapon(10, 275)
    final parallelFleets = [
      Fleet.create(id: 1, enterTime: 15, caption: '',
        hostType: HostType.falcon1, count: 16, bonus: CollType.generatorUpgrade,
        triggerSteps: 22, durationSec: 12 * hs,
        srcX: 200, srcY: -45 * hs, dstX: w - 200, dstY: h + 5, pathType: PathType.linear),
      Fleet.create(id: 2, enterTime: 15, caption: '',
        hostType: HostType.falcon1, count: 16, bonus: CollType.bonusCredit,
        triggerSteps: 22, durationSec: 12 * hs,
        srcX: w - 200, srcY: -45 * hs, dstX: 200, dstY: h + 5, pathType: PathType.linear),
      Fleet.create(id: 3, enterTime: 30, caption: '',
        hostType: HostType.falcon2, count: 18, bonus: CollType.shieldUpgrade,
        triggerSteps: 22, durationSec: 12 * hs,
        srcX: 200, srcY: -45 * hs, dstX: w - 200, dstY: h + 5, pathType: PathType.linear),
      Fleet.create(id: 4, enterTime: 30, caption: '',
        hostType: HostType.falcon2, count: 18, bonus: CollType.healthUpgrade,
        triggerSteps: 22, durationSec: 12 * hs,
        srcX: w - 200, srcY: -45 * hs, dstX: 200, dstY: h + 5, pathType: PathType.linear),
      Fleet.create(id: 5, enterTime: 45, caption: '',
        hostType: HostType.falcon3, count: 20, bonus: CollType.bonusCredit,
        triggerSteps: 22, durationSec: 12 * hs, bonusMoney: 3000,
        srcX: 200, srcY: -45 * hs, dstX: w - 200, dstY: h + 5, pathType: PathType.linear),
      Fleet.create(id: 6, enterTime: 45, caption: '',
        hostType: HostType.falcon3, count: 20, bonus: CollType.bonusCredit,
        triggerSteps: 22, durationSec: 12 * hs, bonusMoney: 5000,
        srcX: w - 200, srcY: -45 * hs, dstX: 200, dstY: h + 5, pathType: PathType.linear),
    ];
    for (final pf in parallelFleets) {
      pf.addWeapon(10, 275);
      s.fleets.add(pf);
    }

    return s;
  }

  // ---- Sector 6+: Random (VB6 Level 7+) ----
  static Sector _sector6(TyrianGame game) {
    return _createRandom(6, game);
  }

  // ---- Random Sector Generation (VB6 Sector.SetupRandom) ----
  static Sector _createRandom(int index, TyrianGame game) {
    final rng = Random(index * 42);
    final level = index + 1;

    // VB6: fleetCount = Round(Rnd * 15 + 5) → 5-20 fleets
    final numFleets = (rng.nextDouble() * 15 + 5).round();

    final s = Sector(
      caption: 'Sector ${index + 1} — Unknown Space',
      level: level,
      // VB6: sectorBonus = CLng(fleetCount) * CLng(2500) * level
      sectorBonus: numFleets * 2500 * level,
    );

    // Track max DPS (VB6 rocket.lastMaxDps)
    final dps = game.vessel.totalDps;
    if (dps > game.vessel.lastMaxDps) {
      game.vessel.lastMaxDps = dps;
    }
    final lastMaxDps = game.vessel.lastMaxDps;

    // VB6 damage growth coefficient (Sector.cls:493-519)
    double dcf = 1.0;
    const dmgGrowLevel = 20;
    if (level >= dmgGrowLevel) {
      double dmgGrow = 0.25;
      if (level >= 35) {
        dmgGrow = 0.60;
      } else if (level >= 30) {
        dmgGrow = 0.45;
      } else if (level >= 25) {
        dmgGrow = 0.35;
      }
      dcf = 1 + ((level - dmgGrowLevel + 1) * dmgGrow);
    }

    // VB6 maxHostLevel: scales with player DPS (Sector.cls:528-531)
    var maxHostLevel = (6 * (lastMaxDps / 500)).round();
    if (maxHostLevel > level + 2) maxHostLevel = level + 1;
    if (maxHostLevel > 10) maxHostLevel = 10;
    if (level >= 17 && dps > 10000) maxHostLevel = 11;
    maxHostLevel = maxHostLevel.clamp(0, HostType.values.length - 1);

    final hostTypes = HostType.values;
    double etime = 2.0;
    double simultan = 1.0;
    double prevDur = 0;

    for (int i = 0; i < numFleets; i++) {
      final typeIndex = rng.nextInt(maxHostLevel + 1).clamp(0, hostTypes.length - 1);
      final ht = hostTypes[typeIndex];
      final enemyHp = Hostile.getHpMax(ht).toDouble();

      // VB6 host count scaling (Sector.cls:536-551)
      var cnt = (rng.nextInt(4) + 1) * 5; // 5-25
      if (lastMaxDps > 0) {
        final hpRatio = enemyHp / lastMaxDps;
        if (hpRatio > 3) {
          if (cnt > 5) cnt = 5;
        } else if (hpRatio > 2) {
          if (cnt > 10) cnt = 10;
        } else if (hpRatio < 0.09) {
          cnt = cnt * 2;
        }
      }

      // VB6 duration scaling (Sector.cls:573-589)
      final pathTypes = PathType.values;
      final pt = pathTypes[rng.nextInt(pathTypes.length)];
      final amp = 60.0 + rng.nextDouble() * 200.0;
      final cyc = 1 + rng.nextInt(5);
      var durCoef = 1.6;
      if (pt.index > 1 && amp >= 100) durCoef += amp / 66;
      if (durCoef > 4.7) durCoef = 4.7;
      var dur = lastMaxDps > 0
          ? (enemyHp / lastMaxDps) * cnt * durCoef
          : 5.0 + rng.nextDouble() * 8.0;
      if (dur < 3.0) dur = 3.0;
      if (dur > 120.0) dur = 120.0;

      // VB6 simultaneous fleet logic: chance of sharing previous enter time
      double enter;
      if (i > 0 && rng.nextDouble() > 0.55 / simultan) {
        enter = etime; // simultaneous with previous fleet
        simultan++;
      } else {
        if (i > 0) {
          etime += prevDur + 2.0 + rng.nextDouble() * 3.0;
        }
        enter = etime;
        simultan = 1.0;
      }
      prevDur = dur;

      // VB6: 35% chance of horizontal attack paths
      double srcX, srcY, dstX, dstY;
      if (rng.nextDouble() < 0.35) {
        final fromLeft = rng.nextBool();
        srcX = fromLeft ? -50.0 : config.gameWidth + 50;
        dstX = fromLeft ? config.gameWidth + 50 : -50.0;
        srcY = config.gameHeight * 0.2 + rng.nextDouble() * config.gameHeight * 0.5;
        dstY = config.gameHeight * 0.2 + rng.nextDouble() * config.gameHeight * 0.5;
      } else {
        srcX = rng.nextDouble() * config.gameWidth;
        srcY = -40.0 - rng.nextDouble() * 60;
        dstX = rng.nextDouble() * config.gameWidth;
        dstY = config.gameHeight + 40.0 + rng.nextDouble() * 60;
      }

      final bonusTypes = CollType.values;
      final bon = bonusTypes[rng.nextInt(bonusTypes.length)];

      final fleet = Fleet.create(
        id: i,
        enterTime: enter,
        caption: '${cnt}x ${Hostile.hostCaption(ht)}',
        hostType: ht,
        count: cnt,
        triggerSteps: 15 + rng.nextInt(30),
        durationSec: dur,
        srcX: srcX,
        srcY: srcY,
        dstX: dstX,
        dstY: dstY,
        pathType: pt,
        amplitude: amp,
        cycles: cyc,
        bonus: bon,
        bonusMoney: 100 + rng.nextInt(500),
        showDamage: true,
      );
      final weapDmg = (typeIndex * 5.555 * dcf).round().clamp(5, 9999);
      final maxFL = (dps / 20).round().clamp(0, 385);
      final weapRecharge = ((400 - maxFL) * 2 + 2).clamp(4, 802);
      fleet.addWeapon(weapDmg, weapRecharge);
      s.fleets.add(fleet);
    }

    // VB6 asteroids: count = Rnd * (fleetCount/2), timed across the sector
    final asteroidCount = (rng.nextDouble() * numFleets / 2).round();
    if (asteroidCount > 0) {
      _addAsteroids(s, 0, asteroidCount, 50, config.gameWidth - 100);
      // Redistribute enter times evenly across sector duration
      final totalTime = etime + prevDur;
      for (int i = 0; i < s.structures.length; i++) {
        final slice = totalTime / s.structures.length;
        s.structures[i].enterTime = slice * i + rng.nextDouble() * slice;
      }
    }

    return s;
  }
}
