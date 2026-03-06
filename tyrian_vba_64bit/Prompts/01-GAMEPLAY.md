# TyrianVB — Complete Gameplay Mechanics Reference

Source: `tyrian_vba_64bit/` (VB6/VBA 64-bit port)

---

## 1. Game Flow

```
START → ComCenter → Sector 1 → ComCenter → Sector 2 → ... → Sector 7 → Random sectors → Game Over
```

- Game launches directly into **ComCenter** (shop screen) before first sector
- After completing each sector, ComCenter is shown again
- ComCenter is **NOT** accessible during gameplay or on demand
- Game over when vessel HP = 0; score saved to high score table

### Main Loop (Module.bas, FRAME_DELAY = 25ms = 40 FPS)

Every frame during sector gameplay:
1. `MoveStars()` — scroll starfield background
2. `rocket.step()` — update vessel position, collision checks
3. `obj.step()` — update all game entities (sectors, fleets, hostiles, collectables)
4. `WPaint()` — render all sprites
5. Weapon fire — if player holds fire button, iterate devices, fire if energy sufficient
6. Collision detection — enemy/player projectiles, collectables

---

## 2. Sectors (Levels)

7 scripted sectors defined in `Objects.InitSectors()` (Objects.cls):

| # | Name | Description |
|---|------|-------------|
| 1 | System perimeter | Tutorial-level, weak enemies |
| 2 | Inner zone | Stronger enemies, cosine paths |
| 3 | Planet perimeter | Mixed fleet types |
| 4 | Planet patrol | Heavier enemies |
| 5 | Planet orbit | Dense fleets |
| 6 | Industry zone | Heavy resistance |
| 7 | Industry headquarters | Final scripted level |
| 8+ | Random | Procedurally generated sectors |

### Sector Structure (Sector.cls)

Each sector contains multiple **fleets** created via `CreateFleet()`:

```
CreateFleet(enterTime, name, hType, count, bonus, fireRate, durationSec,
            startX, startY, endX, endY, pathType, amplitude, frequency, decay, bonusMoney)
```

Parameters:
- `enterTime` — seconds into sector when fleet activates
- `hType` — enemy type (falcon1–falcon6, different HP/sprites)
- `count` — number of enemies in fleet
- `bonus` — collectable type dropped when fleet dies
- `fireRate` — enemy firing cooldown (frames)
- `durationSec` — travel time from start to destination
- `pathType` — movement: Linear, Sinus, Cosinus, SinCos
- `amplitude`, `frequency`, `decay` — path modifiers
- `bonusMoney` — credit value for BonusCredit drops

### Sector Completion (Sector.TimedAction)

Sector completes when:
1. All enemies killed (`count = 0`)
2. Elapsed time > minimum time
3. All enemy projectiles cleared

On completion:
- Award `sectorBonus` credits to player
- Set `displayComCenter = True`
- Activate ComCenter buttons

### Enemy Weapons per Sector

Each sector calls `AddWeapon(damage, rechargeTime)` to arm enemy fleets.
Example: `AddWeapon(10, 300)` = enemies deal 10 damage, fire every 300 frames.

---

## 3. Vessel (Player Ship)

### Properties (Vessel.cls)

| Property | Initial | Description |
|----------|---------|-------------|
| hp | 100 | Current hull points |
| hpMax | 100 | Maximum hull |
| shield | 50 | Current shield |
| shieldMax | 50 | Maximum shield |
| shieldRegen | 0.15 | Shield regen per frame (when genValue > 0) |
| genValue | 100 | Current energy |
| genMax | 100 | Energy capacity |
| genPower | 4 | Energy regen per frame (set by generator device) |
| credit | 0 | Currency for ComCenter purchases |
| score | 0 | Total score (determines weapon unlocks) |
| pilotName | "" | Editable pilot name |

### Movement (AdjustPosition)

- Mouse-controlled with **approach-based** smoothing
- Approach coefficient = 0.2 (vessel moves 20% of distance to mouse per frame)
- Blocked only by structure collisions (asteroids)

### Damage Model

1. Incoming damage hits **shield first**
2. Shield absorbs damage; if shield > 0, reduced damage passes to hull
3. When shield = 0, full damage goes to hull
4. HP = 0 → Game Over

### Shield Regeneration

- Regenerates `shieldRegen` per frame
- **Gated by energy**: only when `genValue > 0`
- Capped at `shieldMax`

---

## 4. Energy / Generator System

### Core Cycle

