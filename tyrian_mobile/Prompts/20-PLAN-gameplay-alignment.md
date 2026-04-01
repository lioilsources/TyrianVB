# Plan: Gameplay Alignment — Sprite Scale + Path Height Normalization

## Motivation

After aligning sprite skins with original VBA proportions (`spriteScale = 0.37`), sprites were
visually too small on both desktop and mobile. Additionally, fleet paths used hardcoded Y
coordinates and `durationSec` values that did not adapt to actual screen height, causing enemies
to move faster on taller screens and leaving dead zones above/below paths.

---

## Problem 1: Sprite Scale (+25%)

### Root cause
`spriteScale = 0.37` matched VBA `SIZE_UNIT ≈ 0.0378` (×10 factor) but was too small visually.

### Fix

**`lib/game/game_config.dart`**

| Line | Old | New |
|------|-----|-----|
| 38 | `spriteScale = 0.37` | `spriteScale = 0.4625` |
| 41 | `iconWidth = 35.0` | `iconWidth = 44.0` |
| 42 | `iconHeight = 35.0` | `iconHeight = 44.0` |

`iconWidth/Height` (collectables) must match — they are sized independently of `spriteScale`.

### Collision impact
Hitbox = `size * 0.7` (collision fraction `cf` in `hostile.dart`), where `size = srcSize * spriteScale`.
Hitbox grows proportionally — no manual adjustment needed. Gameplay feel is preserved.

---

## Problem 2: Fleet Path Y-Coordinate Normalization

### Root cause

Fleet paths in `sector.dart` read `h = config.gameHeight` for endpoints but used hardcoded values
for `durationSec`, `srcY`, and `amplitude`. On a taller screen:

```
speed = distance(src→dst) / durationSec
```

On 600×1300 vs 600×832:  `distance = 1350px vs 882px`, same `durationSec` → enemies ~53% faster.

### How the coordinate system works

The game world is **always in portrait coordinate space** (width = 600, height = dynamic).
Desktop landscape is a `-90°` camera rotation only — game logic uses the same coordinates.

```dart
// Desktop 1920×1080:
config.gameHeight = 600 * (1920 / 1080) = 1066.7
// Same as a tall mobile portrait screen — same fleet code path
```

### Fix

Add to each `_sectorN` function:
```dart
final hs = config.gameHeight / config.scrHeight; // 1.0 at 832px, ~1.56 at 1300px
```

Apply `* hs` to:
- Every `durationSec` → preserves visual speed (px/sec per screen fraction)
- Every hardcoded `srcY`, `dstY` (not using `h`) → preserves relative screen position
- `amplitude` for `sinus`, `sinCos` paths → preserves oscillation proportion
- `amplitude` for `cosinus` paths on diagonal/vertical routes → same rationale

### What does NOT get scaled

| What | Why |
|------|-----|
| `dstY: h + 5` references | Already use `config.gameHeight` |
| X coordinates | `gameWidth = 600` is always fixed |
| `triggerSteps` | Spawn cadence, not spatial distance |
| `altParam1/2` in sector 4 | Relative movement deltas for hover animation |
| `srcY: 0` | Multiplying by `hs` is a no-op |
| `_createRandom` | All Y values already use `config.gameHeight` |
| `_addAsteroids` | Destination uses `config.gameHeight`, entry offset (-50) is minor |
| Boss extra path `h * 0.48` etc. | Fractional expressions already scale with `h` |

### Gameplay benefit

On 600×1300 screen (`hs ≈ 1.56`): `durationSec: 17` → `17 * 1.56 ≈ 26.5s`
Enemies traverse at same **visual speed** (same % of screen per second).
Player has ~56% more absolute time to shoot → intended benefit on taller devices.

---

## Files Changed

| File | Changes |
|------|---------|
| `lib/game/game_config.dart` | 3 constant values |
| `lib/systems/sector.dart` | `hs` added to `_sector0`–`_sector5`; ~60 values scaled |

