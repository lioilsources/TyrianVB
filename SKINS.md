# Skins

Kiran ships with 13 visual themes. Each skin provides its own sprites, parallax backgrounds, SFX, and post-process shader preset.

All skin sprites were generated via the **Grok Image API** and post-processed through the Go pipeline in `pipeline/`, unless noted otherwise.

---

| Skin | Theme | Vessels | Bloom | CRT | Tint | Notes |
|------|-------|--------:|:-----:|:---:|------|-------|
| Space Invaders (1978) | 1978 arcade | 4 | — | scanlines 0.4, curve 0.01 | neutral | Subtle CRT phosphor |
| Asteroids (1979) | Vector wireframe | 4 | 0.6× | — | green tint (0.85 / 1.0 / 0.85) | Glow on geometry |
| Galaga (1981) | Classic fixed-shooter | 4 | 0.5× | — | neutral | Soft bloom on projectiles |
| R-Type (1987) | Sci-fi horizontal shmup | 4 | 0.7× | — | neutral | Neutral bloom |
| Blazing Lazers (1989) | PC Engine shooter | 4 | 0.8× | — | warm (1.0 / 0.95 / 0.9) | Subtle warm glow |
| Tyrian DOS (1995) | DOS-era pixel art | 4 | — | scanlines 0.7, curve 0.02 | warm (1.0 / 0.95 / 0.85) | Faithful retro feel |
| Ikaruga (2001) | Polarity shooter | 4 | 0.8× | — | cool blue (0.9 / 0.95 / 1.0) | Matches ikaruga's palette |
| Geometry Wars (2003) | Neon twin-stick | 4 | 1.5× | — | cyan tint (0.8 / 1.0 / 1.0) | Strongest bloom preset |
| Gradius V (2004) | Classic horizontal shmup | 4 | 0.6× | — | cool blue (0.9 / 0.95 / 1.0) | Clean, high-contrast |
| Luftrausers (2014) | Sepia war aesthetic | 4 | — | — | warm yellow (1.0 / 0.9 / 0.7) | No bloom — flat palette |
| Nuclear Throne (2015) | Post-apoc top-down | 4 | — | — | desaturated warm | Saturation 0.85, orange tint |
| Nex Machina (2017) | Neon twin-stick (dark) | 4 | 1.0× | — | neutral | High-contrast neon |
| Kiran (2026) | Tyrian original | 1 | — | — | neutral | Hand-crafted baseline |

---

## Shader Legend

- **Bloom** — 3-pass blur composited over bright pixels; strength `0.5–1.5×`, threshold `0.6–0.8`
- **CRT** — scanline overlay + barrel curvature; only on pixel-art retro skins (`tyrian_dos`, `space_invaders`)
- **Vignette** — applied to all skins (radius `0.85–0.95`, softness `0.15–0.2`)
- **Chromatic aberration** — triggered on damage hit, not part of the static skin preset

## Adding a New Skin

1. Create `assets/skins/<name>/` with `sprites/`, `ui/`, `sfx/`, `backgrounds/` subdirs
2. Add 4 vessel sprites: `vessel_0.png` – `vessel_3.png`
3. Run `dart run tool/pack_atlas.dart` to rebuild the texture atlas
4. Register a `ShaderConfig` entry in `lib/rendering/shader_config.dart`
5. Add the skin ID to `SkinRegistry` in `lib/services/skin_registry.dart`
