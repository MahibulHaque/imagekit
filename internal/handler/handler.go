package handler

import (
	"context"
	"fmt"
	"log"
	"net/url"
	"strconv"
	"strings"

	"github.com/aws/aws-lambda-go/events"
	"github.com/mahibulhaque/imagekit/internal/optimizer"
	"github.com/mahibulhaque/imagekit/internal/storage"
)

type Config struct {
	SourceBucket string
	CacheBucket  string
	Region       string
	MaxWidth     int
	MaxHeight    int
	Quality      int
}

type Handler struct {
	config    Config
	optimizer *optimizer.Optimizer
	storage   *storage.S3Storage
}

func New(config Config) (*Handler, error) {
	s3Storage, err := storage.NewS3Storage(config.Region)
	if err != nil {
		return nil, fmt.Errorf("failed to create S3 storage: %w", err)
	}

	opt := optimizer.NewOptimizer(config.MaxWidth, config.MaxHeight, config.Quality)

	return &Handler{
		config:    config,
		optimizer: opt,
		storage:   s3Storage,
	}, nil
}

// Handle processes S3 events triggered by CloudFront origin requests
func (h *Handler) Handle(ctx context.Context, s3Event events.S3Event) error {
	for _, record := range s3Event.Records {
		// Get the S3 object key that was requested
		key := record.S3.Object.Key
		log.Printf("Processing S3 event for key: %s", key)

		// Parse the key to extract image parameters
		params, err := h.parseS3Key(key)
		if err != nil {
			log.Printf("Failed to parse S3 key: %v", err)
			return err
		}

		// Check if this is already an optimized image (in cache bucket)
		if strings.HasPrefix(key, h.config.CacheBucket) {
			log.Printf("Key is already in cache bucket, skipping")
			continue
		}

		// Get original image from source bucket
		sourceKey := params.ImagePath
		sourceObj, err := h.storage.GetObject(ctx, h.config.SourceBucket, sourceKey)
		if err != nil {
			log.Printf("Failed to get source image: %v", err)
			return fmt.Errorf("source image not found: %w", err)
		}

		// Optimize image
		optimized, contentType, err := h.optimizer.Optimize(sourceObj.Data, params)
		if err != nil {
			log.Printf("Failed to optimize image: %v", err)
			return fmt.Errorf("optimization failed: %w", err)
		}

		// Store optimized image in cache bucket with the same key structure
		cacheKey := key
		err = h.storage.PutObject(ctx, h.config.CacheBucket, cacheKey, optimized, contentType)
		if err != nil {
			log.Printf("Failed to cache image: %v", err)
			return fmt.Errorf("failed to store optimized image: %w", err)
		}

		log.Printf("Successfully optimized and cached image: %s", cacheKey)
	}

	return nil
}

// HandleS3GetObject handles direct invocation for image optimization
func (h *Handler) HandleS3GetObject(ctx context.Context, bucket, key string) ([]byte, string, error) {
	log.Printf("Processing direct request for bucket: %s, key: %s", bucket, key)

	// Parse the key to extract image parameters
	params, err := h.parseS3Key(key)
	if err != nil {
		return nil, "", fmt.Errorf("invalid key format: %w", err)
	}

	// Check if optimized version exists in cache
	cached, err := h.storage.GetObject(ctx, h.config.CacheBucket, key)
	if err == nil && cached != nil {
		log.Printf("Cache hit for key: %s", key)
		return cached.Data, cached.ContentType, nil
	}

	// Cache miss - get original and optimize
	sourceObj, err := h.storage.GetObject(ctx, h.config.SourceBucket, params.ImagePath)
	if err != nil {
		return nil, "", fmt.Errorf("source image not found: %w", err)
	}

	// Optimize image
	optimized, contentType, err := h.optimizer.Optimize(sourceObj.Data, params)
	if err != nil {
		return nil, "", fmt.Errorf("optimization failed: %w", err)
	}

	// Store in cache
	err = h.storage.PutObject(ctx, h.config.CacheBucket, key, optimized, contentType)
	if err != nil {
		log.Printf("Warning: Failed to cache image: %v", err)
		// Continue and return the optimized image anyway
	}

	return optimized, contentType, nil
}

// parseS3Key parses the S3 key to extract image path and optimization parameters
// Format: image.jpg or format=auto/image.jpg or format=auto,width=200/image.jpg
func (h *Handler) parseS3Key(key string) (optimizer.ImageParams, error) {
	params := optimizer.ImageParams{
		Format:  "auto",
		Quality: h.config.Quality,
	}

	// Split by slash to separate parameters from image path
	parts := strings.Split(key, "/")

	if len(parts) == 0 {
		return params, fmt.Errorf("invalid key format")
	}

	// Last part is always the image path
	params.ImagePath = parts[len(parts)-1]

	// If there are previous parts, they contain parameters
	if len(parts) > 1 {
		// Join all parts except the last one as parameters
		paramStr := strings.Join(parts[:len(parts)-1], "/")

		// Parse parameters (format: key1=value1,key2=value2)
		paramParts := strings.Split(paramStr, ",")
		for _, param := range paramParts {
			kv := strings.Split(param, "=")
			if len(kv) != 2 {
				continue
			}

			key := strings.TrimSpace(kv[0])
			value := strings.TrimSpace(kv[1])

			switch key {
			case "width", "w":
				if width, err := strconv.Atoi(value); err == nil {
					params.Width = width
				}
			case "height", "h":
				if height, err := strconv.Atoi(value); err == nil {
					params.Height = height
				}
			case "quality", "q":
				if quality, err := strconv.Atoi(value); err == nil {
					params.Quality = quality
				}
			case "format", "f":
				params.Format = value
			}
		}
	}

	return params, nil
}

// parseQueryParams is a helper for URL-based parameter parsing (if needed)
func (h *Handler) ParseQueryParams(queryString string) (optimizer.ImageParams, error) {
	params := optimizer.ImageParams{
		Format:  "auto",
		Quality: h.config.Quality,
	}

	if queryString == "" {
		return params, nil
	}

	values, err := url.ParseQuery(queryString)
	if err != nil {
		return params, err
	}

	if w := values.Get("w"); w != "" {
		if width, err := strconv.Atoi(w); err == nil {
			params.Width = width
		}
	}

	if h := values.Get("h"); h != "" {
		if height, err := strconv.Atoi(h); err == nil {
			params.Height = height
		}
	}

	if q := values.Get("q"); q != "" {
		if quality, err := strconv.Atoi(q); err == nil {
			params.Quality = quality
		}
	}

	if f := values.Get("format"); f != "" {
		params.Format = f
	}

	return params, nil
}
