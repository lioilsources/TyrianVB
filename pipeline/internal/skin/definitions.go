package skin

// PostProcessEffect defines the shader effect applied to the game canvas.
type PostProcessEffect string

const (
	EffectNone       PostProcessEffect = "none"
	EffectScanlines  PostProcessEffect = "scanlines"
	EffectBloom      PostProcessEffect = "bloom"
	EffectVignette   PostProcessEffect = "vignette"
	EffectFilmGrain  PostProcessEffect = "film_grain"
	EffectGridDistort PostProcessEffect = "grid_distort"
)

// SkinDef defines all parameters needed to generate assets for a single skin.
type SkinDef struct {
	ID   string
	Name string

	// Prompt parameters
	ArtDirective       string
	StyleKeywords      string
	PaletteDescription string
	BackgroundMood     string
	ExplosionStyle     string
	BulletDirective    string

	// Technical
	SpriteSize int
	FrameCount int

	// Post-process shader
	PostProcess PostProcessEffect

	// Font
	GoogleFont string

	// Audio
	SfxStyle string // audio style keywords for SFX prompt construction

	// Unlock
	UnlockedByDefault bool
	UnlockDesc        string
}

// Registry holds all known skin definitions keyed by ID.
var Registry = map[string]SkinDef{
	"space_invaders": {
		ID:                 "space_invaders",
		Name:               "Space Invader",
		ArtDirective:       "Retro 1978 arcade game aesthetic. Chunky 8-bit pixel art with visible pixel grid.",
		StyleKeywords:      "8-bit pixel art, monochrome green phosphor CRT, chunky blocky pixels, retro arcade 1978",
		PaletteDescription: "monochrome green #00FF00 on pure black #000000, subtle green glow halos",
		BackgroundMood:     "deep black void with sparse green-tinted pixel stars, CRT phosphor glow",
		ExplosionStyle:     "blocky pixel explosion, green squares scatter outward, no smooth gradients",
		BulletDirective:    "small bright green pixel rectangle, 2x6 pixels, sharp edges, no glow",
		SpriteSize:         16,
		FrameCount:         4,
		PostProcess:        EffectScanlines,
		GoogleFont:         "Press Start 2P",
		SfxStyle:           "8-bit chiptune, lo-fi square wave, classic arcade",
		UnlockedByDefault:  true,
		UnlockDesc:         "Default skin",
	},
	"galaga": {
		ID:                 "galaga",
		Name:               "Galaga Ace",
		ArtDirective:       "Namco 1981 arcade pixel art. Colorful but limited palette, clean sprite work.",
		StyleKeywords:      "Namco 8-bit pixel art, primary colors, clean sprite edges, 1981 arcade",
		PaletteDescription: "bright red, white, yellow on black background, occasional blue accents",
		BackgroundMood:     "dark space with colorful distant stars, warm arcade cabinet glow",
		ExplosionStyle:     "colorful pixel burst, red-yellow-white concentric rings expanding outward",
		BulletDirective:    "small bright white pixel bolt with yellow trail, 3x8 pixels",
		SpriteSize:         24,
		FrameCount:         4,
		PostProcess:        EffectScanlines,
		GoogleFont:         "VT323",
		SfxStyle:           "Classic 80s arcade, FM synthesis, bright tones",
		UnlockedByDefault:  false,
		UnlockDesc:         "Score 10,000 points",
	},
	"asteroids": {
		ID:                 "asteroids",
		Name:               "Vector Pilot",
		ArtDirective:       "Atari 1979 vector graphics. Pure wireframe outlines, no filled shapes.",
		StyleKeywords:      "vector wireframe, white lines on black, Atari 1979, minimal geometric, oscilloscope aesthetic",
		PaletteDescription: "white wireframe lines with subtle blue-white glow on pure black",
		BackgroundMood:     "empty void with faint geometric grid lines fading into distance",
		ExplosionStyle:     "wireframe line segments flying outward from center, no fill, just edges",
		BulletDirective:    "single bright white dot with short trailing line, 2x4 pixels",
		SpriteSize:         32,
		FrameCount:         3,
		PostProcess:        EffectVignette,
		GoogleFont:         "Share Tech Mono",
		SfxStyle:           "Minimal vector-style, sine waves, white noise bursts",
		UnlockedByDefault:  false,
		UnlockDesc:         "Survive 2 minutes without shooting",
	},
	"geometry_wars": {
		ID:                 "geometry_wars",
		Name:               "Neon Destroyer",
		ArtDirective:       "2003 Xbox Live neon geometry. Glowing vector outlines on black, synthwave palette.",
		StyleKeywords:      "neon glow, geometric shapes, synthwave, vivid outlines, HDR bloom, 2003 retro-futurism",
		PaletteDescription: "cyan #00FFFF, magenta #FF00FF, yellow #FFFF00 on pure black, intense glow",
		BackgroundMood:     "deep black with subtle dark blue grid lines that pulse and warp",
		ExplosionStyle:     "neon particle shower, cyan and magenta sparks radiating outward with bloom trails",
		BulletDirective:    "small glowing cyan diamond shape with bloom trail, 4x4 pixels",
		SpriteSize:         32,
		FrameCount:         6,
		PostProcess:        EffectBloom,
		GoogleFont:         "Orbitron",
		SfxStyle:           "Synthwave neon, deep bass, electronic glitch",
		UnlockedByDefault:  false,
		UnlockDesc:         "Survive 3 minutes without power-ups",
	},
	"ikaruga": {
		ID:                 "ikaruga",
		Name:               "Polarity",
		ArtDirective:       "Minimalist Japanese bullet-hell 2001. Elegant, clean, high-contrast monochrome.",
		StyleKeywords:      "minimalist Japanese, bullet-hell elegance, high contrast, clean edges, zen aesthetic",
		PaletteDescription: "pure white #FFFFFF, near-black #0A0A0F, accent violet #8866FF",
		BackgroundMood:     "serene dark gradient with faint geometric mandalas, subtle violet accent light",
		ExplosionStyle:     "elegant white particle dissolve, circular wave expanding outward, minimal debris",
		BulletDirective:    "small white circle with violet core glow, 3x3 pixels, clean anti-aliased",
		SpriteSize:         28,
		FrameCount:         4,
		PostProcess:        EffectVignette,
		GoogleFont:         "Rajdhani",
		SfxStyle:           "Japanese arcade, clean electronic, precise tonal",
		UnlockedByDefault:  false,
		UnlockDesc:         "Complete a level without taking damage",
	},
	"nuclear_throne": {
		ID:                 "nuclear_throne",
		Name:               "Wasteland Mutant",
		ArtDirective:       "Vlambeer-style chunky pixel art, 2015 post-apocalyptic mutant aesthetic. Thick outlines, exaggerated proportions, intentionally rough.",
		StyleKeywords:      "chunky pixel art, post-apocalyptic, Vlambeer screenshake aesthetic, rough hand-drawn pixels, low resolution, gritty indie",
		PaletteDescription: "warm desert browns #8B6914, toxic greens #4CAF50, rusty orange #D84315, dried blood red #8B0000 on dark earth #1A1A0E",
		BackgroundMood:     "scorched desert wasteland, irradiated dunes, dusty orange haze",
		ExplosionStyle:     "chunky pixel debris burst, brown-orange-green particles, thick smoke chunks",
		BulletDirective:    "chunky glowing bullet, thick bright green pixel pellet, 4x4 pixels",
		SpriteSize:         24,
		FrameCount:         4,
		PostProcess:        EffectFilmGrain,
		GoogleFont:         "Silkscreen",
		SfxStyle:           "Crunchy lo-fi, heavy bass impact, distorted chiptune, Vlambeer screenshake audio",
		UnlockedByDefault:  false,
		UnlockDesc:         "Destroy 50 enemies in one run",
	},
	"luftrausers": {
		ID:                 "luftrausers",
		Name:               "Rauser Ace",
		ArtDirective:       "Vlambeer 2014 sepia monochrome WW2 aerial combat. Heavy ink outlines on parchment background, silhouette-focused.",
		StyleKeywords:      "sepia monochrome, WW2 propaganda poster, heavy ink outlines, cream and brown tones, vintage aviation, silhouette art",
		PaletteDescription: "warm sepia #704214, dark ink brown #2C1810, cream parchment #F5E6C8 on aged paper #E8D5B0",
		BackgroundMood:     "overcast sepia sky, thick cloud banks in cream and brown, vintage film grain",
		ExplosionStyle:     "ink-splatter explosion, dark brown burst with sepia smoke rings",
		BulletDirective:    "dark brown ink dot projectile, small circular pellet with short sepia trail, 3x6 pixels",
		SpriteSize:         28,
		FrameCount:         4,
		PostProcess:        EffectVignette,
		GoogleFont:         "Special Elite",
		SfxStyle:           "WW2 propeller engine, vintage radio static, muffled explosions, old film reel audio",
		UnlockedByDefault:  false,
		UnlockDesc:         "Complete 5 sectors without upgrades",
	},
	"nex_machina": {
		ID:                 "nex_machina",
		Name:               "Voxel Storm",
		ArtDirective:       "Housemarque 2017 voxel-art twin-stick shooter. Dense neon particle effects, HDR bloom, dark backgrounds with vivid saturated colors.",
		StyleKeywords:      "voxel 3D rendered, intense neon particles, HDR bloom glow, Housemarque arcade, dense particle effects, vivid saturated neon",
		PaletteDescription: "electric blue #0066FF, hot magenta #FF0066, neon green #00FF66, bright orange #FF6600 on deep black #050510",
		BackgroundMood:     "dark alien planet surface, voxel terrain with deep shadows, distant neon-lit structures",
		ExplosionStyle:     "dense voxel particle shower, bright neon cubes scattering, electric blue and magenta with bloom trails",
		BulletDirective:    "bright neon blue energy cube projectile, small glowing voxel with intense bloom trail, 3x5 pixels",
		SpriteSize:         32,
		FrameCount:         4,
		PostProcess:        EffectBloom,
		GoogleFont:         "Exo 2",
		SfxStyle:           "Dense electronic, bass-heavy impacts, neon synth, Housemarque arcade intensity",
		UnlockedByDefault:  false,
		UnlockDesc:         "Score 500,000 points",
	},
	"tyrian_dos": {
		ID:                 "tyrian_dos",
		Name:               "DOS Reforged",
		ArtDirective:       "1995 DOS-era VGA pixel art space shooter. Richly detailed metallic sprites with dithering, 320x200 aesthetic upscaled.",
		StyleKeywords:      "DOS VGA 256-color, detailed metallic pixel art, dithered shading, 1995 Epic MegaGames, hand-pixeled sprites",
		PaletteDescription: "steel blue #4682B4, gunmetal gray #6C7A89, gold accents #FFD700, engine orange #FF8C00 on deep space blue #0A0A2E",
		BackgroundMood:     "classic DOS parallax starfield, deep blue-purple space, layered star planes",
		ExplosionStyle:     "detailed pixel explosion, orange-yellow-white fireball with dithered shading",
		BulletDirective:    "bright VGA-colored energy bolt, yellow-white elongated pulse with blue edge glow, 3x8 pixels",
		SpriteSize:         32,
		FrameCount:         4,
		PostProcess:        EffectScanlines,
		GoogleFont:         "IBM Plex Mono",
		SfxStyle:           "DOS AdLib/Sound Blaster, FM synthesis, 16-bit game audio, crunchy digital",
		UnlockedByDefault:  false,
		UnlockDesc:         "Reach sector 5",
	},
	"gradius_v": {
		ID:                 "gradius_v",
		Name:               "Vic Viper",
		ArtDirective:       "Treasure/Konami 2004 Japanese shmup. Clean detailed 2D sprites with smooth shading, precise linework, professional arcade quality.",
		StyleKeywords:      "Japanese shmup, Konami arcade, clean detailed 2D, smooth gradient shading, precise mechanical design",
		PaletteDescription: "silver white #E0E0E0, deep navy #0D1B2A, bright red accents #FF1744, gold trim #FFD600, plasma blue #00B8D4",
		BackgroundMood:     "dark outer space with mechanical Moai structures, organic-mechanical landscape, dim purple nebula",
		ExplosionStyle:     "clean bright explosion, white-hot center expanding to orange-red ring, smooth gradient falloff",
		BulletDirective:    "bright plasma blue energy oval, smooth glowing projectile, 3x6 pixels",
		SpriteSize:         32,
		FrameCount:         4,
		PostProcess:        EffectNone,
		GoogleFont:         "Chakra Petch",
		SfxStyle:           "Japanese arcade, clean electronic, precise laser tones, Konami digital",
		UnlockedByDefault:  false,
		UnlockDesc:         "Collect 100 power-ups",
	},
	"rtype": {
		ID:                 "rtype",
		Name:               "Bydo Slayer",
		ArtDirective:       "Irem 1987 biomechanical H.R. Giger aesthetic. Dark brooding alien organic forms merged with machinery, unsettling biological horror.",
		StyleKeywords:      "biomechanical, H.R. Giger inspired, dark organic alien, fleshy machinery, 1987 arcade, horror sci-fi",
		PaletteDescription: "dark flesh pink #8B4557, bone white #DDD5C0, alien red #CC0033, rusted metal #5C4033, sickly green #556B2F on near-black #080810",
		BackgroundMood:     "dark alien interior, biomechanical walls with ribbed organic textures, pulsing veins, dim red ambient",
		ExplosionStyle:     "organic burst, dark red-pink fleshy debris, bone-white fragments, sickly green fluid splatter",
		BulletDirective:    "bright orange-white energy beam segment, thin concentrated laser, 2x8 pixels",
		SpriteSize:         32,
		FrameCount:         4,
		PostProcess:        EffectVignette,
		GoogleFont:         "Teko",
		SfxStyle:           "Dark sci-fi horror, organic squelch, metallic resonance, biomechanical hum",
		UnlockedByDefault:  false,
		UnlockDesc:         "Defeat 10 elite enemies",
	},
	"blazing_lazers": {
		ID:                 "blazing_lazers",
		Name:               "Gunhed",
		ArtDirective:       "Compile/Hudson 1989 TurboGrafx-16 colorful shooter. Vibrant 16-bit palette, clean detailed sprites, cheerful sci-fi action.",
		StyleKeywords:      "TurboGrafx-16 16-bit, vibrant primary colors, clean detailed sprites, 1989 Hudson Soft, cheerful sci-fi",
		PaletteDescription: "bright sky blue #4FC3F7, vivid red #F44336, sunshine yellow #FFEB3B, grass green #66BB6A, hot pink #EC407A on deep blue #0D0D30",
		BackgroundMood:     "colorful alien planet, bright blue sky fading to space, vivid terrain, cheerful cosmic backdrop",
		ExplosionStyle:     "colorful 16-bit explosion, bright red-yellow-white fireball with blue sparks",
		BulletDirective:    "bright yellow-white energy beam, wide vertical pulse with blue edge glow, 4x8 pixels",
		SpriteSize:         28,
		FrameCount:         4,
		PostProcess:        EffectScanlines,
		GoogleFont:         "Bungee",
		SfxStyle:           "Bright 16-bit console, cheerful FM synth, Hudson Soft PC Engine, punchy tones",
		UnlockedByDefault:  false,
		UnlockDesc:         "Win a co-op game",
	},
}

// AllSkins returns all registered skin definitions.
func AllSkins() []SkinDef {
	skins := make([]SkinDef, 0, len(Registry))
	for _, s := range Registry {
		skins = append(skins, s)
	}
	return skins
}

// GetSkin returns a skin definition by ID and whether it was found.
func GetSkin(id string) (SkinDef, bool) {
	s, ok := Registry[id]
	return s, ok
}
