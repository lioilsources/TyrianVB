# Mobile Port: Initial Differences from Original VB6

Analysis of how the Flutter/Flame mobile port differed from the original VB6 game after the initial port (before the sector content rewrite).

---

## What Was Ported 1:1

### Path System (95% complete)
- All 4 path types: Linear, Cosinus, Sinus, SinCos
- Exact same math formulas for trajectory generation
- Cyclic paths, path concatenation, cloning
- This is the most faithful subsystem

### Weapon System (85% complete)
- All 8 weapon types defined with correct properties
- Upgrade system with correct multipliers (dmg ×1.1, cooldown ÷1.02, etc.)
- Projectile spawning, guided homing, beam weapons
- Power/generator consumption model

### Vessel Core (90% complete)
- HP, shield, shield regen, generator system
- All weapon slots (front, left, right)
- Damage model (shield absorbs first, overflow to HP)
- Credit and score tracking

### ComCenter / Shop (functional)
- Buy/upgrade/sell weapons
- Category tabs (Front / Side)
- Stat display (DPS, HP/Shield/Generator bars)
- Pilot name input
- Start mission button

### Save System (functional)
- High scores persistence
- Game state save (pilot name, credits, weapons, HP)
- Uses SharedPreferences + JSON (vs VB6 binary file)

---

## What Was Simplified or Changed

### Touch Controls (vs Mouse)
- **VB6**: Click-to-move (vessel snaps/slides to mouse position)
- **Mobile**: Drag-delta (vessel moves relative to finger movement)
- Mobile feels more natural for touch but different from original
- No multi-touch, no right-click equivalent

### Rendering Pipeline
- **VB6**: GDI/GdiplusX with manual double-buffering, bitmap blitting, gradient fills
- **Mobile**: Flame engine with component system, Canvas rendering
- Mobile added: health bars on enemies, float text damage popups
- Mobile missing: GDI visual effects, ComCenter animation frames

### Movement Physics
- **VB6**: Smooth approach with speed property, `moveBlock` axis restrictions
- **Mobile**: Direct position clamping, no inertia or approach smoothing

### Game Resolution
- **VB6**: Fixed 600×832 with 280px OSD panel
- **Mobile**: Fixed 600px width, gameHeight adjusts to device aspect ratio
- OSD is a Flutter overlay, not part of game canvas

---

## What Was Drastically Simplified

### Sector Content (THE BIGGEST GAP)
The original VB6 game had:
- **8-18 fleets per sector** with 100-200 enemies each
- Complex timing (enter times spread across 3+ minutes per sector)
- Special mechanics: FreezeFleet, ReplacePath, extra paths
- Staggered asteroid fields with timed spawning

The initial mobile port had:
- **2-3 fleets per sector** with 3-12 enemies total
- Simple timing (2-16 second enter times)
- No special path mechanics (FreezeFleet/ReplacePath were stub `break;` statements)
- Asteroids were static `StructBehavior.fall` objects, never actually added to game world (bug)
- Sector 6 was a hardcoded boss fight instead of calling random generation

**Impact**: Game felt empty — long waits between tiny waves, sectors over in seconds.

### Enemy Types in Use
- VB6: All 12 types used across 6 scripted sectors (falcon1 through falconx3)
- Mobile: Only falcon1-falcon6, falconx, falconx2, falconx3, falconxb used
- Bouncer and falconxt never appeared in any sector

### Fleet Bonus System
- VB6: Carefully tuned per-fleet bonus money ($500-$20,000) and weapon/item drops
- Mobile: Generic small bonuses ($100-$800), less variety

---

## What Was Completely Missing

### Enemy Weapons (CRITICAL)
- **VB6**: Enemies fire Bubble Gun variants scaled to their type, with configurable cooldowns
- **Mobile**: Enemies NEVER fire. `Fleet.weapon` field exists but no firing code in `Hostile.update()`
- **Impact**: The game has zero challenge from ranged attacks. Only collision damage threatens the player.

### FreezeFleet / ReplacePath Path Actions
- Both enum values existed but were unimplemented (`break;` in switch)
- Sector 5 (Planet Orbit) depends entirely on these — was non-functional
- **Status**: Now implemented in the sector content rewrite

### Extra Path System
- `Fleet.extraPath` field did not exist
- Multi-segment boss paths (used in Sectors 2, 4) were impossible
- **Status**: Now implemented in the sector content rewrite

### Timed Structure Spawning
- VB6: Structures have `enTime` and only activate when `elapsed >= enTime`
- Mobile: Structures were added to `sector.structures` list but never added to `game.world`
- Asteroid sectors were effectively broken (asteroids never appeared)
- **Status**: Now implemented in the sector content rewrite

### Score-Based Weapon Unlocks
- VB6: Vulcan at 400k score, Blaster at 4M, Laser at 14M
- Mobile: All weapons available from the start
- No `WepLevScores` threshold system

### Generator Load Feedback
- VB6: `GeneratorLoad()` calculates PPS vs generation rate, warns when overloaded
- Mobile: No indication when weapons consume more power than generator produces
- Player can equip weapons they can't sustain without knowing

### Persistent Save/Resume
- VB6: Full vessel state persisted between sessions (resume from last sector with all gear)
- Mobile: Only high scores persist; game state resets on app restart
- No "continue from where you left off" feature

### DPS-Based Difficulty Scaling (Random Levels)
- VB6: Random levels scale enemy types and count based on `player.dps`
- Mobile: `_createRandom()` uses level index for difficulty, not player power
- VB6: Handicap system adjusts if player is under-equipped
- Mobile: No handicap system

### Damage Growth Coefficient (Level 20+)
- VB6: Enemy damage multiplier grows after level 20 (+25% per level, up to +60%)
- Mobile: No damage scaling for late-game random levels

### Float Text / Message System
- VB6: `obj.CreateMessage()` for incoming fleet announcements, kill rewards, etc.
- Mobile: `FloatText` class exists but only used for damage numbers, not game messages

---

## Architecture Differences

| Aspect | VB6 | Mobile |
|--------|-----|--------|
| Data structures | Linked lists (prv/nxt) | Dart Lists |
| Game loop | Manual frame timing | Flame's update(dt) |
| Rendering | GDI BitBlt + GdiplusX | Flame Canvas + Sprites |
| UI | GDI-drawn in-game | Flutter Material overlays |
| Input | Mouse WM_MOUSEMOVE | DragCallbacks delta |
| Components | Class instances | Flame Component tree |
| Collision | Manual AABB checks | Mix of manual + Flame hitboxes |
| Asset format | BMP files | PNG sprites |

---

## Summary: Completeness by System

| System | Port Quality | Critical Gap? |
|--------|-------------|---------------|
| Path System | 95% | No |
| Weapons (player) | 85% | No |
| Vessel | 90% | No |
| ComCenter | 80% | No |
| Collectables | 80% | No |
| Save System | 70% | Minor |
| Rendering | 80% | No |
| **Sector Content** | **15%** | **YES — fixed** |
| **Enemy Weapons** | **0%** | **YES — still missing** |
| **Weapon Unlock Progression** | **0%** | Minor |
| **DPS-Based Scaling** | **0%** | Minor (affects level 7+) |
| **Timed Structures** | **0%** | **YES — fixed** |
| **FreezeFleet/ReplacePath** | **0%** | **YES — fixed** |
