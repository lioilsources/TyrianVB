# Changelog

## [01/04/2026]
- Corner statistics overlay on gameplay screen
- Doubled sprite scale to 0.74 to correctly match original VBA proportions
- Gun nozzle Y offset computed from sprite aspect ratio — fixes shot origin on tall-canvas skins (tyrian_dos, gradius_v, blazing_lazers)

## [29/03/2026]
- Fixed vessel animation jitter on blazing_lazers, gradius_v, and tyrian_dos skins
- Sprite scaling aligned to original VBA reference proportions

## [26–27/03/2026]
- Added dissolve and pixel-explosion GLSL fragment shaders
- Voronoi fragmentation — enemies shatter into physics-driven shards on destruction
- Radial shard physics with fade-out
- ComCenter UI fully rewritten to match VBA original; popup dialogs removed

## [25/03/2026]
- Replaced `flame_audio` with `just_audio` for cross-platform `.ogg` support (iOS, Android, macOS, Windows)

## [21/03/2026]
- Desktop landscape mode (camera rotated −90°)
- Gamepad input: PS4 / Xbox analog sticks + buttons, co-op local split support
- Fixed collision boxes sized too large
- Fixed projectile spawn offset in landscape orientation
- Fixed gamepad crash; improved audio resilience

## [19/03/2026]
- Shader configuration document added (13 skins × 4 shader effect presets)

## [16–18/03/2026]
- GPU shader pipeline via Flutter `FragmentProgram`: vignette, 3-pass bloom, CRT scanlines, chromatic aberration
- Fixed viewport scaling and enemy trajectory path oscillation
- Initial shader `.frag` files integrated

## [16/03/2026]
- Full skin system: Go asset pipeline, 12 skins with per-skin sprites, SFX, backgrounds, and shader presets
- In-game skin selector UI
- Skins: Nuclear Throne, Luftrausers, Nex Machina, Tyrian DOS, Gradius V, R-Type, Blazing Lazers, Galaga, Space Invaders, Geometry Wars, Ikaruga, Asteroids

## [04/03/2026]
- Gameplay Phase 4: full VB6 alignment — 19 fixes covering collision damage, explosion visuals, weapon max level, economy (kills → credits proportional to maxHP), random sector generation
- Moved original VBA app into its own folder

## [03/03/2026] — Flutter Port
- Ported TyrianVB to Flutter / Flame for Android and iOS
- Gameplay Phase 1: enemy wave spawning, basic fleet mechanics
- Gameplay Phase 2: enemy weapons, damage scaling, weapon unlock thresholds (400k / 4M / 14M credits)
- Gameplay Phase 3: beam weapon damage fix, float text messages, game-restart state reset
- Weapon, vessel, and score values aligned 1:1 with VB6 source

## [02/03/2026] — VB6 Win32→64-bit
- Converted Win32 API declarations to 64-bit for Office 365 compatibility
- Fixed `GdipLoadImg` type mismatch, `Chr(wParam)` LongPtr conversion, `CreateBlaster` wrong weapon assignment
- Removed `SplitDatabase` form dependency

## [02/03/2026] — Initial Commit
- Original TyrianVB VB6 source files
