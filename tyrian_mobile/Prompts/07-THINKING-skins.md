# Sprite Asset Guide & Multi-Style Theme System

## Context
User wants to regenerate all game sprites using Grok Image AI in multiple visual styles, with the ability to switch between themes at runtime.

---

## Complete Asset Inventory

### Category 1: Player Ship
| Asset | Current Size | Rendering | Description |
|-------|-------------|-----------|-------------|
| `vessel.png` | 57×42 | Sprite | Blue/cyan angular ship, top-down view, facing up |

### Category 2: Regular Enemies (falcon1–6)
| Asset | Current Size | Rendering | Description |
|-------|-------------|-----------|-------------|
| `falcon.png` | 34×34 | Sprite | Generic falcon (unused fallback?) |
| `falcon1.png` | 34×34 | Sprite | Weakest enemy (HP 100), orange ship |
| `falcon2.png` | 34×34 | Sprite | HP 120, orange variant |
| `falcon3.png` | 34×34 | Sprite | HP 140, orange variant |
| `falcon4.png` | 34×34 | Sprite | HP 160, orange variant |
| `falcon5.png` | 34×34 | Sprite | HP 180, orange variant |
| `falcon6.png` | 34×34 | Sprite | HP 200, strongest regular |

### Category 3: Boss Enemies
| Asset | Current Size | Rendering | Description |
|-------|-------------|-----------|-------------|
| `falconx.png` | 51×51 | Sprite | Mini-boss (HP 1000) |
| `falconx2.png` | 51×51 | Sprite | Boss (HP 2000) |
| `falconx3.png` | 51×51 | Sprite | Heavy boss (HP 3000) |
| `falconxb.png` | 61×61 | Sprite | Mega-boss (HP 5000) |
| `falconxt.png` | 67×67 | Sprite | Final boss (HP 10000) |
| `bouncer.png` | 64×71 | Sprite | Special enemy (HP 100000, indestructible) |

### Category 4: Projectiles
| Asset | Current Size | Rendering | Description |
|-------|-------------|-----------|-------------|
| `bubble.png` | 30×29 | Sprite | Bubble Gun projectile, pink/white sphere |
| `vulcan.png` | 5×12 | Sprite | Vulcan Cannon shot, tiny orange flame |
| `blaster.png` | 42×12 | Sprite | Blaster arc, yellow crescent |
| `starg.png` | 12×12 | Sprite | Star Gun projectile, small glowing dot |
| `laser.png` | 20×20 | Sprite | Laser icon (beam is drawn procedurally) |

### Category 5: Structures
| Asset | Current Size | Rendering | Description |
|-------|-------------|-----------|-------------|
| `asteroid.png` | 42×40 | Sprite | Small rocky asteroid |
| `asteroid1.png` | 44×83 | Sprite | Tall asteroid variant |
| `asteroid2.png` | 52×75 | Sprite | Wide asteroid variant |
| `asteroid3.png` | 37×25 | Sprite | Small flat asteroid |

### Category 6: Explosions
| Asset | Current Size | Rendering | Description |
|-------|-------------|-----------|-------------|
| `explosion1.png` | 90×90 | **UNUSED** — code draws procedural circles | Fireball variant 1 |
| `explosion2.png` | 90×90 | **UNUSED** | Fireball variant 2 |
| `explosion3.png` | 90×90 | **UNUSED** | Fireball variant 3 |
| `explosion4.png` | 90×90 | **UNUSED** | Fireball variant 4 |

### Category 7: Currently Procedural (no sprite)
| Element | Current Rendering | Could Become Sprite? |
|---------|------------------|---------------------|
| Collectables (7 types) | Colored rectangles + letter | Yes — icon sprites per type |
| Beam weapon | Canvas drawLine + glow | Keep procedural (looks good) |
| Starfield (1000 stars) | 1-2px squares | Keep procedural |
| Damage flash | Red overlay on vessel | Keep procedural |

### Category 8: Unused/Orphan Assets
| Asset | Size | Notes |
|-------|------|-------|
| `star.png` | 15×15 | Not referenced in code |
| `rododendron.png` | 128×128 | Not referenced in code |

