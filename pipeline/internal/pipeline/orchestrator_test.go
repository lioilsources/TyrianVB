package pipeline

import (
	"context"
	"encoding/base64"
	"os"
	"path/filepath"
	"testing"

	"tyrian-pipeline/internal/grokimage"
	"tyrian-pipeline/internal/skin"
)

// mockGenerator implements grokimage.ImageGenerator for testing.
type mockGenerator struct {
	calls    int
	failNext bool
}

func (m *mockGenerator) Generate(ctx context.Context, req grokimage.GenerateRequest) (*grokimage.GenerateResponse, error) {
	m.calls++
	if m.failNext {
		m.failNext = false
		return nil, &grokimage.APIError{StatusCode: 500, Message: "mock error", Retryable: false}
	}

	fakeJPG := base64.StdEncoding.EncodeToString([]byte("fake-jpg-content"))
	data := make([]grokimage.ImageData, req.N)
	for i := range data {
		data[i] = grokimage.ImageData{B64JSON: fakeJPG, RevisedPrompt: "revised"}
	}
	return &grokimage.GenerateResponse{Data: data}, nil
}

func TestOrchestratorDryRun(t *testing.T) {
	mock := &mockGenerator{}
	outDir := t.TempDir()

	orch := NewOrchestrator(mock, outDir, WithDryRun(true), WithN(2))
	s, _ := skin.GetSkin("space_invaders")
	stats := orch.Run(context.Background(), s)

	if mock.calls != 0 {
		t.Errorf("dry run should make 0 API calls, got %d", mock.calls)
	}
	if stats.Generated != 0 {
		t.Error("dry run should not generate anything")
	}
}

func TestOrchestratorGenerate(t *testing.T) {
	mock := &mockGenerator{}
	outDir := t.TempDir()

	orch := NewOrchestrator(mock, outDir,
		WithWorkers(1),
		WithN(2),
		WithAssetType("ship"),
	)
	s, _ := skin.GetSkin("space_invaders")
	stats := orch.Run(context.Background(), s)

	if stats.Generated != 1 {
		t.Errorf("expected 1 generated, got %d", stats.Generated)
	}
	if stats.Failed != 0 {
		t.Errorf("expected 0 failed, got %d", stats.Failed)
	}

	// Check output files exist
	v1 := filepath.Join(outDir, "space_invaders", "sprites", "ship_frames_v1.jpg")
	v2 := filepath.Join(outDir, "space_invaders", "sprites", "ship_frames_v2.jpg")
	for _, path := range []string{v1, v2} {
		info, err := os.Stat(path)
		if err != nil {
			t.Errorf("expected file %s to exist: %v", path, err)
		} else if info.Size() == 0 {
			t.Errorf("expected file %s to have content", path)
		}
	}
}

func TestOrchestratorResume(t *testing.T) {
	mock := &mockGenerator{}
	outDir := t.TempDir()

	// Pre-create files to simulate previous run
	skinDir := filepath.Join(outDir, "space_invaders", "sprites")
	os.MkdirAll(skinDir, 0755)
	for i := 1; i <= 2; i++ {
		path := filepath.Join(skinDir, "ship_frames_v"+string(rune('0'+i))+".jpg")
		os.WriteFile(path, []byte("existing"), 0644)
	}

	orch := NewOrchestrator(mock, outDir,
		WithWorkers(1),
		WithN(2),
		WithAssetType("ship"),
	)
	s, _ := skin.GetSkin("space_invaders")
	stats := orch.Run(context.Background(), s)

	if stats.Skipped != 1 {
		t.Errorf("expected 1 skipped (resume), got %d", stats.Skipped)
	}
	if mock.calls != 0 {
		t.Errorf("resume should make 0 API calls, got %d", mock.calls)
	}
}

func TestOrchestratorDirectories(t *testing.T) {
	mock := &mockGenerator{}
	outDir := t.TempDir()

	orch := NewOrchestrator(mock, outDir,
		WithWorkers(1),
		WithN(1),
		WithAssetType("ship"),
	)
	s, _ := skin.GetSkin("space_invaders")
	orch.Run(context.Background(), s)

	// Check that placeholder directories were created
	for _, dir := range []string{"sfx", "music", "shaders"} {
		path := filepath.Join(outDir, "space_invaders", dir)
		info, err := os.Stat(path)
		if err != nil {
			t.Errorf("expected directory %s to exist: %v", dir, err)
		} else if !info.IsDir() {
			t.Errorf("expected %s to be a directory", dir)
		}
	}
}
