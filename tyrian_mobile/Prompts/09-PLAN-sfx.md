# SFX Sound System

## Context

Hra neměla žádný zvuk. Přidáváme SFX systém, kde každý skin dostane vlastní tematický zvukový balíček. Default skin používá ručně vytvořené zvuky z jsfxr; AI skiny generuje ElevenLabs Sound Effects API.

---

## Sprint 0 — Default SFX + Game Integration

### S0.1 — Zvukové assety pro default skin

10 OGG souborů vytvořených v jsfxr.me, uložených do `assets/skins/default/sfx/`:

| File | Event | jsfxr preset | Duration |
|------|-------|-------------|----------|
| `fire_bullet.ogg` | Projectile fire | Laser/Shoot | ~0.15s |
| `fire_beam.ogg` | Beam weapon | Laser/Shoot (long) | ~0.8s |
| `hit_shield.ogg` | Shield absorb | Hit/Hurt (metallic) | ~0.2s |
| `hit_hull.ogg` | HP damage | Hit/Hurt (low) | ~0.25s |
| `explosion_small.ogg` | Small enemy dies | Explosion (tight) | ~0.5s |
| `explosion_large.ogg` | Boss/heavy dies | Explosion (deep) | ~1.2s |
| `pickup.ogg` | Collectable | Pickup/Coin | ~0.3s |
| `weapon_unlock.ogg` | Weapon tier unlock | Powerup | ~1.5s |
| `sector_complete.ogg` | Sector cleared | Powerup (long) | ~2.0s |
| `game_over.ogg` | All vessels dead | Hit/Hurt (descend) | ~2.5s |

Workflow: jsfxr.me → export WAV → `ffmpeg -i in.wav -c:a libvorbis -q:a 4 out.ogg`

**Stav:** Placeholder soubory vytvořeny, je třeba nahradit reálnými zvuky z jsfxr.me.

### S0.2 — `flame_audio` dependency

```yaml
# pubspec.yaml
flame_audio: ^2.10.0
```

**Stav: HOTOVO**

### S0.3 — SoundService (`lib/services/sound_service.dart`)

```dart
enum SfxEvent {
  fireBullet, fireBeam, hitShield, hitHull,
  explosionSmall, explosionLarge, pickup,
  weaponUnlock, sectorComplete, gameOver,
}

class SoundService {
  static final instance = SoundService._();
  SoundService._();

  String _skinId = 'default';
  bool _muted = false;
  final Map<SfxEvent, String> _paths = {};

  Future<void> init();                      // load mute from SharedPreferences, set audioCache prefix
  Future<void> loadSkin(String skinId);     // load sfx/ paths, fallback to default
  void play(SfxEvent event);               // fire-and-forget, skin fallback on error
  Future<void> toggleMute();               // persist via SharedPreferences
}
```

- `loadSkin(id)`: pro každý `SfxEvent` nastaví cestu `skins/{id}/sfx/{name}.ogg`, fallback `skins/default/sfx/{name}.ogg`
- `play()`: `FlameAudio.play(path)`, při chybě fallback na default skin
- `FlameAudio.audioCache.prefix` nastaven na `'assets/'` pro přímý přístup ke skin cestám
- Mute stav v `SharedPreferences` key `sfx_muted`

**Stav: HOTOVO**

### S0.4 — Game integration (7 souborů)

| File | Line/method | Sound | Condition |
|------|------------|-------|-----------|
| `lib/systems/device.dart` | `fire()` po spawn projectile | `fireBullet` / `fireBeam` | `beam > 0` → beam, jinak bullet |
| `lib/entities/vessel.dart` | `takeDamage()` | `hitShield` / `hitHull` | shield absorbed all → shield, jinak hull |
| `lib/entities/vessel.dart` | `addScore()` unlock branch | `weaponUnlock` | `nextWeaponLevel` changed |
| `lib/systems/fleet.dart` | `onHostileKilled()` | `explosionSmall` / `explosionLarge` | `hostile.hpMax > 5000` → large |
| `lib/entities/collectable.dart` | `applyEffect()` | `pickup` | any collectable type |
| `lib/game/tyrian_game.dart` | `_onSectorComplete()` | `sectorComplete` | — |
| `lib/game/tyrian_game.dart` | `triggerGameOver()` | `gameOver` | — |

**Stav: HOTOVO**

### S0.5 — Skin selector + init integration

- `SkinSelector._play()`: volá `SoundService.instance.loadSkin(id)` vedle `AssetLibrary.instance.loadSkin(id)`
- `main.dart` `initState()`: volá `SoundService.instance.init()` + `loadSkin('default')`
- `pubspec.yaml`: přidány `assets/skins/{skin_id}/sfx/` pro všech 6 skinů

