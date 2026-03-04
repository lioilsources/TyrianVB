# Phase 2: Gameplay Alignment 1:1 with VB6

## Context

Phase 1 completed sector waves, weapon/vessel values, collision damage, score display, and upgrade formulas. Two Phase 1 items remain (enemy weapons, fleet acceleration) plus Phase 2 features: weapon unlocks, damage scaling, DPS-based random sectors, and generator warnings.

---

## P2.1 — Enemy Weapons (CRITICAL)

Enemies never fire. Zero ranged threat — only collision damage exists.

### VB6 mechanics
- `Fleet` has `weap: Device` + `weapCharge: Integer` + `weapCD: Integer`
- In `Hostile.step()`: increment `weapCD`, when it equals `weapCharge` → fire + reset
- Only fire when hostile is on-screen (`y2 > 0 && x mid > 0 && x mid < SCR_WIDTH`)
- `AddWeapon(dmg, recharge)` creates a Bubble Gun device with `ratio = clamp(dmg/75, 0.3, 0.99)` as projectile scale
- Enemy projectile: same `Projectile` class, **positive speed** (downward), spawns below enemy

### Implementation

**`lib/systems/fleet.dart`** — add weapon fields:
```dart
int weapCharge = 0;   // frames between shots (recharge)
int _weapCD = 0;      // current cooldown counter
int weapDamage = 0;   // enemy weapon damage
double weapScale = 0.5; // projectile scale ratio
```

Add `addWeapon(int dmg, int recharge)` method:
```dart
void addWeapon(int dmg, int recharge) {
  weapDamage = dmg;
  weapCharge = recharge;
  final ratio = (dmg / 75.0).clamp(0.3, 0.99);
  weapScale = ratio;
}
```

**`lib/entities/hostile.dart`** — add firing in `update()`:
```dart
// After path follow, before collision check:
if (parentFleet != null && parentFleet!.weapCharge > 0) {
  parentFleet!._weapCD++;
  if (parentFleet!._weapCD >= parentFleet!.weapCharge) {
    if (y2 > 0 && position.x > 0 && x2 < config.gameWidth) {
      _fireWeapon();
    }
    parentFleet!._weapCD = 0;
  }
}
```

`_fireWeapon()` spawns a `Projectile` with:
- positive speed (downward) = `15.0` (bubble gun speed)
- damage = `parentFleet!.weapDamage`
- scale = `parentFleet!.weapScale`
- position = center-bottom of hostile
- Add to `game.enemyProjectiles` list (new)

**`lib/game/tyrian_game.dart`** — add enemy projectile tracking:
```dart
final List<Projectile> enemyProjectiles = [];
```

Add `spawnEnemyProjectile(double x, double y, int dmg, double scale)` method.

In `update()`, iterate `enemyProjectiles` to check collision with vessel (AABB overlap → `vessel.takeDamage(dmg)`), remove if off-screen or hit.

In `_clearActiveObjects()`, clean up enemy projectiles.

**`lib/systems/sector.dart`** — add `addWeapon()` calls after each fleet creation:

Level 1 (4 fleets get weapons):
- Fleet 4 (escort): `addWeapon(10, 300)`
- Fleet 7: `addWeapon(15, 300)`
- Fleet 8 (falcon5): `addWeapon(15, 275)`
- Fleet 9 (falcon6): `addWeapon(18, 175)`

Level 2 (7 fleets):
- Fleets 0-3: `addWeapon(20, 400/400/350/350)`
- Fleet 4: `addWeapon(20, 350)`
- Fleet 5: `addWeapon(20, 300)`
- Boss (fleet 7): `addWeapon(30, 120)`

Level 3 (7 fleets):
- Fleets 0-1: `addWeapon(33, 450)`
- Fleet 2: `addWeapon(33, 300)`
- Fleet 3 (falconx): `addWeapon(40, 350)`
- Fleet 4: `addWeapon(33, 250)`
- Fleet 5 (falconx): `addWeapon(40, 350)`
- Fleet 6 (falconx): `addWeapon(40, 350)`

Level 4 (17 fleets):
- Swarm (falcon5 150): `addWeapon(35, 500)`
- 4x falconx bosses: `addWeapon(40, 350)`
- falconx2 boss: `addWeapon(40, 350)`
- 7x falconx2: `addWeapon(40, 300)`
- 4x falconx3: `addWeapon(40, 275/275/250/250)`

Level 5 (13 fleets):
- FreezeFleet 6: dmg 15→10, recharge 300
- FreezeFleet 5-1: dmg 14→10, recharge 300→300
- falconx3 alt: `addWeapon(50, 225)`
- ReplacePath 6 fleets: dmg 20→15, recharge 275

Level 6 (7 fleets):
- Main spiral: `addWeapon(45, 250)`
- Parallel fleets: `addWeapon(10, 275)` each

Random levels:
- damage = `round(hostTypeIndex * 5.555) * dcf`
- recharge = `round((400 - min(dps/20, 385)) * 2 + 2)`

### Files
- `lib/systems/fleet.dart` — weapon fields + addWeapon method
- `lib/entities/hostile.dart` — firing logic in update()
- `lib/game/tyrian_game.dart` — enemy projectile list + collision + spawn helper
- `lib/systems/sector.dart` — addWeapon calls for all 7 sector builders + random

---

