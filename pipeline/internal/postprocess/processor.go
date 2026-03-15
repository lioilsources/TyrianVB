package postprocess

import (
	"encoding/json"
	"fmt"
	"image"
	"image/jpeg"
	"image/png"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"tyrian-pipeline/internal/skin"
)

// Config controls the postprocess pipeline.
type Config struct {
	SkinDir     string // input: pipeline output/assets/skins/{id}
	OutputDir   string // output: tyrian_mobile/assets/skins/{id}
	Variation   int    // which _v{N} to pick (default 1; explosion always uses 1-4)
	TargetSize  int    // max dimension in px (default 128)
	BgThreshold int    // color distance threshold (default 30)
	BgMargin    int    // soft-edge ramp width (default 15)
}

// DefaultConfig returns a Config with sensible defaults.
func DefaultConfig() Config {
	return Config{
		Variation:   1,
		TargetSize:  128,
		BgThreshold: 30,
		BgMargin:    15,
	}
}

// Run executes the full postprocess pipeline for one skin.
func Run(cfg Config) error {
	// Read manifest
	manifest, err := readManifest(cfg.SkinDir)
	if err != nil {
		return fmt.Errorf("read manifest: %w", err)
	}

	// Create output directories
	spritesDir := filepath.Join(cfg.OutputDir, "sprites")
	uiDir := filepath.Join(cfg.OutputDir, "ui")
	bgDir := filepath.Join(cfg.OutputDir, "backgrounds")
	if err := os.MkdirAll(spritesDir, 0755); err != nil {
		return fmt.Errorf("create sprites dir: %w", err)
	}
	if err := os.MkdirAll(uiDir, 0755); err != nil {
		return fmt.Errorf("create ui dir: %w", err)
	}
	if err := os.MkdirAll(bgDir, 0755); err != nil {
		return fmt.Errorf("create bg dir: %w", err)
	}

	for _, asset := range manifest.Assets {
		switch {
		case asset.Type == "sfx":
			// SFX handled separately by processSfx(); skip here.
			continue

		case asset.Name == "explosion":
			// Special: load v1-v4 → explosion1-explosion4.png
			if err := processExplosions(cfg, asset, spritesDir); err != nil {
				return fmt.Errorf("process explosion: %w", err)
			}

		case asset.Name == "ship_frames":
			// Special: sprite sheet with N frames side-by-side → extract first frame as vessel.png
			if err := processShipFrames(cfg, asset, spritesDir); err != nil {
				return fmt.Errorf("process ship_frames: %w", err)
			}

		case asset.Type == "background":
			if err := processBackgrounds(cfg, asset, bgDir); err != nil {
				return fmt.Errorf("process background %s: %w", asset.Name, err)
			}

		case asset.Type == "hud_icon":
			// Copy HUD icons to ui/ subdir
			if err := processAsset(cfg, asset, uiDir); err != nil {
				return fmt.Errorf("process %s: %w", asset.Name, err)
			}

		case asset.Name == "preview":
			// Copy preview to ui/preview.png
			if err := processAsset(cfg, asset, uiDir); err != nil {
				return fmt.Errorf("process preview: %w", err)
			}

		default:
			// Standard sprite: apply name mapping
			gameName, ok := GameName(asset.Name)
			if !ok {
				continue
			}
			if err := processNamedAsset(cfg, asset, spritesDir, gameName); err != nil {
				return fmt.Errorf("process %s: %w", asset.Name, err)
			}
		}
	}

	// Process SFX: convert MP3 → OGG with volume normalization
	if err := processSfx(cfg); err != nil {
		fmt.Printf("Warning: SFX processing: %v\n", err)
	}

	fmt.Printf("Postprocessed skin %s → %s\n", manifest.Skin.ID, cfg.OutputDir)
	return nil
}

func processAsset(cfg Config, asset skin.ManifestAsset, outDir string) error {
	return processNamedAsset(cfg, asset, outDir, asset.Name)
}

func processNamedAsset(cfg Config, asset skin.ManifestAsset, outDir, gameName string) error {
	srcPath := variationPath(cfg.SkinDir, asset.Dir, asset.Name, cfg.Variation)
	img, err := loadJPEG(srcPath)
	if err != nil {
		return fmt.Errorf("load %s: %w", srcPath, err)
	}

	rgba := RemoveBackground(img, cfg.BgThreshold, cfg.BgMargin)
	resized := Resize(rgba, cfg.TargetSize)

	outPath := filepath.Join(outDir, gameName+".png")
	return savePNG(outPath, resized)
}

func processShipFrames(cfg Config, asset skin.ManifestAsset, outDir string) error {
	srcPath := variationPath(cfg.SkinDir, asset.Dir, asset.Name, cfg.Variation)
	img, err := loadJPEG(srcPath)
	if err != nil {
		return fmt.Errorf("load %s: %w", srcPath, err)
	}

	// Extract each frame from the horizontal sprite sheet (4 frames side-by-side)
	bounds := img.Bounds()
	numFrames := 4
	frameW := bounds.Dx() / numFrames

	for f := 0; f < numFrames; f++ {
		x0 := bounds.Min.X + f*frameW
		cropped := image.NewNRGBA(image.Rect(0, 0, frameW, bounds.Dy()))
		for y := bounds.Min.Y; y < bounds.Max.Y; y++ {
			for x := x0; x < x0+frameW; x++ {
				cropped.Set(x-x0, y-bounds.Min.Y, img.At(x, y))
			}
		}

		rgba := RemoveBackground(cropped, cfg.BgThreshold, cfg.BgMargin)
		resized := Resize(rgba, cfg.TargetSize)

		outPath := filepath.Join(outDir, fmt.Sprintf("vessel_%d.png", f))
		if err := savePNG(outPath, resized); err != nil {
			return err
		}
	}
	return nil
}

