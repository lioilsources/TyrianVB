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

    // Check for sector completion
    if (!complete && fleets.every((f) => !f.active || f.kills >= f.count)) {
      if (fleets.isNotEmpty && fleets.every((f) => f.started)) {
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

  // ---- Sector 0: Tutorial / Easy ----
  static Sector _sector0(TyrianGame game) {
    final s = Sector(caption: 'Sector 1 — First Contact', level: 1, sectorBonus: 200);

    s.fleets.add(Fleet.create(
      id: 0,
      enterTime: 2.0,
      caption: '3x Falcon I',
      hostType: HostType.falcon1,
      count: 3,
      triggerSteps: 40,
      durationSec: 5.0,
      srcX: config.gameWidth / 2,
      srcY: -40,
      dstX: config.gameWidth / 2,
      dstY: config.gameHeight + 40,
      pathType: PathType.linear,
      bonus: CollType.bonusCredit,
      bonusMoney: 100,
    ));

    s.fleets.add(Fleet.create(
      id: 1,
      enterTime: 8.0,
      caption: '5x Falcon I',
      hostType: HostType.falcon1,
      count: 5,
      triggerSteps: 30,
      durationSec: 6.0,
      srcX: 100,
      srcY: -40,
      dstX: config.gameWidth - 100,
      dstY: config.gameHeight + 40,
      pathType: PathType.cosinus,
      amplitude: 80,
      cycles: 2,
      bonus: CollType.frontWepUpgrade,
    ));

    s.fleets.add(Fleet.create(
      id: 2,
      enterTime: 16.0,
      caption: '4x Falcon II',
      hostType: HostType.falcon2,
      count: 4,
      triggerSteps: 25,
      durationSec: 7.0,
      srcX: config.gameWidth - 50,
      srcY: -40,
      dstX: 50,
      dstY: config.gameHeight + 40,
      pathType: PathType.sinus,
      amplitude: 60,
      cycles: 3,
      bonus: CollType.healthUpgrade,
    ));

    return s;
  }

  // ---- Sector 1: Building Up ----
  static Sector _sector1(TyrianGame game) {
    final s = Sector(caption: 'Sector 2 — Escalation', level: 2, sectorBonus: 400);

    s.fleets.add(Fleet.create(
      id: 0,
      enterTime: 1.0,
      caption: '4x Falcon II',
      hostType: HostType.falcon2,
      count: 4,
      triggerSteps: 25,
      durationSec: 6.0,
      srcX: 200,
      srcY: -40,
      dstX: config.gameWidth - 50,
      dstY: config.gameHeight + 40,
      pathType: PathType.sinCos,
      amplitude: 100,
      cycles: 3,
      bonus: CollType.bonusCredit,
      bonusMoney: 200,
    ));

    s.fleets.add(Fleet.create(
      id: 1,
      enterTime: 6.0,
      caption: '6x Falcon III',
      hostType: HostType.falcon3,
      count: 6,
      triggerSteps: 20,
      durationSec: 8.0,
      srcX: config.gameWidth,
      srcY: -40,
      dstX: 0,
      dstY: config.gameHeight + 40,
      pathType: PathType.cosinus,
      amplitude: 120,
      cycles: 4,
      bonus: CollType.leftWepUpgrade,
    ));

    s.fleets.add(Fleet.create(
      id: 2,
      enterTime: 14.0,
      caption: '3x Falcon IV',
      hostType: HostType.falcon4,
      count: 3,
      triggerSteps: 30,
      durationSec: 7.0,
      srcX: config.gameWidth / 2,
      srcY: -40,
      dstX: config.gameWidth / 2,
      dstY: config.gameHeight + 40,
      pathType: PathType.linear,
      bonus: CollType.shieldUpgrade,
      showDamage: true,
    ));

    return s;
  }

  // ---- Sector 2: Asteroids ----
  static Sector _sector2(TyrianGame game) {
    final s = Sector(caption: 'Sector 3 — Asteroid Field', level: 3, sectorBonus: 500);

    // Asteroid structures
    final rng = Random();
    for (int i = 0; i < 8; i++) {
      final ast = Structure(
        caption: 'Asteroid',
        behavior: StructBehavior.fall,
        structType: StructType.asteroid,
        hp: 999999,
        hpMax: 999999,
        imgName: 'asteroid${rng.nextInt(4) == 0 ? '' : (rng.nextInt(3) + 1).toString()}',
        position: Vector2(
          rng.nextDouble() * config.gameWidth,
          -(rng.nextDouble() * 400 + 100),
        ),
      );
      s.structures.add(ast);
    }

    s.fleets.add(Fleet.create(
      id: 0,
      enterTime: 3.0,
      caption: '5x Falcon III',
      hostType: HostType.falcon3,
      count: 5,
      triggerSteps: 20,
      durationSec: 7.0,
      srcX: 400,
      srcY: -40,
      dstX: 400,
      dstY: config.gameHeight + 40,
      pathType: PathType.sinCos,
      amplitude: 150,
      cycles: 2,
      bonus: CollType.frontWepUpgrade,
    ));

    s.fleets.add(Fleet.create(
      id: 1,
      enterTime: 10.0,
      caption: '4x Falcon V',
      hostType: HostType.falcon5,
      count: 4,
      triggerSteps: 25,
      durationSec: 8.0,
      srcX: 100,
      srcY: -40,
      dstX: config.gameWidth - 50,
      dstY: config.gameHeight + 40,
      pathType: PathType.cosinus,
      amplitude: 100,
      cycles: 3,
      bonus: CollType.generatorUpgrade,
    ));

    return s;
  }

  // ---- Sector 3: Heavy Assault ----
  static Sector _sector3(TyrianGame game) {
    final s = Sector(caption: 'Sector 4 — Heavy Assault', level: 4, sectorBonus: 700);

    s.fleets.add(Fleet.create(
      id: 0,
      enterTime: 1.0,
      caption: '8x Falcon IV',
      hostType: HostType.falcon4,
      count: 8,
      triggerSteps: 15,
      durationSec: 6.0,
      srcX: 0,
      srcY: -40,
      dstX: config.gameWidth,
      dstY: config.gameHeight + 40,
      pathType: PathType.sinus,
      amplitude: 80,
      cycles: 5,
      bonus: CollType.bonusCredit,
      bonusMoney: 400,
    ));

    s.fleets.add(Fleet.create(
      id: 1,
      enterTime: 8.0,
      caption: '6x Falcon V',
      hostType: HostType.falcon5,
      count: 6,
      triggerSteps: 20,
      durationSec: 8.0,
      srcX: config.gameWidth,
      srcY: -40,
      dstX: 0,
      dstY: config.gameHeight + 40,
      pathType: PathType.sinCos,
      amplitude: 120,
      cycles: 3,
      bonus: CollType.rightWepUpgrade,
    ));

    s.fleets.add(Fleet.create(
      id: 2,
      enterTime: 16.0,
      caption: '4x Falcon VI',
      hostType: HostType.falcon6,
      count: 4,
      triggerSteps: 25,
      durationSec: 7.0,
      srcX: config.gameWidth / 2,
      srcY: -40,
      dstX: config.gameWidth / 2,
      dstY: config.gameHeight + 40,
      pathType: PathType.cosinus,
      amplitude: 150,
      cycles: 4,
      bonus: CollType.healthUpgrade,
    ));

    return s;
  }

  // ---- Sector 4: Elite Force ----
  static Sector _sector4(TyrianGame game) {
    final s = Sector(caption: 'Sector 5 — Elite Force', level: 5, sectorBonus: 1000);

    s.fleets.add(Fleet.create(
      id: 0,
      enterTime: 2.0,
      caption: '2x Falcon X',
      hostType: HostType.falconx,
      count: 2,
      triggerSteps: 60,
      durationSec: 10.0,
      srcX: 200,
      srcY: -60,
      dstX: config.gameWidth - 50,
      dstY: config.gameHeight + 60,
      pathType: PathType.sinCos,
      amplitude: 150,
      cycles: 2,
      bonus: CollType.frontWepUpgrade,
      showDamage: true,
    ));

    s.fleets.add(Fleet.create(
      id: 1,
      enterTime: 10.0,
      caption: '6x Falcon VI',
      hostType: HostType.falcon6,
      count: 6,
      triggerSteps: 18,
      durationSec: 7.0,
      srcX: config.gameWidth - 100,
      srcY: -40,
      dstX: 100,
      dstY: config.gameHeight + 40,
      pathType: PathType.cosinus,
      amplitude: 100,
      cycles: 4,
      bonus: CollType.shieldUpgrade,
    ));

    s.fleets.add(Fleet.create(
      id: 2,
      enterTime: 18.0,
      caption: '1x Falcon X-II',
      hostType: HostType.falconx2,
      count: 1,
      triggerSteps: 1,
      durationSec: 12.0,
      srcX: config.gameWidth / 2,
      srcY: -80,
      dstX: config.gameWidth / 2,
      dstY: config.gameHeight + 80,
      pathType: PathType.sinCos,
      amplitude: 200,
      cycles: 3,
      bonus: CollType.bonusCredit,
      bonusMoney: 800,
      showDamage: true,
    ));

    return s;
  }

  // ---- Sector 5: Gauntlet ----
  static Sector _sector5(TyrianGame game) {
    final s = Sector(caption: 'Sector 6 — Gauntlet', level: 6, sectorBonus: 1500);

    s.fleets.add(Fleet.create(
      id: 0,
      enterTime: 1.0,
      caption: '10x Falcon V',
      hostType: HostType.falcon5,
      count: 10,
      triggerSteps: 12,
      durationSec: 5.0,
      srcX: 0,
      srcY: -40,
      dstX: config.gameWidth,
      dstY: config.gameHeight + 40,
      pathType: PathType.sinus,
      amplitude: 60,
      cycles: 6,
      bonus: CollType.healthUpgrade,
    ));

    s.fleets.add(Fleet.create(
      id: 1,
      enterTime: 5.0,
      caption: '10x Falcon V',
      hostType: HostType.falcon5,
      count: 10,
      triggerSteps: 12,
      durationSec: 5.0,
      srcX: config.gameWidth,
      srcY: -40,
      dstX: 0,
      dstY: config.gameHeight + 40,
      pathType: PathType.sinus,
      amplitude: 60,
      cycles: 6,
      bonus: CollType.generatorUpgrade,
    ));

    s.fleets.add(Fleet.create(
      id: 2,
      enterTime: 12.0,
      caption: '2x Falcon X-III',
      hostType: HostType.falconx3,
      count: 2,
      triggerSteps: 80,
      durationSec: 12.0,
      srcX: config.gameWidth / 4,
      srcY: -80,
      dstX: config.gameWidth * 3 / 4,
      dstY: config.gameHeight + 80,
      pathType: PathType.sinCos,
      amplitude: 200,
      cycles: 2,
      bonus: CollType.frontWepUpgrade,
      showDamage: true,
    ));

    return s;
  }

  // ---- Sector 6: Boss ----
  static Sector _sector6(TyrianGame game) {
    final s = Sector(caption: 'Sector 7 — Final Stand', level: 7, sectorBonus: 3000);

    // Escort waves
    s.fleets.add(Fleet.create(
      id: 0,
      enterTime: 1.0,
      caption: '8x Falcon VI',
      hostType: HostType.falcon6,
      count: 8,
      triggerSteps: 15,
      durationSec: 6.0,
      srcX: 100,
      srcY: -40,
      dstX: config.gameWidth - 50,
      dstY: config.gameHeight + 40,
      pathType: PathType.sinCos,
      amplitude: 100,
      cycles: 4,
      bonus: CollType.healthUpgrade,
    ));

    // Boss: Falcon XB
    s.fleets.add(Fleet.create(
      id: 1,
      enterTime: 8.0,
      caption: '1x Falcon XB',
      hostType: HostType.falconxb,
      count: 1,
      triggerSteps: 1,
      durationSec: 15.0,
      srcX: config.gameWidth / 2,
      srcY: -100,
      dstX: config.gameWidth / 2,
      dstY: config.gameHeight + 100,
      pathType: PathType.sinCos,
      amplitude: 250,
      cycles: 2,
      bonus: CollType.bonusCredit,
      bonusMoney: 5000,
      showDamage: true,
    ));

    // More escorts during boss
    s.fleets.add(Fleet.create(
      id: 2,
      enterTime: 12.0,
      caption: '6x Falcon V',
      hostType: HostType.falcon5,
      count: 6,
      triggerSteps: 20,
      durationSec: 6.0,
      srcX: config.gameWidth,
      srcY: -40,
      dstX: 0,
      dstY: config.gameHeight + 40,
      pathType: PathType.cosinus,
      amplitude: 80,
      cycles: 3,
    ));

    return s;
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
