# Plan: Add 7 New Skins + Run Full Pipeline

## Context

The game has 6 skins (default + 5 AI-generated). The user requested 8 new skins, but **Geometry Wars already exists** as `geometry_wars`/`Neon Destroyer` — so **7 new skins** need to be added. The existing pipeline (Go + Grok Image API + ElevenLabs SFX + postprocessing) handles all asset generation. The work is purely data-driven: define skin parameters, register in Flutter, create directories, then run the pipeline.

**Note:** Existing non-default skins (space_invaders, galaga, asteroids, geometry_wars, ikaruga) currently have empty sprite/ui dirs (.gitkeep only). Running the full pipeline will also generate their assets.

---

## Files to Modify (3 files + directory creation)

| File | Change |
|------|--------|
| `pipeline/internal/skin/definitions.go` | Add 7 SkinDef entries to Registry map |
| `tyrian_mobile/lib/services/skin_registry.dart` | Add 7 SkinInfo entries to kSkins list |
| `tyrian_mobile/pubspec.yaml` | Add 28 asset directory lines (4 per skin) |
| `tyrian_mobile/assets/skins/` | Create 7x4 directories with .gitkeep |

---

## Step 1: Add 7 SkinDef entries to `definitions.go`

**File:** `pipeline/internal/skin/definitions.go`

All skins use **FrameCount: 4** (the postprocessor hardcodes `numFrames := 4` at line 138 of `processor.go`, and Flutter loads vessel_0..3 max).

### Skin definitions:

| ID | Name | SpriteSize | PostProcess | GoogleFont |
|----|------|-----------|-------------|------------|
| `nuclear_throne` | Wasteland Mutant | 24 | film_grain | Silkscreen |
| `luftrausers` | Rauser Ace | 28 | vignette | Special Elite |
| `nex_machina` | Voxel Storm | 32 | bloom | Exo 2 |
| `tyrian_dos` | DOS Reforged | 32 | scanlines | IBM Plex Mono |
| `gradius_v` | Vic Viper | 32 | none | Chakra Petch |
| `rtype` | Bydo Slayer | 32 | vignette | Teko |
| `blazing_lazers` | Gunhed | 28 | scanlines | Bungee |

### Full SkinDef values:

**nuclear_throne** — Vlambeer 2015, chunky post-apocalyptic pixel art
- ArtDirective: "Vlambeer-style chunky pixel art, 2015 post-apocalyptic mutant aesthetic. Thick outlines, exaggerated proportions, intentionally rough."
- StyleKeywords: "chunky pixel art, post-apocalyptic, Vlambeer screenshake aesthetic, rough hand-drawn pixels, low resolution, gritty indie"
- Palette: warm desert browns #8B6914, toxic greens #4CAF50, rusty orange #D84315, dried blood red #8B0000 on dark earth #1A1A0E
- BackgroundMood: scorched desert wasteland, irradiated dunes, dusty orange haze
- ExplosionStyle: chunky pixel debris burst, brown-orange-green particles, thick smoke chunks
- BulletDirective: chunky glowing bullet, thick bright green pixel pellet, 4x4 pixels
- SfxStyle: "Crunchy lo-fi, heavy bass impact, distorted chiptune, Vlambeer screenshake audio"
- Unlock: "Destroy 50 enemies in one run"

**luftrausers** — Vlambeer 2014, sepia monochrome WW2
- ArtDirective: "Vlambeer 2014 sepia monochrome WW2 aerial combat. Heavy ink outlines on parchment background, silhouette-focused."
- StyleKeywords: "sepia monochrome, WW2 propaganda poster, heavy ink outlines, cream and brown tones, vintage aviation, silhouette art"
- Palette: warm sepia #704214, dark ink brown #2C1810, cream parchment #F5E6C8 on aged paper #E8D5B0
- BackgroundMood: overcast sepia sky, thick cloud banks in cream and brown, vintage film grain
- ExplosionStyle: ink-splatter explosion, dark brown burst with sepia smoke rings
- BulletDirective: dark brown ink dot projectile, small circular pellet with short sepia trail, 3x6 pixels
- SfxStyle: "WW2 propeller engine, vintage radio static, muffled explosions, old film reel audio"
- Unlock: "Complete 5 sectors without upgrades"