func processExplosions(cfg Config, asset skin.ManifestAsset, outDir string) error {
	for v := 1; v <= 4; v++ {
		srcPath := variationPath(cfg.SkinDir, asset.Dir, asset.Name, v)
		img, err := loadJPEG(srcPath)
		if err != nil {
			return fmt.Errorf("load explosion v%d: %w", v, err)
		}

		rgba := RemoveBackground(img, cfg.BgThreshold, cfg.BgMargin)
		resized := Resize(rgba, cfg.TargetSize)

		outPath := filepath.Join(outDir, fmt.Sprintf("explosion%d.png", v))
		if err := savePNG(outPath, resized); err != nil {
			return err
		}
	}
	return nil
}

func processBackgrounds(cfg Config, asset skin.ManifestAsset, bgDir string) error {
	srcPath := variationPath(cfg.SkinDir, asset.Dir, asset.Name, cfg.Variation)
	img, err := loadJPEG(srcPath)
	if err != nil {
		return fmt.Errorf("load %s: %w", srcPath, err)
	}

	resized := ResizeExact(img, 512, 1024)

	// layer_0 is opaque (no bg removal); layer_1+ get bg removal
	var out image.Image
	if asset.Name == "layer_0" {
		out = resized
	} else {
		out = RemoveBackground(resized, cfg.BgThreshold, cfg.BgMargin)
	}

	outPath := filepath.Join(bgDir, asset.Name+".png")
	return savePNG(outPath, out)
}

func variationPath(skinDir, subDir, name string, variation int) string {
	return filepath.Join(skinDir, subDir, fmt.Sprintf("%s_v%d.jpg", name, variation))
}

func loadJPEG(path string) (image.Image, error) {
	f, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer f.Close()

	// Try JPEG first, fall back to generic decode
	img, err := jpeg.Decode(f)
	if err != nil {
		f.Seek(0, 0)
		img, _, err = image.Decode(f)
		if err != nil {
			return nil, fmt.Errorf("decode %s: %w", path, err)
		}
	}
	return img, nil
}

func savePNG(path string, img image.Image) error {
	f, err := os.Create(path)
	if err != nil {
		return err
	}
	defer f.Close()
	return png.Encode(f, img)
}

func readManifest(skinDir string) (*skin.Manifest, error) {
	data, err := os.ReadFile(filepath.Join(skinDir, "manifest.json"))
	if err != nil {
		return nil, err
	}
	var m skin.Manifest
	if err := json.Unmarshal(data, &m); err != nil {
		return nil, err
	}
	return &m, nil
}

// ListSpriteNames returns the expected game sprite file names (without extension)
// for a given manifest, useful for verification.
func ListSpriteNames(manifest *skin.Manifest) []string {
	var names []string
	for _, a := range manifest.Assets {
		switch {
		case a.Name == "explosion":
			for i := 1; i <= 4; i++ {
				names = append(names, fmt.Sprintf("explosion%d", i))
			}
		case a.Type == "background":
			continue
		case a.Type == "hud_icon" || a.Name == "preview":
			continue
		default:
			name, ok := GameName(a.Name)
			if ok {
				names = append(names, name)
			}
		}
	}
	return names
}

// processSfx converts MP3 files in {skinDir}/sfx/ to OGG in {outputDir}/sfx/
// using ffmpeg with loudnorm volume normalization.
func processSfx(cfg Config) error {
	srcSfxDir := filepath.Join(cfg.SkinDir, "sfx")
	entries, err := os.ReadDir(srcSfxDir)
	if err != nil {
		// No sfx directory — not an error, just skip
		return nil
	}

	dstSfxDir := filepath.Join(cfg.OutputDir, "sfx")
	if err := os.MkdirAll(dstSfxDir, 0755); err != nil {
		return fmt.Errorf("create sfx output dir: %w", err)
	}

	converted := 0
	for _, entry := range entries {
		if entry.IsDir() || !strings.HasSuffix(entry.Name(), ".mp3") {
			continue
		}

		baseName := strings.TrimSuffix(entry.Name(), ".mp3")
		srcPath := filepath.Join(srcSfxDir, entry.Name())
		dstPath := filepath.Join(dstSfxDir, baseName+".ogg")

		// Skip if output already exists
		if _, err := os.Stat(dstPath); err == nil {
			continue
		}

		// ffmpeg: normalize volume + convert to OGG/Opus
		cmd := exec.Command("ffmpeg", "-y",
			"-i", srcPath,
			"-af", "loudnorm=I=-14:TP=-3",
			"-c:a", "libopus",
			"-b:a", "96k",
			dstPath,
		)
		if output, err := cmd.CombinedOutput(); err != nil {
			fmt.Printf("  [sfx] ffmpeg error for %s: %v\n%s\n", baseName, err, output)
			continue
		}

		converted++
		fmt.Printf("  [sfx] %s.mp3 → %s.ogg\n", baseName, baseName)
	}

	if converted > 0 {
		fmt.Printf("  Converted %d SFX files\n", converted)
	}
	return nil
}

// init registers jpeg decoder (imported for side effects in loadJPEG fallback)
func init() {
	_ = strings.NewReader // ensure strings import
}
