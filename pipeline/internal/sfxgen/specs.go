package sfxgen

import "fmt"

// SfxSpec defines a single sound effect to generate.
type SfxSpec struct {
	Name      string  // output filename (without extension)
	EventDesc string  // description of the sound event
	Duration  float64 // target duration in seconds
}

// SfxSpecs lists all sound effects to generate per skin.
var SfxSpecs = []SfxSpec{
	{"fire_bullet", "laser shot, quick projectile fire", 0.5},
	{"fire_beam", "sustained energy beam, continuous hum", 0.8},
	{"hit_shield", "energy shield deflection, electronic ping", 0.5},
	{"hit_hull", "metallic hull impact, damage crunch", 0.5},
	{"explosion_small", "small explosion, quick impact burst", 0.5},
	{"explosion_large", "massive explosion, deep boom with debris", 1.2},
	{"pickup", "item collect chime, bright ascending tone", 0.5},
	{"weapon_unlock", "power-up unlock fanfare, triumphant jingle", 1.5},
	{"sector_complete", "level complete victory fanfare", 2.0},
	{"game_over", "defeat sting, descending somber tone", 2.5},
}

// BuildSfxPrompt constructs the ElevenLabs prompt for a given skin style and SFX spec.
func BuildSfxPrompt(sfxStyle string, spec SfxSpec) string {
	return sfxStyle + " " + spec.EventDesc + ". Short sound effect, " +
		formatDuration(spec.Duration) + " seconds, game audio."
}

func formatDuration(d float64) string {
	if d == float64(int(d)) {
		return fmt.Sprintf("%.1f", d)
	}
	return fmt.Sprintf("%.1f", d)
}
