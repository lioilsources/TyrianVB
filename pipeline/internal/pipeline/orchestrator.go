package pipeline

import (
	"context"
	"fmt"
	"os"
	"path/filepath"
	"sync"
	"time"

	"tyrian-pipeline/internal/generator"
	"tyrian-pipeline/internal/grokimage"
	"tyrian-pipeline/internal/skin"
)

// Stats tracks generation results.
type Stats struct {
	Generated int
	Skipped   int
	Failed    int
	Elapsed   time.Duration
}

// Orchestrator coordinates parallel asset generation with rate limiting.
type Orchestrator struct {
	client     grokimage.ImageGenerator
	outDir     string
	workers    int
	n          int // variations per asset
	model      string
	resolution string
	dryRun     bool
	assetType  string // filter: empty = all
}

// OrchestratorOption configures the Orchestrator.
type OrchestratorOption func(*Orchestrator)

func WithWorkers(n int) OrchestratorOption    { return func(o *Orchestrator) { o.workers = n } }
func WithN(n int) OrchestratorOption          { return func(o *Orchestrator) { o.n = n } }
func WithModel(m string) OrchestratorOption   { return func(o *Orchestrator) { o.model = m } }
func WithResolution(r string) OrchestratorOption { return func(o *Orchestrator) { o.resolution = r } }
func WithDryRun(d bool) OrchestratorOption    { return func(o *Orchestrator) { o.dryRun = d } }
func WithAssetType(t string) OrchestratorOption { return func(o *Orchestrator) { o.assetType = t } }

// NewOrchestrator creates a configured Orchestrator.
func NewOrchestrator(client grokimage.ImageGenerator, outDir string, opts ...OrchestratorOption) *Orchestrator {
	o := &Orchestrator{
		client:     client,
		outDir:     outDir,
		workers:    3,
		n:          4,
		model:      "grok-imagine-image",
		resolution: "1k",
	}
	for _, opt := range opts {
		opt(o)
	}
	return o
}

// Run generates all assets for a skin, returning stats.
func (o *Orchestrator) Run(ctx context.Context, s skin.SkinDef) Stats {
	start := time.Now()
	specs := generator.AssetsForSkin(s)

	// Filter by asset type if specified
	if o.assetType != "" {
		filtered := specs[:0]
		for _, spec := range specs {
			if spec.AssetType == o.assetType || spec.Name == o.assetType {
				filtered = append(filtered, spec)
			}
		}
		specs = filtered
	}

	if o.dryRun {
		return o.dryRunSpecs(s, specs, start)
	}

	// Create output directories
	skinDir := filepath.Join(o.outDir, s.ID)
	for _, dir := range []string{"sprites", "backgrounds", "ui", "sfx", "music", "shaders"} {
		os.MkdirAll(filepath.Join(skinDir, dir), 0755)
	}

	// Rate limiter: 1 API call per 2 seconds, shared across workers
	rateLimiter := time.NewTicker(2 * time.Second)
	defer rateLimiter.Stop()

	// Worker pool
	work := make(chan generator.AssetSpec, len(specs))
	for _, spec := range specs {
		work <- spec
	}
	close(work)

	var mu sync.Mutex
	var stats Stats

	var wg sync.WaitGroup
	for i := 0; i < o.workers; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			for spec := range work {
				if ctx.Err() != nil {
					return
				}

				// Check resume: skip if all N variations exist
				if o.allVariationsExist(skinDir, spec) {
					mu.Lock()
					stats.Skipped++
					mu.Unlock()
					fmt.Printf("  SKIP %s/%s (all %d variations exist)\n", spec.OutputDir, spec.Name, o.n)
					continue
				}

				// Rate limit
				select {
				case <-ctx.Done():
					return
				case <-rateLimiter.C:
				}

				err := o.generateAsset(ctx, s, spec, skinDir)
				mu.Lock()
				if err != nil {
					stats.Failed++
					fmt.Printf("  FAIL %s/%s: %v\n", spec.OutputDir, spec.Name, err)
				} else {
					stats.Generated++
					fmt.Printf("  OK   %s/%s (%d variations)\n", spec.OutputDir, spec.Name, o.n)
				}
				mu.Unlock()
			}
		}()
	}

	wg.Wait()
	stats.Elapsed = time.Since(start)
	return stats
}

func (o *Orchestrator) dryRunSpecs(s skin.SkinDef, specs []generator.AssetSpec, start time.Time) Stats {
	fmt.Printf("\n=== DRY RUN: %s (%s) ===\n", s.Name, s.ID)
	fmt.Printf("Assets: %d specs, %d variations each\n\n", len(specs), o.n)

	for i, spec := range specs {
		prompt, err := generator.BuildPrompt(spec.AssetType, s, spec.ExtraVars)
		if err != nil {
			fmt.Printf("[%d] %s/%s — ERROR: %v\n", i+1, spec.OutputDir, spec.Name, err)
			continue
		}
		fmt.Printf("[%d] %s/%s\n", i+1, spec.OutputDir, spec.Name)
		fmt.Printf("    Type: %s | Ratio: %s | Res: %s\n", spec.AssetType, spec.AspectRatio, spec.Resolution)
		fmt.Printf("    Output: {skin}/%s/%s_v1..v%d.jpg\n", spec.OutputDir, spec.Name, o.n)
		fmt.Printf("    Prompt:\n    %s\n\n", prompt)
	}

	return Stats{Elapsed: time.Since(start)}
}

func (o *Orchestrator) generateAsset(ctx context.Context, s skin.SkinDef, spec generator.AssetSpec, skinDir string) error {
	prompt, err := generator.BuildPrompt(spec.AssetType, s, spec.ExtraVars)
	if err != nil {
		return fmt.Errorf("build prompt: %w", err)
	}

	// Use spec-specific resolution/ratio, falling back to orchestrator defaults
	resolution := spec.Resolution
	if resolution == "" {
		resolution = o.resolution
	}
	aspectRatio := spec.AspectRatio

	resp, err := o.client.Generate(ctx, grokimage.GenerateRequest{
		Model:          o.model,
		Prompt:         prompt,
		N:              o.n,
		AspectRatio:    aspectRatio,
		Resolution:     resolution,
		ResponseFormat: "b64_json",
	})
	if err != nil {
		return err
	}

	// Save each variation
	for i, img := range resp.Data {
		filename := fmt.Sprintf("%s_v%d.jpg", spec.Name, i+1)
		outPath := filepath.Join(skinDir, spec.OutputDir, filename)

		imgBytes, err := img.Bytes()
		if err != nil {
			return fmt.Errorf("decode image %d: %w", i+1, err)
		}

		if err := os.WriteFile(outPath, imgBytes, 0644); err != nil {
			return fmt.Errorf("write %s: %w", outPath, err)
		}
	}
	return nil
}

func (o *Orchestrator) allVariationsExist(skinDir string, spec generator.AssetSpec) bool {
	for i := 1; i <= o.n; i++ {
		filename := fmt.Sprintf("%s_v%d.jpg", spec.Name, i)
		path := filepath.Join(skinDir, spec.OutputDir, filename)
		info, err := os.Stat(path)
		if err != nil || info.Size() == 0 {
			return false
		}
	}
	return true
}
