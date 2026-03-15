package postprocess

import (
	"image"
	"image/color"
	"testing"
)

func TestResize_4x4to2x2(t *testing.T) {
	src := image.NewNRGBA(image.Rect(0, 0, 4, 4))

	// Top-left 2×2 block: red
	for y := 0; y < 2; y++ {
		for x := 0; x < 2; x++ {
			src.SetNRGBA(x, y, color.NRGBA{200, 0, 0, 255})
		}
	}
	// Top-right 2×2: green
	for y := 0; y < 2; y++ {
		for x := 2; x < 4; x++ {
			src.SetNRGBA(x, y, color.NRGBA{0, 200, 0, 255})
		}
	}
	// Bottom-left 2×2: blue
	for y := 2; y < 4; y++ {
		for x := 0; x < 2; x++ {
			src.SetNRGBA(x, y, color.NRGBA{0, 0, 200, 255})
		}
	}
	// Bottom-right 2×2: white
	for y := 2; y < 4; y++ {
		for x := 2; x < 4; x++ {
			src.SetNRGBA(x, y, color.NRGBA{200, 200, 200, 255})
		}
	}

	result := Resize(src, 2)
	if result.Bounds().Dx() != 2 || result.Bounds().Dy() != 2 {
		t.Fatalf("expected 2×2, got %d×%d", result.Bounds().Dx(), result.Bounds().Dy())
	}

	// Each output pixel is the average of its 2×2 source block
	check := func(x, y int, wantR, wantG, wantB uint8) {
		c := result.NRGBAAt(x, y)
		if c.R != wantR || c.G != wantG || c.B != wantB {
			t.Errorf("(%d,%d) = (%d,%d,%d), want (%d,%d,%d)",
				x, y, c.R, c.G, c.B, wantR, wantG, wantB)
		}
		if c.A != 255 {
			t.Errorf("(%d,%d) alpha=%d, want 255", x, y, c.A)
		}
	}

	check(0, 0, 200, 0, 0)     // red
	check(1, 0, 0, 200, 0)     // green
	check(0, 1, 0, 0, 200)     // blue
	check(1, 1, 200, 200, 200) // white
}

func TestResize_AspectRatio(t *testing.T) {
	// Non-square: 8×4 → target 4 → should become 4×2
	src := image.NewNRGBA(image.Rect(0, 0, 8, 4))
	for y := 0; y < 4; y++ {
		for x := 0; x < 8; x++ {
			src.SetNRGBA(x, y, color.NRGBA{128, 128, 128, 255})
		}
	}

	result := Resize(src, 4)
	if result.Bounds().Dx() != 4 || result.Bounds().Dy() != 2 {
		t.Errorf("expected 4×2, got %d×%d", result.Bounds().Dx(), result.Bounds().Dy())
	}
}

func TestResize_AlreadySmall(t *testing.T) {
	// 2×2 with target 128 → returns same image
	src := image.NewNRGBA(image.Rect(0, 0, 2, 2))
	result := Resize(src, 128)
	if result != src {
		t.Error("expected same image when already smaller than target")
	}
}
