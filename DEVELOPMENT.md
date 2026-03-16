# Development Guide

This guide provides instructions for developing and testing the SimpleKafka applications.

## Project Structure

```
simplekafka/
├── producer/                 # Producer application
│   ├── main.go              # Producer implementation
│   ├── Dockerfile           # Container definition
│   └── go.mod               # Go module
├── consumer/                 # Consumer application
│   ├── main.go              # Consumer implementation
│   ├── Dockerfile           # Container definition
│   └── go.mod               # Go module
├── k8s/                      # Local Kubernetes manifests
├── aws-eks/                  # AWS EKS manifests
├── scripts/                  # Deployment scripts
├── docker-compose.yaml       # Local Docker Compose setup
├── Makefile                  # Build automation
├── go.mod                    # Root Go module
├── README.md                 # Project documentation
└── main.go                   # Workspace info
```

## Development Setup

### Prerequisites

- Go 1.25 or higher
- Docker
- Git

### Clone and Setup

```bash
cd simplekafka
go mod download
```

## Building Locally

### Build All

```bash
make build
```

Or:

```bash
go build ./...
```

### Build Individual Components

#### Build Producer

```bash
cd producer
go build -o producer .
```

#### Build Consumer

```bash
cd consumer
go build -o consumer .
```

## Running Locally

### Run Producer (Standalone)

You'll need a Kafka broker running first. Use Docker Compose (see below).

```bash
cd producer
./producer
```

Configure with environment variables:

```bash
KAFKA_BROKERS=kafka:9092 \
KAFKA_TOPIC=test-topic \
MESSAGE_COUNT=100 \
MESSAGE_INTERVAL=500 \
./producer
```

### Run Consumer (Standalone)

```bash
cd consumer
./consumer
```

Configure with environment variables:

```bash
KAFKA_BROKERS=kafka:9092 \
KAFKA_TOPIC=test-topic \
KAFKA_GROUP_ID=dev-group-1 \
./consumer
```

## Using Docker Compose (Recommended for Local Development)

```bash
# Start all services
make compose-up
# or
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

This starts:
- Zookeeper (port 2181)
- Kafka (port 9092)
- Producer (sends test messages)
- Consumer (receives messages)

## Debugging

### Enable Debug Logging

Add debug logging to the code:

```go
log.Printf("DEBUG: %+v", variable)
```

### Check Running Processes

```bash
# With Docker Compose
docker-compose ps
docker-compose logs producer
docker-compose logs consumer

# View specific service logs
docker logs <container_id>
```

### Connect to Running Container

```bash
docker-compose exec producer /bin/sh
docker-compose exec consumer /bin/sh
```

## Code Style

### Format Code

```bash
make fmt
```

Or:

```bash
gofmt -s -w producer/ consumer/
```

### Additional Linting (Optional)

Install golangci-lint:

```bash
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
```

Run linter:

```bash
golangci-lint run ./producer ./consumer
```

## Testing

### Run Tests

```bash
make test
```

Or:

```bash
go test ./...
go test ./producer -v
go test ./consumer -v
```

### Test with Coverage

```bash
go test -cover ./...
go test -coverprofile=coverage.out ./...
go tool cover -html=coverage.out
```

## Working with Docker Images

### Build Images

```bash
# Build all images
make docker-build

# Build specific image
make docker-build-producer
make docker-build-consumer
```

### View Images

```bash
docker image ls | grep kafka
```

### Remove Images

```bash
docker rmi kafka-producer:latest
docker rmi kafka-consumer:latest
```

### Publish to Registry

```bash
# Tag for registry
docker tag kafka-producer:latest registry.example.com/kafka-producer:v1.0.0
docker tag kafka-consumer:latest registry.example.com/kafka-consumer:v1.0.0

# Push to registry
docker push registry.example.com/kafka-producer:v1.0.0
docker push registry.example.com/kafka-consumer:v1.0.0
```

## Kubernetes Development

### Deploy to Minikube

```bash
# Start Minikube
minikube start --cpus=4 --memory=8192

# Use Minikube Docker environment
eval $(minikube docker-env)

# Deploy
make k8s-deploy
```

### Monitor Deployment

```bash
# Check pods
kubectl get pods -n kafka -w

# View logs
kubectl logs -n kafka -l app=kafka-producer -f
```

### Debug Kubernetes

```bash
# Describe pod
kubectl describe pod -n kafka <pod-name>

# Execute command in pod
kubectl exec -it -n kafka <pod-name> -- /bin/sh

# Port forward
kubectl port-forward -n kafka svc/kafka 9092:9092
```

## Making Changes

### Update Producer

1. Edit `producer/main.go`
2. Test locally: `cd producer && go build && ./producer`
3. Test with Docker: `docker-compose down && docker-compose up`
4. Commit changes

### Update Consumer

1. Edit `consumer/main.go`
2. Test locally: `cd consumer && go build && ./consumer`
3. Test with Docker: `docker-compose down && docker-compose up`
4. Commit changes

### Update Kubernetes Manifests

1. Edit files in `k8s/` for local deployment
2. Edit files in `aws-eks/` for AWS deployment
3. Test with `make k8s-deploy`
4. Commit changes

## Git Workflow

```bash
# Create feature branch
git checkout -b feature/my-feature

# Make changes
# Commit
git add .
git commit -m "Add my feature"

# Push
git push origin feature/my-feature

# Create pull request
```

## Environment Variables

### Producer/Consumer Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| KAFKA_BROKERS | localhost:9092 | Kafka broker address(es) |
| KAFKA_TOPIC | test-topic | Topic name |
| KAFKA_GROUP_ID | consumer-group-1 | Consumer group (consumer only) |
| MESSAGE_COUNT | 10 | Messages to send (producer only) |
| MESSAGE_INTERVAL | 1000 | Interval in milliseconds |

Example:

```bash
export KAFKA_BROKERS=kafka-broker-1:9092,kafka-broker-2:9092
export KAFKA_TOPIC=my-topic
export MESSAGE_COUNT=1000
export MESSAGE_INTERVAL=100
```

## Dependencies

The project uses:

- `github.com/segmentio/kafka-go` - Kafka client library

View all dependencies:

```bash
cd producer && go mod graph
cd consumer && go mod graph
```

Update dependencies:

```bash
go get -u ./...
```

## Performance Profiling

### CPU Profiling

```go
import "runtime/pprof"

// In main()
f, _ := os.Create("cpu.prof")
defer f.Close()
pprof.StartCPUProfile(f)
defer pprof.StopCPUProfile()

// Your application code
```

Analyze:

```bash
go tool pprof cpu.prof
```

### Memory Profiling

```bash
go test -memprofile=mem.prof ./package
go tool pprof mem.prof
```

## Troubleshooting

### Build Issues

```bash
# Clean build cache
go clean -cache
go clean -testcache

# Download dependencies
go mod download

# Verify dependencies
go mod verify
```

### Docker Issues

```bash
# Check Docker daemon
docker ps

# Clean up containers
docker container prune

# Clean up images
docker image prune
```

### Kafka Connection Issues

```bash
# Check if Kafka is running
docker-compose ps kafka

# View Kafka logs
docker-compose logs kafka

# Test connection
nc -zv localhost 9092
```

## Additional Resources

- [Go Documentation](https://golang.org/doc/)
- [Kafka Documentation](https://kafka.apache.org/documentation/)
- [segmentio/kafka-go](https://github.com/segmentio/kafka-go)
- [Docker Documentation](https://docs.docker.com/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
