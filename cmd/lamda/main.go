package main

import (
	"context"
	"log"
	"os"
	"strconv"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/mahibulhaque/imagekit/internal/handler"
)

func main() {
	// Initialize logger
	log.SetFlags(log.LstdFlags | log.Lshortfile)

	// Get configuration from environment
	config := handler.Config{
		SourceBucket: os.Getenv("SOURCE_BUCKET"),
		CacheBucket:  os.Getenv("CACHE_BUCKET"),
		Region:       getEnv("AWS_REGION", "us-east-1"),
		MaxWidth:     getEnvAsInt("MAX_WIDTH", 2000),
		MaxHeight:    getEnvAsInt("MAX_HEIGHT", 2000),
		Quality:      getEnvAsInt("QUALITY", 80),
	}

	// Validate configuration
	if config.SourceBucket == "" {
		log.Fatal("SOURCE_BUCKET environment variable is required")
	}
	if config.CacheBucket == "" {
		log.Fatal("CACHE_BUCKET environment variable is required")
	}

	log.Printf("Initializing handler with config: SourceBucket=%s, CacheBucket=%s, Region=%s",
		config.SourceBucket, config.CacheBucket, config.Region)

	// Initialize handler
	h, err := handler.New(config)
	if err != nil {
		log.Fatalf("Failed to initialize handler: %v", err)
	}

	// Start Lambda - handles S3 events
	lambda.Start(func(ctx context.Context, s3Event events.S3Event) error {
		return h.Handle(ctx, s3Event)
	})
}

func getEnv(key, defaultVal string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultVal
}

func getEnvAsInt(key string, defaultVal int) int {
	valStr := os.Getenv(key)
	if valStr == "" {
		return defaultVal
	}
	val, err := strconv.Atoi(valStr)
	if err != nil {
		log.Printf("Warning: Invalid integer value for %s: %s, using default: %d", key, valStr, defaultVal)
		return defaultVal
	}
	return val
}