**Stav: HOTOVO**

### S0.6 — Mute toggle

Mute ikonka v `OsdPanel` (bottom-right, vedle pause) — `Icons.volume_up` / `Icons.volume_off`.
Callback `onMuteToggle` → `setState` v `main.dart` pro refresh ikony.

**Stav: HOTOVO**

---

## Sprint 1 — Pipeline ElevenLabs Integration

### S1.1 — ElevenLabs API client (`pipeline/internal/sfxgen/client.go`)

```go
// POST https://api.elevenlabs.io/v1/sound-generation
// Header: xi-api-key: {key}
// Body JSON: { "text": "...", "duration_seconds": 1.5, "prompt_influence": 0.5 }
// Response: binary audio (MP3)

type Client struct {
    apiKey  string
    httpCli *http.Client
}

func (c *Client) Generate(ctx context.Context, req GenerateRequest) ([]byte, error)
// Returns raw MP3 bytes. Retry on 429 with exponential backoff (3 attempts).
```

**Stav: HOTOVO**

### S1.2 — SFX specs (`pipeline/internal/sfxgen/specs.go`)

10 specifikací zvuků s názvem, popisem a cílovou délkou:

```go
var SfxSpecs = []SfxSpec{
    {"fire_bullet", "laser shot, quick projectile fire", 0.15},
    {"fire_beam", "sustained energy beam, continuous hum", 0.8},
    // ... (10 entries)
}

func BuildSfxPrompt(sfxStyle string, spec SfxSpec) string
```

**Stav: HOTOVO**

### S1.3 — SkinDef rozšíření (`pipeline/internal/skin/definitions.go`)

Nové pole `SfxStyle string` v `SkinDef`:

| Skin | SfxStyle |
|------|----------|
| space_invaders | `"8-bit chiptune, lo-fi square wave, classic arcade"` |
| galaga | `"Classic 80s arcade, FM synthesis, bright tones"` |
| asteroids | `"Minimal vector-style, sine waves, white noise bursts"` |
| geometry_wars | `"Synthwave neon, deep bass, electronic glitch"` |
| ikaruga | `"Japanese arcade, clean electronic, precise tonal"` |

**Stav: HOTOVO**

### S1.4 — Prompt construction

```go
func BuildSfxPrompt(sfxStyle string, spec SfxSpec) string {
    return sfxStyle + " " + spec.EventDesc + ". Short sound effect, X.X seconds, game audio."
}
```

Příklady:
- **geometry_wars/explosion_small**: `Synthwave neon, deep bass, electronic glitch small explosion, quick impact burst. Short sound effect, 0.5 seconds, game audio.`
- **space_invaders/fire_bullet**: `8-bit chiptune, lo-fi square wave, classic arcade laser shot, quick projectile fire. Short sound effect, 0.2 seconds, game audio.`

**Stav: HOTOVO** (součást specs.go)

### S1.5 — Generate command rozšíření (`pipeline/cmd/generate/main.go`)

- Nový flag: `-sfx` (bool) — generovat SFX místo obrázků
- Env var: `ELEVENLABS_API_KEY`
- Flow: pro každý skin × každý SfxSpec → volat ElevenLabs → uložit `sfx/{name}.mp3`
- Rate limit: 1 req/2s
- Resume: skip pokud `sfx/{name}.mp3` existuje

**Stav: HOTOVO**

### S1.6 — Postprocess SFX (`pipeline/internal/postprocess/processor.go`)

Pro každý `.mp3` v `{skinDir}/sfx/`: konvertovat na OGG přes exec `ffmpeg`:
```
ffmpeg -y -i in.mp3 -af loudnorm=I=-14:TP=-3 -c:a libvorbis -q:a 4 out.ogg
```

Integrováno do `Run()` — automaticky se spustí po zpracování obrázků.

**Stav: HOTOVO**

### S1.7 — Manifest update

SFX assety (type `"sfx"`, dir `"sfx"`) se přidávají do manifestu automaticky při generování, pokud `sfx/` adresář obsahuje soubory.

**Stav: HOTOVO**

---

## Soubory — přehled změn

