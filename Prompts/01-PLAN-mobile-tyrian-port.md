# Plan: Port TyrianVB (VBA/Win32) na Android/iOS

## Context

TyrianVB je 2D vertikalni scrolling shooter (~7000 radku VBA) bezici v MS Access s Win32 GDI/GDI+ renderingem. Cil je portovat hru na mobilni platformy (Android + iOS) se zachovanim vsech hernich mechanik.

---

## Technologie: Flutter + Flame engine

| Kriterium | Hodnoceni |
|-----------|-----------|
| Rychlost vyvoje | 9/10 — jeden codebase, hot reload, Flame ma sprite/collision/game-loop |
| Vykon | 8/10 — Skia renderer, 60fps, GPU akcelerace |
| Sdileni kodu | 10/10 — 100% sdileny Dart kod Android + iOS |
| Deploy | 8/10 — `flutter build apk` / `flutter build ios` |
| Vhodnost | 9/10 — Flame je presne pro tento typ 2D sprite her |

Alternativy (Godot, Unity, KMP) jsou prilis tezke pro jednoduchou 2D hru. React Native neni vhodny pro hry.

---

## Struktura projektu

```
tyrian_mobile/
  lib/
    main.dart                       # Vstupni bod
    game/
      tyrian_game.dart              # FlameGame (nahrazuje Module.bas game loop)
      game_config.dart              # Konstanty (FRAME_DELAY, STAR_COUNT, atd.)
    entities/
      vessel.dart                   # Hrac (Vessel.cls)
      hostile.dart                  # Nepritel (Hostile.cls)
      structure.dart                # Prekazky (Structure.cls)
      projectile.dart               # Strely (Projectile.cls)
      collectable.dart              # Bonusy (Collectable.cls)
      explosion.dart                # Exploze (Explosion.cls)
    systems/
      fleet.dart                    # Vlna nepratelu (Fleet.cls)
      sector.dart                   # Level (Sector.cls)
      device.dart                   # Zbran (Device.cls)
      dev_type.dart                 # Statistiky zbrani (DevType.cls)
      path_system.dart              # Trajektorie (Path.cls + Position.cls)
    ui/
      com_center.dart               # Obchod (ComCenter.cls) — Flutter widgety
      osd_panel.dart                # HUD panel — Flutter overlay
      button_widget.dart            # UI tlacitka — Flutter Material
      float_text.dart               # Plovouci text (FloatText.cls)
      high_scores.dart              # Tabulka skore (Record.cls)
    rendering/
      starfield.dart                # Parallax hvezdy (MoveStars)
      beam_renderer.dart            # Laserovy paprsek (DrawBeam)
      health_bar.dart               # HP bary
      progress_bar.dart             # OSD progress bary
    services/
      asset_library.dart            # Nacitani assetu (Library.cls)
      save_service.dart             # Ukladani stavu (shared_preferences)
  assets/
    sprites/                        # PNG sprity (konvertovane z BMP)
    ui/                             # UI obrazky
    fonts/                          # Fonty (nahrady za Windows fonty)
```

---

## Faze implementace

### Faze 1: Zaklad (2 tydny)

- Flutter projekt + Flame dependency
- Konverze vsech BMP assetu na PNG s alpha kanalem (odstraneni celeho mask systemu)
- `TyrianGame extends FlameGame` s 60fps game loop
- `GameConfig` — vsechny konstanty z Module.bas (r.4-36)
- `AssetLibrary` — nahrazuje Library.cls
- Parallax starfield (z `MoveStars` + `starField`)
- **Overeni:** cerna obrazovka s pohybujicimi se hvezdami, 60fps

### Faze 2: Hrac + Input (1 tyden)

- `Vessel` jako `SpriteComponent` — pozice, okraje, stats
- Touch input: prst = pozice lode, s Y-offsetem aby lod byla viditelna nad prstem
- Responsivni layout: logicke rozliseni 1000x640 skalovane na zarizeni
- OSD panel jako Flutter overlay widget
- **Overeni:** lod sleduje prst plynule na ruznych zarizenich

### Faze 3: Zbrane + Strely (1 tyden)

- `DevType` — 8 typu zbrani (statistiky z `GetDevType` v ComCenter.cls)
- `Device` — instance zbrane s cooldownem, object pool
- `Projectile` s object poolingem (nahrazuje `proPool` linked list)
- Beam zbrane (Laser) jako custom Flame renderer
- Generator system (`genValue`/`genPower`/`genMax`)
- Tap pro prepinani fire on/off + volitelny auto-fire
- **Overeni:** vsech 6 typu zbrani strili spravne

