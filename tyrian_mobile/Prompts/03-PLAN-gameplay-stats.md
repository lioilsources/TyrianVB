# Fix: Weapon Values, Vessel Stats & Score Display

## Context

After the sector content rewrite, sectors spawn correct VB6 enemy counts (147-200 per sector) with correct HP values (100-100,000). But weapon damage values in the mobile port are **10-90% lower** than VB6 originals, making enemies nearly impossible to kill. The vessel also starts with no shield, less HP, and a tiny generator that doesn't match the VB6 power economy. Additionally, the score/credit display never updates because the OSD refresh callback is never invoked.

---

## Problem Summary

### Weapon Damage (dev_type.dart vs VB6 ComCenter.cls)

| Weapon | VB6 Dmg | Mobile Dmg | Ratio | VB6 Price | Mobile Price |
|--------|---------|------------|-------|-----------|-------------|
| Bubble Gun | 21 | 15 | 71% | $2,000 | $0 |
| Vulcan | 24 | 8 | **33%** | $16,000 | $500 |
| Blaster | 250 | 25 | **10%** | $60,000 | $800 |
| Laser | 64×6 | 35 | **9%** | $175,000 | $1,200 |
| Small Bubble | 6 | 8 | 133% | $750 | $300 |
| Small Vulcan | 6 | 5 | 83% | $8,000 | $400 |
| Star Gun | 30 | 12 | **40%** | $30,000 | $600 |
| Small Laser | 28×6 | 20 | **12%** | $80,000 | $900 |

Speed, cooldown, pwrNeed, upgCost also all differ.

### Vessel Stats (vessel.dart vs VB6 Vessel.cls ResetVessel)

| Stat | VB6 | Mobile | Issue |
|------|-----|--------|-------|
| HP | 125 | 100 | 20% less |
| Shield | 100 | **0** | No shield at start! |
| ShieldMax | 100 | **0** | |
| ShieldRegen | 0.1/frame | 0.01/frame | 10× slower |
| GenMax | 100 | **5** | 20× less |
| GenPower | 4/frame | **0.02**/frame | 200× less |

With VB6 weapon pwrNeed (12-85), the mobile generator (max 5) can't fire a single shot.

### Score Display Bug
`game.onOsdUpdate` callback is registered in `main.dart` but **never called** anywhere. The OSD panel reads `vessel.score` directly but never gets told to rebuild.

---

## Changes (DONE)

### 1. `lib/systems/dev_type.dart` — VB6 weapon values

Replaced all 8 weapon definitions with exact VB6 values from ComCenter.GetDevType():

```
Bubble Gun:    dmg=21, spd=15, cd=9,  pwr=12,  price=2000,   upg=0.25, guide=0, scale=0.5-0.85
Vulcan:        dmg=24, spd=30, cd=3,  pwr=16,  price=16000,  upg=0.30, xShift=14, scale=n/a
Blaster:       dmg=250,spd=27, cd=15, pwr=85,  price=60000,  upg=0.30, guide=2
Laser:         dmg=64, spd=12, cd=15, pwr=66,  price=175000, upg=0.42, beam=1, seqs=6, guide=3
Small Bubble:  dmg=6,  spd=15, cd=9,  pwr=4,   price=750,    upg=0.25, scale=0.3-0.55
Small Vulcan:  dmg=6,  spd=30, cd=3,  pwr=4,   price=8000,   upg=0.30, xShift=14
Star Gun:      dmg=30, spd=17, cd=8,  pwr=10,  price=30000,  upg=0.33, guide=10
Small Laser:   dmg=28, spd=12, cd=15, pwr=27,  price=80000,  upg=0.42, beam=1, seqs=6, guide=3
```

Also added generator DevType (for ComCenter display/upgrade):
```
Falcon Basic:  pwrGen=4.35, price=2000, upg=0.35
```

### 2. `lib/entities/vessel.dart` — VB6 default stats

```dart
int hp = 125;
int hpMax = 125;
double shield = 100;
double shieldMax = 100;
double shieldRegen = 0.1;    // per frame (×scaledDt)
double genValue = 100;
double genMax = 100;
double genPower = 4;          // per frame (×scaledDt)
```

### 3. `lib/entities/hostile.dart` — Per-type collision damage

Added static method `getCollisionDmg(HostType)` used in constructor:

| Type | Collision Dmg |
|------|--------------|
| falcon1-4 | 1 |
| falcon5-6 | 2 |
| falconx | 4 |
| falconx2 | 6 |
| falconx3 | 8 |
| falconxb | 10 |
| falconxt | 12 |
| bouncer | 20 |

### 4. Score display fix — periodic `onOsdUpdate` call

In `tyrian_game.dart` `update()`, added `_osdTimer` that calls `onOsdUpdate?.call()` every 0.25s (~4Hz). Covers score, HP, shield, power — everything.

### 5. `lib/entities/collectable.dart` — Percentage-based upgrade effects

VB6-matching formulas:

- **HealthUpgrade**: If HP > 50% max: +25% HP, hpMax +5%. If HP ≤ 50%: +50% HP
- **ShieldUpgrade**: +30% shield, shieldMax +10%, shieldRegen ×1.1 (if shieldMax < 1500; else +35%, regen ×1.025)
- **GeneratorUpgrade**: genPower ×1.255, genMax ×1.2

---

## Files Modified

| File | What |
|------|------|
| `lib/systems/dev_type.dart` | All 8 weapon stat blocks → VB6 values + generator DevType |
| `lib/entities/vessel.dart` | Default HP/shield/gen stats → VB6 values |
| `lib/entities/hostile.dart` | Collision damage per HostType |
| `lib/game/tyrian_game.dart` | Periodic onOsdUpdate call (4Hz) |
| `lib/entities/collectable.dart` | Percentage-based upgrade effects |

---

## Verification

1. `flutter analyze` — no errors
2. Start game → vessel has 125 HP, 100 shield, full generator bar
3. Fire Bubble Gun → projectile damages Falcon I (100 HP) — should die in ~5 hits (21 dmg each)
4. Kill an enemy → score and credit update visually in HUD
5. Buy Vulcan at ComCenter → costs $16,000 (need to earn enough first)
6. Pick up HealthUpgrade collectable → HP increases by percentage, hpMax grows
7. Pick up ShieldUpgrade → shield capacity increases
8. Play through Sector 0 → all 147 enemies killable with starter Bubble Gun
9. Generator refills between shots (power bar visibly drains and refills)
