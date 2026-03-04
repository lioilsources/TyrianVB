# TyrianVB Original Gameplay Analysis

Comprehensive breakdown of the original VB6 game mechanics, extracted from the source code.

---

## Vessel (Rocket)

| Stat | Default | Notes |
|------|---------|-------|
| Name | "Puddle Jumper" | Cosmetic only |
| HP | 125 | hpMax, can grow via HealthUpgrade |
| Shield | 100 | Absorbs all damage first; excess goes to HP |
| Shield Max | 100 | Grows via ShieldUpgrade |
| Shield Regen | 0.1/frame | ~4/sec at 40fps, grows with upgrades |
| Generator Max | 100 | Energy pool for weapons |
| Generator Power | 4/frame | Energy regen rate (~160/sec) |
| Speed | 0.2 px/frame | Mouse-tracking movement |
| Starting Credits | 0 | |
| Starting Score | 0 | |

### Damage Model
1. All damage hits **shield** first
2. When shield < 0, overflow transfers to HP
3. Shield regenerates passively each frame
4. Collision with enemies/asteroids applies collision damage (separate from projectile damage)

### Weapon Slots (7 total)
| Slot | Name | Purpose |
|------|------|---------|
| 1 | FrontGun | Primary weapon |
| 2 | Generator | Power generation |
| 3 | LeftGun | Secondary left |
| 4 | NotAvailable | Reserved |
| 5 | RightGun | Secondary right |
| 6 | Satellite | Reserved (unused) |
| 7 | ShieldCapacitor | Reserved (unused) |

### Score-Based Weapon Levels
| Level | Score Threshold | Unlocks |
|-------|----------------|---------|
| I | 0 | Bubble Gun, Small Bubble |
| II | 400,000 | Vulcan Cannon, Small Vulcan |
| III | 4,000,000 | Blaster, Star Gun |
| IV | 14,000,000 | Laser, Small Laser |

---

## Weapons / Devices

### Front Guns

| Weapon | Damage | Speed | Cooldown | Power | Price | Upgrade Cost | Special |
|--------|--------|-------|----------|-------|-------|-------------|---------|
| Bubble Gun | 21 | 15 | 9 frames | 12 | $2,000 | +25% | Scales projectile 0.5-0.85 |
| Vulcan Cannon | 24 | 30 | 3 frames | 16 | $16,000 | +30% | X-shift spread (±14px) |
| Blaster | 250 | 27 | 15 frames | 85 | $60,000 | +30% | Guided (2px/frame homing) |
| Laser | 64×6 | 12 | 15 frames | 66 | $175,000 | +42% | Beam, 6 sequences, guided (3px/f) |

### Side Guns (Left/Right)

| Weapon | Damage | Speed | Cooldown | Power | Price | Upgrade Cost | Special |
|--------|--------|-------|----------|-------|-------|-------------|---------|
| Small Bubble | 6 | 15 | 9 frames | 4 | $750 | +25% | Scales 0.3-0.55 |
| Small Vulcan | 6 | 30 | 3 frames | 4 | $8,000 | +30% | X-shift spread |
| Star Gun | 30 | 17 | 8 frames | 10 | $30,000 | +33% | Guided (10px/f homing) |
| Small Laser | 28×6 | 12 | 15 frames | 27 | $80,000 | +42% | Beam, guided (3px/f) |

### Generator

| Name | Power Gen | Price | Upgrade Cost |
|------|-----------|-------|-------------|
| Falcon Basic | 4.35/frame | $2,000 | +35% |

### Upgrade System (per level, max 25)
- Damage: ×1.1 (round)
- Power Need: ×1.2 (round)
- Cooldown: ÷1.02 (faster fire)
- Generator: Power ×1.255, MaxPower ×1.2
- Price: ×(1 + upgCost)
- Projectile scale: lerp from min to max ratio

### Sell Values at Max Level (25)
| Sector Level | Sell Price |
|-------------|-----------|
| 5+ | $25,000 |
| 10+ | $50,000 |
| 15+ | $100,000 |
| 20+ | $250,000 |
| 25+ | $500,000 |
| 30+ | $1,000,000 |
| 40+ | $2,500,000 |

---

## Enemies (Hostiles)

### Enemy Types

| Type | HP | Collision Dmg | Tier |
|------|------|------|------|
| Falcon I | 100 | 1 | Basic |
| Falcon II | 120 | 1 | Basic |
| Falcon III | 140 | 1 | Basic |
| Falcon IV | 160 | 1 | Medium |
| Falcon V | 180 | 2 | Medium |
| Falcon VI | 200 | 2 | Medium |
| Falcon X | 1,000 | 4 | Heavy |
| Falcon X-2 | 2,000 | 6 | Heavy |
| Falcon X-3 | 3,000 | 8 | Boss |
| Falcon X-B | 5,000 | 10 | Boss |
| Falcon X-T | 10,000 | 12 | Ultra Boss |
| Bouncer | 100,000 | 20 | Final Boss |

### Enemy Weapons
- Enemies equip "Bubble Gun" variant scaled to their damage value
- Damage formula: `hostType_index × 5.555 × difficulty_coefficient`
- Cooldown formula: `(400 - min(player.dps/20, 385)) × 2 + 2` frames
- Enemies fire downward when in range
- `weapCharge` countdown per fleet controls fire rate