**nex_machina** — Housemarque 2017, voxel neon HDR bloom
- ArtDirective: "Housemarque 2017 voxel-art twin-stick shooter. Dense neon particle effects, HDR bloom, dark backgrounds with vivid saturated colors."
- StyleKeywords: "voxel 3D rendered, intense neon particles, HDR bloom glow, Housemarque arcade, dense particle effects, vivid saturated neon"
- Palette: electric blue #0066FF, hot magenta #FF0066, neon green #00FF66, bright orange #FF6600 on deep black #050510
- BackgroundMood: dark alien planet surface, voxel terrain with deep shadows, distant neon-lit structures
- ExplosionStyle: dense voxel particle shower, bright neon cubes scattering, electric blue and magenta with bloom trails
- BulletDirective: bright neon blue energy cube projectile, small glowing voxel with intense bloom trail, 3x5 pixels
- SfxStyle: "Dense electronic, bass-heavy impacts, neon synth, Housemarque arcade intensity"
- Unlock: "Score 500,000 points"

**tyrian_dos** — Epic MegaGames 1995, VGA pixel art (reimagined, not original sprites)
- ArtDirective: "1995 DOS-era VGA pixel art space shooter. Richly detailed metallic sprites with dithering, 320x200 aesthetic upscaled."
- StyleKeywords: "DOS VGA 256-color, detailed metallic pixel art, dithered shading, 1995 Epic MegaGames, hand-pixeled sprites"
- Palette: steel blue #4682B4, gunmetal gray #6C7A89, gold accents #FFD700, engine orange #FF8C00 on deep space blue #0A0A2E
- BackgroundMood: classic DOS parallax starfield, deep blue-purple space, layered star planes
- ExplosionStyle: detailed pixel explosion, orange-yellow-white fireball with dithered shading
- BulletDirective: bright VGA-colored energy bolt, yellow-white elongated pulse with blue edge glow, 3x8 pixels
- SfxStyle: "DOS AdLib/Sound Blaster, FM synthesis, 16-bit game audio, crunchy digital"
- Unlock: "Reach sector 5"

**gradius_v** — Treasure/Konami 2004, clean Japanese shmup
- ArtDirective: "Treasure/Konami 2004 Japanese shmup. Clean detailed 2D sprites with smooth shading, precise linework, professional arcade quality."
- StyleKeywords: "Japanese shmup, Konami arcade, clean detailed 2D, smooth gradient shading, precise mechanical design"
- Palette: silver white #E0E0E0, deep navy #0D1B2A, bright red accents #FF1744, gold trim #FFD600, plasma blue #00B8D4
- BackgroundMood: dark outer space with mechanical Moai structures, organic-mechanical landscape, dim purple nebula
- ExplosionStyle: clean bright explosion, white-hot center expanding to orange-red ring, smooth gradient falloff
- BulletDirective: bright plasma blue energy oval, smooth glowing projectile, 3x6 pixels
- SfxStyle: "Japanese arcade, clean electronic, precise laser tones, Konami digital"
- Unlock: "Collect 100 power-ups"

**rtype** — Irem 1987, biomechanical H.R. Giger
- ArtDirective: "Irem 1987 biomechanical H.R. Giger aesthetic. Dark brooding alien organic forms merged with machinery, unsettling biological horror."
- StyleKeywords: "biomechanical, H.R. Giger inspired, dark organic alien, fleshy machinery, 1987 arcade, horror sci-fi"
- Palette: dark flesh pink #8B4557, bone white #DDD5C0, alien red #CC0033, rusted metal #5C4033, sickly green #556B2F on near-black #080810
- BackgroundMood: dark alien interior, biomechanical walls with ribbed organic textures, pulsing veins, dim red ambient
- ExplosionStyle: organic burst, dark red-pink fleshy debris, bone-white fragments, sickly green fluid splatter
- BulletDirective: bright orange-white energy beam segment, thin concentrated laser, 2x8 pixels
- SfxStyle: "Dark sci-fi horror, organic squelch, metallic resonance, biomechanical hum"
- Unlock: "Defeat 10 elite enemies"