```
Generator → genValue += genPower/frame → capped at genMax
                ↓
Weapon fire → if genValue >= pwrNeed → fire, genValue -= pwrNeed
                                     → else: silent block (no fire)
                ↓
Shield regen → only if genValue > 0
```

### Key Rules

1. **Firing gate**: weapon fires ONLY if `genValue >= weapon.pwrNeed`
2. **Binary**: either fires or doesn't — no slowdown, no warning
3. **Shield regen stops** when `genValue <= 0`
4. **Weapon "off"**: if `pwrNeed > genMax` (tank too small), weapon can never fire

### Generator Load (informational metric)

```
Load% = (sum of all weapon power-per-second) / (generator output per second) × 100
```

- PPS per weapon = `pwrNeed / cooldown × FPS`
- Generator output = `genPower × FPS`
- Load > 100% = energy drains faster than it regenerates

### Generator Upgrade

Each upgrade (collectable or ComCenter):
- `pwrGen *= 1.255` (+25.5% output)
- `genMax *= 1.2` (+20% capacity)
- Multiplicative — compounds with each level

---

## 5. Weapons & Devices

### Weapon Slots

| Slot | Name | Direction |
|------|------|-----------|
| 1 | FrontGun | Forward |
| 2 | LeftGun | Left-angled |
| 3 | RightGun | Right-angled |
| 4 | Generator | N/A (power source) |

### Weapon Catalog (DevType / ComCenter.GetDevType)

#### Front Weapons

| Weapon | Damage | Cooldown | PwrNeed | Price | UpgCost | Notes |
|--------|--------|----------|---------|-------|---------|-------|
| Bubble Gun | 21 | 9 | 12 | $2,000 | 0.25 | Default weapon |
| Vulcan Cannon | 24 | 3 | 16 | $16,000 | 0.30 | High fire rate |
| Blaster | 250 | 15 | 85 | $60,000 | 0.30 | Guided, high damage |
| Laser | 64 | 15 | 66 | $175,000 | 0.42 | Beam, 6 sequences |

#### Side Weapons

| Weapon | Damage | Cooldown | PwrNeed | Price | UpgCost | Notes |
|--------|--------|----------|---------|-------|---------|-------|
| Small Bubble | 6 | 9 | 4 | $750 | 0.25 | |
| Small Vulcan | 6 | 3 | 4 | $8,000 | 0.30 | |
| Star Gun | 30 | 8 | 10 | $30,000 | 0.33 | Guided |
| Small Laser | 28 | 15 | 27 | $80,000 | 0.42 | Beam |

#### Generator

| Device | PwrGen | Price | UpgCost |
|--------|--------|-------|---------|
| Falcon Basic | 4.35 | $2,000 | 0.35 |

### Upgrade Formulas (Device.Upgrade)

Per level (max level 25):
- `damage *= 1.1` (+10%)
- `pwrNeed *= 1.2` (+20%)
- `cooldown /= 1.02` (−2%)
- `price *= (1 + upgCost)`
- Display name appends Roman numeral (e.g., "Vulcan III")

Generator upgrade per level:
- `pwrGen *= 1.255`
- `genMax *= 1.2`

### Score-Based Weapon Unlock Tiers

```
WepLevScores = [0, 400000, 4000000, 14000000]
```

| Tier | Score Required | Weapons Unlocked |
|------|----------------|------------------|
| 0 | 0 | Bubble Gun, Small Bubble |
| 1 | 400,000 | Vulcan, Small Vulcan, Star Gun |
| 2 | 4,000,000 | Blaster, Small Laser |
| 3 | 14,000,000 | Laser |

---

## 6. Enemies (Hostiles)

### Enemy Types (Fleet.hType)

| Type | Name | HP (relative) |
|------|------|---------------|
| falcon1 | Light scout | Low |
| falcon2 | Medium fighter | Medium |
| falcon3 | Heavy fighter | Medium-high |
| falcon4 | Armored | High |
| falcon5 | Elite | Very high |
| falcon6 | Boss-class | Highest |

### Enemy Behavior (Hostile.cls, Fleet.cls)

- Spawned by fleet at `triggerSteps` interval
- Follow predefined path (Linear, Sinus, Cosinus, SinCos)
- Fire weapon automatically at player with fleet-defined cooldown
- Score awarded on kill = `enemy.hpMax` (attacker-based in co-op)

### Fleet Spawning (Fleet.step)

Every frame where `stepCount % triggerSteps == 0`:
- Create one Hostile from fleet
- Clone path for movement
- Add to linked list

---

## 7. Collectables (Power-ups)

