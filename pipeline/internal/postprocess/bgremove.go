package postprocess

import (
	"image"
	"image/color"
	"math"
)

// RemoveBackground detects the dominant background color from image corners
// and sets alpha based on euclidean color distance.
// Pixels close to the background color become transparent; others stay opaque.
// A soft ramp between threshold and threshold+margin provides anti-aliased edges.
func RemoveBackground(src image.Image, threshold, margin int) *image.NRGBA {
	bounds := src.Bounds()
	w, h := bounds.Dx(), bounds.Dy()
	dst := image.NewNRGBA(bounds)

	bg := sampleBackground(src)
	thresh := float64(threshold)
	marg := float64(margin)

	for y := bounds.Min.Y; y < bounds.Max.Y; y++ {
		for x := bounds.Min.X; x < bounds.Max.X; x++ {
			r, g, b, _ := src.At(x, y).RGBA()
			sr := uint8(r >> 8)
			sg := uint8(g >> 8)
			sb := uint8(b >> 8)

			dist := colorDistance(sr, sg, sb, bg)

			var alpha uint8
			if dist < thresh {
				alpha = 0
			} else if marg <= 0 || dist > thresh+marg {
				alpha = 255
			} else {
				t := (dist - thresh) / marg
				alpha = uint8(t * 255)
			}

			dst.SetNRGBA(x, y, color.NRGBA{R: sr, G: sg, B: sb, A: alpha})
			_ = w
			_ = h
		}
	}
	return dst
}

// sampleBackground samples the 4 corners of the image and returns the average color.
func sampleBackground(src image.Image) [3]uint8 {
	bounds := src.Bounds()
	corners := [][2]int{
		{bounds.Min.X, bounds.Min.Y},
		{bounds.Max.X - 1, bounds.Min.Y},
		{bounds.Min.X, bounds.Max.Y - 1},
		{bounds.Max.X - 1, bounds.Max.Y - 1},
	}

	var rSum, gSum, bSum int
	for _, c := range corners {
		r, g, b, _ := src.At(c[0], c[1]).RGBA()
		rSum += int(r >> 8)
		gSum += int(g >> 8)
		bSum += int(b >> 8)
	}

	return [3]uint8{
		uint8(rSum / 4),
		uint8(gSum / 4),
		uint8(bSum / 4),
	}
}

// colorDistance computes euclidean distance in RGB space.
func colorDistance(r, g, b uint8, bg [3]uint8) float64 {
	dr := float64(r) - float64(bg[0])
	dg := float64(g) - float64(bg[1])
	db := float64(b) - float64(bg[2])
	return math.Sqrt(dr*dr + dg*dg + db*db)
}
