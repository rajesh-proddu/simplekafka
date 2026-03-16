# Build stage
FROM golang:1.25-alpine AS builder

WORKDIR /app

# Install build dependencies
RUN apk add --no-cache git

# Copy go mod files
COPY go.mod go.sum* ./

# Download dependencies
RUN go mod download

# Copy source code
COPY . .

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o producer .

# Final stage
FROM alpine:latest

RUN apk --no-cache add ca-certificates

WORKDIR /root/

# Copy the binary from builder
COPY --from=builder /app/producer .

# Environment variables
ENV KAFKA_BROKERS=kafka:9092
ENV KAFKA_TOPIC=test-topic
ENV MESSAGE_COUNT=10
ENV MESSAGE_INTERVAL=1000

# Run the application
CMD ["./producer"]
