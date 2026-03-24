# Plan: Přepis ComCenter — alignment s VBA originálem + odstranění popupů

## Context
Aktuální Flutter ComCenter je funkční ale vizuálně zjednodušený oproti originálu. Zároveň dva popup dialogy (solo-IP, pause-skin) narušují gameplay flow. Přepis ComCenter je příležitost obojí vyřešit najednou.

## Rozdíly originál (VBA) vs. aktuální (Flutter)

| Aspekt | VBA originál | Flutter aktuální |
|--------|-------------|-----------------|
| **Background** | Animovaný gradient + grid (12 bitmap cyklus) | Statický tmavý gradient |
| **Ship preview** | Vizuální model lodi | Chybí |
| **Staty** | HP/Shield jako čísla + slot assignmenty | HealthBar widgety + text wrap |
| **Zbraně** | Karty s obrázkem, jménem, DMG/SPD/PRICE, grid layout + paginace | Scrollable ListView, textové řádky |
| **High Scores** | Top 10 tabulka přímo v ComCenter | Chybí (jen po game over) |
| **Buy/Sell/Upgrade** | Samostatné tlačítko per slot | Generické tlačítko pod weapon listem |
| **Join Game** | Neexistuje (single-player VBA) | Solo-IP popup (před ComCenter) |
| **Pause** | Minimalizace okna | Modální popup overlay |

## Plán přepisu

### Krok 1: Layout — alignovat s originálem

**Soubor: `lib/ui/com_center.dart`**

Nový landscape layout (primární — hra běží landscape):
```
┌──────────────────────────────────────────────────┐
│  COMMAND CENTER              Credits: 12500      │
├────────────────────┬─────────────────────────────┤
│  [Ship Preview]    │  FRONT WEAPONS              │
│                    │  ┌────────┐ ┌────────┐      │
│  Pilot: _______    │  │Bubble  │ │Vulcan  │ ...  │
│                    │  │DMG:21  │ │DMG:24  │      │
│  HP: 125  SH: 100 │  │SPD:15  │ │SPD:30  │      │
│  GEN: 100          │  │$2,000  │ │$16,000 │      │
│                    │  │[BUY]   │ │[BUY]   │      │
│  Front: Bubble I   │  └────────┘ └────────┘      │
│  Left:  ---        │  SIDE WEAPONS               │
│  Right: ---        │  ┌────────┐ ┌────────┐      │
│  Gen: Falcon I     │  │Sm.Bubb │ │Sm.Vulc │ ...  │
│                    │  │...     │ │...     │      │
│  DPS: 2.3         │  └────────┘ └────────┘      │
│  Load: 45%        │                              │
│                    │                              │
│  TOP SCORES        │                              │
│  1. Ace   1200000  │                              │
│  2. ...            │                              │
├────────────────────┴─────────────────────────────┤
│  [JOIN]                        [START MISSION]   │
└──────────────────────────────────────────────────┘
```

Klíčové změny oproti aktuálnímu layoutu:
- **Weapon cards v gridu** místo scrollable listu — každá zbraň jako karta s rámečkem (jako originál DevPaint)
- **Front + Side zbraně najednou** místo tabů — obě kategorie viditelné současně (jako originál)
- **Slot assignmenty** jako explicitní seznam (Front/Left/Right/Gen) místo wrap textu
- **Top 10 scores** v levém sloupci pod ship stats
- **Ship preview** — sprite aktuálního skinu (vessel sprite z AssetLibrary)

### Krok 2: Weapon Cards

**Soubor: `lib/ui/com_center.dart`** (nová metoda `_buildWeaponCard`)

Každá weapon card obsahuje:
- Jméno zbraně + level (pokud owned)
- DMG / SPD / PWR stats
- Cena nebo "OWNED"
- Akční tlačítko: BUY / UPGRADE / SELL
- BEAM indikátor pro laser
- Barevné kódování: zelený border = owned, žlutý = selected, šedý = locked/unaffordable

Grid: `GridView` s `crossAxisCount` vypočteným z dostupné šířky (2-4 karty na řádek).

### Krok 3: Slot management — explicit per-slot