---

## Recommended Sizes for Mobile HD

Current game width = 600 logical px. On a typical phone at 3x PPI, each game pixel ≈ 2 physical pixels. Recommendation:

| Category | Current | Recommended (2x) | Notes |
|----------|---------|-------------------|-------|
| Vessel | 57×42 | **114×84** | Player ship — most visible, deserves most detail |
| Regular enemies | 34×34 | **68×68** | 6 visually distinct variants needed |
| Mini-bosses | 51×51 | **102×102** | Noticeably bigger than regulars |
| Heavy bosses | 61-67 | **122×122 / 134×134** | Imposing, detailed |
| Bouncer | 64×71 | **128×142** | Unique silhouette |
| Projectiles | 5-42 | **10-84** | Scale proportionally |
| Asteroids | 37-52 | **74-104** | Irregular shapes OK |
| Explosions | 90×90 | **180×180** | Big and dramatic |
| Collectables | — | **48×48** | New sprite set needed |

**Key insight**: Keep logical component sizes the same (so collision boxes don't change). Provide higher-res PNGs — Flame's `Sprite` renders at the component's `size`, regardless of image resolution. A 68×68 PNG rendered in a 34×34 component will look 2x sharper on high-PPI screens. **No code changes needed for resolution upgrade.**

---

## Multi-Style Theme System — Challenges

### Architecture
```
assets/sprites/pixel/      ← HD pixel art theme
assets/sprites/painted/    ← Semi-realistic painted
assets/sprites/neon/       ← Neon/synthwave
assets/sprites/flat/       ← Cel-shaded/flat
```

Each folder contains the same filenames (`vessel.png`, `falcon1.png`, etc.).

### Challenges

1. **App bundle size**: 4 themes × ~30 assets × ~15KB avg = ~1.8MB. Acceptable for mobile.

2. **Consistency within theme**: Each theme must have ALL sprites. Missing one = crash or placeholder. Generate all or nothing per theme.

3. **Visual consistency between sprites**: Falcon1-6 must look like a progression within each theme. Bosses must look like bigger/meaner versions. This is the hardest prompt engineering challenge.

4. **Collision boxes unchanged**: Sprites can be any resolution, but `size` in code determines hitbox. Keep component sizes the same (34×34, 51×51, etc.) — higher-res PNGs just look crisper.

5. **Transparent backgrounds**: Every PNG must have clean alpha transparency. Grok Image may generate with backgrounds — you'll need to remove them (Photoshop/remove.bg/rembg).

6. **Top-down perspective**: All ships must be top-down, facing consistently (player up, enemies down). This is tricky with AI generators.

7. **Runtime switching**: Need to reload sprite cache when theme changes. `AssetLibrary._load()` currently hardcodes `sprites/`. Change to `sprites/{theme}/`. Add theme selector in settings/ComCenter.

### Implementation for theme switching
- Add `currentTheme` to `AssetLibrary` (default: 'pixel')
- Change `_load('vessel', 'sprites/vessel.png')` → `_load('vessel', 'sprites/$currentTheme/vessel.png')`
- Add `Future<void> switchTheme(String theme)` that clears cache + reloads
- Store selected theme in `SharedPreferences`
- Theme picker UI in ComCenter or settings

---

## Grok Image Prompt Guide (per category)

### General prompt prefix (prepend to all)
> `Top-down 2D game sprite, transparent background, [STYLE], centered, single object, no text, no shadows on background, PNG`

### Style modifiers
- **Pixel art**: `pixel art, 16-bit era, clean pixels, limited color palette, sharp edges`
- **Painted**: `hand-painted, detailed metallic textures, soft lighting, sci-fi, smooth gradients`
- **Neon**: `neon glow, dark background, glowing outlines, synthwave, cyan and magenta, electric`
- **Flat**: `flat design, bold outlines, cel-shaded, solid colors, clean vector look`

### Per-asset prompts

**Vessel (player ship)**:
> `Top-down 2D game sprite, transparent background, [STYLE]. Sleek fighter spacecraft facing upward, blue and cyan color scheme, angular aggressive design, engine exhausts glowing at the back, symmetrical, small compact fighter ship`

**Falcon 1-6 (regular enemies)** — generate as a set with progression:
> `Top-down 2D game sprite, transparent background, [STYLE]. Enemy spacecraft facing downward, orange and red color scheme, alien/hostile design. Variant [1-6] of 6 — [1=basic scout, 2=light fighter, 3=medium fighter, 4=heavy fighter, 5=assault ship, 6=elite fighter]. Each variant slightly more armored and aggressive than previous`

**FalconX / X2 / X3 (bosses)**:
> `Top-down 2D game sprite, transparent background, [STYLE]. Large enemy boss spacecraft facing downward, menacing design, heavy armor plating, multiple weapon hardpoints, orange-red with dark accents. [X=mini-boss, X2=boss, X3=heavy boss — progressively bigger and more dangerous]`

**FalconXB (mega-boss)**:
> `Top-down 2D game sprite, transparent background, [STYLE]. Massive enemy capital ship, heavily armored, intimidating silhouette, dark metallic with red glowing elements, multiple turrets, battle-scarred`

**FalconXT (final boss)**:
> `Top-down 2D game sprite, transparent background, [STYLE]. Ultimate enemy flagship, enormous warship, most powerful and imposing design, dark hull with pulsing energy core, bristling with weapons, alien technology`

**Bouncer (indestructible)**:
> `Top-down 2D game sprite, transparent background, [STYLE]. Indestructible space obstacle/drone, spherical or geometric, metallic sheen, energy shield effect, neutral gray/silver, looks impenetrable`

**Bubble projectile**:
> `Top-down 2D game sprite, transparent background, [STYLE]. Energy sphere projectile, glowing pink/white, translucent, small round, plasma ball`

**Vulcan projectile**:
> `Top-down 2D game sprite, transparent background, [STYLE]. Tiny bullet/tracer round, elongated, bright orange-yellow, fast-moving feel, small and narrow`

**Blaster projectile**:
> `Top-down 2D game sprite, transparent background, [STYLE]. Wide energy arc/crescent projectile, yellow-orange glow, curved shape, powerful blast wave`

**Star Gun projectile**:
> `Top-down 2D game sprite, transparent background, [STYLE]. Small glowing star-shaped projectile, bright white-blue, pointed, homing missile feel`

**Asteroids (4 variants)**:
> `Top-down 2D game sprite, transparent background, [STYLE]. Space asteroid, rocky surface, irregular shape, brown/gray, cratered, space debris. Variant [1-4] — different shapes and sizes`

**Explosions (4 variants)**:
> `Top-down 2D game sprite, transparent background, [STYLE]. Explosion fireball, bright orange-yellow center fading to red edges, dynamic energy burst, space explosion. Variant [1-4]`

**Collectables (new sprites, 7 types)**:
> `Top-down 2D game sprite, transparent background, [STYLE]. Floating power-up pickup icon, glowing, [TYPE-specific]:`
> - frontWepUpgrade: orange weapon upgrade crate, "W" symbol
> - leftWepUpgrade: blue side-weapon module, "L" symbol
> - rightWepUpgrade: blue side-weapon module, "R" symbol
> - healthUpgrade: red health kit/repair module, cross symbol
> - shieldUpgrade: cyan shield module, hexagonal
> - generatorUpgrade: yellow energy cell, lightning symbol
> - bonusCredit: green credit chip/coin, "$" symbol

---

## Post-Generation Checklist
For each generated sprite:
1. Remove background → ensure clean alpha channel (transparent)
2. Crop to tight bounds (no excess transparent padding)
3. Resize to target dimensions (see table above), or keep larger and let Flame downscale
4. Save as PNG with alpha
5. Name exactly matching current filenames
6. Place in correct theme folder

## Code Changes Needed
1. `asset_library.dart` — add theme support to path loading
2. `save_service.dart` — persist selected theme
3. ComCenter or settings UI — theme picker
4. (Optional) Add collectable sprites to `asset_library.dart` loading + update `collectable.dart` to render sprite instead of colored rect
5. (Optional) Update `explosion.dart` to use sprite sheets instead of procedural circles
