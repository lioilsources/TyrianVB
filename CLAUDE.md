# CLAUDE.md

## Project Overview

Kiran is a Flutter/Flame 2D vertical-scrolling space shooter — a cross-platform mobile remake of the classic DOS game Tyrian, originally ported from TyrianVB (VB6/Win32). The original VB6 game is the design reference for all gameplay values (HP, damage, weapon stats, sector structure).

## Key Directories

```
tyrian_mobile/
├── lib/
│   ├── entities/       # Game objects: Vessel, Hostile, Projectile, Structure, Collectable, Explosion, Shard
│   ├── game/           # TyrianGame (FlameGame), game_config.dart (constants)
│   ├── input/          # Touch drag, keyboard, gamepad handlers
│   ├── net/            # UDP co-op multiplayer protocol
│   ├── rendering/      # BatchRenderer, ParallaxBg, shader passes (bloom, vignette, CRT, chromatic aberration)
│   ├── services/       # AssetLibrary (singleton), SaveService, SoundService, SkinRegistry
│   ├── systems/        # Device/Weapon, Fleet, Sector, PathSystem
│   └── ui/             # Flutter overlays: OsdPanel, ComCenter, SkinSelector, FloatText
├── assets/skins/       # 13 skins, each with sprites/, ui/, sfx/, backgrounds/, atlas.png, atlas.json
├── shaders/            # GLSL fragment shaders (.frag)
└── tool/               # pack_atlas.dart — texture atlas builder

pipeline/               # Go asset generation pipeline (Grok Image API, ElevenLabs SFX)
tyrian_vba_64bit/       # Original VB6 source (reference only)
```

## Common Commands

```bash
cd tyrian_mobile

# Run on device
flutter run -d ios
flutter run -d android
flutter run -d macos

# Build
flutter build ios
flutter build apk

# Rebuild texture atlases
dart run tool/pack_atlas.dart

# Asset pipeline (Go)
cd ../pipeline
go run .
```

## Architecture

- **Entity system**: All game objects extend Flame `PositionComponent`. `TyrianGame` owns the root component tree.
- **Services**: Singletons (`AssetLibrary`, `SoundService`, `SaveService`) loaded at startup. `AssetLibrary` resolves per-skin assets with fallback to `default` skin.
- **Skin system**: Each skin lives in `assets/skins/<name>/`. `SkinRegistry` maps skin IDs to asset paths and shader presets.
- **Shader pipeline**: Flutter `FragmentProgram` loads `.frag` files at runtime. Passes are composited in `TyrianGame.render()`.
- **Sector / Fleet**: `Sector` drives enemy wave scripting. `Fleet` manages groups of `Hostile` entities following paths defined in `PathSystem`.
- **UI**: Flutter Material overlays rendered on top of the Flame canvas via `GameWidget` overlays. `ComCenter` is the main between-sector shop.

## Conventions

- Flame `PositionComponent` hierarchy — do not use Flutter widgets inside the game canvas.
- All gameplay numeric constants (HP, damage, credit thresholds, weapon stats) must match VB6 source values. See `game_config.dart` and `Prompts/00-GAMEPLAY-original.md`.
- Per-skin asset keys follow the pattern `skins/<name>/sprites/<asset>.png`.
- Shader uniforms are set per-frame in the corresponding `*Pass` class under `lib/rendering/passes/`.
- Portrait-first layout. Landscape mode is desktop-only (macOS/Windows) and handled via camera rotation, not separate layout.

## Constraints

- **No web target** — `web/` folder does not exist; do not add it.
- **VB6 parity** — all gameplay balance changes require a reference to the original VB6 values.
- **Audio**: Use `just_audio` only — `flame_audio` was removed for cross-platform `.ogg` support.
- **Sprite scale**: `spriteScale` in `game_config.dart` is the single source of truth for all entity sizing. Do not hardcode pixel sizes in entities.
