import 'dart:typed_data';
import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'game_config.dart' as config;
import '../rendering/starfield.dart';
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
import '../rendering/beam_renderer.dart';
import '../ui/float_text.dart';
import '../net/protocol.dart';
import '../net/coop_host.dart';
import '../net/coop_client.dart';

enum GameState { comCenter, playing, paused, gameOver }
enum CoopRole { none, host, client }

class TyrianGame extends FlameGame
    with DragCallbacks, TapCallbacks, HasCollisionDetection {
  TyrianGame();

  late Starfield starfield;
  late Vessel vessel;
  Vessel? vessel2; // null = solo mode
  late BeamRenderer beamRenderer;

  bool get isCoop => vessel2 != null;

  // Co-op networking
  CoopRole coopRole = CoopRole.none;
  CoopHost? coopHost;
  CoopClient? coopClient;
  bool hostReady = false;
  bool clientReady = false;

  /// All active (visible) vessels for collision iteration
  List<Vessel> get allVessels => [
        vessel,
        if (vessel2 != null) vessel2!,
      ];

  // Client-side entity cache for snapshot rendering
  final Map<int, Hostile> _clientHostiles = {};
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
    // Fill screen: keep width=600, adjust height for device aspect ratio
    config.gameHeight = config.gameWidth * (size.y / size.x);

    camera.viewport = FixedResolutionViewport(
      resolution: Vector2(config.gameWidth, config.gameHeight),
    );
    camera.viewfinder.anchor = Anchor.topLeft;
    camera.viewfinder.position = Vector2.zero();

    await AssetLibrary.instance.loadAll();

    starfield = Starfield();
    world.add(starfield);

    beamRenderer = BeamRenderer();
    world.add(beamRenderer);

    vessel = Vessel();
    await vessel.init();
    world.add(vessel);

    // Start in comCenter state
    state = GameState.comCenter;
    vessel.visible = false;
    isLoaded = true;
    onLoaded?.call();
  }

  void startGame() {
    state = GameState.playing;
    vessel.visible = true;
    vessel.resetPosition();
    if (vessel2 != null) {
      vessel2!.visible = true;
      vessel2!.resetPosition();
      // Offset P2 slightly to the right of P1
      vessel2!.position.x += 60;
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
  }

  @override
  void update(double dt) {
    // Client mode: apply snapshots, then call super.update for component mounting/rendering
    if (coopRole == CoopRole.client) {
      final snap = coopClient?.latestSnapshot;
      if (snap != null) {
        applySnapshot(snap);
        coopClient!.latestSnapshot = null;
      }
      super.update(dt);
      return;
    }

    if (state == GameState.paused || state == GameState.comCenter) {
      starfield.update(dt);
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

    // Check sector completion
    if (currentSector != null && currentSector!.isComplete) {
      _onSectorComplete();
    }

    // Host mode: send snapshot to client after each frame
    if (coopRole == CoopRole.host && coopHost != null && coopHost!.hasClient) {
      coopHost!.sendSnapshot(extractSnapshot());
    }
  }

  void _onSectorComplete() {
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

  void openComCenter() {
    state = GameState.comCenter;
    onShowComCenter?.call();
  }

  void resumeFromComCenter() {
    state = GameState.playing;
  }

  void togglePause() {
    if (state == GameState.playing) {
      state = GameState.paused;
    } else if (state == GameState.paused) {
      state = GameState.playing;
    }
  }

  void triggerGameOver() {
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

  /// Initialize co-op as host with a connected client
  Future<void> setupCoopHost(CoopHost host, String clientPilotName) async {
    coopRole = CoopRole.host;
    coopHost = host;

    vessel2 = Vessel(playerIndex: 1);
    vessel2!.pilotName = clientPilotName;
    await vessel2!.init();
    world.add(vessel2!);
    vessel2!.visible = false;

    // Wire up client input to vessel2
    host.onClientInput = (dx, dy, fire) {
      if (vessel2 != null && vessel2!.visible) {
        vessel2!.adjustPosition(dx, dy);
        vessel2!.fire = fire;
      }
    };

    host.onClientReady = () {
      clientReady = true;
      _checkBothReady();
    };

    host.onClientDisconnected = () {
      // Client disconnect — remove vessel2, continue solo
      vessel2?.visible = false;
      showMessage('Player 2 disconnected');
    };

    host.onShopAction = (action, slot, weaponName) {
      _handleClientShopAction(action, slot, weaponName);
    };
  }

  /// Initialize co-op as client. Call after onLoad.
  Future<void> setupCoopClient(CoopClient client) async {
    coopRole = CoopRole.client;
    coopClient = client;

    // Create vessel2 (this client's ship) — visible in world for rendering
    vessel2 = Vessel(playerIndex: 1);
    await vessel2!.init();
    world.add(vessel2!);
    vessel2!.visible = false;

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
  }

  /// Callback when remote peer disconnects
  VoidCallback? onDisconnected;

  void _checkBothReady() {
    if (hostReady && clientReady) {
      hostReady = false;
      clientReady = false;
      // Notify client that game is starting
      coopHost?.sendEvent(EventType.gameStart);
      onBothReady?.call();
    }
  }

  VoidCallback? onBothReady;
  /// Fires on client when host signals game start
  VoidCallback? onRemoteStart;

  void setHostReady() {
    hostReady = true;
    _checkBothReady();
  }

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
    );
  }

  // ==== Client: apply snapshot ====

  void applySnapshot(GameSnapshot snap) {
    // Update vessel stats from snapshot
    _applyVesselSnap(vessel, snap.vessel1);
    if (vessel2 != null) {
      _applyVesselSnap(vessel2!, snap.vessel2);
    }

    // Update game state
    if (snap.gameState < GameState.values.length) {
      state = GameState.values[snap.gameState];
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

  // ==== Client shop action handling on host ====

  void _handleClientShopAction(int action, int slot, String weaponName) {
    if (vessel2 == null) return;
    final v = vessel2!;

    switch (action) {
      case ShopActionType.buy:
        // Find weapon type by name
        final wt = _findWeaponType(weaponName);
        if (wt == null || v.credit < wt.price) return;
        v.credit -= wt.price;
        final ws = WeaponSlot.values[slot.clamp(0, WeaponSlot.values.length - 1)];
        v.equipWeapon(wt, ws);

      case ShopActionType.sell:
        final device = v.devices.where((d) => d.name == weaponName).firstOrNull;
        if (device == null) return;
        v.credit += device.price;
        v.removeWeapon(device.slot);

      case ShopActionType.upgrade:
        final device = v.devices.where((d) => d.name == weaponName).firstOrNull;
        if (device == null) return;
        if (v.credit < device.price) return;
        v.credit -= device.price;
        device.upgrade();
    }

    // Send updated shop state back to client
    _sendShopStateToClient();
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

  void _sendShopStateToClient() {
    if (coopHost == null || vessel2 == null) return;
    final v = vessel2!;

    final vesselSnap = VesselSnap(
      x: v.position.x, y: v.position.y,
      hp: v.hp, hpMax: v.hpMax,
      shield: v.shield, shieldMax: v.shieldMax,
      gen: v.genValue, genMax: v.genMax,
      score: v.score, credit: v.credit,
      fire: v.fire, dmgTaken: v.dmgTaken, visible: v.visible,
    );

    final weapons = v.devices.map((d) => (
      name: d.name,
      slot: d.slot.index,
      level: d.level,
      damage: d.damage,
      price: d.price,
    )).toList();

    coopHost!.send(encodeShopState(vesselData: vesselSnap, weapons: weapons));
  }

  // ==== Cleanup ====

  Future<void> disposeCoop() async {
    await coopHost?.dispose();
    await coopClient?.dispose();
    coopHost = null;
    coopClient = null;
    coopRole = CoopRole.none;

    if (vessel2 != null) {
      vessel2!.removeFromParent();
      vessel2 = null;
    }

    // Clean up client-side entities
    for (final h in _clientHostiles.values) {
      h.removeFromParent();
    }
    _clientHostiles.clear();
    for (final p in _clientPlayerProjectiles) {
      p.removeFromParent();
    }
    _clientPlayerProjectiles.clear();
  }
}