---

## Sector-by-Sector Details

### `_sector0` — System Perimeter
- `hs` added after `final h`
- Fleets 0–3: `durationSec: 17 * hs`, `srcY: -45 * hs`
- Fleets 2–3 (sinus): `amplitude: 20 * hs`
- Fleet 4 (cosinus escort): `durationSec: 27 * hs`, `srcY: -45 * hs` — amplitude NOT scaled (horizontal deviation on vertical path)
- Fleet 5 (sinCos): `durationSec: 26 * hs`, `srcY: -200 * hs`, `amplitude: 180 * hs`
- Fleet 6 (sinCos): `durationSec: 27 * hs`, `srcY: -400 * hs`, `amplitude: 200 * hs`
- Fleet 7 (sinus): `durationSec: 22 * hs`, `srcY: -40 * hs`, `amplitude: 100 * hs`
- Fleet 8 (sinus): `durationSec: 20 * hs`, `srcY: -40 * hs`, `amplitude: 100 * hs`
- Fleet 9 (horizontal sweep, sinus): `durationSec: 24 * hs`, `srcY: 200 * hs`, `dstY: 200 * hs`, `amplitude: 100 * hs`

### `_sector1` — Inner Zone
- `hs` added after `final h`
- Fleets 0–3 (sinCos): `durationSec: 27 * hs`, `srcY: -200 * hs`, amplitudes scaled
- Fleets 4–6, 8 (linear): `durationSec: 16 * hs`, `srcY: -45 * hs`
- Boss fleet 7: `durationSec: 12 * hs`
- Extra path ep seg1: `dstY: -100 * hs` (off-screen target)
- Extra path ep seg2: `srcY: -100 * hs` (entry from off-screen)
- Extra path segs 3–4: use `h * 0.58`, `h * 0.48`, `h * 0.19` — already scale with `h`

### `_sector2` — Planet Perimeter
- `hs` added after `final h`
- All 7 fleets: `durationSec * hs`, `srcY * hs`, `amplitude * hs`
- Cosinus fleets (s2f2, s2f4): amplitude scaled — diagonal paths where ys component is significant

### `_sector3` — Planet Patrol
- `hs` added after `final h`
- Boss1 initial path: `durationSec: 19 * hs`
- Extra path ep: all off-screen Y endpoints scaled (`-100 * hs`, `500 * hs`, `20 * hs`)
- `sharedEp.clone()` — cloned after `ep` is built, so all boss clones inherit scaled path
- Swarm (sinCos): `durationSec: 70 * hs`, `srcY: -180 * hs`, `amplitude: 160 * hs`
- All individual boss fleets (falconx, falconx2, falconx3 loops): `durationSec * hs`

### `_sector4` — Planet Orbit
- `hs` added (no `h` needed — not used in this function)
- `freezeData` array: formation Y rows `100–600` → `100 * hs – 600 * hs` (both srcY and dstY)
- `freezeData` loop: `durationSec: 12 * hs`
- `rpFleet0`: `durationSec: 12 * hs`, `srcY: 10 * hs`, `dstY: 10 * hs`
- `rpData` array: formation Y rows scaled, loop `durationSec: 12 * hs`
- `altParam1/2` (hover deltas 50, 40): NOT scaled — relative movement, not screen position

### `_sector5` — Industry Zone
- `hs` added after `final h`
- Spiral (cosinus): `durationSec: 35 * hs`, `srcY: -55 * hs` — amplitude NOT scaled (vertical cosinus = horizontal deviation, width fixed)
- 6 parallel linear fleets: `durationSec: 12 * hs`, `srcY: -45 * hs` each

---

## Key Formulas

```
hs = config.gameHeight / config.scrHeight

spriteScale:  0.37 * 1.25 = 0.4625
iconSize:     35 * 1.25 = 43.75 → 44 (integer alignment)

visual speed (px/sec per screen height) = distance / durationSec / gameHeight
                                        = constant after * hs fix
```
