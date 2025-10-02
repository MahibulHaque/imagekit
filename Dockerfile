# ---------------------------
# Stage 1: Builder
# ---------------------------
FROM golang:1.25-alpine AS builder

# Install build dependencies and libvips-dev
RUN apk add --no-cache git ca-certificates tzdata build-base vips-dev pkgconfig

WORKDIR /app

# Download dependencies first (caching)
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build static binary
RUN CGO_ENABLED=1 GOOS=linux GOARCH=amd64 go build -o main ./cmd/lambda

# Optional: compress binary
RUN apk add --no-cache upx && upx --lzma --best main || true


# ---------------------------
# Stage 2: Minimal Runtime
# ---------------------------
FROM alpine:3.20

# Install libvips runtime + certificates
RUN apk add --no-cache vips tzdata ca-certificates

WORKDIR /app

# Copy the Go binary
COPY --from=builder /app/main /app/main

# Non-root user for security
RUN adduser -D appuser
USER appuser

EXPOSE 8080

ENTRYPOINT ["/app/main"]
