# Phase 1 Plan: Core Gameplay Parity

Goal: Make the mobile port **feel like the original game** — dense enemy waves, enemies that fight back, and balanced progression through all 6 scripted sectors.

---

## Completed Work

### Sector Content Rewrite (DONE)
All 7 sector builders rewritten with exact VB6 data:
- Sectors 0-5: 7-18 fleets each, 136-200 enemies per sector
- FreezeFleet implemented (Sector 4: enemies park in rows)
- ReplacePath implemented (Sector 4: enemies oscillate after arriving)
- Extra paths implemented (Sectors 1, 3: bosses follow multi-segment chains)
- Timed asteroid spawning with 100k HP, destructible
- Sector 6+ calls `_createRandom()` for procedural generation

### Infrastructure (DONE)
- `PathSystem.finish()` — jump to last node
- `PathSystem.addPath()` — copies onExit from appended path
- `Fleet.extraPath` + `setExtraPath()` — multi-segment path chaining
- `Hostile.parentFleet` — back-reference for fleet-wide actions
- `Hostile.cyclePath()` — out-and-back oscillation path
- `Structure.enterTime` + `activated` — timed structure spawning
- Fleet depletion: based on `_spawned >= count && hostiles.isEmpty` (not just kills)
- Sector completion: all fleets started AND all fleets inactive

---

## Remaining Phase 1 Tasks

### P1.1 — Enemy Weapons (HIGH PRIORITY)

**Problem**: Enemies never fire. The game has zero ranged threat. Only collision damage exists.

**What VB6 does**:
- Each fleet has a `Device` (weapon) + `weapCharge` cooldown
- In `Hostile.step()`, when `weapCharge` counts down to 0, the enemy fires a projectile downward
- Damage formula: `hostType_index × 5.555 × difficulty_coefficient`
- Cooldown formula: `(400 - min(player.dps/20, 385)) × 2 + 2` frames

**Implementation plan**:

1. **Add weapon fields to Fleet** (already has `Device? weapon`):
   - Add `int weapCharge = 0` (frames between shots)
   - Add `int _weapTimer = 0` (countdown)

2. **Add firing logic to Hostile.update()**:
   - Check `parentFleet?.weapon != null`
   - Decrement fleet's `_weapTimer`
   - When timer reaches 0: spawn enemy projectile (downward, toward player)
   - Reset timer to `weapCharge`
   - Only fire when hostile is on-screen (y > 0 && y < gameHeight)

3. **Enemy Projectile entity**:
   - Reuse existing `Projectile` class with `isEnemy: true` flag
   - Travels downward at weapon speed
   - Damages vessel on hit (bypasses normal collision)
   - Different visual (red/orange tint vs player's blue/green)

4. **Add `AddWeapon()` calls to sector builders**:
   - Each VB6 sector has `Call AddWeapon(damage, recharge)` after fleet creation
   - Port these as `fleet.weapon = ...` + `fleet.weapCharge = ...`
   - Damage and recharge values from VB6 source (see Sector.cls)

5. **Vessel collision with enemy projectiles**:
   - In `vessel.dart` update loop, check against enemy projectiles
   - Apply damage to shield then HP (same as current model)

**Files to modify**: `hostile.dart`, `fleet.dart`, `sector.dart`, `vessel.dart`, `projectile.dart`, `tyrian_game.dart`

---

### P1.2 — Fleet Acceleration (MEDIUM PRIORITY)

**Problem**: When the player kills all visible enemies quickly, there's a long wait until the next fleet's `enterTime`. VB6 has the same issue but the dense sectors mask it.

**Implementation**:
- In `sector.dart update()`, after fleet activation loop:
  - If all started fleets are inactive (all enemies dead)
  - And there are unstarted fleets remaining
  - Fast-forward `elapsed` to the next fleet's `enterTime`
- This skips dead time between waves without changing the intended pacing when fleets overlap

**Files to modify**: `sector.dart`

---

### P1.3 — Collision Damage Balancing (MEDIUM PRIORITY)

**Problem**: VB6 enemies have specific collision damage per type (1-20), but mobile port uses flat `collisionDmg = 10` for all.

**Implementation**:
- Add collision damage lookup per HostType (matching VB6 values)
- Falcon I-IV: 1, Falcon V-VI: 2, Falcon X: 4, X-2: 6, X-3: 8, X-B: 10, X-T: 12, Bouncer: 20
- Apply in `Hostile` constructor based on hostType

**Files to modify**: `hostile.dart`

---

### P1.4 — Credit/Score Formula Fix (LOW PRIORITY)

**Problem**: VB6 awards `hpMax` as score and `hpMax / 10` as credit per kill. Mobile awards `hpMax` as both score AND credit, making credits too generous.

**Implementation**:
- In `fleet.dart onHostileKilled()`, change `credit += h.hpMax ~/ 10`
- Verify sector bonus amounts match VB6 (already fixed in sector rewrite)

**Files to modify**: `fleet.dart`

---

### P1.5 — Weapon Values Alignment (LOW PRIORITY)

**Problem**: Mobile weapon damage values differ slightly from VB6.

| Weapon | VB6 Damage | Mobile Damage |
|--------|-----------|---------------|
| Bubble Gun | 21 | 15 |
| Vulcan | 24 | 8 |
| Blaster | 250 | 25 |
| Laser | 64×6 | 35 |

**Implementation**:
- Update `dev_type.dart` weapon definitions to match VB6 values exactly
- Verify upgrade multipliers match (×1.1 damage, ÷1.02 cooldown)
- Check price and upgrade cost values

**Files to modify**: `dev_type.dart`

---

## Out of Scope (Phase 2+)

| Feature | Priority | Notes |
|---------|----------|-------|
| Score-based weapon unlocks | P2 | Vulcan at 400k, Blaster at 4M, Laser at 14M |
| Generator load warnings | P2 | UI indicator when PPS > generation |
| DPS-based random scaling | P2 | Random levels scale with player power |
| Damage growth coefficient | P2 | Enemy damage grows after level 20 |
| Persistent save/resume | P2 | Resume from last sector between sessions |
| Smooth vessel movement | P3 | Approach-based movement like VB6 |
| Advanced ComCenter UI | P3 | Animation frames, gradient effects |
| Sound / Music | P3 | No audio in either version currently |

---

## Verification Plan

### After P1.1 (Enemy Weapons):
- Enemies fire visible projectiles downward
- Player takes damage from enemy projectiles (shield absorbs first)
- Fire rate scales with fleet configuration
- Sectors 1-6 have correct weapon values per fleet

### After P1.2 (Fleet Acceleration):
- Killing all current enemies speeds up next wave appearance
- No infinite wait between waves
- Overlapping waves still activate at correct relative times

### After all P1 tasks:
- Play through all 6 scripted sectors on device
- Difficulty feels appropriate (not too easy, not impossible)
- ComCenter economy works (can buy upgrades between sectors)
- Sector 7+ random generation produces playable content
- No performance issues with 150+ concurrent enemies
