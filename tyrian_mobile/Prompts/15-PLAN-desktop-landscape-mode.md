# Desktop Landscape + Gamepad Plan

## Context

TyrianVB je vertikalni (portrait) strilecka v Flutter/Flame. Na desktopu chceme **fullscreen landscape** horizontal shooter (hrac vlevo, strili vpravo, nepratelé z prava) s podporou gamepadu (PS4, Xbox, generic).

Klicovy princip: **camera rotation** — herni logika zustava vertikalni, kamera otoci rendering o -90° (CCW). Nulova duplicita kodu.

## Jak to funguje

```
GAME SPACE (portrait)          SCREEN (landscape)
  enemies →  Y=0 (top)         enemies → right edge
  player  →  Y=max (bottom)    player  → left edge
  shoot   →  -Y (up)           shoot   → +X (right)
```

`camera.viewfinder.angle = -pi/2` rotuje svet tak ze:
- game UP → screen RIGHT (strely leti doprava)
- game DOWN → screen LEFT (hrac je vlevo)
- game X (lateral) → screen Y (hrac se pohybuje nahoru/dolu)

---

## Faze 1: Platform config + Windows setup

### 1a: `lib/game/platform_config.dart` (novy soubor)
```dart
import 'dart:io';
const bool isDesktop = Platform.isMacOS || Platform.isWindows || Platform.isLinux;
const bool isLandscape = isDesktop; // desktop = landscape, mobile = portrait
const double spriteRotation = isLandscape ? pi / 2 : 0.0; // kompenzace rotace kamery
```

### 1b: Windows platform
```bash
cd tyrian_mobile && flutter create --platforms=windows .
```
- Upravi `windows/runner/main.cpp` — titulek "Tyrian"
- Upravi `windows/runner/flutter_window.cpp` — start fullscreen

### 1c: `pubspec.yaml` — nova dependency
```yaml
window_manager: ^0.4.3  # fullscreen, window title (macOS + Windows)
```

---

## Faze 2: Fullscreen + orientace