**blazing_lazers** — Compile/Hudson 1989, TG-16 colorful
- ArtDirective: "Compile/Hudson 1989 TurboGrafx-16 colorful shooter. Vibrant 16-bit palette, clean detailed sprites, cheerful sci-fi action."
- StyleKeywords: "TurboGrafx-16 16-bit, vibrant primary colors, clean detailed sprites, 1989 Hudson Soft, cheerful sci-fi"
- Palette: bright sky blue #4FC3F7, vivid red #F44336, sunshine yellow #FFEB3B, grass green #66BB6A, hot pink #EC407A on deep blue #0D0D30
- BackgroundMood: colorful alien planet, bright blue sky fading to space, vivid terrain, cheerful cosmic backdrop
- ExplosionStyle: colorful 16-bit explosion, bright red-yellow-white fireball with blue sparks
- BulletDirective: bright yellow-white energy beam, wide vertical pulse with blue edge glow, 4x8 pixels
- SfxStyle: "Bright 16-bit console, cheerful FM synth, Hudson Soft PC Engine, punchy tones"
- Unlock: "Win a co-op game"

---

## Step 2: Register in Flutter `skin_registry.dart`

**File:** `tyrian_mobile/lib/services/skin_registry.dart`

Add 7 entries to kSkins list (IDs and names matching the Go definitions exactly).

---

## Step 3: Add asset dirs to `pubspec.yaml`

**File:** `tyrian_mobile/pubspec.yaml`

Add 4 lines per skin (sprites/, ui/, sfx/, backgrounds/) after the existing ikaruga block.

---

## Step 4: Create directory structures

```bash
for skin in nuclear_throne luftrausers nex_machina tyrian_dos gradius_v rtype blazing_lazers; do
  for subdir in sprites ui sfx backgrounds; do
    mkdir -p tyrian_mobile/assets/skins/$skin/$subdir
    touch tyrian_mobile/assets/skins/$skin/$subdir/.gitkeep
  done
done
```

---

## Step 5: Run full pipeline

```bash
cd pipeline

# 5a. Dry-run to verify prompts (optional, quick)
go run ./cmd/generate -dry-run

# 5b. Generate images (all skins — resume skips existing)
go run ./cmd/generate -out output/assets/skins -workers 3

# 5c. Generate SFX
go run ./cmd/generate -sfx -out output/assets/skins

# 5d. Post-process → game assets
go run ./cmd/postprocess -output ../tyrian_mobile/assets/skins
```

**Note:** Pipeline requires `XAI_API_KEY` and `ELEVENLABS_API_KEY` env vars (or `.env` file). Images: ~12 skins x 28 assets x 4 variations = ~1344 API calls total. SFX: ~12 skins x 10 effects = 120 API calls.

---

## Step 6: Validation

```bash
for skin in nuclear_throne luftrausers nex_machina tyrian_dos gradius_v rtype blazing_lazers; do
  echo "=== $skin ==="
  echo "  sprites: $(ls tyrian_mobile/assets/skins/$skin/sprites/*.png 2>/dev/null | wc -l)"
  echo "  backgrounds: $(ls tyrian_mobile/assets/skins/$skin/backgrounds/*.png 2>/dev/null | wc -l)"
  echo "  ui: $(ls tyrian_mobile/assets/skins/$skin/ui/*.png 2>/dev/null | wc -l)"
  echo "  sfx: $(ls tyrian_mobile/assets/skins/$skin/sfx/*.ogg 2>/dev/null | wc -l)"
done
```

Expected per skin: ~30 sprites, 4 backgrounds, 4 UI, 10 SFX.

---

## Execution notes

### Bug fix during implementation
The postprocessor had a bug: SFX entries in some skin manifests fell through to the default image-processing case (tried to load `.mp3` as `.jpg`). Fixed by adding `case asset.Type == "sfx": continue` in `processor.go` — SFX is handled separately by `processSfx()`.

### LFS for raw pipeline output
Raw pipeline output (`pipeline/output/assets/`) was previously gitignored, which meant the generate skip logic didn't work across clones (all assets re-generated every time). Fixed by:
1. Removing `output/assets/` from `pipeline/.gitignore`
2. Setting up Git LFS to track `pipeline/output/assets/**/*.jpg` and `pipeline/output/assets/**/*.mp3`

This preserves skip logic across clones while keeping the repo small (LFS pointers instead of 1.1 GB of raw files).
