# Phase 4: Full VB6 Gameplay Alignment (19 fixes)

## Context

Phases 1-3 complete. Thorough VB6 vs mobile gap analysis identified 19 gameplay differences. All fixed in this phase.

---

## P4.1 — Fix Hostile Body Collision
Enemy should NOT take damage from player contact (VB6 only damages vessel).
- `hostile.dart`: removed `takeDamage(collisionDmg, game)` from `_checkPlayerCollision()`

## P4.2 — Death Explosions (centralized)
VB6 spawns explosion on every enemy death. Moved explosion spawning from `takeDamage()` to `fleet.dart` cleanup loop — covers both weapon kills and path-end deaths.
- `fleet.dart`: `game.addExplosion()` in `removeWhere` loop
- `hostile.dart`: removed duplicate explosion from `takeDamage()`

## P4.3 — Weapon Max Level Cap (25) + Bonus
VB6 caps upgrades at level 25. At max level, collectables convert to credit/score bonus based on sector level. ComCenter UPGRADE button disabled at max.
- `device.dart`: `static const maxLevel = 25`, bonus logic in `upgrade()`, `showMessage('Max. level! Sold for $X')`
- `com_center.dart`: button shows "MAX LV" and `onPressed: null` at max

---

## Economy & Scoring Fixes

## P4.4 — Kill Credit = hpMax (not hpMax/10)
VB6 `Fleet.cls:112`: `rocket.AddCredit h.hpMax`. Mobile had `hpMax ~/ 10` — 10x too low.
- `fleet.dart:onHostileKilled`: `credit += h.hpMax`

## P4.5 — Bonus Only on All-Kill
VB6 drops bonus only when `kills == count` (all enemies killed by player). Mobile dropped bonus even when enemies escaped off-screen (path-destroy).
- `fleet.dart`: `if (kills >= count) _spawnBonus()`
- Bonus now spawns at last killed hostile's position (VB6 behavior), not fleet bbox center

## P4.6 — Sell Price = 100%
VB6 `Vessel.Sell` refunds full `d.price`. Mobile had 50%.
- `com_center.dart:_sellWeapon`: `credit += device.price`

## P4.7 — Random Sector Bonus Formula
VB6: `sectorBonus = fleetCount * 2500 * level`. Mobile had `500 + index * 200` (tiny).
- `sector.dart:_createRandom`: correct formula

---

## Random Sector Generation Fixes

## P4.8 — Random Fleet Count 5-20
VB6: `Round(Rnd * 15 + 5)` = 5-20 fleets. Mobile had 3-5.
- `sector.dart:_createRandom`: `(rng.nextDouble() * 15 + 5).round()`

## P4.9 — Horizontal Attack Paths
VB6: 35% chance of side-to-side attack paths. Mobile only had top-to-bottom.
- `sector.dart:_createRandom`: 35% branch with edge-to-edge X, mid-screen Y

## P4.10 — Simultaneous Fleet Spawning
VB6 `simultan` logic: chance of multiple fleets sharing the same enter time.
- `sector.dart:_createRandom`: `if (rng.nextDouble() > 0.55 / simultan)` gives same enter time

## P4.11 — Fleet Acceleration 2-Second Buffer
VB6 skips at most 2 seconds ahead. Mobile snapped instantly to next fleet.
- `sector.dart`: `elapsed = target - 2` instead of `elapsed = target`

## P4.12 — Random Asteroids With Paths
VB6: asteroid count = `Rnd * (fleetCount/2)`, timed across sector with `ByPath` behavior. Mobile had simple `StructBehavior.fall`.
- `sector.dart:_createRandom`: uses `_addAsteroids()` with redistributed enter times

---

## Weapon & Combat Fixes

## P4.13 — Enemy Weapon Multi-Fire Bug
Multiple hostiles sharing one `weapCD` counter incremented it N times per frame (N = alive hostiles), making enemy fire rate up to 20x faster than VB6.
- `hostile.dart`: removed weapon firing logic
- `fleet.dart:update()`: centralized weapon firing — one shot per cooldown cycle

## P4.14 — Vulcan xShift Step = 7
VB6 `Device.cls:106`: shifts by 7 pixels per shot. Mobile had 1.
- `device.dart`: `xShift += xShiftDir * 7`

## P4.15 — DPS Calculation With seqs (beam weapons)
VB6 `Vessel.cls:308`: `dps = damage * seqs / cooldown`. Mobile missed `seqs` multiplier — beam DPS underreported, affecting random sector scaling.
- `device.dart:dps`: `if (beam > 0) return damage * seqs / cooldown`

## P4.16 — Guided Weapon Angle Filtering
VB6 `TestDistance`: computes `grat = guide / speed`, filters by `grat >= dx/dy`. Mobile homed toward any nearest enemy regardless of angle.
- `vessel.dart:_findClosestEnemy`: guidance cone check, enemies below player skipped

## P4.17 — displayName Update After Upgrade
VB6 updates `d.displayName = name & " " & ROMNUM(level)`. Mobile kept base name forever.
- `device.dart:upgrade()`: `displayName = '$name ${_roman[level]}'`

---

## Collectable & Stats Fixes

## P4.18 — Collectables Create Missing Weapons
VB6: weapon upgrade collectable creates Bubble Gun / Small Bubble if slot is empty. Mobile silently discarded upgrade.
- `collectable.dart`: `??= vessel.equipWeapon(DevType.bubbleGun/smallBubble, slot)`

## P4.19 — New Game Resets All Stat Upgrades
VB6 `ResetVessel` resets hpMax=125, shieldMax=100, genMax=100, genPower=4, shieldRegen=0.1. Mobile kept all stat upgrades across deaths.
- `vessel.dart:newGame()`: full stat reset to VB6 defaults

## P4.20 — HP Scaling Linear Above 2000
VB6: `hpMax * 1.05` below 2000, `hpMax + 50` above. Mobile was exponential forever.
- `collectable.dart:healthUpgrade`: cap check at 2000

## P4.21 — ShieldMax Grows Above 1500
VB6: rounds `(shieldMax + 25) / 25 * 25` at >=1500. Mobile froze shieldMax.
- `collectable.dart:shieldUpgrade`: `((shieldMax + 25) / 25).round() * 25`

## P4.22 — Asteroid Collision With Player
VB6 `Structure.cls:129-146`: asteroids deal `collisionDmg` and push player below. Mobile asteroids were harmless scenery.
- `structure.dart`: `_checkPlayerCollision()` with damage + Y-push

---

## Additional Fixes (side effects)

- `tyrian_game.dart:loadSector`: sets `vessel.lvlNum = index + 1` (needed for max-level bonus formula)
- `hostile.dart`: removed unused `game_config.dart` import after weapon firing move

## Files Modified
- `lib/entities/hostile.dart`
- `lib/entities/vessel.dart`
- `lib/entities/collectable.dart`
- `lib/entities/structure.dart`
- `lib/systems/device.dart`
- `lib/systems/fleet.dart`
- `lib/systems/sector.dart`
- `lib/ui/com_center.dart`
- `lib/game/tyrian_game.dart`
