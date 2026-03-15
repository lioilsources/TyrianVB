package generator

import (
	"strings"
	"testing"

	"tyrian-pipeline/internal/skin"
)

func TestBuildPromptShip(t *testing.T) {
	s, _ := skin.GetSkin("space_invaders")
	prompt, err := BuildPrompt("ship", s, nil)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if !strings.Contains(prompt, "top-down") {
		t.Error("ship prompt should contain 'top-down'")
	}
	if !strings.Contains(prompt, "16px") {
		t.Error("ship prompt should contain sprite size '16px'")
	}
	if !strings.Contains(prompt, "4 animation frames") {
		t.Error("ship prompt should contain frame count")
	}
	if !strings.Contains(prompt, "8-bit pixel art") {
		t.Error("ship prompt should contain style keywords")
	}
}

func TestBuildPromptExplosion(t *testing.T) {
	s, _ := skin.GetSkin("geometry_wars")
	prompt, err := BuildPrompt("explosion", s, nil)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if !strings.Contains(prompt, "neon") {
		t.Error("explosion prompt should contain skin-specific style")
	}
	if !strings.Contains(prompt, "32px") {
		t.Error("explosion prompt should contain sprite size")
	}
}

func TestBuildPromptBackground(t *testing.T) {
	s, _ := skin.GetSkin("space_invaders")
	extra := map[string]string{"LayerDesc": "distant stars, very sparse, tiny dots"}
	prompt, err := BuildPrompt("background", s, extra)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if !strings.Contains(prompt, "distant stars") {
		t.Error("background prompt should contain layer description from extra")
	}
	if !strings.Contains(prompt, "tile seamlessly") {
		t.Error("background prompt should mention tiling")
	}
}

func TestBuildPromptHUDIcon(t *testing.T) {
	s, _ := skin.GetSkin("ikaruga")
	extra := map[string]string{"IconType": "extra life heart"}
	prompt, err := BuildPrompt("hud_icon", s, extra)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if !strings.Contains(prompt, "extra life heart") {
		t.Error("hud_icon prompt should contain icon type")
	}
	if !strings.Contains(prompt, "32x32") {
		t.Error("hud_icon prompt should specify 32x32")
	}
}

func TestBuildPromptPreview(t *testing.T) {
	s, _ := skin.GetSkin("galaga")
	prompt, err := BuildPrompt("preview", s, nil)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if !strings.Contains(prompt, "selection screen") {
		t.Error("preview prompt should mention selection screen")
	}
}

func TestBuildPromptEnemy(t *testing.T) {
	s, _ := skin.GetSkin("geometry_wars")
	extra := map[string]string{"EnemyDirective": "standard fighter, medium size, angular wings"}
	prompt, err := BuildPrompt("enemy", s, extra)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if !strings.Contains(prompt, "enemy spacecraft") {
		t.Error("enemy prompt should contain 'enemy spacecraft'")
	}
	if !strings.Contains(prompt, "standard fighter") {
		t.Error("enemy prompt should contain directive from ExtraVars")
	}
	if !strings.Contains(prompt, "facing downward") {
		t.Error("enemy prompt should specify facing downward")
	}
}

func TestBuildPromptStructure(t *testing.T) {
	s, _ := skin.GetSkin("space_invaders")
	extra := map[string]string{"StructureDirective": "large rocky asteroid, cratered surface, irregular shape"}
	prompt, err := BuildPrompt("structure", s, extra)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if !strings.Contains(prompt, "obstacle") {
		t.Error("structure prompt should contain 'obstacle'")
	}
	if !strings.Contains(prompt, "rocky asteroid") {
		t.Error("structure prompt should contain directive from ExtraVars")
	}
	if !strings.Contains(prompt, "16px") {
		t.Error("structure prompt should contain sprite size")
	}
}

func TestBuildPromptUnknownType(t *testing.T) {
	s, _ := skin.GetSkin("space_invaders")
	_, err := BuildPrompt("nonexistent", s, nil)
	if err == nil {
		t.Error("expected error for unknown asset type")
	}
}