### Scoring
- Kill enemy: +hpMax to score AND credit
- Credit per kill: hpMax ÷ 10
- Fleet bonus: collectable drop at fleet center when last enemy killed

---

## Collectables

| Type | Effect |
|------|--------|
| FrontWepUpgrade | Creates Bubble Gun if empty, otherwise upgrades front gun +1 level |
| LeftWepUpgrade | Creates Small Bubble if empty, otherwise upgrades left gun +1 level |
| RightWepUpgrade | Creates Small Bubble if empty, otherwise upgrades right gun +1 level |
| HealthUpgrade | If HP > 50%: +25% HP, hpMax +5%. If HP ≤ 50%: +50% HP |
| ShieldUpgrade | If shieldMax < 1500: +30% shield, shieldMax +10%, regen ×1.1. Else: +35%, regen ×1.025 |
| GeneratorUpgrade | Calls Upgrade() on generator device (+1 level) |
| BonusCredit | Awards value in credits (varies per fleet/level) |

---

## Structures / Asteroids

| Property | Value |
|----------|-------|
| Asteroid HP | 100,000 |
| Asteroid Collision Dmg | = sector.level |
| Asteroid Reward | Full hpMax as credit + score |
| Behaviors | Fall, Follow, FallAndFollow, ByPath |

- **Fall**: straight down at 0.05 px/frame
- **Follow**: tracks player X position with smooth approach
- **ByPath**: follows a PathSystem trajectory

---

## Sectors / Levels

### Progression
- Levels 1-6: Scripted (hardcoded fleet compositions)
- Level 7+: Random procedural generation

### Scripted Levels

| Level | Name | Fleets | Enemies | Bonus | Key Feature |
|-------|------|--------|---------|-------|-------------|
| 1 | System Perimeter | 10 + 20 asteroids | 147 | $5,000 | Introduction, basic paths |
| 2 | Inner Zone | 9 | 173 | $7,500 | Boss with extra path (4-segment chain) |
| 3 | Planet Perimeter | 7 + 20 asteroids | 196 | $10,000 | Two falconx fleets (85sec duration) |
| 4 | Planet Patrol | 18 | ~167 | $15,000 | 150× swarm + 17 bosses, shared extra path |
| 5 | Planet Orbit | 13 + 7 asteroids | 200+ | $20,000 | FreezeFleet + ReplacePath mechanics |
| 6 | Industry Zone | 7 | 136 | $25,000 | Growing spiral, parallel linear waves |

### Random Level Generation (Level 7+)
- Fleet count: 5-20 random fleets
- Sector bonus: fleetCount × 2,500 × level
- Enemy selection based on player DPS ratio
- Difficulty coefficient grows after level 20: +25% per level (up to +60%)
- Handicap system: reduces enemy level if player is under-equipped
- Asteroid fields: 0 to fleetCount/2 random fields

### Path Actions
| Action | Behavior |
|--------|----------|
| Destroy | Enemy dies when path ends (default) |
| Stay | Enemy stops at final position |
| FreezeFleet | ALL fleet enemies jump to their path end and stay |
| ReplacePath | ALL fleet enemies get cyclic oscillation path (using altParam1-4) |

### Fleet Bonus Types
Each fleet drops one collectable when fully eliminated. Type configured per fleet (weapon upgrade, health, shield, generator, or credits).

---

## Command Center (Shop)

### Available Between Sectors
- Browse weapons by category (Front / Side)
- Buy new weapons (if credits >= price)
- Upgrade equipped weapons (+1 level, if credits >= upgrade price)
- Sell weapons (refund at full price)
- View pilot stats: DPS, HP, Shield, Generator, equipped loadout
- View high scores (top 10)
- "Continue" button starts next sector

### Weapon Availability
Weapons unlock based on score thresholds (see Weapon Levels above). Low-tier weapons are always available; Laser requires 14M score.

---

## Game Flow

```
Start → ComCenter (buy starter weapon) → Sector 1
    ↓
Play Sector → Kill all fleets → "Complete" + Bonus
    ↓
ComCenter → Upgrade/Buy → Next Sector
    ↓
Repeat through Level 6 → Random levels forever
    ↓
Death → GameOver → Score saved → ComCenter (restart)
```

### Scoring
- Enemy kill: +hpMax points
- Asteroid/structure destroy: +hpMax points
- Sector complete: +sectorBonus points
- Credits earned: hpMax ÷ 10 per kill + fleet bonuses + sector bonus

### Save System
- Saves: high scores (top 10), pilot name, last level
- Persists vessel state between sessions (weapons, credits, HP)

---

## Technical Constants

| Constant | Value |
|----------|-------|
| FRAME_DELAY | 25ms (40 FPS) |
| SCR_WIDTH | 600 px |
| SCR_HEIGHT | 832 px |
| OSD_WIDTH | 280 px |
| MAX_WEAP_LEVEL | 25 |
| DELAY_ON_COMPLETE | 2 seconds |
| PI | 3.14159265359 |