## P2.2 — Fleet Acceleration

When all active fleets are cleared, fast-forward to next fleet's `enterTime`.

**`lib/systems/sector.dart`** — in `update()`, after fleet activation loop:
```dart
// If all started fleets are inactive and unstarted fleets remain, skip ahead
final allStartedDead = fleets.where((f) => f.started).every((f) => !f.active);
final nextUnstarted = fleets.where((f) => !f.started).toList();
if (allStartedDead && nextUnstarted.isNotEmpty) {
  elapsed = nextUnstarted.first.enterTime;
}
```

### Files
- `lib/systems/sector.dart`

---

## P2.3 — Score-Based Weapon Unlocks

VB6 thresholds: `[0, 400000, 4000000, 14000000]`

**`lib/entities/vessel.dart`**:
- `nextWeaponLevel` already exists (line 37, initialized to 0)
- Add `static const wepLevScores = [0, 400000, 4000000, 14000000];`
- Add `addScore(int s)` method that checks threshold and sets `nextWeaponLevel`:
  ```dart
  void addScore(int s) {
    score += s;
    if (nextWeaponLevel < wepLevScores.length &&
        score > wepLevScores[nextWeaponLevel]) {
      nextWeaponLevel++;
      game.showMessage('Weapon level ${_romanNum(nextWeaponLevel)} unlocked');
    }
  }
  ```

- Replace direct `score +=` in `fleet.dart:onHostileKilled` and `vessel.dart` structure hits with `vessel.addScore()`

**`lib/ui/com_center.dart`** — filter available weapons by `vessel.nextWeaponLevel`:
- Level 0: Bubble Gun, Small Bubble only
- Level 1 (400k): + Vulcan, Small Vulcan
- Level 2 (4M): + Blaster, Star Gun
- Level 3 (14M): + Laser, Small Laser
- Gray out / hide locked weapons

### Files
- `lib/entities/vessel.dart` — addScore + unlock logic
- `lib/systems/fleet.dart` — use addScore instead of direct +=
- `lib/ui/com_center.dart` — weapon availability filtering

---

## P2.4 — Damage Growth Coefficient (Level 20+)

VB6 tiers:
- Levels 1-19: dcf = 1.0
- Levels 20-24: dmgGrow = 0.25 per level
- Levels 25-29: dmgGrow = 0.35 per level
- Levels 30-34: dmgGrow = 0.45 per level
- Levels 35+: dmgGrow = 0.60 per level

Formula: `dcf = 1 + ((level - 20 + 1) * dmgGrow)`

**`lib/systems/sector.dart`** — in `_createRandom()`:
- Calculate `dcf` based on level
- Apply `dcf` to enemy weapon damage: `damage = round(hostTypeIndex * 5.555 * dcf)`
- Show message: `"Enemy damage +X%"` when dcf > 1

### Files
- `lib/systems/sector.dart`

---

## P2.5 — DPS-Based Random Sector Scaling

Currently random sectors use basic level-based type selection. VB6 scales with player DPS.

**`lib/systems/sector.dart`** — rewrite `_createRandom()`:
- Accept `TyrianGame game` (already does)
- Get `dps = game.vessel.totalDps`, track `lastMaxDps = max(dps, lastMaxDps)`
- `maxHostLevel = round(6 * (lastMaxDps / 500))`, capped at level+2, hard cap 10 (11 if level>=17 && dps>10000)
- Host count scaling: if enemyHP/DPS > 2 → cap 10, if >3 → cap 5, if <0.09 → double
- Duration: `(enemyHP / DPS) * count * durCoef`
- Enemy weapon recharge: `round((400 - min(dps/20, 385)) * 2 + 2)`

### Files
- `lib/systems/sector.dart`
- `lib/entities/vessel.dart` — add `lastMaxDps` field

---

## P2.6 — Generator Load Display

VB6 shows "Cap X | Load Y% | [weapon] off | low" in ComCenter.

**`lib/entities/vessel.dart`** — add methods:
```dart
double get generatorLoad => totalPPS / (genPower * config.originalFps) * 100;
String get genInfo { ... } // Format load string
```

Where `totalPPS` sums `pwrNeed / cooldown` across all devices.

**`lib/ui/com_center.dart`** — display `vessel.genInfo` in generator section.

### Files
- `lib/entities/vessel.dart`
- `lib/ui/com_center.dart`

---

## Implementation Order

1. **P2.1 Enemy Weapons** — critical, makes game actually challenging
2. **P2.2 Fleet Acceleration** — small change, fixes pacing
3. **P2.3 Weapon Unlocks** — progression system
4. **P2.4 Damage Growth** — endgame scaling (small, in sector.dart)
5. **P2.5 DPS Random Scaling** — rewrite _createRandom()
6. **P2.6 Generator Load** — UI info

---

## Verification

1. `flutter analyze` — no errors
2. Start game → enemies fire visible projectiles downward in Sector 0 fleet 4+
3. Enemy projectiles damage vessel (shield absorbs first)
4. Kill all current enemies → next wave starts immediately (no dead time)
5. Reach 400k score → "Weapon level II unlocked" message, Vulcan available in ComCenter
6. Reach level 20+ in random sectors → "Enemy damage +X%" message
7. Random sector enemies scale with player DPS (stronger DPS → harder enemies)
8. ComCenter shows generator load percentage
