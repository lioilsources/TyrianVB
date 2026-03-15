package postprocess

import (
	"bytes"
	"encoding/json"
	"image"
	"image/color"
	"image/jpeg"
	"os"
	"path/filepath"
	"testing"

	"tyrian-pipeline/internal/skin"
)

func TestGameName_Mapping(t *testing.T) {
	tests := []struct {
		input    string
		wantName string
		wantOk   bool
	}{
		{"ship_frames", "vessel", true},
		{"explosion", "explosion", true},
		{"falcon", "falcon", true},
		{"falcon1", "falcon1", true},
		{"falconx", "falconx", true},
		{"laser", "laser", true},
		{"asteroid", "asteroid", true},
	}
	for _, tt := range tests {
		name, ok := GameName(tt.input)
		if name != tt.wantName || ok != tt.wantOk {
			t.Errorf("GameName(%q) = (%q, %v), want (%q, %v)",
				tt.input, name, ok, tt.wantName, tt.wantOk)
		}
	}
}

func TestStripVariationSuffix(t *testing.T) {
	tests := []struct{ input, want string }{
		{"falcon_v2", "falcon"},
		{"explosion_v1", "explosion"},
		{"falconxb_v10", "falconxb"},
		{"no_suffix", "no_suffix"},
		{"has_vx", "has_vx"}, // non-digit after _v
	}
	for _, tt := range tests {
		got := StripVariationSuffix(tt.input)
		if got != tt.want {
			t.Errorf("StripVariationSuffix(%q) = %q, want %q", tt.input, got, tt.want)
		}
	}
}

func TestRun_SyntheticSkin(t *testing.T) {
	// Create a minimal fake skin directory with a manifest and synthetic JPEGs
	tmpDir := t.TempDir()
	skinDir := filepath.Join(tmpDir, "input", "test_skin")
	spritesDir := filepath.Join(skinDir, "sprites")
	uiDir := filepath.Join(skinDir, "ui")
	os.MkdirAll(spritesDir, 0755)
	os.MkdirAll(uiDir, 0755)

	// Minimal manifest with just a few assets
	manifest := skin.Manifest{
		Version: "1.0.0",
		Model:   "test",
		Skin: skin.ManifestSkin{
			ID:   "test_skin",
			Name: "Test Skin",
		},
		Assets: []skin.ManifestAsset{
			{Name: "ship_frames", Type: "ship", Dir: "sprites", Variations: 4},
			{Name: "explosion", Type: "explosion", Dir: "sprites", Variations: 4},
			{Name: "falcon", Type: "enemy", Dir: "sprites", Variations: 4},
			{Name: "laser", Type: "bullet", Dir: "sprites", Variations: 4},
			{Name: "preview", Type: "preview", Dir: "ui", Variations: 4},
		},
	}

	manifestData, _ := json.MarshalIndent(manifest, "", "  ")
	os.WriteFile(filepath.Join(skinDir, "manifest.json"), manifestData, 0644)

	// Create synthetic 8×8 JPEGs: black bg with colored center
	createTestJPEG := func(dir, name string, variations int) {
		for v := 1; v <= variations; v++ {
			img := image.NewRGBA(image.Rect(0, 0, 8, 8))
			// Black background
			for y := 0; y < 8; y++ {
				for x := 0; x < 8; x++ {
					img.Set(x, y, color.RGBA{0, 0, 0, 255})
				}
			}
			// Colored center
			img.Set(4, 4, color.RGBA{255, 0, 0, 255})

			var buf bytes.Buffer
			jpeg.Encode(&buf, img, nil)
			path := filepath.Join(dir, name+"_v"+string(rune('0'+v))+".jpg")
			os.WriteFile(path, buf.Bytes(), 0644)
		}
	}

	createTestJPEG(spritesDir, "ship_frames", 4)
	createTestJPEG(spritesDir, "explosion", 4)
	createTestJPEG(spritesDir, "falcon", 4)
	createTestJPEG(spritesDir, "laser", 4)
	createTestJPEG(uiDir, "preview", 4)

	// Run postprocess
	outDir := filepath.Join(tmpDir, "output", "test_skin")
	cfg := Config{
		SkinDir:     skinDir,
		OutputDir:   outDir,
		Variation:   1,
		TargetSize:  128,
		BgThreshold: 30,
		BgMargin:    15,
	}

	if err := Run(cfg); err != nil {
		t.Fatalf("Run() error: %v", err)
	}

	// Verify output files exist
	expectedFiles := []string{
		"sprites/vessel.png",      // ship_frames → vessel
		"sprites/explosion1.png",  // explosion v1
		"sprites/explosion2.png",  // explosion v2
		"sprites/explosion3.png",  // explosion v3
		"sprites/explosion4.png",  // explosion v4
		"sprites/falcon.png",      // falcon
		"sprites/laser.png",       // laser
		"ui/preview.png",          // preview
	}

	for _, f := range expectedFiles {
		path := filepath.Join(outDir, f)
		if _, err := os.Stat(path); os.IsNotExist(err) {
			t.Errorf("expected file %s not found", f)
		}
	}
}

func TestListSpriteNames(t *testing.T) {
	m := &skin.Manifest{
		Assets: []skin.ManifestAsset{
			{Name: "ship_frames", Type: "ship"},
			{Name: "explosion", Type: "explosion"},
			{Name: "falcon", Type: "enemy"},
			{Name: "layer_0", Type: "background"},
			{Name: "icon_life", Type: "hud_icon"},
			{Name: "preview", Type: "preview"},
		},
	}

	names := ListSpriteNames(m)
	expected := []string{"vessel", "explosion1", "explosion2", "explosion3", "explosion4", "falcon"}
	if len(names) != len(expected) {
		t.Fatalf("got %d names, want %d: %v", len(names), len(expected), names)
	}
	for i, name := range names {
		if name != expected[i] {
			t.Errorf("names[%d]=%q, want %q", i, name, expected[i])
		}
	}
}