### Sprint 0 — Game
| Akce | Soubor | Stav |
|------|--------|------|
| **Create** | `tyrian_mobile/assets/skins/default/sfx/*.ogg` (10 placeholders) | ⚠️ placeholder — nahradit reálnými zvuky |
| **Create** | `tyrian_mobile/lib/services/sound_service.dart` | ✅ |
| Edit | `tyrian_mobile/lib/systems/device.dart` — fire sound | ✅ |
| Edit | `tyrian_mobile/lib/entities/vessel.dart` — hit + unlock sounds | ✅ |
| Edit | `tyrian_mobile/lib/systems/fleet.dart` — explosion sound | ✅ |
| Edit | `tyrian_mobile/lib/entities/collectable.dart` — pickup sound | ✅ |
| Edit | `tyrian_mobile/lib/game/tyrian_game.dart` — sector complete + game over | ✅ |
| Edit | `tyrian_mobile/lib/ui/skin_selector.dart` — call SoundService.loadSkin | ✅ |
| Edit | `tyrian_mobile/lib/ui/osd_panel.dart` — mute toggle | ✅ |
| Edit | `tyrian_mobile/lib/main.dart` — init + mute callback | ✅ |
| Edit | `tyrian_mobile/pubspec.yaml` — flame_audio + sfx asset dirs | ✅ |

### Sprint 1 — Pipeline
| Akce | Soubor | Stav |
|------|--------|------|
| **Create** | `pipeline/internal/sfxgen/client.go` | ✅ |
| **Create** | `pipeline/internal/sfxgen/specs.go` | ✅ |
| **Create** | `pipeline/internal/sfxgen/client_test.go` | ✅ |
| Edit | `pipeline/internal/skin/definitions.go` — SfxStyle field | ✅ |
| Edit | `pipeline/cmd/generate/main.go` — -sfx flag + ElevenLabs flow | ✅ |
| Edit | `pipeline/internal/postprocess/processor.go` — MP3→OGG conversion | ✅ |
| Edit | `pipeline/internal/skin/manifest.go` — SFX v manifest (directories already included) | ✅ |

---

## Architektura

```
┌─────────────────┐     ┌──────────────────┐
│  jsfxr.me       │     │  ElevenLabs API  │
│  (default skin) │     │  (AI skins)      │
└────────┬────────┘     └────────┬─────────┘
         │ WAV                   │ MP3
         ▼                       ▼
    ffmpeg → OGG           pipeline/cmd/generate -sfx
         │                       │ MP3
         ▼                       ▼
  assets/skins/default/sfx/  pipeline/output/skins/{id}/sfx/
                                     │
                                     ▼
                            postprocess → ffmpeg loudnorm → OGG
                                     │
                                     ▼
                            assets/skins/{id}/sfx/
                                     │
                                     ▼
                            ┌─────────────────┐
                            │  SoundService    │
                            │  .loadSkin(id)   │
                            │  .play(event)    │
                            └─────────────────┘
                                     │
                    ┌────────────────┼────────────────┐
                    ▼                ▼                ▼
              device.fire()   vessel.takeDamage()  fleet.onHostileKilled()
              collectable     tyrian_game          osd_panel (mute)
```

---

## Verifikace

```bash
# Sprint 0
ls tyrian_mobile/assets/skins/default/sfx/   # 10 OGG files
cd tyrian_mobile && flutter analyze           # no new warnings
cd tyrian_mobile && flutter run               # test on device
# → fire weapon → hear fire_bullet.ogg
# → get hit → hear hit_shield/hit_hull
# → kill enemy → hear explosion
# → clear sector → hear sector_complete
# → tap mute icon → sounds toggle off

# Sprint 1
cd pipeline && go build ./...                 # compiles
cd pipeline && go test ./internal/sfxgen/     # tests pass
export ELEVENLABS_API_KEY=...
go run ./cmd/generate -sfx -skin geometry_wars
ls output/assets/skins/geometry_wars/sfx/     # 10 MP3 files
go run ./cmd/postprocess -skin geometry_wars \
  -input pipeline/output/assets/skins \
  -output tyrian_mobile/assets/skins
ls tyrian_mobile/assets/skins/geometry_wars/sfx/ # 10 OGG files
```

---

## Zbývá

- [ ] **S0.1**: Nahradit placeholder OGG soubory reálnými zvuky z jsfxr.me
- [x] S0.2: flame_audio dependency
- [x] S0.3: SoundService
- [x] S0.4: Game integration (7 trigger points)
- [x] S0.5: Skin selector + init
- [x] S0.6: Mute toggle
- [x] S1.1: ElevenLabs client
- [x] S1.2: SFX specs
- [x] S1.3: SkinDef SfxStyle
- [x] S1.4: Prompt construction
- [x] S1.5: Generate -sfx command
- [x] S1.6: Postprocess MP3→OGG
- [x] S1.7: Manifest SFX entries
