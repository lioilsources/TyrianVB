package generator

import (
	"bytes"
	"fmt"
	"text/template"

	"tyrian-pipeline/internal/skin"
)

var promptTemplates = map[string]string{
	"ship": `{{.ArtDirective}}
Single spacecraft viewed from directly above (top-down), centered on transparent background.
Pixel art style, {{.SpriteSize}}px sprite sheet with {{.FrameCount}} animation frames in a horizontal row.
Style: {{.StyleKeywords}}. Color palette: {{.PaletteDescription}}.
Clean silhouette, no background elements, no text, no UI.
Transparent background (PNG).`,

	"explosion": `Explosion animation sprite sheet, 8 frames horizontal row on transparent background.
Style: {{.StyleKeywords}}. {{.ExplosionStyle}}
Starts small bright flash, expands outward, fades to particles/smoke.
Each frame {{.SpriteSize}}px wide. No text, no UI, transparent PNG.`,

	"bullet": `Game projectile sprite on transparent background.
{{.BulletDirective}}
Style: {{.StyleKeywords}}. Color palette: {{.PaletteDescription}}.
Single projectile, centered, facing upward. No text, no UI, transparent PNG.`,

	"background": `Seamless tileable space background, vertical scrolling game.
Layer: {{.LayerDesc}}.
Style: {{.StyleKeywords}}. Color mood: {{.BackgroundMood}}.
Must tile seamlessly vertically. No ships, no UI, purely atmospheric.
Wide landscape format 1024x2048px.`,

	"hud_icon": `Game HUD icon: {{.IconType}}. Style: {{.StyleKeywords}}.
Pixel art, 32x32 pixels, transparent background.
Clear readable shape at small size. Color: {{.PaletteDescription}}.
No text, centered, transparent PNG.`,

	"enemy": `{{.ArtDirective}}
Top-down enemy spacecraft, {{.EnemyDirective}}.
Style: {{.StyleKeywords}}. Color palette: {{.PaletteDescription}}.
Menacing hostile design, facing downward. Single sprite, centered on transparent background.
{{.SpriteSize}}px sprite. No text, no UI, transparent PNG.`,

	"structure": `Top-down space obstacle/debris: {{.StructureDirective}}.
Style: {{.StyleKeywords}}. Color palette: {{.PaletteDescription}}.
Irregular natural shape, no propulsion or weapons visible.
{{.SpriteSize}}px sprite, centered on transparent background. No text, no UI, transparent PNG.`,

	"preview": `Game skin preview image showing the overall visual theme.
Style: {{.StyleKeywords}}. Color palette: {{.PaletteDescription}}.
Show a representative scene: spacecraft, stars, projectiles in this art style.
Atmospheric, eye-catching thumbnail for a selection screen. No text overlay.`,
}

var compiledTemplates = make(map[string]*template.Template)

func init() {
	for name, tmplStr := range promptTemplates {
		t, err := template.New(name).Parse(tmplStr)
		if err != nil {
			panic(fmt.Sprintf("failed to parse template %q: %v", name, err))
		}
		compiledTemplates[name] = t
	}
}

// BuildPrompt renders a prompt template for the given asset type and skin.
// extra can supply additional template variables (e.g. LayerDesc, IconType).
func BuildPrompt(assetType string, s skin.SkinDef, extra map[string]string) (string, error) {
	tmpl, ok := compiledTemplates[assetType]
	if !ok {
		return "", fmt.Errorf("unknown asset type %q", assetType)
	}

	data := map[string]interface{}{
		"ArtDirective":       s.ArtDirective,
		"StyleKeywords":      s.StyleKeywords,
		"PaletteDescription": s.PaletteDescription,
		"BackgroundMood":     s.BackgroundMood,
		"ExplosionStyle":     s.ExplosionStyle,
		"BulletDirective":    s.BulletDirective,
		"SpriteSize":         s.SpriteSize,
		"FrameCount":         s.FrameCount,
	}
	for k, v := range extra {
		data[k] = v
	}

	var buf bytes.Buffer
	if err := tmpl.Execute(&buf, data); err != nil {
		return "", fmt.Errorf("execute template %q: %w", assetType, err)
	}
	return buf.String(), nil
}
