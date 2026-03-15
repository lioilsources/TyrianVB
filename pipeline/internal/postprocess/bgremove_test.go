package postprocess

import (
	"image"
	"image/color"
	"testing"
)

func TestRemoveBackground_SolidBlack(t *testing.T) {
	// 4×4 image: black background with a white center pixel
	img := image.NewRGBA(image.Rect(0, 0, 4, 4))
	// Fill black
	for y := 0; y < 4; y++ {
		for x := 0; x < 4; x++ {
			img.Set(x, y, color.RGBA{0, 0, 0, 255})
		}
	}
	// White center
	img.Set(2, 2, color.RGBA{255, 255, 255, 255})

	result := RemoveBackground(img, 30, 15)

	// Corner pixels should be fully transparent (background)
	for _, pt := range [][2]int{{0, 0}, {3, 0}, {0, 3}, {3, 3}} {
		c := result.NRGBAAt(pt[0], pt[1])
		if c.A != 0 {
			t.Errorf("corner (%d,%d) alpha=%d, want 0", pt[0], pt[1], c.A)
		}
	}

	// White pixel should be fully opaque
	c := result.NRGBAAt(2, 2)
	if c.A != 255 {
		t.Errorf("white pixel alpha=%d, want 255", c.A)
	}
}

func TestRemoveBackground_GradientEdge(t *testing.T) {
	// 1×5 strip: pixel values 0, 10, 30, 45, 255 on black bg
	// threshold=30, margin=15 → distances < 30 transparent, 30-45 ramp, >45 opaque
	img := image.NewRGBA(image.Rect(0, 0, 5, 1))
	for i, v := range []uint8{0, 10, 30, 45, 255} {
		img.Set(i, 0, color.RGBA{v, v, v, 255})
	}

	// Corners are (0,0) and (4,0) — bg will average to ~midpoint.
	// For a clean test, make all corners black:
	// Row is only 1 high so corners are (0,0), (4,0), (0,0), (4,0).
	// Pixel 0 = black, pixel 4 = white → bg = average ≈ (127,127,127)
	// This makes the test less clean. Let's use a 5×3 image with black borders.

	img2 := image.NewRGBA(image.Rect(0, 0, 5, 3))
	// Fill black
	for y := 0; y < 3; y++ {
		for x := 0; x < 5; x++ {
			img2.Set(x, y, color.RGBA{0, 0, 0, 255})
		}
	}
	// Middle row: gradient
	for i, v := range []uint8{0, 10, 30, 45, 255} {
		img2.Set(i, 1, color.RGBA{v, v, v, 255})
	}

	result := RemoveBackground(img2, 30, 15)

	// (0,1) is black like bg → alpha=0
	if a := result.NRGBAAt(0, 1).A; a != 0 {
		t.Errorf("pixel(0,1) alpha=%d, want 0", a)
	}

	// (1,1) gray=10 → distance ~17.3, below threshold 30 → alpha=0
	if a := result.NRGBAAt(1, 1).A; a != 0 {
		t.Errorf("pixel(1,1) alpha=%d, want 0", a)
	}

	// (2,1) gray=30 → distance ~51.96, above threshold 30 → should be in ramp or opaque
	a2 := result.NRGBAAt(2, 1).A
	if a2 == 0 {
		t.Errorf("pixel(2,1) alpha=%d, want >0", a2)
	}

	// (4,1) gray=255 → distance ~441.7, fully opaque
	if a := result.NRGBAAt(4, 1).A; a != 255 {
		t.Errorf("pixel(4,1) alpha=%d, want 255", a)
	}
}

func TestRemoveBackground_NonBlackBg(t *testing.T) {
	// 4×4 image with blue background
	img := image.NewRGBA(image.Rect(0, 0, 4, 4))
	blue := color.RGBA{0, 0, 200, 255}
	for y := 0; y < 4; y++ {
		for x := 0; x < 4; x++ {
			img.Set(x, y, blue)
		}
	}
	// Red pixel in center
	img.Set(2, 2, color.RGBA{255, 0, 0, 255})

	result := RemoveBackground(img, 30, 15)

	// Background (blue) pixels should be transparent
	if a := result.NRGBAAt(0, 0).A; a != 0 {
		t.Errorf("bg pixel alpha=%d, want 0", a)
	}

	// Red pixel should be opaque (far from blue)
	if a := result.NRGBAAt(2, 2).A; a != 255 {
		t.Errorf("red pixel alpha=%d, want 255", a)
	}
}
