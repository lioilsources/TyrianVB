# SkinPipeline — Go Asset Generation Pipeline

## Project Context

Mobilní top-down vesmírná střílečka ve Flutteru (Flame engine).
Systém skinů inspirovaných ikonickými hrami různých ér — jen **estetika a feel**, žádné kopírování assetů ani mechanik.

---

## Stack

- **Go** — asset generation pipeline
- **Flutter + Flame** — mobilní hra
- **Grok Image API** (`grok-2-image`, xAI) — generování obrázků
- **jsfxr / Bfxr** — SFX generace
- **BeepBox / Suno** — hudba per skin
- **GLSL shaders** — post-process efekty ve Flutter (`FragmentProgram`)

---

## Adresářová struktura — Pipeline

```
pipeline/
├── cmd/generate/main.go
├── internal/
│   ├── grokimage/client.go        # xAI image API client
│   ├── generator/
│   │   ├── prompts.go             # prompt builders (ship, explosion, bullet, bg, hud)
│   │   ├── font.go                # Google Fonts download
│   │   └── sfx.go                 # SFX generation via jsfxr CLI
│   ├── postprocess/
│   │   ├── spritesheet.go         # compose sprite sheets
│   │   ├── resize.go              # mobile DPI: 1x/2x/3x
│   │   └── palette.go             # enforce color palette per skin
│   └── skin/
│       ├── manifest.go            # generuje manifest.json
│       └── definitions.go         # všechny SkinDef záznamy
├── output/
│   └── assets/skins/
└── go.mod
```

---

## Adresářová struktura — Assets (output)

```
assets/skins/{skin_id}/
├── manifest.json
├── sprites/
│   ├── ship_frames.png            # horizontal sprite sheet (N frames)
│   ├── explosion.png              # 8-frame horizontal sprite sheet
│   ├── bullet_default.png
│   └── bullet_laser.png
├── backgrounds/
│   ├── layer_0.png                # daleké hvězdy — speedFactor: 0.02
│   ├── layer_1.png                # mlhovina/nebula — speedFactor: 0.08
│   ├── layer_2.png                # střední hvězdy — speedFactor: 0.15
│   └── layer_3.png                # foreground debris — speedFactor: 0.40
├── sfx/
│   ├── shoot.ogg
│   ├── explosion_small.ogg
│   ├── explosion_big.ogg
│   ├── powerup.ogg
│   └── thruster.ogg
├── music/
│   └── theme.ogg
├── shaders/
│   └── postprocess.frag           # GLSL shader pro tento skin
└── ui/
    ├── font.ttf
    ├── icon_life.png
    ├── icon_bomb.png
    ├── icon_shield.png
    └── preview.png                # skin select screen preview
```

---

## Skin Definice (Go struct)

```go
type SkinDef struct {
    ID                 string
    Name               string

    // Prompt parametry
    ArtDirective       string  // hlavní umělecká instrukce
    StyleKeywords      string  // opakuje se ve všech promptech
    PaletteDescription string
    BackgroundMood     string
    ExplosionStyle     string
    BulletDirective    string

    // Technické
    SpriteSize         int
    FrameCount         int

    // Post-process shader
    PostProcess        PostProcessEffect

    // Font
    GoogleFont         string  // název fontu z Google Fonts (OFL licence)

    // Unlock
    UnlockedByDefault  bool
    UnlockDesc         string
}

type PostProcessEffect string
const (
    EffectNone       PostProcessEffect = "none"
    EffectScanlines  PostProcessEffect = "scanlines"
    EffectBloom      PostProcessEffect = "bloom"
    EffectVignette   PostProcessEffect = "vignette"
    EffectFilmGrain  PostProcessEffect = "film_grain"
    EffectGridDistort PostProcessEffect = "grid_distort"
)
```

---

## Skiny — 5 prioritních (Sprint 1–6)

### 1. `space_invaders` — Space Invader (1978)
- **Style:** 8-bit pixel art, monochrome zelená, CRT scanlines
- **Palette:** `#00FF00` na `#000000`
- **Shader:** `scanlines`
- **Font:** Press Start 2P (Google Fonts)
- **SpriteSize:** 16px, 4 frames
- **Unlock:** default (odemčeno od začátku)
- **Music vibe:** monotónní chiptune, square wave, pomalé tempo

### 2. `galaga` — Galaga Ace (1981)
- **Style:** Namco 8-bit, barevný pixel art, primary colors
- **Palette:** červená, bílá, žlutá na černé
- **Shader:** `scanlines` (lehčí)
- **Font:** VT323 (Google Fonts)
- **SpriteSize:** 24px, 4 frames
- **Unlock:** dosáhni 10,000 bodů
- **Music vibe:** energický arkádový chiptune, 120 BPM

