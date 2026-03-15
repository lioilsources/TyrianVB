package main

import (
	"flag"
	"fmt"
	"os"
	"path/filepath"

	"tyrian-pipeline/internal/postprocess"
)

func main() {
	skinID := flag.String("skin", "", "Skin ID to process (required)")
	input := flag.String("input", "output/assets/skins", "Pipeline output dir")
	output := flag.String("output", "../tyrian_mobile/assets/skins", "Game assets dir")
	variation := flag.Int("variation", 1, "Which variation to use (default 1)")
	size := flag.Int("size", 128, "Max target dimension px")
	threshold := flag.Int("threshold", 30, "Background removal threshold")
	margin := flag.Int("margin", 15, "Background removal soft-edge margin")
	flag.Parse()

	var skinIDs []string
	if *skinID != "" {
		skinIDs = append(skinIDs, *skinID)
	} else {
		// Process all skins found in the input directory
		entries, err := os.ReadDir(*input)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error reading input dir: %v\n", err)
			os.Exit(1)
		}
		for _, e := range entries {
			if e.IsDir() {
				skinIDs = append(skinIDs, e.Name())
			}
		}
		if len(skinIDs) == 0 {
			fmt.Fprintln(os.Stderr, "No skin directories found in", *input)
			os.Exit(1)
		}
		fmt.Printf("Processing %d skins: %v\n\n", len(skinIDs), skinIDs)
	}

	for _, id := range skinIDs {
		cfg := postprocess.Config{
			SkinDir:     filepath.Join(*input, id),
			OutputDir:   filepath.Join(*output, id),
			Variation:   *variation,
			TargetSize:  *size,
			BgThreshold: *threshold,
			BgMargin:    *margin,
		}

		if err := postprocess.Run(cfg); err != nil {
			fmt.Fprintf(os.Stderr, "Error processing %s: %v\n", id, err)
			continue
		}
	}
}