### `lib/main.dart` (upravit)
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (isDesktop) {
    await windowManager.ensureInitialized();
    await windowManager.setFullScreen(true);
    await windowManager.setTitle('Tyrian');
  } else {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp, DeviceOrientation.portraitDown,
    ]);
  }
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const TyrianApp());
}
```

### `macos/Runner/MainFlutterWindow.swift` (upravit)
- Smazat portrait proportions (w:450, h:624) a `contentAspectRatio`
- Nechat `window_manager` ridit fullscreen

### `_loadDeviceName()` — pridat macOS/Windows branch
```dart
} else if (Platform.isMacOS) {
  final mac = await info.macOsInfo;
  name = mac.computerName;
} else if (Platform.isWindows) {
  final win = await info.windowsInfo;
  name = win.computerName;
}
```

---

## Faze 3: Camera rotation pro landscape

### `lib/game/tyrian_game.dart` — `onLoad()` (upravit radky 91-103)

```dart
@override
Future<void> onLoad() async {
  if (isDesktop) {
    // Desktop landscape: game height scales with screen WIDTH (to fill after rotation)
    config.gameHeight = config.gameWidth * (size.x / size.y);

    camera.viewport = FixedResolutionViewport(
      resolution: Vector2(config.gameHeight, config.gameWidth), // landscape dims
    );
    camera.viewfinder.anchor = Anchor.center;
    camera.viewfinder.position = Vector2(config.gameWidth / 2, config.gameHeight / 2);
    camera.viewfinder.angle = -pi / 2; // CCW rotation: up→right, player on left
  } else {
    // Mobile portrait: unchanged
    config.gameHeight = config.gameWidth * (size.y / size.x);
    if (config.gameHeight < config.gameWidth) config.gameHeight = config.gameWidth;

    camera.viewport = FixedResolutionViewport(
      resolution: Vector2(config.gameWidth, config.gameHeight),
    );
    camera.viewfinder.anchor = Anchor.topLeft;
    camera.viewfinder.position = Vector2.zero();
  }
  // ... rest unchanged
}
```

**Riziko**: Post-process shadery (`camera.postProcess = shaderPipeline.build()`) mohou mit problem s rotovanym framebufferem. Fallback: pridat finalni rotation shader pass. Testovat empiricky.

---

## Faze 4: Sprite rotace (kompenzace)

Kamera otoci cely svet -90°. Sprity je treba rotovat +90° zpet, aby lodicky koukaly spravnym smerem.

### Zpusob: Canvas rotation v `render()` metodach

**Helper v `platform_config.dart`:**
```dart
void landscapeRotate(Canvas canvas, Vector2 size) {
  if (!isLandscape) return;
  canvas.translate(size.x / 2, size.y / 2);
  canvas.rotate(pi / 2);
  canvas.translate(-size.y / 2, -size.x / 2);
}
```

**Soubory k uprave** (pridat `canvas.save()` + `landscapeRotate()` + `canvas.restore()` v `render()`):
1. `lib/entities/vessel.dart:478` — hracska lod
2. `lib/entities/hostile.dart:240` — nepratel
3. `lib/entities/projectile.dart:62` — strely
4. `lib/entities/structure.dart` — asteroidy
5. `lib/entities/collectable.dart` — pickup
6. `lib/ui/float_text.dart` — plovouci text (aby byl citelny)

**DULEZITE**: Rotace je jen vizualni (v render). Kolizni boxy zustavaji axis-aligned — `PositionComponent.angle` se NEMENI.

---

## Faze 5: Keyboard input

### `lib/game/tyrian_game.dart` — pridat `KeyboardHandler` mixin

```dart
class TyrianGame extends FlameGame
    with DragCallbacks, TapCallbacks, HasCollisionDetection, KeyboardHandler {
```

### Novy soubor: `lib/input/keyboard_input.dart`

```dart
class KeyboardInput {
  final Set<LogicalKeyboardKey> _pressed = {};

  void onKeyEvent(KeyEvent event) { /* add/remove from _pressed */ }

  double get dx {
    double v = 0;
    if (_pressed.contains(LogicalKeyboardKey.keyA) || _pressed.contains(LogicalKeyboardKey.arrowLeft)) v -= 1;
    if (_pressed.contains(LogicalKeyboardKey.keyD) || _pressed.contains(LogicalKeyboardKey.arrowRight)) v += 1;
    return v;
  }
  double get dy { /* W/S, Up/Down */ }
  bool get fire => _pressed.contains(LogicalKeyboardKey.space);
  bool get pause => _pressed.contains(LogicalKeyboardKey.escape);
}
```

### Integrace do `update()`:

```dart
if (isDesktop && state == GameState.playing) {
  final dx = keyboardInput.dx; // screen-space: left/right
  final dy = keyboardInput.dy; // screen-space: up/down

  // Inverse rotation: screen → game space
  // screen RIGHT (+X) = game UP (-Y), screen DOWN (+Y) = game RIGHT (+X)
  final gameDx = dy;   // screen vertical → game lateral
  final gameDy = -dx;  // screen horizontal → game forward/back

  final speed = 300.0; // game units/sec (tunable)
  vessel.adjustPosition(
    vessel.position.x + gameDx * speed * dt,
    vessel.position.y + gameDy * speed * dt,
  );
  vessel.fire = keyboardInput.fire;
}
```

### Input mapping:

| Klavesa | Akce (screen) | Game space |
|---------|--------------|------------|
| A / Left | Lod vlevo (k neprateli) | game Y- (nahoru) |
| D / Right | Lod vpravo (od neprateli) | game Y+ (dolu) |
| W / Up | Lod nahoru | game X- (vlevo) |
| S / Down | Lod dolu | game X+ (vpravo) |
| Space | Fire | vessel.fire = true |
| Escape | Pause | togglePause() |
| Enter | Menu confirm | — |

---

## Faze 6: Gamepad input

### 6a: Novy soubor `lib/input/gamepad_input.dart`

Abstrakce nad gamepad API:
```dart
class GamepadInput {
  double leftStickX = 0, leftStickY = 0; // -1.0 to 1.0
  bool fire = false;     // R2 / RT / Cross / A
  bool pause = false;    // Options / Start
  bool confirm = false;  // Cross / A
  bool cancel = false;   // Circle / B

  void poll();  // Nacte stav z nativniho API

  static double deadzone(double v, {double dz = 0.15}) {
    if (v.abs() < dz) return 0.0;
    return (v.abs() - dz) / (1.0 - dz) * v.sign;
  }
}
```

### 6b: Nativni gamepad plugin via MethodChannel

**macOS**: `GCController` framework
- `macos/Runner/GamepadBridge.swift` — polls connected controllers
- MethodChannel `com.tyrian/gamepad` → vraci stav stiku a tlacitek
- Supports DualShock 4 (wireless via BT), Xbox (wired USB), MFi

**Windows**: XInput API
- `windows/runner/gamepad_bridge.cpp` — `XInputGetState()`
- Stejny MethodChannel
- Covers Xbox nativne; PS4 pres Steam input / DS4Windows

### 6c: Integrace

```dart
// V update(), pred keyboard:
if (gamepadInput.isConnected) {
  final dx = GamepadInput.deadzone(gamepadInput.leftStickX);
  final dy = GamepadInput.deadzone(gamepadInput.leftStickY);
  // Stejna inverse rotace jako keyboard
  vessel.adjustPosition(
    vessel.position.x + dy * speed * dt,
    vessel.position.y - dx * speed * dt,
  );
  vessel.fire = gamepadInput.fire;
}
```

### 6d: Gamepad pro menu navigaci

- D-pad → Flutter FocusTraversalGroup (mapovano jako arrow key events)
- A/Cross → confirm, B/Circle → cancel
- SkinSelector, ComCenter, Pause overlay — pridat focus management

### 6e: Multi-gamepad (local co-op)

- Gamepad index 0 → vessel (P1), index 1 → vessel2 (P2)
- Novy `CoopRole.local` — oba hraci na jednom stroji, bez site
- Hot-plug: `onControllerConnected/Disconnected` callbacky

---

## Faze 7: UI layout pro landscape

Flutter overlay widgety (OSD, ComCenter, menus) NEJSOU ovlivneny camera rotaci — renderuji v screen-space.

### `lib/ui/osd_panel.dart`
- Na desktopu: HUD dole, sirsi layout, vetsi font
- `if (isDesktop)` branch v `build()` — horizontal spread

### `lib/ui/com_center.dart`
- Na desktopu: two-column layout (ship stats vlevo, weapon shop vpravo)
- Gamepad focus navigation

### `lib/ui/skin_selector.dart`
- Na desktopu: wider grid (vic sloupcu, min radku)
- Gamepad D-pad navigace

### Pause / GameOver / Scanning overlays v `main.dart`
- Drobne layout tweaky (padding, sizing)

---

## Soubory k uprave/vytvoreni

### Nove soubory:
| Soubor | Ucel |
|--------|------|
| `lib/game/platform_config.dart` | Platform detection, isDesktop/isLandscape, helper funkce |
| `lib/input/keyboard_input.dart` | WASD/arrows → pohyb + fire |
| `lib/input/gamepad_input.dart` | Gamepad abstrakce + deadzone |
| `macos/Runner/GamepadBridge.swift` | macOS GCController polling |
| `windows/runner/gamepad_bridge.cpp` | Windows XInput polling |
| `windows/` (cely adresar) | Flutter create --platforms=windows |

### Existujici soubory k uprave:
| Soubor | Co se meni |
|--------|-----------|
| `lib/main.dart:20-28` | Conditional orientation + fullscreen via window_manager |
| `lib/main.dart:89-109` | _loadDeviceName — macOS/Windows branch |
| `lib/game/tyrian_game.dart:33-34` | Pridat KeyboardHandler mixin |
| `lib/game/tyrian_game.dart:91-103` | Camera rotation pro landscape |
| `lib/game/tyrian_game.dart:386-450` | Keyboard/gamepad input v update() |
| `lib/game/game_config.dart` | Pridat isLandscape flag |
| `lib/entities/vessel.dart:478` | Sprite rotation v render() |
| `lib/entities/hostile.dart:240` | Sprite rotation v render() |
| `lib/entities/projectile.dart:62` | Sprite rotation v render() |
| `lib/entities/structure.dart` | Sprite rotation v render() |
| `lib/entities/collectable.dart` | Sprite rotation v render() |
| `lib/ui/float_text.dart` | Text rotation kompenzace |
| `lib/ui/osd_panel.dart` | Landscape layout |
| `lib/ui/com_center.dart` | Landscape layout + gamepad nav |
| `lib/ui/skin_selector.dart` | Landscape layout + gamepad nav |
| `macos/Runner/MainFlutterWindow.swift` | Smazat portrait constraints |
| `pubspec.yaml` | Pridat window_manager |

---

## Poradi implementace

1. **Faze 1** — Platform config + Windows setup + window_manager dep
2. **Faze 2** — Fullscreen + orientace (main.dart, MainFlutterWindow.swift)
3. **Faze 3** — Camera rotation (tyrian_game.dart onLoad)
4. **Faze 4** — Sprite rotace (6 entity souboru)
5. **Faze 5** — Keyboard input (okamzite testovani na desktopu)
6. **Faze 7** — UI layout (OSD, ComCenter, menus)
7. **Faze 6** — Gamepad (nativni plugin, deadzone, menu nav, multi-pad)

---

## Verifikace

1. `flutter run -d macos` — fullscreen landscape, starfield scrolluje zleva doprava
2. WASD ovlada lod (W/S = nahoru/dolu na obrazovce, A/D = vlevo/vpravo)
3. Space strili doprava, strely leti na pravou stranu
4. Nepritelé prichazeji z prave strany, padaji doleva
5. Sprity jsou spravne otocene (nos lodicky smeruje doprava)
6. OSD panel se zobrazuje korektne v landscape
7. ComCenter shop funguje v landscape layoutu
8. PS4 DualShock (BT) — analog stick pohybuje lodi, R2/X strili
9. Xbox pad (USB) — to same
10. Dva gamepady — local co-op funguje
11. `flutter run -d ios` / android — regrese: vse funguje v portrait
12. Post-process shadery (bloom, CRT, vignette) fungují po rotaci

### Rizika k otestovani prvne:
- **Camera rotation + post-process**: Otestovat `viewfinder.angle = -pi/2` se shader pipeline ihned po Fazi 3
- **FixedResolutionViewport + rotace**: Overit ze viewport spravne scaluje rotovany obsah
- **Input coordinates**: `event.canvasPosition` v drag callbacks musi byt spravne mapovany i s rotaci (fallback: `camera.globalToLocal()`)