### 3. `asteroids` — Vector Pilot (1979)
- **Style:** Atari vektorová grafika, wireframe, bílé linie
- **Palette:** bílé linie, subtle blue-white glow, černé pozadí
- **Shader:** `vignette` (wireframe efekt řeš na sprite úrovni)
- **Font:** Share Tech Mono (Google Fonts)
- **SpriteSize:** 32px, 3 frames
- **Unlock:** přežij 2 minuty bez střílení
- **Music vibe:** minimální ambient, sine wave drony

### 4. `geometry_wars` — Neon Destroyer (2003)
- **Style:** neon geometrie, glowing outlines, synthwave
- **Palette:** cyan `#00FFFF`, magenta `#FF00FF`, yellow `#FFFF00` na černé
- **Shader:** `bloom`
- **Font:** Orbitron (Google Fonts)
- **SpriteSize:** 32px, 6 frames
- **Unlock:** přežij 3 minuty bez power-upu
- **Music vibe:** EDM trance, 140+ BPM, synth bass

### 5. `ikaruga` — Polarity (2001)
- **Style:** minimalistický japonský bullet-hell, elegantní, monochromatický
- **Palette:** bílá `#FFFFFF`, near-black `#0A0A0F`, accent `#8866FF`
- **Shader:** `vignette`
- **Font:** Rajdhani (Google Fonts)
- **SpriteSize:** 28px, 4 frames
- **Unlock:** dokonči level bez jediného zásahu
- **Music vibe:** orchestrální, smyčce + perkuse, dramatické

---

## Grok Image Client — klíčové detaily

```go
// API endpoint
const apiURL = "https://api.x.ai/v1/images/generations"

// Request
type GenerateRequest struct {
    Model          string `json:"model"`           // "grok-2-image"
    Prompt         string `json:"prompt"`
    N              int    `json:"n"`
    Size           string `json:"size"`            // "256x256" / "512x512" / "1024x1024"
    ResponseFormat string `json:"response_format"` // "b64_json"
}

// Auth
httpReq.Header.Set("Authorization", "Bearer "+apiKey) // env: XAI_API_KEY
```

**Rate limiting:** 2s mezi requesty (time.Tick)
**Resume support:** skip pokud output soubor již existuje
**Concurrency:** `-workers` flag (default 3)

---

## Prompt šablona (per asset type)

### Loď (ship)
```
{ArtDirective}
Single spacecraft viewed from directly above (top-down), centered on transparent background.
Pixel art style, {SpriteSize}px sprite sheet with {FrameCount} animation frames in a horizontal row.
Style: {StyleKeywords}. Color palette: {PaletteDescription}.
Clean silhouette, no background elements, no text, no UI.
Transparent background (PNG).
```

### Výbuch (explosion)
```
Explosion animation sprite sheet, 8 frames horizontal row on transparent background.
Style: {StyleKeywords}. {ExplosionStyle}
Starts small bright flash, expands outward, fades to particles/smoke.
Each frame {SpriteSize}px wide. No text, no UI, transparent PNG.
```

### Parallax vrstva (background)
```
Seamless tileable space background, vertical scrolling game.
Layer: {layerDescription}.
Style: {StyleKeywords}. Color mood: {BackgroundMood}.
Must tile seamlessly vertically. No ships, no UI, purely atmospheric.
Wide landscape format 1024x2048px.
```

### HUD ikona
```
Game HUD icon: {iconType}. Style: {StyleKeywords}.
Pixel art, 32x32 pixels, transparent background.
Clear readable shape at small size. Color: {PaletteDescription}.
```

**Tip:** Vždy přidej `N=4` pro variace, vyber nejlepší manuálně.

---

## Post-process Shadery (GLSL / Flutter FragmentProgram)

Soubory v `assets/shaders/`:
- `scanlines.frag` — CRT řádky + vignette (Space Invaders, Galaga)
- `bloom.frag` — Gaussian blur na světlé pixely (Geometry Wars)
- `vignette.frag` — tmavé rohy, kinematický (Ikaruga)
- `film_grain.frag` — šum + sepia (Battle Garegga)
- `grid_distort.frag` — deformace mřížky dle pozice lodi (Geometry Wars bonus)
- `none.frag` — passthrough (žádný efekt)

**pubspec.yaml registrace:**
```yaml
flutter:
  shaders:
    - assets/shaders/scanlines.frag
    - assets/shaders/bloom.frag
    - assets/shaders/vignette.frag
    - assets/shaders/film_grain.frag
    - assets/shaders/grid_distort.frag
    - assets/shaders/none.frag
  assets:
    - assets/skins/
```

