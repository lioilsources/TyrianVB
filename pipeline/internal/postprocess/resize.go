package postprocess

import (
	"image"
	"image/color"
)

// ResizeExact scales src to exactly dstW×dstH using area-average (box filter).
func ResizeExact(src image.Image, dstW, dstH int) *image.NRGBA {
	bounds := src.Bounds()
	srcW := bounds.Dx()
	srcH := bounds.Dy()
	dst := image.NewNRGBA(image.Rect(0, 0, dstW, dstH))

	for dy := 0; dy < dstH; dy++ {
		sy0 := dy * srcH / dstH
		sy1 := (dy + 1) * srcH / dstH
		if sy1 <= sy0 {
			sy1 = sy0 + 1
		}
		for dx := 0; dx < dstW; dx++ {
			sx0 := dx * srcW / dstW
			sx1 := (dx + 1) * srcW / dstW
			if sx1 <= sx0 {
				sx1 = sx0 + 1
			}

			var rSum, gSum, bSum, aSum, count int
			for sy := sy0; sy < sy1; sy++ {
				for sx := sx0; sx < sx1; sx++ {
					r, g, b, a := src.At(sx+bounds.Min.X, sy+bounds.Min.Y).RGBA()
					rSum += int(r >> 8)
					gSum += int(g >> 8)
					bSum += int(b >> 8)
					aSum += int(a >> 8)
					count++
				}
			}
			if count == 0 {
				count = 1
			}
			dst.SetNRGBA(dx, dy, color.NRGBA{
				R: uint8(rSum / count),
				G: uint8(gSum / count),
				B: uint8(bSum / count),
				A: uint8(aSum / count),
			})
		}
	}
	return dst
}

// Resize downscales src to fit within targetSize×targetSize using area-average
// (box filter). Aspect ratio is preserved — the longer dimension becomes targetSize.
// If the source is already smaller than targetSize, it is returned as-is.
func Resize(src *image.NRGBA, targetSize int) *image.NRGBA {
	bounds := src.Bounds()
	srcW := bounds.Dx()
	srcH := bounds.Dy()

	if srcW <= targetSize && srcH <= targetSize {
		return src
	}

	// Determine output dimensions preserving aspect ratio.
	var dstW, dstH int
	if srcW >= srcH {
		dstW = targetSize
		dstH = srcH * targetSize / srcW
		if dstH < 1 {
			dstH = 1
		}
	} else {
		dstH = targetSize
		dstW = srcW * targetSize / srcH
		if dstW < 1 {
			dstW = 1
		}
	}

	dst := image.NewNRGBA(image.Rect(0, 0, dstW, dstH))

	for dy := 0; dy < dstH; dy++ {
		// Source row range for this destination row.
		sy0 := dy * srcH / dstH
		sy1 := (dy + 1) * srcH / dstH
		if sy1 <= sy0 {
			sy1 = sy0 + 1
		}

		for dx := 0; dx < dstW; dx++ {
			// Source column range for this destination column.
			sx0 := dx * srcW / dstW
			sx1 := (dx + 1) * srcW / dstW
			if sx1 <= sx0 {
				sx1 = sx0 + 1
			}

			var rSum, gSum, bSum, aSum, count int
			for sy := sy0; sy < sy1; sy++ {
				for sx := sx0; sx < sx1; sx++ {
					c := src.NRGBAAt(sx+bounds.Min.X, sy+bounds.Min.Y)
					rSum += int(c.R)
					gSum += int(c.G)
					bSum += int(c.B)
					aSum += int(c.A)
					count++
				}
			}

			if count == 0 {
				count = 1
			}
			dst.SetNRGBA(dx, dy, color.NRGBA{
				R: uint8(rSum / count),
				G: uint8(gSum / count),
				B: uint8(bSum / count),
				A: uint8(aSum / count),
			})
		}
	}
	return dst
}
