# Kiran

A cross-platform 2D vertical-scrolling space shooter — a mobile remake of the classic DOS game Tyrian, ported from the original TyrianVB (VB6/Win32).

## Platforms

| Platform | Status |
|----------|--------|
| iOS | Supported |
| Android | Supported |
| macOS | Partial (landscape + gamepad in progress) |
| Windows | Partial (landscape + gamepad in progress) |

## Features

- **7 sectors** (levels 1–6 scripted, 7+ procedurally random)
- **12 enemy types** from basic fighters to end-game bosses
- **8 weapons** across 4 primary and 4 secondary slots, upgradeable through combat economy
- **13 visual skins** — each with theme-specific sprites, sounds, parallax backgrounds, and post-process shaders (Nuclear Throne, Luftrausers, Nex Machina, Tyrian DOS, Gradius V, R-Type, Blazing Lazers, Galaga, Space Invaders, Geometry Wars, Ikaruga, Asteroids, Default)
- **GPU shader pipeline** — vignette, bloom, CRT scanlines, chromatic aberration, dissolve, pixel explosion
- **Sprite destruction system** — Voronoi fragmentation with radial shard physics
- **ComCenter shop** — buy and upgrade weapons between sectors
- **Network co-op** — 2-player online multiplayer
- **Gamepad support** — PS4 / Xbox analog + buttons on desktop

## Tech Stack

- [Flutter](https://flutter.dev) + [Flame](https://flame-engine.org) ^1.35.1 game engine
- Custom GLSL fragment shaders via Flutter `FragmentProgram`
- Go asset pipeline (`pipeline/`) — sprite generation, atlas packing, SFX via Grok Image API / ElevenLabs

## Build

```bash
cd tyrian_mobile

# iOS
flutter run -d ios

# Android
flutter run -d android

# macOS
flutter run -d macos
```

## Documentation

- [CHANGELOG.md](CHANGELOG.md) — development history
- [GALLERY.md](GALLERY.md) — screenshots and videos