### Drop Mechanics

- Each fleet has a pre-assigned `bonus` type
- Drops when **entire fleet is destroyed**
- Collectable moves along a path toward bottom of screen
- Must be collected before it exits screen

### Collectable Types (Collectable.cls)

| Type | ID | Effect |
|------|-----|--------|
| FrontWepUpgrade | 1 | If no front weapon: create Bubble Gun (dmg 21, pwr 12, cd 9). If exists: `device.Upgrade()` |
| LeftWepUpgrade | 2 | If no left weapon: create Small Bubble (dmg 6, pwr 4, cd 9). If exists: upgrade |
| RightWepUpgrade | 3 | If no right weapon: create Small Bubble. If exists: upgrade |
| HealthUpgrade | 4 | If HP > 50%: repair 25%, hpMax +5% (cap 2000). If HP ≤ 50%: repair 50% |
| ShieldUpgrade | 5 | Recharge shield + increase shieldMax |
| GeneratorUpgrade | 6 | Upgrade generator device (pwrGen ×1.255, genMax ×1.2) |
| BonusCredit | 7 | Award credits (value = fleet.bonusMoney) |

---

## 8. ComCenter (Shop)

### When Displayed

1. **Game startup** — before first sector
2. **After sector completion** — mandatory between every sector
3. NOT accessible during gameplay

### Features

- **Pilot name** — editable text field
- **Vessel stats** — model name, HP/Shield max, equipped weapons, generator info
- **Generator load** — "Cap X | Load Y%" display
- **DPS display** — total vessel damage per second
- **Weapon catalog** — 2 columns (front/side), paginated with Next Page button
- **High score table** — top 10 scores displayed inline
- **Animated background** — 32 pre-rendered bitmaps with color-cycling grid effect

### Actions

| Action | Description | Cost |
|--------|-------------|------|
| Buy | Purchase weapon into slot | weapon.price (credits) |
| Sell | Remove weapon from slot | +weapon.price refund |
| Upgrade | Increase weapon level (+1) | price × upgCost × level |
| Continue | Start next sector | — |
| Exit | Quit game | — |
| Next Page | Cycle weapon catalog page | — |

### Weapon Visibility

- Weapons only appear if player score >= tier threshold (WepLevScores)
- Buy button only shows if player can afford it

---

## 9. Scoring

### Score Sources

| Source | Score Value |
|--------|------------|
| Kill enemy | enemy.hpMax |
| Destroy asteroid | asteroid.hpMax |
| Sector completion bonus | sectorBonus (typically 5,000–10,000) |

### Score Effects

- Determines weapon unlock tiers (see Section 5)
- Recorded in high score table at game over

---

## 10. Path System (Movement)

### Path Types (Path.cls)

| Type | Movement |
|------|----------|
| Linear | Straight line from start to end |
| Sinus | Sinusoidal horizontal wave |
| Cosinus | Cosinusoidal horizontal wave |
| SinCos | Combined sin+cos complex wave |

Path parameters:
- `amplitude` — wave width
- `frequency` — wave speed
- `decay` — amplitude reduction over time (< 1.0 decays, > 1.0 grows)

---

## 11. Structures (Asteroids)

- Static/moving obstacles on screen
- Block vessel movement (collision = position clamp)
- Can be destroyed by player weapons
- Award score = hpMax on destruction

---

## 12. Random Sector Generation (Level 8+)

After completing all 7 scripted sectors, game generates **random procedural sectors**:
- Random fleet counts, enemy types, timing
- Scaling difficulty based on current level
- DPS-based random scaling
- Damage growth coefficient for level 20+

---

## 13. Timing & Constants

| Constant | Value | Description |
|----------|-------|-------------|
| FRAME_DELAY | 25 ms | Frame duration (40 FPS) |
| SCR_WIDTH | ~1000 px | Screen width |
| SCR_HEIGHT | ~700 px | Screen height |
| Max weapon level | 25 | Upgrade cap |
| Shield regen rate | 0.15/frame | Base regen (when energy > 0) |
| Approach speed | 0.2 | Vessel movement smoothing |

---

## 14. Co-op Multiplayer

- **Host-authoritative**: host runs full simulation, client sends input
- TCP with 4-byte length framing
- UDP discovery on port 5742 (`TYRIAN_COOP|port|pilotName` beacon)
- Separate score/credits per player (attacker-based scoring)
- Co-op death = invisible until ComCenter revive
- Game over only when **both** vessels dead
- ComCenter ready sync: both players must press READY
