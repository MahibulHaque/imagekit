.PHONY: help build build-optimized test docker-build docker-build-optimized docker-push deploy clean

# Variables
PROJECT_NAME ?= imgix
AWS_REGION ?= us-east-1
AWS_ACCOUNT_ID ?= $(shell aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY ?= $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com
ECR_REPOSITORY ?= $(PROJECT_NAME)
IMAGE_TAG ?= latest
FULL_IMAGE_NAME = $(ECR_REGISTRY)/$(ECR_REPOSITORY):$(IMAGE_TAG)

# Enable Docker BuildKit for faster builds
export DOCKER_BUILDKIT=1

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-20s %s\n", $1, $2}' $(MAKEFILE_LIST)

init: ## Initialize Go modules
	go mod download
	go mod tidy
	go mod verify

build: ## Build the Go binary locally
	CGO_ENABLED=1 go build -o bin/main ./cmd/lambda

test: ## Run tests
	go test -v ./...

lint: ## Run linter
	golangci-lint run ./...

docker-build: ## Build Docker image (standard)
	docker build -t $(ECR_REPOSITORY):$(IMAGE_TAG) .
	docker tag $(ECR_REPOSITORY):$(IMAGE_TAG) $(FULL_IMAGE_NAME)

docker-push: ecr-login ecr-create ## Push Docker image to ECR
	docker push $(FULL_IMAGE_NAME)
	@echo "Pushed: $(FULL_IMAGE_NAME)"

