# Sprint 0: Go Asset Generation Pipeline (SkinPipeline)

## Context

TyrianVB Mobile potřebuje systém skinů — vizuálních témat inspirovaných ikonickými hrami. Aktuálně má projekt 32 statických PNG v `assets/sprites/` bez jakéhokoli theme systému. Cílem je Go pipeline, který přes xAI Grok Image API generuje kompletní asset sady per skin.

Sprint 0 = skeleton pipeline + Grok client + 1 test skin (space_invaders, ship only).

**Umístění:** `/Volumes/YOTTA/Dev/TyrianVB/pipeline/` (sibling k `tyrian_mobile/`)

---

## API — důležité rozdíly oproti 08-THINKING

| 08-THINKING plán | Aktuální xAI API (březen 2026) |
|-----------------|-------------------------------|
| model: `grok-2-image` | model: `grok-imagine-image` (deprecated 28.2.2026) |
| `size: "512x512"` | `aspect_ratio: "1:1"` + `resolution: "1k"` |
| Output: PNG s transparencí | Output: **JPG** (transparence vyžaduje post-process) |

Sprint 0 generuje raw JPG. Post-processing (background removal → PNG) je Sprint 1.

---

## Soubory k vytvoření (12 souborů)

```
pipeline/
├── go.mod
├── cmd/generate/main.go              # CLI: -skin, -out, -workers, -model, -dry-run, -asset-type, -n
├── internal/
│   ├── grokimage/
│   │   ├── client.go                 # HTTP client (Generate method, retry, error handling)
│   │   └── client_test.go            # Mock httptest server
│   ├── generator/
│   │   ├── prompts.go                # text/template prompt builders (ship, explosion, bullet, bg, hud)
│   │   ├── prompts_test.go
│   │   └── assets.go                 # AssetSpec struct + AssetsForSkin() → []AssetSpec
│   ├── skin/
│   │   ├── definitions.go            # SkinDef struct + 5 skinů (SpaceInvaders plně definovaný)
│   │   ├── manifest.go               # manifest.json generátor
│   │   └── manifest_test.go
│   └── pipeline/
│       ├── orchestrator.go           # Worker pool + rate limiter + resume + file I/O
│       └── orchestrator_test.go
└── output/                           # gitignored, runtime output
```

---

## Implementační pořadí

### 1. `go.mod`
```
go mod init tyrian-pipeline
```
Žádné externí závislosti — vše stdlib (`net/http`, `encoding/json`, `encoding/base64`, `flag`, `text/template`, `sync`, `time`, `context`).

### 2. `internal/skin/definitions.go`
- `SkinDef` struct (ID, Name, ArtDirective, StyleKeywords, PaletteDescription, BackgroundMood, ExplosionStyle, BulletDirective, SpriteSize, FrameCount, PostProcess, GoogleFont, UnlockedByDefault, UnlockDesc)
- `PostProcessEffect` type + konstanty (none, scanlines, bloom, vignette, film_grain, grid_distort)
- `Registry map[string]SkinDef` + `AllSkins()` + `GetSkin(id)`
- Všech 5 skinů definovaných (space_invaders, galaga, asteroids, geometry_wars, ikaruga)

### 3. `internal/generator/prompts.go` + test
- `text/template` šablony pro: ship, explosion, bullet, background (4 vrstvy), hud_icon, preview
- `BuildPrompt(assetType string, skin SkinDef, extra map[string]string) string`
- Šablony dle 08-THINKING prompt templates

### 4. `internal/generator/assets.go`
- `AssetSpec` struct: Name, AssetType, OutputPath, AspectRatio, Resolution, ExtraVars
- `AssetsForSkin(skin SkinDef) []AssetSpec` — vrací 12 specs per skin:
  - ship_frames (sprites/, 1:1, 1k)
  - explosion (sprites/, 1:1, 1k)
  - bullet_default, bullet_laser (sprites/, 1:1, 1k)
  - layer_0..3 (backgrounds/, 1:2, 2k)
  - icon_life, icon_bomb, icon_shield (ui/, 1:1, 1k)
  - preview (ui/, 1:1, 1k)

