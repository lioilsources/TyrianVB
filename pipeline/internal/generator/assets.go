package generator

import (
	"tyrian-pipeline/internal/skin"
)

// AssetSpec describes a single image asset to generate.
type AssetSpec struct {
	Name        string
	AssetType   string // ship, explosion, bullet, background, hud_icon, preview, enemy, structure
	OutputDir   string // relative subdirectory (sprites/, backgrounds/, ui/)
	AspectRatio string // "1:1" or "1:2"
	Resolution  string // "1k" or "2k"
	ExtraVars   map[string]string
}

var bulletSpecs = []struct{ name, directive string }{
	{"laser", "Laser beam projectile, thin vertical line with intense glow core"},
	{"bubble", "Energy bubble projectile, round glowing orb with translucent shell"},
	{"vulcan", "Rapid-fire vulcan bullet, small dense round pellet with motion trail"},
	{"blaster", "Blaster bolt, elongated energy pulse with bright leading edge"},
	{"starg", "Star-shaped projectile, spinning multi-pointed star with energy glow"},
}

var enemySpecs = []struct{ name, directive string }{
	{"falcon", "standard fighter, medium size, angular wings"},
	{"falcon1", "light scout, small and fast, swept-back wings"},
	{"falcon2", "armored interceptor, heavier build, reinforced hull plates"},
	{"falcon3", "bomber variant, wide body, visible weapon pods"},
	{"falcon4", "stealth fighter, sleek and narrow, dark paneling"},
	{"falcon5", "assault craft, bulky frame, twin engine pods"},
	{"falcon6", "elite fighter, ornate markings, advanced design"},
	{"falconx", "experimental prototype, unusual geometry, glowing accents"},
	{"falconx2", "experimental mark III, tri-wing layout, plasma conduits"},
	{"falconx3", "experimental mark IV, heavily armed, oversized cannons"},
	{"falconxb", "experimental boss, large imposing frame, command vessel"},
	{"falconxt", "experimental turret carrier, rotating weapon platform"},
	{"bouncer", "agile drone, spherical body, unpredictable movement design"},
}

var structureSpecs = []struct{ name, directive string }{
	{"asteroid", "large rocky asteroid, cratered surface, irregular shape"},
	{"asteroid1", "medium asteroid fragment, jagged edges, mineral veins"},
	{"asteroid2", "small asteroid chunk, rough texture, tumbling debris"},
	{"asteroid3", "tiny asteroid shard, sharp angular fragment"},
}

var backgroundLayers = []struct {
	name     string
	layerDesc string
}{
	{"layer_0", "distant stars, very sparse tiny dots, deepest background layer"},
	{"layer_1", "nebula clouds and gas, mid-distance, translucent wisps"},
	{"layer_2", "medium stars and space dust, moderate density"},
	{"layer_3", "foreground debris, closest layer, larger particles and rocks"},
}

// AssetsForSkin returns all asset specs needed for a given skin.
func AssetsForSkin(s skin.SkinDef) []AssetSpec {
	specs := make([]AssetSpec, 0, 32)

	// Ship frames
	specs = append(specs, AssetSpec{
		Name:        "ship_frames",
		AssetType:   "ship",
		OutputDir:   "sprites",
		AspectRatio: "1:1",
		Resolution:  "1k",
	})

	// Explosion
	specs = append(specs, AssetSpec{
		Name:        "explosion",
		AssetType:   "explosion",
		OutputDir:   "sprites",
		AspectRatio: "1:1",
		Resolution:  "1k",
	})

	// Projectiles (match game imgNames)
	for _, b := range bulletSpecs {
		specs = append(specs, AssetSpec{
			Name:        b.name,
			AssetType:   "bullet",
			OutputDir:   "sprites",
			AspectRatio: "1:1",
			Resolution:  "1k",
			ExtraVars:   map[string]string{"BulletDirective": b.directive},
		})
	}

	// Enemies
	for _, e := range enemySpecs {
		specs = append(specs, AssetSpec{
			Name:        e.name,
			AssetType:   "enemy",
			OutputDir:   "sprites",
			AspectRatio: "1:1",
			Resolution:  "1k",
			ExtraVars:   map[string]string{"EnemyDirective": e.directive},
		})
	}

	// Structures
	for _, st := range structureSpecs {
		specs = append(specs, AssetSpec{
			Name:        st.name,
			AssetType:   "structure",
			OutputDir:   "sprites",
			AspectRatio: "1:1",
			Resolution:  "1k",
			ExtraVars:   map[string]string{"StructureDirective": st.directive},
		})
	}

	// Background layers
	for _, layer := range backgroundLayers {
		specs = append(specs, AssetSpec{
			Name:        layer.name,
			AssetType:   "background",
			OutputDir:   "backgrounds",
			AspectRatio: "1:2",
			Resolution:  "2k",
			ExtraVars:   map[string]string{"LayerDesc": layer.layerDesc},
		})
	}

	// HUD icons
	for _, icon := range []struct{ name, desc string }{
		{"icon_life", "extra life heart or ship silhouette"},
		{"icon_bomb", "bomb or special weapon explosive"},
		{"icon_shield", "shield or protective barrier"},
	} {
		specs = append(specs, AssetSpec{
			Name:        icon.name,
			AssetType:   "hud_icon",
			OutputDir:   "ui",
			AspectRatio: "1:1",
			Resolution:  "1k",
			ExtraVars:   map[string]string{"IconType": icon.desc},
		})
	}

	// Preview
	specs = append(specs, AssetSpec{
		Name:        "preview",
		AssetType:   "preview",
		OutputDir:   "ui",
		AspectRatio: "1:1",
		Resolution:  "1k",
	})

	return specs
}
