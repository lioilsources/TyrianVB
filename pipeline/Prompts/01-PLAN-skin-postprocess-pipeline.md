# Pipeline Postprocess + Game Skin System

## Context

Pipeline generates 33 JPG sprites per skin via xAI Grok (1024×1024, no alpha). Game loads 27 PNG sprites with alpha channel from `assets/sprites/`. There's no skin system — all paths are hardcoded. Need:
1. Post-processing step in the pipeline: JPG→PNG with alpha, resize, rename
2. Skin selection UI in the game (6 skins: 5 from pipeline + default)

### Key mismatches to resolve
- **Format**: pipeline outputs JPG (no transparency) → game needs PNG with alpha
- **Size**: pipeline 1024×1024 → game sprites 5×12 to 90×90
- **Names**: `ship_frames`→`vessel`, `explosion`(×4 variations)→`explosion1-4`
- **Pipeline has `falconx1`** but game doesn't use it → remove from pipeline

---

## Part A: Pipeline Postprocess

### A1 — Fix pipeline asset specs (align with game)

**`pipeline/internal/generator/assets.go`**:
- Remove `falconx1` from `enemySpecs` (game has no `falconx1`)
- Total: 33→32 assets per skin

**`pipeline/internal/skin/manifest_test.go`**:
- Update counts: 33→32 total, 14→13 enemies

### A2 — New package `internal/postprocess/`

**`bgremove.go`** — background removal:
- Sample 4 corners of image to detect dominant background color
- For each pixel: compute euclidean distance from bg color in RGB space
- Alpha = 0 if distance < threshold, 255 if distance > (threshold + margin), linear ramp between
- Returns `*image.NRGBA` with alpha channel

**`resize.go`** — area-average downscale (no external deps):
- Box filter: divide source into target-sized blocks, average RGB + alpha per block
- Handles non-square images (preserve aspect ratio within target bounding box)
- Pure stdlib: `image`, `image/color`

**`namemap.go`** — pipeline→game name mapping:
```
ship_frames  → vessel
explosion    → explosion{1-4} (4 variations → 4 files)
(all others) → same name, drop _v{N} suffix
```

**`processor.go`** — orchestrates full postprocess:
```go
type Config struct {
    SkinDir     string // input: pipeline output/assets/skins/{id}
    OutputDir   string // output: tyrian_mobile/assets/skins/{id}
    Variation   int    // which _v{N} to pick (default 1; explosion always uses 1-4)
    TargetSize  int    // max dimension in px (default 128)
    BgThreshold int    // color distance threshold (default 30)
    BgMargin    int    // soft-edge ramp width (default 15)
}
```

Flow per asset:
1. Read `manifest.json` → get asset list
2. For each asset: load `{name}_v{variation}.jpg`
3. Apply name mapping (skip `falconx1`)
4. Remove background → RGBA
5. Resize to target (preserve aspect ratio within TargetSize×TargetSize box)
6. Encode PNG → write to `{output}/{game_name}.png`
7. Special: `explosion` → load v1-v4 → output as `explosion1-4.png`
8. Special: `ship_frames` → output as `vessel.png`
9. Copy HUD icons → `ui/` subdir
10. Copy preview → `ui/preview.png`

### A3 — New command `cmd/postprocess/main.go`

```
Flags:
  -skin string      Skin ID to process (required)
  -input string     Pipeline output dir (default "output/assets/skins")
  -output string    Game assets dir (default "../../tyrian_mobile/assets/skins")
  -variation int    Which variation to use (default 1)
  -size int         Max target dimension px (default 128)
  -threshold int    Background removal threshold (default 30)
```

### A4 — Tests

**`internal/postprocess/bgremove_test.go`**:
- Test with solid-black-background image → all bg pixels get alpha=0
- Test with gradient edge → smooth alpha transition
- Test with non-black background (corner sampling)

**`internal/postprocess/resize_test.go`**:
- Test downscale 4×4→2×2 with known pixel values
- Test aspect ratio preservation (non-square input)

**`internal/postprocess/processor_test.go`**:
- Test name mapping: ship_frames→vessel, explosion→explosion1-4
- Test full pipeline with a tiny synthetic JPG (create in test)

---

## Part B: Game Skin System

### B1 — Asset directory reorganization

Move current sprites into default skin directory:
```
assets/sprites/*.png  →  assets/skins/default/sprites/*.png
```

Keep `assets/sprites/` for backward compat (can remove later).
Create default preview: `assets/skins/default/ui/preview.png` (screenshot or manual).

Final structure:
```
assets/skins/
├── default/
│   ├── sprites/   (29 PNGs — moved from assets/sprites/)
│   └── ui/
│       └── preview.png
├── geometry_wars/
│   ├── sprites/   (27 PNGs — postprocess output)
│   └── ui/
│       └── preview.png
├── space_invaders/ ...
├── galaga/ ...
├── asteroids/ ...
└── ikaruga/ ...
```

### B2 — Skin registry (new file)

**`lib/services/skin_registry.dart`**:
```dart
class SkinInfo {
  final String id;
  final String name;
  const SkinInfo(this.id, this.name);
  String get previewPath => 'skins/$id/ui/preview.png';
  String spritePath(String name) => 'skins/$id/sprites/$name.png';
}

const kSkins = [
  SkinInfo('default', 'Tyrian Classic'),
  SkinInfo('space_invaders', 'Space Invader'),
  SkinInfo('galaga', 'Galaga Ace'),
  SkinInfo('asteroids', 'Vector Pilot'),
  SkinInfo('geometry_wars', 'Neon Destroyer'),
  SkinInfo('ikaruga', 'Polarity'),
];
```

