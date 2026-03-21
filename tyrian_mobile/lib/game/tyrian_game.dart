import 'dart:math' show pi;
import 'dart:typed_data';
import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game_config.dart' as config;
import 'platform_config.dart' as platform;
import '../input/keyboard_input.dart';
import '../input/gamepad_input.dart';
import '../rendering/starfield.dart';
import '../rendering/parallax_bg.dart';
import '../entities/vessel.dart';
import '../entities/explosion.dart';
import '../entities/collectable.dart';
import '../entities/structure.dart';
import '../entities/hostile.dart';
import '../systems/sector.dart';
import '../systems/fleet.dart';
import '../systems/dev_type.dart';
import '../entities/projectile.dart';
import '../services/asset_library.dart';
import '../services/sound_service.dart';
import '../rendering/beam_renderer.dart';
import '../rendering/shader_pipeline.dart';
import '../services/skin_registry.dart';
import '../ui/float_text.dart';
import '../net/protocol.dart';
import '../net/coop_host.dart';
import '../net/coop_client.dart';

enum GameState { comCenter, playing, paused, gameOver }
enum CoopRole { none, host, client }

class TyrianGame extends FlameGame
    with DragCallbacks, TapCallbacks, HasCollisionDetection, KeyboardEvents {
  TyrianGame();

  final KeyboardInput keyboardInput = KeyboardInput();
  final GamepadInput gamepadInput = GamepadInput();
  double _gamepadPollTimer = 0;

  late Starfield starfield;
  late ParallaxBackground parallaxBg;
  late Vessel vessel;
  Vessel? vessel2; // null = solo mode
  late BeamRenderer beamRenderer;
  late ShaderPipeline shaderPipeline;

  bool get isCoop => vessel2 != null;

  // Co-op networking
  CoopRole coopRole = CoopRole.none;
  CoopHost? coopHost;
  CoopClient? coopClient;
  String? hostIp; // Display to user for manual connect
  /// Callback when a client joins (for UI notification)
  VoidCallback? onClientJoined;

  /// All active (visible) vessels for collision iteration
  List<Vessel> get allVessels => [
        vessel,
        if (vessel2 != null) vessel2!,
      ];

  // Client-side entity cache for snapshot rendering
  final Map<int, Hostile> _clientHostiles = {};
  final Map<int, Structure> _clientStructures = {};
  final List<Projectile> _clientPlayerProjectiles = [];

  GameState state = GameState.comCenter;
  bool isLoaded = false;

  // Active game objects
  final List<Fleet> activeFleets = [];
  final List<Structure> activeStructures = [];
  final List<Collectable> activeCollectables = [];
  final List<Explosion> activeExplosions = [];
  final List<Projectile> enemyProjectiles = [];

  Sector? currentSector;
  int currentSectorIndex = 0;
  double elapsed = 0;
  double _osdTimer = 0;

  // Callbacks for Flutter overlay UI
  VoidCallback? onOsdUpdate;
  VoidCallback? onGameOver;
  VoidCallback? onShowComCenter;
  VoidCallback? onSectorComplete;
  VoidCallback? onLoaded;

  @override
  Color backgroundColor() => const Color(0xFF000000);

  @override
  Future<void> onLoad() async {
    if (platform.isLandscape) {
      // Desktop landscape: game height scales with screen WIDTH (fills after -90° rotation)
      config.gameHeight = config.gameWidth * (size.x / size.y);

      camera.viewport = FixedResolutionViewport(
        resolution: Vector2(config.gameHeight, config.gameWidth), // landscape dims
      );
      camera.viewfinder.anchor = Anchor.center;
      camera.viewfinder.position =
          Vector2(config.gameWidth / 2, config.gameHeight / 2);
      camera.viewfinder.angle = -pi / 2; // CCW: game UP → screen RIGHT
    } else {
      // Mobile portrait: width=600, height scaled to device aspect ratio
      config.gameHeight = config.gameWidth * (size.y / size.x);
      if (config.gameHeight < config.gameWidth) {
        config.gameHeight = config.gameWidth;
      }

      camera.viewport = FixedResolutionViewport(
        resolution: Vector2(config.gameWidth, config.gameHeight),
      );
      camera.viewfinder.anchor = Anchor.topLeft;
      camera.viewfinder.position = Vector2.zero();
    }

    await AssetLibrary.instance.loadAll();

    starfield = Starfield();
    world.add(starfield);

    parallaxBg = ParallaxBackground();
    parallaxBg.loadLayers();
    world.add(parallaxBg);

    beamRenderer = BeamRenderer();
    world.add(beamRenderer);

    vessel = Vessel();
    await vessel.init();
    world.add(vessel);

    // Debug: screen/viewport info
    print('[LAYOUT] FlameGame.size: ${size.x} x ${size.y}');
    print('[LAYOUT] gameWidth: ${config.gameWidth}, gameHeight: ${config.gameHeight}');
    print('[LAYOUT] landscape: ${platform.isLandscape}');

    // Shader pipeline
    shaderPipeline = ShaderPipeline();
    final skinId = AssetLibrary.instance.skinId;
    final skinInfo = kSkins.firstWhere((s) => s.id == skinId,
        orElse: () => kSkins.first);
    shaderPipeline.configure(skinInfo.shaderConfig);
    camera.postProcess = shaderPipeline.build();

    // Start in comCenter state
    state = GameState.comCenter;
    vessel.visible = false;
    isLoaded = true;
    onLoaded?.call();
  }

  /// Re-fetch sprites on all persistent entities after a skin change.
  void refreshSprites() {
    vessel.refreshSprite();
    vessel2?.refreshSprite();
    parallaxBg.loadLayers();

    // Reconfigure shaders for new skin
    final skinId = AssetLibrary.instance.skinId;
    final skinInfo = kSkins.firstWhere((s) => s.id == skinId,
        orElse: () => kSkins.first);
    shaderPipeline.configure(skinInfo.shaderConfig);
  }

  void startGame() {
    state = GameState.playing;
    vessel.visible = true;
    vessel.resetPosition();
    if (vessel2 != null) {
      // Re-clone P1 stats onto P2 before each sector
      _cloneVesselStats(vessel, vessel2!);
      vessel2!.visible = true;
      vessel2!.resetPosition();
      // Offset P2 slightly to the right of P1
      vessel2!.position.x += 60;
    }
    // Notify client that game is starting
    if (coopRole == CoopRole.host && coopHost != null && coopHost!.hasClient) {
      coopHost!.sendEvent(EventType.gameStart);
    }
    loadSector(currentSectorIndex);
  }

  void loadSector(int index) {
    // Clean up previous sector
    _clearActiveObjects();
    currentSector?.removeFromParent();

    currentSector = Sector.create(index, this);
    if (currentSector != null) {
      world.add(currentSector!);
    }
    currentSectorIndex = index;
    vessel.lvlNum = index + 1;
    if (vessel2 != null) vessel2!.lvlNum = index + 1;
    elapsed = 0;
  }

  void _clearActiveObjects() {
    for (final f in [...activeFleets]) {
      // Remove hostiles first — they're world children, not fleet children
      for (final h in [...f.hostiles]) {
        h.removeFromParent();
      }
      f.hostiles.clear();
      f.removeFromParent();
    }
    activeFleets.clear();
    for (final s in [...activeStructures]) {
      s.removeFromParent();
    }
    activeStructures.clear();
    for (final c in [...activeCollectables]) {
      c.removeFromParent();
    }
    activeCollectables.clear();
    for (final e in [...activeExplosions]) {
      e.removeFromParent();
    }
    activeExplosions.clear();
    for (final p in [...enemyProjectiles]) {
      p.removeFromParent();
    }
    enemyProjectiles.clear();
    // Clear player projectiles (world children via devices)
    for (final v in allVessels) {
      for (final d in v.devices) {
        for (final p in [...d.projectiles]) {
          p.removeFromParent();
        }
        d.clearProjectiles();
      }
    }
  }

  @override
  void update(double dt) {
    // Client mode: apply snapshots, then call super.update for component mounting/rendering
    if (coopRole == CoopRole.client) {
      final snap = coopClient?.latestSnapshot;
      if (snap != null) {
        try {
          applySnapshot(snap);
        } catch (_) {}
        coopClient!.latestSnapshot = null;
      }
      super.update(dt);
      return;
    }

    // Desktop keyboard + gamepad input (handles pause toggle even when paused)
    _processDesktopInput(dt);

    if (state == GameState.paused || state == GameState.comCenter) {
      starfield.update(dt);
      parallaxBg.update(dt);
      return;
    }

    super.update(dt);
    elapsed += dt;

    // Update beam renderer with vessel data
    beamRenderer.vessel = vessel;
    beamRenderer.vessel2 = vessel2;
    beamRenderer.activeFleets = activeFleets;

    // Periodic OSD refresh (~4Hz)
    _osdTimer += dt;
    if (_osdTimer >= 0.25) {
      _osdTimer = 0;
      onOsdUpdate?.call();
    }

    // Update enemy projectiles — collision with vessel
    _updateEnemyProjectiles();

    // Feed damage flash into shader pipeline (after projectile collision)
    double maxFlash = 0;
    for (final v in allVessels) {
      if (v.dmgTaken > 0) {
        final flash = v.dmgTaken / 4.0; // 4 = max dmgTaken frames
        if (flash > maxFlash) maxFlash = flash;
      }
    }
    shaderPipeline.setDamageFlash(maxFlash);

    // Check sector completion
    if (currentSector != null && currentSector!.isComplete) {
      _onSectorComplete();
    }

    // Host mode: send snapshot to client after each frame
    if (coopRole == CoopRole.host && coopHost != null && coopHost!.hasClient) {
      try {
        coopHost!.sendSnapshot(extractSnapshot());
      } catch (_) {}
    }
  }

  void _onSectorComplete() {
    SoundService.instance.play(SfxEvent.sectorComplete);
    vessel.credit += currentSector!.sectorBonus;
    if (vessel2 != null) vessel2!.credit += currentSector!.sectorBonus;

    // Revive dead vessels for ComCenter
    if (isCoop) {
      if (!vessel.visible || vessel.hp <= 0) {
        vessel.visible = true;
        vessel.hp = 1; // Barely alive — player should heal in shop
      }
      if (vessel2 != null && (!vessel2!.visible || vessel2!.hp <= 0)) {
        vessel2!.visible = true;
        vessel2!.hp = 1;
      }
    }

    if (coopRole == CoopRole.host && coopHost != null) {
      coopHost!.sendEvent(EventType.sectorComplete);
    }

    onSectorComplete?.call();
  }

  void advanceToNextSector() {
    currentSectorIndex++;
    loadSector(currentSectorIndex);
  }

  /// Reset all game state for a fresh new game.
  void resetForNewGame() {
    _clearActiveObjects();
    currentSector?.removeFromParent();
    currentSector = null;
    currentSectorIndex = 0;
    vessel.newGame();
    elapsed = 0;
  }

  void openComCenter() {
    state = GameState.comCenter;
    onShowComCenter?.call();
  }

  void resumeFromComCenter() {
    // Re-clone P1 stats onto P2 before each sector (host upgraded in ComCenter)
    if (vessel2 != null && coopRole == CoopRole.host) {
      _cloneVesselStats(vessel, vessel2!);
      vessel2!.visible = true;
      vessel2!.resetPosition();
      vessel2!.position.x += 60;
    }
    state = GameState.playing;
    // Notify client that game is starting
    if (coopRole == CoopRole.host && coopHost != null && coopHost!.hasClient) {
      coopHost!.sendEvent(EventType.gameStart);
    }
  }

  void togglePause() {
    if (state == GameState.playing) {
      state = GameState.paused;
    } else if (state == GameState.paused) {
      state = GameState.playing;
    }
  }

  void triggerGameOver() {
    SoundService.instance.play(SfxEvent.gameOver);
    state = GameState.gameOver;
    onGameOver?.call();
  }

  /// In co-op: game over only when both vessels are dead
  void checkCoopGameOver() {
    final p1Dead = !vessel.visible || vessel.hp <= 0;
    final p2Dead = vessel2 == null || !vessel2!.visible || vessel2!.hp <= 0;
    if (p1Dead && p2Dead) {
      triggerGameOver();
    }
  }

  /// Returns X position of nearest visible vessel to a point (for structure targeting)
  double nearestVesselX(double x, double y) {
    if (vessel2 == null || !vessel2!.visible) return vessel.position.x;
    if (!vessel.visible) return vessel2!.position.x;
    final d1 = (vessel.position.x - x).abs() + (vessel.position.y - y).abs();
    final d2 = (vessel2!.position.x - x).abs() + (vessel2!.position.y - y).abs();
    return d1 <= d2 ? vessel.position.x : vessel2!.position.x;
  }

  // Touch input — delta-based so finger and vessel move in sync
  Vector2? _prevDragPos;

  // Client touch target position (for sending to host)
  double _clientTargetX = config.gameWidth / 2;
  double _clientTargetY = config.gameHeight * 0.75;
  bool _clientFire = false;

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (state != GameState.playing) return;
    _prevDragPos = event.canvasPosition.clone();

    if (coopRole == CoopRole.client) {
      _clientFire = true;
    } else {
      vessel.fire = true;
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    if (state != GameState.playing || _prevDragPos == null) return;
    final pos = event.canvasEndPosition;
    final delta = pos - _prevDragPos!;
    _prevDragPos = pos.clone();

    final scale = config.gameWidth / size.x;

    if (coopRole == CoopRole.client) {
      // Client: compute target and send to host
      _clientTargetX += delta.x * scale;
      _clientTargetY += delta.y * scale;
      // Clamp to screen
      _clientTargetX = _clientTargetX.clamp(0, config.gameWidth);
      _clientTargetY = _clientTargetY.clamp(0, config.gameHeight);
      coopClient?.sendInput(_clientTargetX, _clientTargetY, _clientFire);
    } else {
      vessel.adjustPosition(
        vessel.position.x + delta.x * scale,
        vessel.position.y + delta.y * scale,
      );
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (state != GameState.playing) return;
    _prevDragPos = null;

    if (coopRole == CoopRole.client) {
      _clientFire = false;
      coopClient?.sendInput(_clientTargetX, _clientTargetY, false);
    } else {
      vessel.fire = false;
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    if (state != GameState.playing) return;

    if (coopRole == CoopRole.client) {
      _clientFire = !_clientFire;
      coopClient?.sendInput(_clientTargetX, _clientTargetY, _clientFire);
    } else {
      vessel.fire = !vessel.fire;
    }
  }

  // ── Keyboard input (desktop) ──────────────────────────────

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    keyboardInput.handleKeyEvent(event);
    return KeyEventResult.handled;
  }

  /// Desktop movement speed (game units per second).
  static const double _kbSpeed = 300.0;

  bool _prevPauseKey = false;
  bool _prevGamepadPause = false;

  /// Apply screen-space input to vessel (handles landscape inverse rotation).
  void _applyMovement(Vessel v, double screenDx, double screenDy, double speed, double dt) {
    if (platform.isLandscape) {
      // Inverse rotation: screen → game space
      // Screen RIGHT = game UP (−Y), Screen DOWN = game RIGHT (+X)
      v.adjustPosition(
        v.position.x + screenDy * speed * dt,
        v.position.y - screenDx * speed * dt,
      );
    } else {
      v.adjustPosition(
        v.position.x + screenDx * speed * dt,
        v.position.y + screenDy * speed * dt,
      );
    }
  }

  /// Process keyboard + gamepad input — called at the start of update().
  void _processDesktopInput(double dt) {
    if (!platform.isDesktop) return;

    // Poll gamepad (~60Hz to avoid MethodChannel overhead)
    _gamepadPollTimer += dt;
    if (_gamepadPollTimer >= 1 / 60) {
      _gamepadPollTimer = 0;
      gamepadInput.poll(); // fire-and-forget async
    }

    // ── Pause toggle (edge-triggered, keyboard + gamepad) ──
    final pauseKb = keyboardInput.pause;
    final pauseGp = gamepadInput.primary.pause;
    if ((pauseKb && !_prevPauseKey) || (pauseGp && !_prevGamepadPause)) {
      if (state == GameState.playing || state == GameState.paused) {
        togglePause();
      }
    }
    _prevPauseKey = pauseKb;
    _prevGamepadPause = pauseGp;

    if (state != GameState.playing) return;

    // ── Gamepad P1 (takes priority over keyboard) ──
    final gp = gamepadInput.primary;
    final gpDx = GamepadInput.deadzone(gp.leftStickX);
    final gpDy = GamepadInput.deadzone(gp.leftStickY);
    final gpActive = gpDx != 0 || gpDy != 0 || gp.fire;

    if (gpActive) {
      _applyMovement(vessel, gpDx, gpDy, _kbSpeed, dt);
      vessel.fire = gp.fire;
    } else {
      // ── Keyboard fallback ──
      final kbDx = keyboardInput.dx;
      final kbDy = keyboardInput.dy;
      if (kbDx != 0 || kbDy != 0) {
        _applyMovement(vessel, kbDx, kbDy, _kbSpeed, dt);
      }
      vessel.fire = keyboardInput.fire;
    }

    // ── Gamepad P2 (local co-op) ──
    if (vessel2 != null && vessel2!.visible && gamepadInput.controllers.length > 1) {
      final gp2 = gamepadInput.secondary;
      final gp2Dx = GamepadInput.deadzone(gp2.leftStickX);
      final gp2Dy = GamepadInput.deadzone(gp2.leftStickY);
      _applyMovement(vessel2!, gp2Dx, gp2Dy, _kbSpeed, dt);
      vessel2!.fire = gp2.fire;
    }
  }

  void showMessage(String msg) {
    world.add(FloatText(
      text: msg,
      color: const Color(0xFF00FFFF),
      fontSize: 18,
      position: Vector2(config.gameWidth / 2, config.gameHeight * 0.3),
    ));
  }

  bool _projectileHitsVessel(Projectile p, Vessel v) {
    return v.visible &&
        p.position.x < v.position.x + v.size.x / 2 &&
        p.position.x + p.size.x > v.position.x - v.size.x / 2 &&
        p.position.y < v.position.y + v.size.y / 2 &&
        p.position.y + p.size.y > v.position.y - v.size.y / 2;
  }

  void _updateEnemyProjectiles() {
    for (int i = enemyProjectiles.length - 1; i >= 0; i--) {
      final p = enemyProjectiles[i];
      if (!p.active) {
        enemyProjectiles.removeAt(i);
        continue;
      }
      // Off-screen check
      if (p.position.y > config.gameHeight + 50 || p.position.y < -50) {
        p.removeFromParent();
        enemyProjectiles.removeAt(i);
        continue;
      }
      // AABB collision with all vessels
      bool hit = false;
      for (final v in allVessels) {
        if (_projectileHitsVessel(p, v)) {
          v.takeDamage(p.damage.toInt());
          hit = true;
          break;
        }
      }
      if (hit) {
        p.removeFromParent();
        enemyProjectiles.removeAt(i);
      }
    }
  }

  /// Spawn an enemy projectile (called from Hostile firing logic)
  void spawnEnemyProjectile(double x, double y, int dmg, double scale) {
    final proj = Projectile(
      imgName: 'bubble',
      position: Vector2(x, y),
      speed: 15.0, // positive = downward
      damage: dmg.toDouble(),
      scale: scale,
    );
    enemyProjectiles.add(proj);
    world.add(proj);
  }

  // Spawn helpers used by Sector/Fleet
  void addExplosion(double x, double y, int size) {
    final exp = Explosion(
      position: Vector2(x, y),
      size: size,
    );
    activeExplosions.add(exp);
    world.add(exp);
  }

  void addCollectable(Collectable c) {
    activeCollectables.add(c);
    world.add(c);
  }

  void removeCollectable(Collectable c) {
    activeCollectables.remove(c);
    c.removeFromParent();
  }

  void removeExplosion(Explosion e) {
    activeExplosions.remove(e);
  }

  // ==== Co-op setup ====

  /// Initialize as auto-host (every solo game). Vessel2 created on client connect.
  void setupAutoHost(CoopHost host) {
    coopRole = CoopRole.host;
    coopHost = host;

    // Wire up callbacks — vessel2 created lazily on connect
    host.onClientInput = (dx, dy, fire) {
      if (vessel2 != null && vessel2!.visible) {
        vessel2!.adjustPosition(dx, dy);
        vessel2!.fire = fire;
      }
    };

    host.onClientConnected = (pilotName) async {
      print('Host: handshake from $pilotName');
      // Create vessel2 on first connect (or re-use if client reconnects)
      if (vessel2 == null) {
        vessel2 = Vessel(playerIndex: 1);
        vessel2!.pilotName = pilotName;
        await vessel2!.init();
        world.add(vessel2!);
      } else {
        vessel2!.pilotName = pilotName;
      }

      // Clone P1 stats onto P2
      _cloneVesselStats(vessel, vessel2!);

      if (state == GameState.playing) {
        // Mid-game join: spawn visible immediately
        vessel2!.visible = true;
        vessel2!.resetPosition();
        vessel2!.position.x += 60;
      } else {
        // In ComCenter: keep invisible until host starts
        vessel2!.visible = false;
      }

      showMessage('Player 2 joined!');
      onClientJoined?.call();
    };

    host.onClientDisconnected = () {
      vessel2?.visible = false;
      showMessage('Player 2 disconnected');
    };
  }

  /// Deep-copy stats and weapons from source vessel to target
  void _cloneVesselStats(Vessel src, Vessel dst) {
    dst.hpMax = src.hpMax;
    dst.hp = src.hp;
    dst.shieldMax = src.shieldMax;
    dst.shield = src.shield;
    dst.shieldRegen = src.shieldRegen;
    dst.genMax = src.genMax;
    dst.genPower = src.genPower;
    dst.genValue = src.genValue;
    dst.credit = src.credit;
    dst.score = src.score;
    dst.nextWeaponLevel = src.nextWeaponLevel;
    dst.lastMaxDps = src.lastMaxDps;
    dst.lvlNum = src.lvlNum;

    // Clone weapons: clear existing, recreate from same DevTypes at same levels
    for (final d in dst.devices) {
      d.clearProjectiles();
    }
    dst.devices.clear();
    dst.guidedWeapon = false;

    for (final srcDev in src.devices) {
      final wt = _findWeaponType(srcDev.name);
      if (wt == null) continue;
      final newDev = dst.equipWeapon(wt, srcDev.slot);
      for (int i = 0; i < srcDev.level; i++) {
        newDev.upgrade();
      }
    }
  }

  /// Initialize co-op as client. Call after onLoad.
  Future<void> setupCoopClient(CoopClient client) async {
    coopRole = CoopRole.client;
    coopClient = client;

    // Set callbacks FIRST (before async gap) to avoid race conditions
    client.onConnected = (hostPilotName) {
      // Connection confirmed by host handshake
    };

    client.onGameEvent = (eventType, x, y, text) {
      switch (eventType) {
        case EventType.explosion:
          addExplosion(x, y, 2);
        case EventType.message:
          showMessage(text);
        case EventType.sectorComplete:
          onSectorComplete?.call();
        case EventType.gameOver:
          triggerGameOver();
        case EventType.paused:
          state = GameState.paused;
          onOsdUpdate?.call();
        case EventType.resumed:
          state = GameState.playing;
          onOsdUpdate?.call();
        case EventType.gameStart:
          state = GameState.playing;
          onRemoteStart?.call();
      }
    };

    client.onDisconnected = () {
      showMessage('Host disconnected');
      onDisconnected?.call();
    };

    // Now do async work — callbacks already wired
    vessel2 = Vessel(playerIndex: 1);
    await vessel2!.init();
    world.add(vessel2!);
    vessel2!.visible = false;
  }

  /// Callback when remote peer disconnects
  VoidCallback? onDisconnected;

  /// Fires on client when host signals game start
  VoidCallback? onRemoteStart;

  // ==== Host: snapshot extraction ====

  /// Extract current game state as a framed snapshot message
  Uint8List extractSnapshot() {
    // Vessel data helper
    List<double> vesselDoubles(Vessel v) => [
          v.position.x, v.position.y,
          v.shield, v.shieldMax,
          v.genValue, v.genMax,
        ];
    List<int> vesselInts(Vessel v) => [
          v.hp, v.hpMax, v.score, v.credit,
          v.fire ? 1 : 0, v.dmgTaken, v.visible ? 1 : 0,
        ];

    // Hostiles
    final hostileSnaps = <HostileSnap>[];
    for (final fleet in activeFleets) {
      for (final h in fleet.hostiles) {
        if (h.isDead) continue;
        hostileSnaps.add(HostileSnap(
          fleetId: fleet.id,
          hostileId: h.id,
          x: h.position.x, y: h.position.y,
          hp: h.hp, hit: h.hit,
          sizeX: h.size.x, sizeY: h.size.y,
          hostType: h.hostType.index,
        ));
      }
    }

    // Enemy projectiles
    final eProjSnaps = <ProjSnap>[];
    for (final p in enemyProjectiles) {
      if (!p.active) continue;
      eProjSnaps.add(ProjSnap(
        x: p.position.x, y: p.position.y,
        sizeX: p.size.x, sizeY: p.size.y,
        speed: p.speed,
      ));
    }

    // Player projectiles (from both vessels)
    final pProjSnaps = <ProjSnap>[];
    for (final v in allVessels) {
      for (final d in v.devices) {
        for (final p in d.projectiles) {
          if (!p.active) continue;
          pProjSnaps.add(ProjSnap(
            x: p.position.x, y: p.position.y,
            sizeX: p.size.x, sizeY: p.size.y,
            speed: p.speed,
          ));
        }
      }
    }

    // Collectables
    final collSnaps = <CollSnap>[];
    for (final c in activeCollectables) {
      collSnaps.add(CollSnap(
        x: c.position.x, y: c.position.y,
        type: c.cType.index,
      ));
    }

    // Beams
    final beamSnaps = <BeamSnap>[];
    for (final v in allVessels) {
      for (final d in v.devices) {
        if (d.beamActive > 0 && d.beam > 0) {
          beamSnaps.add(BeamSnap(
            sx: d.sx, sy: d.sy,
            dx: d.dx, dy: d.dy,
            active: true,
          ));
        }
      }
    }

    // Structures (asteroids)
    final structSnaps = <StructSnap>[];
    for (final s in activeStructures) {
      if (s.isDead) continue;
      structSnaps.add(StructSnap(
        id: s.id,
        x: s.position.x, y: s.position.y,
        sizeX: s.size.x, sizeY: s.size.y,
        hp: s.hp, hit: s.hit,
        structType: s.structType.index,
        imgName: s.imgName,
      ));
    }

    final v2 = vessel2 ?? vessel; // Fallback if no vessel2

    return encodeGameSnapshot(
      gameState: state.index,
      sectorIndex: currentSectorIndex,
      elapsed: elapsed,
      v1Data: vesselDoubles(vessel),
      v1Ints: vesselInts(vessel),
      v2Data: vesselDoubles(v2),
      v2Ints: vesselInts(v2),
      hostiles: hostileSnaps,
      enemyProjs: eProjSnaps,
      playerProjs: pProjSnaps,
      collectables: collSnaps,
      beams: beamSnaps,
      structures: structSnaps,
    );
  }

  // ==== Client: apply snapshot ====

  void applySnapshot(GameSnapshot snap) {
    // Update vessel stats from snapshot
    _applyVesselSnap(vessel, snap.vessel1);
    if (vessel2 != null) {
      _applyVesselSnap(vessel2!, snap.vessel2);
    }

    // Update game state (don't let snapshot downgrade playing→comCenter on client —
    // gameStart event may arrive before first snapshot with playing state)
    if (snap.gameState < GameState.values.length) {
      final newState = GameState.values[snap.gameState];
      if (!(coopRole == CoopRole.client && state == GameState.playing && newState == GameState.comCenter)) {
        state = newState;
      }
    }
    currentSectorIndex = snap.sectorIndex;
    elapsed = snap.elapsed;

    // Update hostiles
    final seenKeys = <int>{};
    for (final hs in snap.hostiles) {
      final key = hs.fleetId * 1000 + hs.hostileId;
      seenKeys.add(key);

      var hostile = _clientHostiles[key];
      if (hostile == null) {
        // Create new hostile for rendering
        hostile = Hostile(
          caption: '',
          id: hs.hostileId,
          hostType: HostType.values[hs.hostType.clamp(0, HostType.values.length - 1)],
          hp: hs.hp,
          hpMax: hs.hp,
        );
        _clientHostiles[key] = hostile;
        world.add(hostile);
      }
      hostile.position.setValues(hs.x, hs.y);
      hostile.hp = hs.hp;
      hostile.hit = hs.hit;
    }

    // Remove hostiles no longer in snapshot
    final toRemove = _clientHostiles.keys.where((k) => !seenKeys.contains(k)).toList();
    for (final k in toRemove) {
      final h = _clientHostiles.remove(k);
      h?.removeFromParent();
    }

    // Structures (asteroids)
    final seenStructIds = <int>{};
    for (final ss in snap.structures) {
      seenStructIds.add(ss.id);
      var structure = _clientStructures[ss.id];
      if (structure == null) {
        structure = Structure(
          caption: '',
          structType: StructType.values[ss.structType.clamp(0, StructType.values.length - 1)],
          hp: ss.hp,
          hpMax: ss.hp,
          imgName: ss.imgName,
        );
        _clientStructures[ss.id] = structure;
        world.add(structure);
      }
      structure.position.setValues(ss.x, ss.y);
      structure.hp = ss.hp;
      structure.hit = ss.hit;
    }
    final structToRemove = _clientStructures.keys.where((k) => !seenStructIds.contains(k)).toList();
    for (final k in structToRemove) {
      final s = _clientStructures.remove(k);
      s?.removeFromParent();
    }

    // Enemy projectiles — recreate each frame (simple, since they're cheap)
    for (final p in enemyProjectiles) {
      p.removeFromParent();
    }
    enemyProjectiles.clear();
    for (final ps in snap.enemyProjectiles) {
      final proj = Projectile(
        imgName: 'bubble',
        position: Vector2(ps.x, ps.y),
        speed: ps.speed,
        damage: 0,
      );
      proj.size = Vector2(ps.sizeX, ps.sizeY);
      enemyProjectiles.add(proj);
      world.add(proj);
    }

    // Player projectiles
    for (final p in _clientPlayerProjectiles) {
      p.removeFromParent();
    }
    _clientPlayerProjectiles.clear();
    for (final ps in snap.playerProjectiles) {
      final proj = Projectile(
        imgName: 'bubble',
        position: Vector2(ps.x, ps.y),
        speed: ps.speed,
        damage: 0,
      );
      proj.size = Vector2(ps.sizeX, ps.sizeY);
      _clientPlayerProjectiles.add(proj);
      world.add(proj);
    }

    onOsdUpdate?.call();
  }

  void _applyVesselSnap(Vessel v, VesselSnap snap) {
    v.position.setValues(snap.x, snap.y);
    v.hp = snap.hp;
    v.hpMax = snap.hpMax;
    v.shield = snap.shield;
    v.shieldMax = snap.shieldMax;
    v.genValue = snap.gen;
    v.genMax = snap.genMax;
    v.score = snap.score;
    v.credit = snap.credit;
    v.fire = snap.fire;
    v.dmgTaken = snap.dmgTaken;
    v.visible = snap.visible;
  }

  DevType? _findWeaponType(String name) {
    for (final w in DevType.frontWeapons) {
      if (w.name == name) return w;
    }
    for (final w in DevType.sideWeapons) {
      if (w.name == name) return w;
    }
    return null;
  }

  // ==== Cleanup ====

  Future<void> disposeCoop() async {
    await coopHost?.dispose();
    await coopClient?.dispose();
    coopHost = null;
    coopClient = null;
    coopRole = CoopRole.none;
    onClientJoined = null;

    if (vessel2 != null) {
      vessel2!.removeFromParent();
      vessel2 = null;
    }

    // Clean up client-side entities
    for (final h in _clientHostiles.values) {
      h.removeFromParent();
    }
    _clientHostiles.clear();
    for (final s in _clientStructures.values) {
      s.removeFromParent();
    }
    _clientStructures.clear();
    for (final p in _clientPlayerProjectiles) {
      p.removeFromParent();
    }
    _clientPlayerProjectiles.clear();
  }
}
