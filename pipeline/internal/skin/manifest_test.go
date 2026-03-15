package skin

import (
	"encoding/json"
	"os"
	"path/filepath"
	"testing"
)

func TestGenerateManifest(t *testing.T) {
	tmpDir := t.TempDir()
	skinDir := filepath.Join(tmpDir, "space_invaders")
	os.MkdirAll(skinDir, 0755)

	s, _ := GetSkin("space_invaders")
	inputs := []ManifestAssetInput{
		{Name: "ship_frames", AssetType: "ship", OutputDir: "sprites", AspectRatio: "1:1", Resolution: "1k"},
		{Name: "explosion", AssetType: "explosion", OutputDir: "sprites", AspectRatio: "1:1", Resolution: "1k"},
		// Projectiles
		{Name: "laser", AssetType: "bullet", OutputDir: "sprites", AspectRatio: "1:1", Resolution: "1k"},
		{Name: "bubble", AssetType: "bullet", OutputDir: "sprites", AspectRatio: "1:1", Resolution: "1k"},
		{Name: "vulcan", AssetType: "bullet", OutputDir: "sprites", AspectRatio: "1:1", Resolution: "1k"},
		{Name: "blaster", AssetType: "bullet", OutputDir: "sprites", AspectRatio: "1:1", Resolution: "1k"},
		{Name: "starg", AssetType: "bullet", OutputDir: "sprites", AspectRatio: "1:1", Resolution: "1k"},
		// Enemies
		{Name: "falcon", AssetType: "enemy", OutputDir: "sprites", AspectRatio: "1:1", Resolution: "1k"},
		{Name: "falcon1", AssetType: "enemy", OutputDir: "sprites", AspectRatio: "1:1", Resolution: "1k"},
		{Name: "falcon2", AssetType: "enemy", OutputDir: "sprites", AspectRatio: "1:1", Resolution: "1k"},
		{Name: "falcon3", AssetType: "enemy", OutputDir: "sprites", AspectRatio: "1:1", Resolution: "1k"},
		{Name: "falcon4", AssetType: "enemy", OutputDir: "sprites", AspectRatio: "1:1", Resolution: "1k"},
		{Name: "falcon5", AssetType: "enemy", OutputDir: "sprites", AspectRatio: "1:1", Resolution: "1k"},
		{Name: "falcon6", AssetType: "enemy", OutputDir: "sprites", AspectRatio: "1:1", Resolution: "1k"},
		{Name: "falconx", AssetType: "enemy", OutputDir: "sprites", AspectRatio: "1:1", Resolution: "1k"},
		{Name: "falconx2", AssetType: "enemy", OutputDir: "sprites", AspectRatio: "1:1", Resolution: "1k"},
		{Name: "falconx3", AssetType: "enemy", OutputDir: "sprites", AspectRatio: "1:1", Resolution: "1k"},
		{Name: "falconxb", AssetType: "enemy", OutputDir: "sprites", AspectRatio: "1:1", Resolution: "1k"},
		{Name: "falconxt", AssetType: "enemy", OutputDir: "sprites", AspectRatio: "1:1", Resolution: "1k"},
		{Name: "bouncer", AssetType: "enemy", OutputDir: "sprites", AspectRatio: "1:1", Resolution: "1k"},
		// Structures
		{Name: "asteroid", AssetType: "structure", OutputDir: "sprites", AspectRatio: "1:1", Resolution: "1k"},
		{Name: "asteroid1", AssetType: "structure", OutputDir: "sprites", AspectRatio: "1:1", Resolution: "1k"},
		{Name: "asteroid2", AssetType: "structure", OutputDir: "sprites", AspectRatio: "1:1", Resolution: "1k"},
		{Name: "asteroid3", AssetType: "structure", OutputDir: "sprites", AspectRatio: "1:1", Resolution: "1k"},
		// Backgrounds
		{Name: "layer_0", AssetType: "background", OutputDir: "backgrounds", AspectRatio: "1:2", Resolution: "2k"},
		{Name: "layer_1", AssetType: "background", OutputDir: "backgrounds", AspectRatio: "1:2", Resolution: "2k"},
		{Name: "layer_2", AssetType: "background", OutputDir: "backgrounds", AspectRatio: "1:2", Resolution: "2k"},
		{Name: "layer_3", AssetType: "background", OutputDir: "backgrounds", AspectRatio: "1:2", Resolution: "2k"},
		// HUD
		{Name: "icon_life", AssetType: "hud_icon", OutputDir: "ui", AspectRatio: "1:1", Resolution: "1k"},
		{Name: "icon_bomb", AssetType: "hud_icon", OutputDir: "ui", AspectRatio: "1:1", Resolution: "1k"},
		{Name: "icon_shield", AssetType: "hud_icon", OutputDir: "ui", AspectRatio: "1:1", Resolution: "1k"},
		// Preview
		{Name: "preview", AssetType: "preview", OutputDir: "ui", AspectRatio: "1:1", Resolution: "1k"},
	}
	err := GenerateManifest(skinDir, s, "grok-imagine-image", 4, inputs)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	// Read and parse manifest
	data, err := os.ReadFile(filepath.Join(skinDir, "manifest.json"))
	if err != nil {
		t.Fatalf("read manifest: %v", err)
	}

	var m Manifest
	if err := json.Unmarshal(data, &m); err != nil {
		t.Fatalf("parse manifest: %v", err)
	}

	if m.Version != "1.0.0" {
		t.Errorf("expected version 1.0.0, got %s", m.Version)
	}
	if m.Model != "grok-imagine-image" {
		t.Errorf("expected model grok-imagine-image, got %s", m.Model)
	}
	if m.Skin.ID != "space_invaders" {
		t.Errorf("expected skin ID space_invaders, got %s", m.Skin.ID)
	}
	if m.Skin.SpriteSize != 16 {
		t.Errorf("expected sprite size 16, got %d", m.Skin.SpriteSize)
	}
	if m.Skin.PostProcess != "scanlines" {
		t.Errorf("expected post_process scanlines, got %s", m.Skin.PostProcess)
	}
	if len(m.Assets) != 32 {
		t.Errorf("expected 32 assets, got %d", len(m.Assets))
	}

	// Verify asset types
	typeCount := map[string]int{}
	for _, a := range m.Assets {
		typeCount[a.Type]++
		if a.Variations != 4 {
			t.Errorf("expected 4 variations for %s, got %d", a.Name, a.Variations)
		}
	}
	if typeCount["ship"] != 1 {
		t.Error("expected 1 ship asset")
	}
	if typeCount["bullet"] != 5 {
		t.Errorf("expected 5 bullet assets, got %d", typeCount["bullet"])
	}
	if typeCount["enemy"] != 13 {
		t.Errorf("expected 13 enemy assets, got %d", typeCount["enemy"])
	}
	if typeCount["structure"] != 4 {
		t.Errorf("expected 4 structure assets, got %d", typeCount["structure"])
	}
	if typeCount["background"] != 4 {
		t.Error("expected 4 background assets")
	}
	if typeCount["hud_icon"] != 3 {
		t.Error("expected 3 hud_icon assets")
	}

	// Verify directories list
	if len(m.Directories) != 6 {
		t.Errorf("expected 6 directories, got %d", len(m.Directories))
	}
}
