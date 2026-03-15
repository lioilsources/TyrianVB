package skin

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"time"
)

// Manifest describes the generated assets for a skin.
type Manifest struct {
	Version     string         `json:"version"`
	GeneratedAt string         `json:"generated_at"`
	Model       string         `json:"model"`
	Skin        ManifestSkin   `json:"skin"`
	Assets      []ManifestAsset `json:"assets"`
	Directories []string       `json:"directories"`
}

// ManifestSkin holds skin metadata in the manifest.
type ManifestSkin struct {
	ID          string `json:"id"`
	Name        string `json:"name"`
	SpriteSize  int    `json:"sprite_size"`
	FrameCount  int    `json:"frame_count"`
	PostProcess string `json:"post_process"`
	GoogleFont  string `json:"google_font"`
}

// ManifestAsset describes a single generated asset.
type ManifestAsset struct {
	Name        string `json:"name"`
	Type        string `json:"type"`
	Dir         string `json:"dir"`
	AspectRatio string `json:"aspect_ratio"`
	Resolution  string `json:"resolution"`
	Variations  int    `json:"variations"`
}

// ManifestAssetInput provides asset info without importing the generator package.
type ManifestAssetInput struct {
	Name        string
	AssetType   string
	OutputDir   string
	AspectRatio string
	Resolution  string
}

// GenerateManifest creates a manifest.json in the skin output directory.
func GenerateManifest(skinDir string, s SkinDef, model string, n int, inputs []ManifestAssetInput) error {
	assets := make([]ManifestAsset, len(inputs))
	for i, in := range inputs {
		assets[i] = ManifestAsset{
			Name:        in.Name,
			Type:        in.AssetType,
			Dir:         in.OutputDir,
			AspectRatio: in.AspectRatio,
			Resolution:  in.Resolution,
			Variations:  n,
		}
	}

	manifest := Manifest{
		Version:     "1.0.0",
		GeneratedAt: time.Now().UTC().Format(time.RFC3339),
		Model:       model,
		Skin: ManifestSkin{
			ID:          s.ID,
			Name:        s.Name,
			SpriteSize:  s.SpriteSize,
			FrameCount:  s.FrameCount,
			PostProcess: string(s.PostProcess),
			GoogleFont:  s.GoogleFont,
		},
		Assets: assets,
		Directories: []string{
			"sprites", "backgrounds", "ui", "sfx", "music", "shaders",
		},
	}

	data, err := json.MarshalIndent(manifest, "", "  ")
	if err != nil {
		return fmt.Errorf("marshal manifest: %w", err)
	}

	outPath := filepath.Join(skinDir, "manifest.json")
	if err := os.WriteFile(outPath, data, 0644); err != nil {
		return fmt.Errorf("write manifest: %w", err)
	}
	return nil
}
