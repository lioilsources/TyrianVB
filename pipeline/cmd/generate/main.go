package main

import (
	"bufio"
	"context"
	"flag"
	"fmt"
	"os"
	"os/signal"
	"path/filepath"
	"strings"
	"time"

	"tyrian-pipeline/internal/generator"
	"tyrian-pipeline/internal/grokimage"
	"tyrian-pipeline/internal/pipeline"
	"tyrian-pipeline/internal/sfxgen"
	"tyrian-pipeline/internal/skin"
)

func main() {
	loadEnvFile(".env")

	skinID := flag.String("skin", "", "Skin ID to generate (empty = all skins)")
	outDir := flag.String("out", "output/assets/skins", "Output directory")
	workers := flag.Int("workers", 3, "Number of concurrent workers")
	model := flag.String("model", "grok-imagine-image", "Image generation model")
	dryRun := flag.Bool("dry-run", false, "Print prompts without calling API")
	assetType := flag.String("asset-type", "", "Filter by asset type (ship, explosion, bullet, enemy, structure, background, hud_icon, preview)")
	n := flag.Int("n", 4, "Number of variations per asset")
	resolution := flag.String("resolution", "1k", "Image resolution (1k, 2k)")
	sfxMode := flag.Bool("sfx", false, "Generate SFX via ElevenLabs instead of images")
	flag.Parse()

	// SFX generation mode
	if *sfxMode {
		runSfxGeneration(*skinID, *outDir, *dryRun)
		return
	}

	// Validate API key (unless dry run)
	apiKey := os.Getenv("XAI_API_KEY")
	if apiKey == "" && !*dryRun {
		fmt.Fprintln(os.Stderr, "Error: XAI_API_KEY environment variable is required (or use -dry-run)")
		os.Exit(1)
	}

	// Resolve skins to process
	var skins []skin.SkinDef
	if *skinID != "" {
		s, ok := skin.GetSkin(*skinID)
		if !ok {
			fmt.Fprintf(os.Stderr, "Error: unknown skin %q\nAvailable skins: %s\n", *skinID, availableSkins())
			os.Exit(1)
		}
		skins = append(skins, s)
	} else {
		skins = skin.AllSkins()
	}

	// Create client
	var client grokimage.ImageGenerator
	if !*dryRun {
		client = grokimage.NewClient(apiKey)
	}

	// Setup context with interrupt handling
	ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt)
	defer cancel()

	// Create orchestrator
	orch := pipeline.NewOrchestrator(client, *outDir,
		pipeline.WithWorkers(*workers),
		pipeline.WithN(*n),
		pipeline.WithModel(*model),
		pipeline.WithResolution(*resolution),
		pipeline.WithDryRun(*dryRun),
		pipeline.WithAssetType(*assetType),
	)

	start := time.Now()
	var totalGenerated, totalSkipped, totalFailed int

	for _, s := range skins {
		fmt.Printf("\n--- Generating: %s (%s) ---\n", s.Name, s.ID)

		stats := orch.Run(ctx, s)
		totalGenerated += stats.Generated
		totalSkipped += stats.Skipped
		totalFailed += stats.Failed

		// Generate manifest (skip in dry-run)
		if !*dryRun {
			skinDir := filepath.Join(*outDir, s.ID)
			specs := generator.AssetsForSkin(s)
			inputs := make([]skin.ManifestAssetInput, len(specs))
			for i, sp := range specs {
				inputs[i] = skin.ManifestAssetInput{
					Name: sp.Name, AssetType: sp.AssetType, OutputDir: sp.OutputDir,
					AspectRatio: sp.AspectRatio, Resolution: sp.Resolution,
				}
			}
			// Add SFX entries if sfx/ dir has files
			sfxDir := filepath.Join(skinDir, "sfx")
			if entries, err := os.ReadDir(sfxDir); err == nil {
				for _, e := range entries {
					if !e.IsDir() && (strings.HasSuffix(e.Name(), ".mp3") || strings.HasSuffix(e.Name(), ".ogg")) {
						baseName := strings.TrimSuffix(strings.TrimSuffix(e.Name(), ".mp3"), ".ogg")
						inputs = append(inputs, skin.ManifestAssetInput{
							Name: baseName, AssetType: "sfx", OutputDir: "sfx",
						})
					}
				}
			}
			if err := skin.GenerateManifest(skinDir, s, *model, *n, inputs); err != nil {
				fmt.Fprintf(os.Stderr, "Warning: manifest generation failed for %s: %v\n", s.ID, err)
			}
		}
	}

	elapsed := time.Since(start)
	fmt.Printf("\n=== Summary ===\n")
	fmt.Printf("Generated: %d | Skipped: %d | Failed: %d\n", totalGenerated, totalSkipped, totalFailed)
	fmt.Printf("Elapsed: %s\n", elapsed.Round(time.Millisecond))
}