**Soubor: `lib/ui/com_center.dart`** (nová metoda `_buildSlotList`)

Místo generického "BUY → auto-assign slot", zobrazit sloty explicitně:
```
Front: [Bubble Gun I]  [UPGRADE] [SELL]
Left:  [---]           [empty]
Right: [---]           [empty]
Gen:   [Falcon Basic]  [UPGRADE]
```

Kliknutí na weapon card + prázdný slot → přiřadí zbraň do slotu.
Kliknutí na weapon card + obsazený slot → nabídne výměnu.

Tím se přiblížíme originálnímu VBA systému kde Buy/Sell/Upgrade měly samostatné buttony per slot.

### Krok 4: Top 10 Scores v ComCenter

**Soubor: `lib/ui/com_center.dart`** (nová metoda `_buildScoreTable`)

Přidat do levého sloupce pod ship stats:
- Top 10 high scores (ze `SaveService`)
- Formát: rank, jméno pilota, level, score
- Top 3 zvýrazněné cyan

**Soubor: `lib/main.dart`**
- Předat `highScores` list do `ComCenterScreen`

### Krok 5: Animated background

**Soubor: `lib/ui/com_center.dart`**

Nahradit statický gradient animovaným:
- `AnimationController` s 12 fázemi (jako originál `ccBBmp(1..12)`)
- Gradient barvy se mění cyklicky (teal → indigo → purple → zpět)
- Jemný grid overlay přes `CustomPainter` (tenké čáry 0.5px, white10)
- Perioda: přepnutí každých ~67ms (4 framy při 60fps, jako originál)

### Krok 6: JOIN button (nahrazuje solo-IP popup)

**Soubor: `lib/ui/com_center.dart`**
- Přidat `VoidCallback? onJoinIp` parametr
- V bottom baru: `[JOIN]` tlačítko vlevo (oranžové), `[START MISSION]` vpravo
- JOIN viditelný jen v solo módu (ne co-op client)

**Soubor: `lib/main.dart`**
- Smazat `_startPlayWithScan()`, `_showNoHostDialog()`, `_NoHostDialog`, `_buildScanningOverlay()`
- SkinSelector.onPlay → rovnou `_startAsAutoHost()`
- Předat `onJoinIp: _showManualIpDialog` do ComCenterScreen

### Krok 7: Pause overlay → OSD integration (nahrazuje pause popup)

**Soubor: `lib/ui/osd_panel.dart`**
- Přidat `VoidCallback? onSkinSelect`
- Při pause: credits text → "PAUSED", přidat SKIN tlačítko

**Soubor: `lib/main.dart`**
- Smazat `_PauseOverlay` class
- Přidat dimming overlay (Colors.black26) při pause
- Propojit OSD skin callback

**Soubor: `lib/game/tyrian_game.dart`**
- `togglePause()` — přidat co-op event sending
- Přidat `onSkinRequested` callback + S/Y shortcut při pause

## Soubory k úpravě

| Soubor | Rozsah |
|--------|--------|
| `lib/ui/com_center.dart` | **Velký** — přepis layoutu, weapon cards, slot management, scores, animace |
| `lib/main.dart` | **Střední** — smazat popupy, propojit nové callbacky |
| `lib/ui/osd_panel.dart` | **Malý** — SKIN tlačítko při pause |
| `lib/game/tyrian_game.dart` | **Malý** — togglePause co-op, skin shortcut |

## Pořadí implementace

1. `tyrian_game.dart` — togglePause + skin callback
2. `osd_panel.dart` — rozšířit pro pause stav
3. `com_center.dart` — kompletní přepis (layout → cards → slots → scores → animace → JOIN)
4. `main.dart` — smazat popupy, propojit vše

## Ověření

- ComCenter layout odpovídá VBA originálu (weapon cards, slots, scores)
- Buy/Sell/Upgrade funguje per-slot
- High scores viditelné v ComCenter
- PLAY → rovnou ComCenter (bez scan/popup)
- JOIN v ComCenter → IP dialog → co-op
- Pause → OSD ukazuje PAUSED + SKIN (bez popup)
- Gamepad navigace funguje ve všech nových prvcích
