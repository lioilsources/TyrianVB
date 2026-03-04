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
import '../systems/sector.dart';
import '../systems/fleet.dart';
import '../services/asset_library.dart';
import '../rendering/beam_renderer.dart';

enum GameState { comCenter, playing, paused, gameOver }

class TyrianGame extends FlameGame
    with DragCallbacks, TapCallbacks, HasCollisionDetection {
  TyrianGame();

  late Starfield starfield;
  late Vessel vessel;
  late BeamRenderer beamRenderer;

  GameState state = GameState.comCenter;
  bool isLoaded = false;

  // Active game objects
  final List<Fleet> activeFleets = [];
  final List<Structure> activeStructures = [];
  final List<Collectable> activeCollectables = [];
  final List<Explosion> activeExplosions = [];

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
  }

  @override
  void update(double dt) {
    if (state == GameState.paused || state == GameState.comCenter) {
      // Still update starfield in comCenter for visual effect
      starfield.update(dt);
      return;
    }

    super.update(dt);
    elapsed += dt;

    // Update beam renderer with vessel data
    beamRenderer.vessel = vessel;
    beamRenderer.activeFleets = activeFleets;

    // Periodic OSD refresh (~4Hz)
    _osdTimer += dt;
    if (_osdTimer >= 0.25) {
      _osdTimer = 0;
      onOsdUpdate?.call();
    }

    // Check sector completion
    if (currentSector != null && currentSector!.isComplete) {
      _onSectorComplete();
    }
  }

  void _onSectorComplete() {
    vessel.credit += currentSector!.sectorBonus;
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

  // Touch input — delta-based so finger and vessel move in sync
  Vector2? _prevDragPos;

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (state != GameState.playing) return;
    _prevDragPos = event.canvasPosition.clone();
    vessel.fire = true;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    if (state != GameState.playing || _prevDragPos == null) return;
    final pos = event.canvasEndPosition;
    final delta = pos - _prevDragPos!;
    _prevDragPos = pos.clone();

    // Scale screen-pixel delta to game coordinates
    final scale = config.gameWidth / size.x;
    vessel.adjustPosition(
      vessel.position.x + delta.x * scale,
      vessel.position.y + delta.y * scale,
    );
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (state != GameState.playing) return;
    _prevDragPos = null;
    vessel.fire = false;
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    if (state != GameState.playing) return;
    vessel.fire = !vessel.fire; // Toggle auto-fire
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
}
