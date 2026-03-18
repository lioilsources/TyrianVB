# Fix Enemy Path Patterns & Viewport Aspect Ratio

## Context

Enemy movement paths in the Flutter/Flame port don't match the VB6 original. Three issues were found:

1. **Critical bug** in `path_system.dart` — oscillation formula uses perpendicular vector instead of direction vector, breaking all non-linear paths
2. **Hardcoded VB6 coordinates** in `sector.dart` — absolute pixel values from the VB6's ~1170-wide viewport that exceed the port's 600-wide viewport
3. **macOS landscape viewport** — `SystemChrome.setPreferredOrientations` is a no-op on desktop; the window starts 800x600 (landscape), squishing the game

---

## Step 1: Fix path oscillation formula (path_system.dart)

**File:** `lib/systems/path_system.dart` lines 73-78

The VB6 original (`Path.cls:55-56`) uses the **direction vector**:
```vb
xs = (dx - sx) / length
ys = (dy - sy) / length
```

The port incorrectly computes the **perpendicular** (90° rotation):
```dart
xs = -(dy - sy) / length;  // WRONG
ys = (dx - sx) / length;   // WRONG
```

**Effect:** For mostly-vertical paths (majority of enemy paths), Cosinus oscillation drops from ~97% to ~22% amplitude, and Sinus gets massive unwanted vertical oscillation.

**Fix:** Replace lines 73-78 with:
```dart
// Direction vector normalized (VB6 Path.cls lines 55-56)
double xs = 0, ys = 0;
if (length > 0) {
  xs = (dx - sx) / length;
  ys = (dy - sy) / length;
}
```

---

## Step 2: Fix hardcoded VB6 coordinates (sector.dart)

**File:** `lib/systems/sector.dart`

Values that exceed the 600-wide / 832-high viewport, scaled proportionally from VB6's ~1170x1050:

| Location | Current | Fix | Why |
|----------|---------|-----|-----|
| Sector 0, f4 `dstX` (L173) | `1100` | `w - 40` | 1100/1170=94% → w-40=560/600=93% |
| Sector 0, f4 `amplitude` (L174) | `250` | `130` | 250/1170=21% → 130/600=22% |
| Sector 0, f6 `amplitude` (L190) | `400` | `200` | 400/1170=34% → 200/600=33% |
| Sector 1, seg2 `dstX` (L306) | `1300` | `w + 100` | Boss flies off right edge |
| Sector 1, seg3 `srcX` (L309) | `1300` | `w + 100` | Continuation |
| Sector 1, seg3 `dstX` (L309) | `680` | `w * 0.58` | 680/1170=58% |
| Sector 1, seg3 `dstY` (L309) | `500` | `h * 0.48` | 500/1050=48% |
| Sector 1, seg4 src/dst X (L312) | `680` | `w * 0.58` | Same center X |
| Sector 1, seg4 `srcY` (L312) | `500` | `h * 0.48` | Continuation |
| Sector 1, seg4 `dstY` (L312) | `200` | `h * 0.19` | 200/1050=19% |
| Sector 2, s2f5 `srcX` (L386) | `690` | `w * 0.59` | 690/1170=59%, off-screen at 600 |

---

## Step 3: Fix macOS viewport (MainFlutterWindow.swift + tyrian_game.dart)

### 3a: Set portrait window with locked aspect ratio

**File:** `macos/Runner/MainFlutterWindow.swift`

Replace current content with portrait-proportioned window + aspect ratio lock:
```swift
import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()

    // Portrait proportions matching game (600:832)
    let w: CGFloat = 450
    let h: CGFloat = 624
    let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
    let frame = NSRect(
      x: (screen.width - w) / 2 + screen.origin.x,
      y: (screen.height - h) / 2 + screen.origin.y,
      width: w, height: h)

    self.contentViewController = flutterViewController
    self.setFrame(frame, display: true)
    self.minSize = NSSize(width: 300, height: 416)
    self.contentAspectRatio = NSSize(width: 600, height: 832)

    RegisterGeneratedPlugins(registry: flutterViewController)
    super.awakeFromNib()
  }
}
```

### 3b: Add gameHeight safety clamp

**File:** `lib/game/tyrian_game.dart` line 93

After computing gameHeight, clamp to prevent landscape squish:
```dart
config.gameHeight = config.gameWidth * (size.y / size.x);
if (config.gameHeight < config.gameWidth) {
  config.gameHeight = config.gameWidth; // never go landscape
}
```

---

## Verification

1. After Step 1: Play sectors 0-2, verify Cosinus paths oscillate horizontally (not vertically), SinCos creates proper figure-8 patterns
2. After Step 2: Verify sector 0 fleet 4 destination is visible, sector 1 boss path stays on-screen, sector 2 fleet 5 starts on-screen
3. After Step 3: Launch on macOS — window should start portrait, resize maintains aspect ratio
