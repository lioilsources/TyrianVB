# Plan: Výměna flame_audio/audioplayers za just_audio (oprava zvuku na Windows)

## Context
`.ogg` zvuky nefungují na Windows protože `audioplayers_windows` používá Windows Media Foundation, které `.ogg` nepodporuje. Na Androidu/iOS `.ogg` funguje. `just_audio` má vlastní dekodér a podporuje `.ogg` na všech platformách.

## Rozsah změn

Audio prochází výhradně přes `SoundService` singleton. Všechny ostatní soubory (vessel.dart, device.dart, fleet.dart, collectable.dart, tyrian_game.dart) volají jen `SoundService.instance.play(SfxEvent.xxx)` — **beze změn**.

### 1. pubspec.yaml — swap dependency

```yaml
# Odebrat:
flame_audio: ^2.10.0

# Přidat:
just_audio: ^0.9.40
```

### 2. lib/services/sound_service.dart — přepsat na just_audio API

**Klíčové rozdíly API:**
- `FlameAudio.play(path, volume: 1.0)` → `AudioPlayer().setAsset('assets/$path')` + `.play()`
- `FlameAudio.audioCache.prefix` → nepotřeba, `setAsset` bere plnou cestu
- `just_audio` potřebuje `AudioPlayer` instance

**Strategie pro SFX (fire-and-forget, overlapping):**
- Pool 2-3 `AudioPlayer` instancí per `SfxEvent` (10 eventů × 3 = 30 players max)
- Round-robin cycling přes pool při `play()`
- Preload při `loadSkin()` přes `player.setAsset()`

**Zachovat:**
- Singleton pattern
- Mute persistence (SharedPreferences)
- Per-skin sound packs s default fallback
- `_failedPaths` + `_disabled` resilience
- Fire-and-forget `play()` API

## Soubory k úpravě

| Soubor | Změna |
|--------|-------|
| `pubspec.yaml` | Swap `flame_audio` → `just_audio` |
| `lib/services/sound_service.dart` | Přepsat na just_audio API s player poolem |

## Ověření

- `flutter build windows --release` projde
- Zvuky hrají na Windows (.ogg formát)
- Zvuky hrají na Android/iOS (.ogg formát)
- Mute toggle funguje
- Změna skinu mění zvuky
- Žádný impact na gameplay performance (fire-and-forget, no blocking)
