package optimizer

import (
	"fmt"
	"strings"

	"github.com/h2non/bimg"
)

type ImageParams struct {
	ImagePath string
	Width     int
	Height    int
	Quality   int
	Format    string
}

type Optimizer struct {
	maxWidth  int
	maxHeight int
	quality   int
}

func NewOptimizer(maxWidth, maxHeight, quality int) *Optimizer {
	return &Optimizer{
		maxWidth:  maxWidth,
		maxHeight: maxHeight,
		quality:   quality,
	}
}

func (o *Optimizer) Optimize(data []byte, params ImageParams) ([]byte, string, error) {
	image := bimg.NewImage(data)

	size, err := image.Size()
	if err != nil {
		return nil, "", fmt.Errorf("failed to get image size: %w", err)
	}

	width, height := o.calculateDimensions(size.Width, size.Height, params)

	outputType, err := o.determineFormat(params.Format, data)
	if err != nil {
		return nil, "", err
	}

	options := bimg.Options{
		Width:   width,
		Height:  height,
		Quality: params.Quality,
		Type:    outputType,
		Crop:    false,
		Enlarge: false,
		Embed:   false,
	}

	processed, err := image.Process(options)
	if err != nil {
		return nil, "", fmt.Errorf("failed to process image: %w", err)
	}

	contentType := o.getContentType(outputType)

	return processed, contentType, nil
}

func (o *Optimizer) calculateDimensions(origWidth, origHeight int, params ImageParams) (int, int) {
	width := params.Width
	height := params.Height

	if width == 0 && height == 0 {
		width = origWidth
		height = origHeight
	}

	if width > 0 && height == 0 {
		height = int(float64(origHeight) * float64(width) / float64(origWidth))
	}

	if height > 0 && width == 0 {
		width = int(float64(origWidth) * float64(height) / float64(origHeight))
	}

	if width > o.maxWidth {
		height = int(float64(height) * float64(o.maxWidth) / float64(width))
		width = o.maxWidth
	}

	if height > o.maxHeight {
		width = int(float64(width) * float64(o.maxHeight) / float64(height))
		height = o.maxHeight
	}

	return width, height
}

func (o *Optimizer) determineFormat(format string, data []byte) (bimg.ImageType, error) {
	currentType := bimg.DetermineImageType(data)

	if format == "auto" || format == "" {
		return bimg.WEBP, nil
	}

	switch strings.ToLower(format) {
	case "jpeg", "jpg":
		return bimg.JPEG, nil
	case "png":
		return bimg.PNG, nil
	case "webp":
		return bimg.WEBP, nil
	case "gif":
		return bimg.GIF, nil
	case "tiff":
		return bimg.TIFF, nil
	case "original":
		return currentType, nil
	default:
		return bimg.WEBP, nil
	}
}

func (o *Optimizer) getContentType(imageType bimg.ImageType) string {
	switch imageType {
	case bimg.JPEG:
		return "image/jpeg"
	case bimg.PNG:
		return "image/png"
	case bimg.WEBP:
		return "image/webp"
	case bimg.GIF:
		return "image/gif"
	case bimg.TIFF:
		return "image/tiff"
	default:
		return "application/octet-stream"
	}
}
