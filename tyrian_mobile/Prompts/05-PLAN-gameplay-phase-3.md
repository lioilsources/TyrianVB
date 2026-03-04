# Phase 3: Gameplay Alignment — Bug Fixes & Missing Mechanics

## Context

Phases 1-2 implemented sector waves, weapon values, enemy weapons, fleet acceleration, weapon unlocks, damage scaling, DPS random sectors, and generator display. Phase 3 fixes confirmed bugs and wires up missing connections that prevent existing code from working.

---

## P3.1 — Fix Beam Weapon Damage (BUG — beams deal 0 damage)

### Problem
`_processBeamCollision()` in `vessel.dart:265` is dead code. It's called from `_checkProjectileCollisions()` which is only invoked per-projectile inside the `_updateProjectiles()` loop. Beam weapons set `beamActive` and return without creating projectiles (`device.dart:109-111`), so the loop body never executes. **Laser and Small Laser are completely non-functional.**

### Fix
In `vessel.dart` `update()`, add a separate beam damage pass after the per-device loop (around line 158):

```dart
// Beam damage — outside projectile loop (beams have 0 projectiles)
for (final d in devices) {
  if (d.beamActive > 0) {
    _processBeamCollision(d);
  }
}
```

Update `_processBeamCollision()` to also award score/credit on kill (matching projectile hit behavior in `_checkProjectileCollisions`).

### Files
- `lib/entities/vessel.dart` — add beam pass in `update()`, update `_processBeamCollision()`

---

## P3.2 — Wire showMessage → FloatText

### Problem
`onShowMessage` in `tyrian_game.dart:50` is never connected in `main.dart`. Weapon unlock messages are silently discarded. `FloatText` exists at `lib/ui/float_text.dart` and works correctly but is never instantiated.

### Fix
In `tyrian_game.dart`, change `showMessage()` to directly add FloatText to the world:

```dart
void showMessage(String msg) {
  world.add(FloatText(
    text: msg,
    color: const Color(0xFF00FFFF), // cyanAccent
    fontSize: 18,
    position: Vector2(config.gameWidth / 2, config.gameHeight * 0.3),
  ));
}
```

Remove unused `onShowMessage` callback. Add `import '../ui/float_text.dart'`.

### Files
- `lib/game/tyrian_game.dart` — showMessage spawns FloatText, remove onShowMessage

---

## P3.3 — Fix Game Restart (New Game doesn't reset state)

### Problem
`resetVessel()` (`vessel.dart:69`) only resets hp/shield/gen. After Game Over → High Scores → Close, the player keeps score, credits, weapon unlocks, equipped weapons, and lastMaxDps.

### Fix
Add `newGame()` to `Vessel`:

```dart
void newGame() {
  score = 0;
  credit = 0;
  nextWeaponLevel = 0;
  lastMaxDps = 0;
  for (final d in devices) { d.clearProjectiles(); }
  devices.clear();
  guidedWeapon = false;
  equipWeapon(DevType.bubbleGun, WeaponSlot.frontGun);
  resetVessel();
}
```

In `main.dart:202`, change `_game.vessel.resetVessel()` → `_game.vessel.newGame()`.

### Files
- `lib/entities/vessel.dart` — add `newGame()`
- `lib/main.dart` — call `newGame()` on restart

---

## P3.4 — Vessel Smooth Movement

### Assessment
VB6 uses `x += (dx/dist) * 0.2` approach-based movement toward mouse. On mobile, current delta-based drag (finger moves → ship moves same delta) is standard touch UX. **Skip — not applicable to touch input.** `vesselDefaultSpeed` remains in `game_config.dart` for future use.

---

## Implementation Order

1. **P3.1** Beam damage — critical, Laser weapons non-functional
2. **P3.2** FloatText — quick, enables unlock messages
3. **P3.3** Game restart — prevents stale state on replay

## Verification

1. `flutter analyze` — no errors
2. Equip Laser → fire at enemies → enemies take damage and die
3. Reach 400k score → floating "Weapon level II unlocked" text on screen
4. Die → High Scores → Close → credit=0, score=0, only Bubble Gun, weapon tier=0