### 5. `internal/grokimage/client.go` + test
- `ImageGenerator` interface: `Generate(ctx, req) (*Response, error)`
- `Client` struct implementuje interface
- `GenerateRequest`: Model, Prompt, N, AspectRatio, Resolution, ResponseFormat
- `GenerateResponse`: Data []struct{ B64JSON, RevisedPrompt, URL }
- Retry: 3x s exponential backoff (401=fatal, 429=Retry-After, 400=content rejected skip, 5xx=retry)
- Model fallback: zkusí `grok-2-image` pokud `grok-imagine-image` vrátí "model not found"

### 6. `internal/pipeline/orchestrator.go` + test
- `Orchestrator` struct: client (ImageGenerator interface), outDir, workers, rateLimiter
- `Run(ctx, skin) Stats`
- Worker pool přes channel `<-chan AssetSpec`
- Rate limiter: `time.NewTicker(2s)` sdílený mezi workery — jen 1 API call per 2s
- Resume: skip pokud `{name}_v1.jpg` až `_v{N}.jpg` všechny existují (size > 0)
- Output naming: `{skin_id}/sprites/ship_frames_v1.jpg` .. `_v4.jpg`
- Po dokončení: generuje manifest, vytvoří prázdné dirs (sfx/, music/, shaders/)

### 7. `internal/skin/manifest.go` + test
- `Manifest` struct → JSON
- Obsah: version, generated_at, model, skin metadata, assets list, directory map

### 8. `cmd/generate/main.go`
- Flag parsing: `-skin`, `-out` (default `output/assets/skins`), `-workers` (default 3), `-model` (default `grok-imagine-image`), `-dry-run`, `-asset-type`, `-n` (default 4), `-resolution` (default `1k`)
- Validace `XAI_API_KEY` env var
- Wire: skin registry → asset specs → orchestrator → manifest
- Summary output: generated/skipped/failed counts + elapsed time

---

## CLI rozhraní

```bash
# Generuj vše pro space_invaders
go run ./cmd/generate -skin space_invaders

# Dry run (jen zobraz prompty, žádné API cally)
go run ./cmd/generate -skin space_invaders -dry-run

# Jen ship sprite, 1 variace
go run ./cmd/generate -skin space_invaders -asset-type ship -n 1

# Resume (automaticky přeskočí existující soubory)
go run ./cmd/generate -skin space_invaders

# Všechny skiny
go run ./cmd/generate -workers 5
```

---

## Klíčová rozhodnutí

1. **JPG output** — API vrací JPG. Sprint 0 ukládá raw JPG. Background removal (→ PNG) bude Sprint 1 post-process krok.
2. **Variace** — N=4 per prompt, naming `_v1`..`_v4`. Uživatel vybere nejlepší manuálně. Budoucí `cmd/pick` tool pro selekci.
3. **Zero dependencies** — celý pipeline je pure Go stdlib. Žádné third-party knihovny.
4. **Interface pro testovatelnost** — `ImageGenerator` interface umožňuje mock v testech.
5. **`pipeline/output/`** přidat do `.gitignore` — generované assety se necommitují.

---

## Verifikace

1. `go build ./cmd/generate` — kompilace bez chyb
2. `go test ./...` — všechny unit testy projdou (mock HTTP server, prompt rendering, manifest JSON)
3. `go run ./cmd/generate -skin space_invaders -dry-run` — vypíše 12 asset specs s prompty, žádné API cally
4. `XAI_API_KEY=xxx go run ./cmd/generate -skin space_invaders -asset-type ship -n 1` — reálný API call, vytvoří `output/assets/skins/space_invaders/sprites/ship_frames_v1.jpg`
5. Otevřít vygenerovaný JPG v prohlížeči — ověřit že je to top-down pixel art ship
6. Spustit znovu → skip (resume funguje)