### Faze 4: Nepratele + Trajektorie (1.5 tydne)

- `PathSystem` — 4 typy: Linear, Cosinus, SinCos, Sinus
- `Hostile` — 12 typu nepratelu (Falcon I-VI, X varianty, Bouncer)
- `Fleet` — spawnovani v intervalech, area bounds, kill tracking
- AABB kolize pres Flame `CollisionCallbacks` (nahrazuje `ProcessEnemies`)
- `Explosion` animace pres Flame `SpriteAnimation`
- HP bary nad neprateli
- Target-closest-enemy system (z `TestDistance`)
- **Overeni:** Sektor 1 hratelny se spravnym chovanim nepratelu

### Faze 5: Levely (1.5 tydne)

- `Sector` — vsech 7 rucne vytvorenych levelu (z `Setup()` case bloky)
- `SetupRandom()` pro nekonecne nahodne levely
- `TimedAction()` pro casovane aktivace fleet
- `Structure` — 4 chovani (Fall, Follow, FallAndFollow, ByPath)
- `Collectable` — 7 typu bonusu + jejich efekty (`Action()`)
- Upgrade system zbrani (`Device.Upgrade()`)
- **Overeni:** vsech 7 levelu hratelnych, nahodne levely se generuji

### Faze 6: Obchod (1 tyden)

- ComCenter jako Flutter screen (Material widgety, ne Flame)
- Statistiky lode (HP, Shield, Generator, DPS)
- Nakup zbrani (4 predni + 4 bocni) s Buy/Sell/Upgrade
- Text field pro jmeno pilota
- High score tabulka (top 10)
- Adaptivni layout pro mobilni obrazovky
- **Overeni:** kompletni buy/sell/upgrade cyklus funguje

### Faze 7: HUD (1 tyden)

- OSD overlay: level, HP/Shield/Generator bary, kredit, zpravy
- `FloatText` pro "Complete", "Game over", weapon unlock
- Message log s auto-expiry
- Damage flash (cerveny okraj)
- Portrait mode: OSD jako spodni panel
- **Overeni:** vsechny HUD elementy se spravne aktualizuji

### Faze 8: Persistence + Polish (1 tyden)

- `SaveService` pres `shared_preferences` (JSON format)
- Game over flow — skore ulozeni, reset, navrat do obchodu
- Pause system (tlacitko + app backgrounding)
- Performance profiling na low-end zarizenich

### Faze 9: Mobilni vylepseni (1 tyden)

- Responsivni skalovani na ruzne obrazovky (landscape i portrait)
- Touch UX: offset lode nad prstem, auto-fire mod, haptic feedback
- Safe area pro notche/home indikatory
- App lifecycle: auto-pause pri backgroundu
- (Volitelne) zvukove efekty

---

## Kriticke konverze

### Frame-based → Delta-time

Puvodni hra pouziva frame-based pohyb (40fps). Na mobilech s 60fps je nutna konverze:

```dart
// Puvodne: position -= speed   (kazdych 25ms)
// Nove:    position -= speed * dt * 40   (dt v sekundach)
```

Dotkne se: rychlost strel, cooldowny, pohyb hvezd, regen shieldu, generator.

### Mask system → PNG alpha

Puvodne: BMP + runtime generovani masky pixel-by-pixel + 2-pass MaskBlt blitting.
Nove: PNG s alpha kanalem, Flame renderuje automaticky. Cely mask system se eliminuje.

### Linked lists → Dart Lists

Vsechny kolekce (fHost, fFleet, fStruct, fColl, fProjectile, fExp) jsou linked listy s nxt/prv pointery. V Dartu se nahradi typovanymi `List<T>` nebo Flame component children.

### Windows fonty → Bundled fonty

| Windows | Nahrada (free) |
|---------|----------------|
| Castellar | Cinzel / Spectral SC |
| Onyx | Josefin Sans Thin |
| Engravers MT | Baskervville SC |
| Gulim | Noto Sans |

---

## Overeni

1. **Unit testy:** Path generovani (4 typy), DPS kalkulace, Upgrade formula, Score overflow, Collectable efekty
2. **Widget testy:** ComCenter buy/sell/upgrade, OSD aktualizace, High score save/load
3. **Manualni testy:** Vsech 8 zbrani ve vsech slotech, 7 levelu + nahodne, ruzne velikosti obrazovek
4. **Performance:** 60fps s max entitami (~1000 hvezd + 25 nepratelu + 50 strel + exploze)

---

## Casovy odhad: ~10 tydnu