### B3 — Modified AssetLibrary

**`lib/services/asset_library.dart`**:
- Add `String _skinId = 'default'` field
- New method `Future<void> loadSkin(String skinId)`:
  - Clears `_sprites` and `_images` caches, resets `_loaded = false`
  - Sets `_skinId = skinId`
  - Calls `loadAll()` which now uses `skins/$_skinId/sprites/{name}.png` paths
- New method `Future<Map<String, ui.Image>> loadPreviews()`:
  - Loads just `skins/{id}/ui/preview.png` for each skin in `kSkins`
  - Returns map of skinId→preview image (for skin selector)
- Change all `_load()` paths: `sprites/{name}.png` → `skins/$_skinId/sprites/{name}.png`

### B4 — Skin selector screen (new file)

**`lib/ui/skin_selector.dart`**:
- Full-screen Material widget (follows ComCenter UI patterns: dark gradient, cyan accents)
- Title: "SELECT SKIN"
- GridView.count: 2 columns, 3 rows
- Each cell = `GestureDetector` wrapping a `Container`:
  - Preview image (fills most of the card, `Image.memory` from loaded preview)
  - Skin name text below
  - Border: cyan if selected, white24 otherwise
- Bottom: "PLAY" button (or tapping a skin directly starts)
- Selected skin saved to `SharedPreferences` key `selected_skin`
- On load: reads last selected skin from SharedPreferences

### B5 — Modified main.dart

- Replace current simple main menu with skin selector integrated into menu screen
- Flow: show skin selector grid → user taps skin → "PLAY" button activates
- On PLAY: `AssetLibrary.instance.loadSkin(selectedSkinId)` → then proceed to game (existing co-op scan flow)
- Keep starfield rendering behind menu (already works — game canvas always renders)

### B6 — pubspec.yaml

Add all skin asset directories:
```yaml
assets:
  - assets/skins/default/sprites/
  - assets/skins/default/ui/
  - assets/skins/geometry_wars/sprites/
  - assets/skins/geometry_wars/ui/
  - assets/skins/space_invaders/sprites/
  - assets/skins/space_invaders/ui/
  - assets/skins/galaga/sprites/
  - assets/skins/galaga/ui/
  - assets/skins/asteroids/sprites/
  - assets/skins/asteroids/ui/
  - assets/skins/ikaruga/sprites/
  - assets/skins/ikaruga/ui/
  - assets/fonts/
```

Remove old `- assets/sprites/` and `- assets/ui/` entries.

---

## Files modified/created

### Pipeline (Go)
| Action | File |
|--------|------|
| Edit | `pipeline/internal/generator/assets.go` — remove `falconx1` |
| Edit | `pipeline/internal/skin/manifest_test.go` — update counts 33→32 |
| **Create** | `pipeline/internal/postprocess/bgremove.go` |
| **Create** | `pipeline/internal/postprocess/resize.go` |
| **Create** | `pipeline/internal/postprocess/namemap.go` |
| **Create** | `pipeline/internal/postprocess/processor.go` |
| **Create** | `pipeline/internal/postprocess/bgremove_test.go` |
| **Create** | `pipeline/internal/postprocess/resize_test.go` |
| **Create** | `pipeline/internal/postprocess/processor_test.go` |
| **Create** | `pipeline/cmd/postprocess/main.go` |

### Game (Dart/Flutter)
| Action | File |
|--------|------|
| **Create** | `tyrian_mobile/lib/services/skin_registry.dart` |
| **Create** | `tyrian_mobile/lib/ui/skin_selector.dart` |
| Edit | `tyrian_mobile/lib/services/asset_library.dart` — skin-aware paths |
| Edit | `tyrian_mobile/lib/main.dart` — integrate skin selector into menu |
| Edit | `tyrian_mobile/pubspec.yaml` — add skin asset dirs |
| Move | `tyrian_mobile/assets/sprites/*.png` → `assets/skins/default/sprites/` |
| **Create** | `tyrian_mobile/assets/skins/default/ui/preview.png` (placeholder) |

---

## Verification

```bash
# 1. Pipeline tests (after falconx1 removal)
cd /Volumes/YOTTA/Dev/TyrianVB/pipeline && go test ./...

# 2. Postprocess dry test with geometry_wars
go run ./cmd/postprocess -skin geometry_wars -input output/assets/skins -output ../../tyrian_mobile/assets/skins

# 3. Verify output
ls -la ../../tyrian_mobile/assets/skins/geometry_wars/sprites/
# Should see: vessel.png, falcon.png, falcon1-6.png, ... explosion1-4.png

# 4. Flutter build (checks asset declarations)
cd /Volumes/YOTTA/Dev/TyrianVB/tyrian_mobile && flutter build apk --debug

# 5. Run game — should show skin selector at start
flutter run
```

## Implementation order

1. A1 — fix falconx1 mismatch (quick)
2. A2+A3+A4 — postprocess package + command + tests
3. Postprocess geometry_wars assets
4. B1 — move default sprites
5. B2+B3 — skin registry + asset library changes
6. B4+B5 — skin selector UI + main.dart
7. B6 — pubspec.yaml
8. Verify full flow
