# Parallax Scrolling Background

## Context

Hra ma pouze proceduralni starfield (1000 hvezd). Pipeline uz generuje 4 vrstvy pozadi pro kazdy AI skin (`layer_0` – `layer_3` v `pipeline/output/assets/skins/*/backgrounds/`), ale postprocess je preskakuje a hra je nepouziva.

Cil: pridat vertikalne scrollujici parallax pozadi z techto vrstev, aby to vypadalo ze teren mizi pod lodi. Default skin (bez vrstev) si ponecha stavajici starfield.

## Vrstvy

| Vrstva | Obsah | Scroll speed | Pruhlednost |
|--------|-------|-------------|-------------|
| layer_0 | Vzdalene hvezdy, zaklad | 20 px/s | Opaque (kresli se pres starfield) |
| layer_1 | Mlhovina, plyn | 40 px/s | Transparentni (cerna → alpha 0) |
| layer_2 | Stredni hvezdy, prach | 80 px/s | Transparentni |
| layer_3 | Popredi, debris, kameny | 140 px/s | Transparentni |

Vrstvy se vertikalne opakuji (tile). Obrazek se kresli 2x nad sebou, oba scrolluji dolu. Kdyz spodni opusti obrazovku, preskoci nahoru.

## Implementace

### 1. Pipeline postprocess — `pipeline/internal/postprocess/processor.go`

Odkomentovat/nahradit `case asset.Type == "background": continue` za volani `processBackgrounds()`.

```go
case asset.Type == "background":
    if err := processBackgrounds(cfg, asset, bgDir); err != nil {
        return fmt.Errorf("process background %s: %w", asset.Name, err)
    }
```

Nova funkce `processBackgrounds()`:
- Nacte `{name}_v{variation}.jpg`
- **layer_0**: resize na 512x1024, **bez bg removal** (opaque zaklad)
- **layer_1–3**: resize na 512x1024, **s bg removal** (cerna → pruhledna)
- Ulozi jako `backgrounds/{name}.png` (tj. `layer_0.png` – `layer_3.png`)

Vystupni adresar: vytvorit `bgDir = filepath.Join(cfg.OutputDir, "backgrounds")` v `Run()`.

Nova funkce `ResizeExact(src, dstW, dstH)` v `resize.go` — area-average resize na presne rozmery (bez zachovani aspect ratio).

### 2. AssetLibrary — `tyrian_mobile/lib/services/asset_library.dart`

Pridat:
```dart
final List<ui.Image> _bgLayers = [];
List<ui.Image> get bgLayers => _bgLayers;
```

V `loadAll()`:
```dart
// Background layers (optional — only AI skins have them)
_bgLayers.clear();
for (int i = 0; i < 4; i++) {
  final img = await _tryLoadImage('skins/$_skinId/backgrounds/layer_$i.png');
  if (img != null) _bgLayers.add(img);
}
```

Pridat `_tryLoadImage()` helper (vraci `ui.Image?`, tichy fail).

V `loadSkin()`: `_bgLayers.clear()` pri reloadu.

### 3. Novy renderer — `tyrian_mobile/lib/rendering/parallax_bg.dart`

```dart
class ParallaxBackground extends Component {
  List<ui.Image> _layers = [];
  List<double> _offsets = [];  // current scroll Y per layer

  static const _speeds = [0.5, 1.0, 2.0, 3.5]; // px per VB6 frame

  void loadLayers() {
    _layers = AssetLibrary.instance.bgLayers;
    _offsets = List.filled(_layers.length, 0.0);
  }

  @override
  void update(double dt) {
    final scaledDt = dt * config.originalFps;
    for (int i = 0; i < _layers.length; i++) {
      _offsets[i] += _speeds[min(i, _speeds.length - 1)] * scaledDt;
      // Wrap offset — image height in game coords
      final imgH = _layers[i].height * (config.gameWidth / _layers[i].width);
      if (_offsets[i] >= imgH) _offsets[i] -= imgH;
    }
  }

  @override
  void render(Canvas canvas) {
    for (int i = 0; i < _layers.length; i++) {
      final img = _layers[i];
      // Scale image to fill game width
      final scale = config.gameWidth / img.width;
      final imgH = img.height * scale;
      final offset = _offsets[i];

      // Draw two copies for seamless tiling
      _drawLayer(canvas, img, scale, offset - imgH);
      _drawLayer(canvas, img, scale, offset);
    }
  }

  void _drawLayer(Canvas canvas, ui.Image img, double scale, double y) {
    canvas.save();
    canvas.translate(0, y);
    canvas.scale(scale);
    canvas.drawImage(img, Offset.zero, Paint());
    canvas.restore();
  }
}
```

### 4. Integrace do hry — `tyrian_mobile/lib/game/tyrian_game.dart`

V `onLoad()`:
```dart
starfield = Starfield();
world.add(starfield);

parallaxBg = ParallaxBackground();
parallaxBg.loadLayers();
world.add(parallaxBg);  // renders AFTER starfield → layer_0 covers it when present
```

V `refreshSprites()`:
```dart
void refreshSprites() {
  vessel.refreshSprite();
  vessel2?.refreshSprite();
  parallaxBg.loadLayers();
}
```

V `update()` — parallax scrolluje i behem `comCenter`/`paused` (stejne jako starfield):
```dart
if (state == GameState.paused || state == GameState.comCenter) {
  starfield.update(dt);
  parallaxBg.update(dt);  // keep scrolling
  return;
}
```

### 5. pubspec.yaml

Pridat `backgrounds/` adresare pro kazdy skin:
```yaml
- assets/skins/galaga/backgrounds/
- assets/skins/asteroids/backgrounds/
# ... atd pro vsechny AI skiny
```

## Soubory k uprave

| Soubor | Zmena |
|--------|-------|
| `pipeline/internal/postprocess/processor.go` | `processBackgrounds()` — resize + conditional bg removal |
| `pipeline/internal/postprocess/resize.go` | `ResizeExact()` — exact-dimension area-average resize |
| `tyrian_mobile/lib/services/asset_library.dart` | Load `bgLayers`, `_tryLoadImage()` helper |
| `tyrian_mobile/lib/rendering/parallax_bg.dart` | **NOVY** — ParallaxBackground component |
| `tyrian_mobile/lib/game/tyrian_game.dart` | Add ParallaxBackground, update during pause, refresh on skin change |
| `tyrian_mobile/pubspec.yaml` | Add `backgrounds/` asset dirs |

## Verifikace

1. `cd pipeline && go build -o postprocess ./cmd/postprocess/ && ./postprocess` — overit backgrounds/ output v skin assets
2. Spustit hru s galaga skinem → videt 4 vrstvy scrollujici ruznymi rychlostmi
3. Prepnout na default skin → starfield bez parallaxu (graceful fallback)
4. ComCenter/pause → pozadi stale scrolluje