**Shader uniform interface (konzistentní pro všechny):**
```glsl
uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTime;
uniform float uIntensity;  // 0.0–1.0, pro plynulé přechody
```

---

## Flutter SkinBundle (Dart) — datový model

```dart
class SkinBundle {
  final String id;
  final String name;
  final String description;

  final String shipSpriteSheet;
  final Vector2 shipFrameSize;
  final int shipFrameCount;

  final List<ParallaxLayerConfig> parallaxLayers;
  final TrailConfig engineTrail;
  final BulletConfig defaultBullet;
  final PostProcessEffect postProcess;
  final SkinPalette palette;
  final HUDConfig hud;

  // Audio paths
  final String sfxShoot;
  final String sfxExplosionSmall;
  final String sfxExplosionBig;
  final String sfxPowerup;
  final String sfxThruster;
  final String musicTheme;

  final bool unlockedByDefault;
  final UnlockCondition? unlockCondition;
}
```

**SkinManager** (`lib/skins/skin_manager.dart`):
- Singleton
- `applySkin(id)` → preload audio, uloží do SharedPreferences
- `playShoot()`, `playExplosionSmall()` atd. — delegují na FlameAudio
- `startMusic()` → FlameAudio.bgm.play(current.musicTheme)

---

## Co nesmí chybět (kompletní checklist)

### Assets per skin
- [ ] `sprites/ship_frames.png` — sprite sheet
- [ ] `sprites/explosion.png` — 8 framů
- [ ] `sprites/bullet_default.png`
- [ ] `backgrounds/layer_0..3.png` — 4 parallax vrstvy
- [ ] `sfx/shoot.ogg` + `explosion_small.ogg` + `explosion_big.ogg` + `powerup.ogg` + `thruster.ogg`
- [ ] `music/theme.ogg` — intro + loop
- [ ] `shaders/postprocess.frag`
- [ ] `ui/font.ttf` — z Google Fonts (OFL)
- [ ] `ui/icon_life.png` + `icon_bomb.png` + `icon_shield.png`
- [ ] `ui/preview.png` — pro skin select screen
- [ ] `manifest.json`

### Flutter/Flame integrace
- [ ] `SkinBundle` datový model
- [ ] `SkinRegistry` — mapa všech skinů
- [ ] `SkinManager` — singleton, audio, persistence
- [ ] `SkinParallaxBackground` — Flame ParallaxComponent
- [ ] `ShaderRegistry` — preload všech shaderů při startu
- [ ] `PostProcessLayer` — Flutter widget wrapping game canvas
- [ ] Skin Select UI — preview animace, lock stav, sound preview
- [ ] HUD respektuje `SkinBundle.hud` (font, barvy, ikony)
- [ ] SafeArea / notch handling
- [ ] Asset density: `1x`/`2x`/`3x` varianty

### Mobilní specifika
- [ ] Max ~150MB GPU paměť — sprite sheets jako `.webp`
- [ ] Shadery precompilovat při startu, ne lazy
- [ ] Parallax jako `RepeatComponent`, ne redraw
- [ ] Touch feedback vizuál per skin

---

## Sprint plán

```
Sprint 0  → Go pipeline skeleton + Grok client + 1 test skin (space_invaders ship only)
Sprint 1  → Space Invaders kompletní (všechny assety) → ověří celý pipeline
Sprint 2  → Shader systém ve Flutter (ShaderRegistry, PostProcessLayer, scanlines first)
Sprint 3  → Font pipeline (Google Fonts download) + HUD system
Sprint 4  → Geometry Wars skin (ověří bloom shader + neon assety)
Sprint 5  → Skin Select UI (Flutter, preview animace, lock/unlock)
Sprint 6  → Ikaruga + Galaga (pipeline by měl být plně automatický)
Sprint 7  → Unlock systém (GameStats, podmínky)
Sprint 8  → Audio polish (BeepBox/Suno hudba per skin)
Sprint N  → Nový skin = 1x SkinDef + `go run ./cmd/generate -skin=new_skin`
```

---

## Klíčový princip

> **Nový skin = nové assety + jeden záznam v `SkinRegistry`.**
> Žádný nový Dart kód. Žádný nový Go kód.
> Pipeline generuje, Flutter konzumuje.

---

## Env variables

```bash
export XAI_API_KEY="your_xai_key_here"
```

## Spuštění pipeline

```bash
# Všechny skiny
go run ./cmd/generate -out output/assets/skins -workers 3

# Jeden skin
go run ./cmd/generate -skin space_invaders -out output/assets/skins

# Resume (přeskočí existující soubory automaticky)
go run ./cmd/generate -skin geometry_wars
```
