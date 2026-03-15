package postprocess

import "strings"

// GameName maps a pipeline asset name to the game sprite name.
// Returns the mapped name and true, or "" and false if the asset should be skipped.
func GameName(pipelineName string) (string, bool) {
	// Ship frames → vessel
	if pipelineName == "ship_frames" {
		return "vessel", true
	}

	// Explosion is handled specially (v1-v4 → explosion1-explosion4)
	// The caller handles this; we just confirm it's valid.
	if pipelineName == "explosion" {
		return "explosion", true
	}

	// All others: drop any _v{N} suffix (but that's handled at file level, not name level).
	// The pipeline name is already the game name for enemies, structures, bullets.
	return pipelineName, true
}

// StripVariationSuffix removes the _v{N} suffix from a filename stem.
// e.g. "falcon_v2" → "falcon"
func StripVariationSuffix(name string) string {
	idx := strings.LastIndex(name, "_v")
	if idx < 0 {
		return name
	}
	// Verify everything after _v is digits
	suffix := name[idx+2:]
	for _, c := range suffix {
		if c < '0' || c > '9' {
			return name
		}
	}
	return name[:idx]
}
