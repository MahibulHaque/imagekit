package imgprocessor

import (
	"fmt"

	"github.com/h2non/bimg"
	"github.com/mahibulhaque/imagekit/internal/queue"
)

func Process(img []byte, job queue.Job) ([]byte, error) {
	image := bimg.NewImage(img)

	opts := bimg.Options{
		Width:  job.Width,
		Height: job.Height,
	}

	switch job.Format {
	case "jpeg", "jpg":
		opts.Type = bimg.JPEG
	case "png":
		opts.Type = bimg.PNG
	case "webp":
		opts.Type = bimg.WEBP
	default:
		opts.Type = bimg.WEBP
	}

	newImage, err := image.Process(opts)
	if err != nil {
		return nil, fmt.Errorf("failed to process image: %w", err)
	}

	return newImage, nil
}
