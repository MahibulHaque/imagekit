# Image Optimization Service

A serverless image optimization service using Go, bimg (libvips), and AWS - following the official AWS blog architecture.

## 🎯 Architecture

Based on: [AWS Image Optimization Blog](https://aws.amazon.com/blogs/networking-and-content-delivery/image-optimization-using-amazon-cloudfront-and-aws-lambda/)

```
┌──────┐    ┌─────────────┐    ┌──────────────────┐
│ User │───▶│ CloudFront  │───▶│ CloudFront Func  │
└──────┘    └─────────────┘    │ (URL Rewrite)    │
                               └──────────────────┘
                                        │
                        ┌───────────────┴───────────────┐
                        ▼                               ▼
                ┌───────────────┐              ┌──────────────┐
                │  S3 Cache     │              │   Lambda     │
                │  [CACHE HIT]  │              │  (on miss)   │
                └───────────────┘              └──────────────┘
                                                      │
                                        ┌─────────────┴─────────────┐
                                        ▼                           ▼
                                ┌──────────────┐          ┌──────────────┐
                                │ S3 Source    │          │  S3 Cache    │
                                │ (originals)  │          │  (optimized) │
                                └──────────────┘          └──────────────┘
```

## ✨ Features

- 🚀 Serverless with AWS Lambda (custom container with libvips)
- 🖼️ High-performance image processing (libvips is 4-8x faster than ImageMagick)
- 📦 Automatic caching with S3 and CloudFront
- 🔄 Support for JPEG, PNG, WebP, GIF formats
- 📏 Dynamic resizing and quality adjustment
- 💰 Cost-effective with CloudFront origin groups
- 🌍 Global CDN distribution

## 🚀 Quick Start

### Prerequisites

- AWS CLI configured
- Docker installed
- Terraform
- Go 1.25+

### 1. Build and Push Container

```bash
# Set variables
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export AWS_REGION=us-east-1

# Create ECR and push image
make push
```

### 2. Deploy Infrastructure

```bash
cd infra/terraform/dev
terraform init
terraform plan
terraform apply
```

### 3. Upload and Test

```bash
# Upload image
SOURCE_BUCKET=$(terraform output -raw source_bucket_name)
aws s3 cp test-image.jpg s3://${SOURCE_BUCKET}/test-image.jpg

# Test optimization
CLOUDFRONT_URL=$(terraform output -raw cloudfront_domain_name)
curl "https://${CLOUDFRONT_URL}/test-image.jpg?w=500&q=80" -o optimized.jpg
```

## 📖 URL Parameters

| Parameter | Description      | Example        |
| --------- | ---------------- | -------------- |
| `w`       | Width in pixels  | `?w=500`       |
| `h`       | Height in pixels | `?h=300`       |
| `q`       | Quality (1-100)  | `?q=80`        |
| `format`  | Output format    | `?format=webp` |

**Examples:**

```bash
# Resize width (maintains aspect ratio)
/image.jpg?w=500

# Resize with quality
/image.jpg?w=800&q=75

# Convert to WebP
/image.jpg?w=500&format=webp

# Full optimization
/image.jpg?w=1200&h=800&q=85&format=webp
```

## 📁 Project Structure

```
image-optimization-service/
├── cmd/lambda/              # Lambda entry point
├── internal/
│   ├── handler/            # Request handling
│   ├── optimizer/          # bimg image processing
│   └── storage/            # S3 operations
├── infra/terraform/ # Infrastructure as Code
├── Dockerfile              # Lambda container with libvips
├── Makefile               # Build automation
└── README.md
```

## 💡 How It Works

1. **User requests:** `https://cdn.example.com/image.jpg?w=500&q=80`
2. **CloudFront Function** rewrites to: `/format=auto,width=500,quality=80/image.jpg`
3. **CloudFront** tries S3 cache bucket
4. **On cache miss (404):** Request goes to Lambda Function URL
5. **Lambda:**
   - Fetches original from source S3
   - Optimizes with bimg (libvips)
   - Stores in cache S3
   - Returns optimized image
6. **Next request:** Served directly from S3 cache (fast!)

## 🔧 Configuration

### Environment Variables (in Lambda)

| Variable        | Description             | Default    |
| --------------- | ----------------------- | ---------- |
| `SOURCE_BUCKET` | Source images S3 bucket | (required) |
| `CACHE_BUCKET`  | Cached images S3 bucket | (required) |
| `MAX_WIDTH`     | Maximum image width     | 2000       |
| `MAX_HEIGHT`    | Maximum image height    | 2000       |
| `QUALITY`       | Default quality         | 80         |

### Terraform Variables

Customize in `variables.tf`:

```hcl
max_image_width      = 2000
max_image_height     = 2000
default_quality      = 85
cache_expiration_days = 90
```