// loadEnvFile reads KEY=VALUE pairs from a file into os env.
// Skips missing file, comments, and empty lines. Does not override existing env vars.
func loadEnvFile(path string) {
	f, err := os.Open(path)
	if err != nil {
		return
	}
	defer f.Close()

	scanner := bufio.NewScanner(f)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}
		key, val, ok := strings.Cut(line, "=")
		if !ok {
			continue
		}
		key = strings.TrimSpace(key)
		val = strings.TrimSpace(val)
		if os.Getenv(key) == "" {
			os.Setenv(key, val)
		}
	}
}

func runSfxGeneration(skinID, outDir string, dryRun bool) {
	apiKey := os.Getenv("ELEVENLABS_API_KEY")
	if apiKey == "" && !dryRun {
		fmt.Fprintln(os.Stderr, "Error: ELEVENLABS_API_KEY environment variable is required for SFX generation (or use -dry-run)")
		os.Exit(1)
	}

	var skins []skin.SkinDef
	if skinID != "" {
		s, ok := skin.GetSkin(skinID)
		if !ok {
			fmt.Fprintf(os.Stderr, "Error: unknown skin %q\nAvailable skins: %s\n", skinID, availableSkins())
			os.Exit(1)
		}
		skins = append(skins, s)
	} else {
		skins = skin.AllSkins()
	}

	ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt)
	defer cancel()

	var client *sfxgen.Client
	if !dryRun {
		client = sfxgen.NewClient(apiKey)
	}

	start := time.Now()
	var generated, skipped int

	for _, s := range skins {
		if s.SfxStyle == "" {
			fmt.Printf("Skipping %s (no SfxStyle defined)\n", s.ID)
			continue
		}

		sfxDir := filepath.Join(outDir, s.ID, "sfx")
		if err := os.MkdirAll(sfxDir, 0755); err != nil {
			fmt.Fprintf(os.Stderr, "Error creating dir %s: %v\n", sfxDir, err)
			continue
		}

		fmt.Printf("\n--- SFX: %s (%s) ---\n", s.Name, s.ID)

		for _, spec := range sfxgen.SfxSpecs {
			outPath := filepath.Join(sfxDir, spec.Name+".mp3")

			// Resume: skip if exists
			if _, err := os.Stat(outPath); err == nil {
				fmt.Printf("  [skip] %s (exists)\n", spec.Name)
				skipped++
				continue
			}

			prompt := sfxgen.BuildSfxPrompt(s.SfxStyle, spec)

			if dryRun {
				fmt.Printf("  [dry] %s: %s\n", spec.Name, prompt)
				continue
			}

			fmt.Printf("  [gen] %s ...", spec.Name)

			data, err := client.Generate(ctx, sfxgen.GenerateRequest{
				Text:            prompt,
				DurationSeconds: spec.Duration,
				PromptInfluence: 0.5,
			})
			if err != nil {
				fmt.Printf(" FAILED: %v\n", err)
				continue
			}

			if err := os.WriteFile(outPath, data, 0644); err != nil {
				fmt.Printf(" WRITE ERROR: %v\n", err)
				continue
			}

			fmt.Printf(" OK (%d bytes)\n", len(data))
			generated++

			// Rate limit: 1 request per 2 seconds
			select {
			case <-ctx.Done():
				fmt.Println("\nInterrupted")
				return
			case <-time.After(2 * time.Second):
			}
		}
	}

	elapsed := time.Since(start)
	fmt.Printf("\n=== SFX Summary ===\n")
	fmt.Printf("Generated: %d | Skipped: %d\n", generated, skipped)
	fmt.Printf("Elapsed: %s\n", elapsed.Round(time.Millisecond))
}

func availableSkins() string {
	skins := skin.AllSkins()
	ids := make([]string, len(skins))
	for i, s := range skins {
		ids[i] = s.ID
	}
	return strings.Join(ids, ", ")
}
