# Quick Reference Guide

## Starting with SimpleKafka

### 1. **Quickest Start (Docker Compose)**

```bash
cd /path/to/simplekafka
docker-compose up
```

This starts Kafka, Producer, and Consumer immediately.

### 2. **Local Kubernetes**

```bash
./scripts/deploy-local-k8s.sh
```

Requires: minikube, Docker Desktop, or local k8s cluster

### 3. **AWS EKS**

```bash
export AWS_ACCOUNT_ID=YOUR_ACCOUNT_ID
export AWS_REGION=us-east-1
export EKS_CLUSTER_NAME=your-cluster

./scripts/deploy-aws-eks.sh
```

## Common Commands

### Build

```bash
make build                    # Build producer + consumer
go build ./producer/         # Build producer only
go build ./consumer/         # Build consumer only
```

### Docker

```bash
make docker-build             # Build all images
docker-compose up             # Start with Docker Compose
docker-compose down           # Stop services
docker-compose logs -f        # See logs
```

### Kubernetes (Local)

```bash
make k8s-deploy               # Deploy to local k8s
make k8s-status               # Check status
make k8s-logs                 # View logs
make k8s-clean                # Delete deployment
kubectl get pods -n kafka     # List pods
kubectl logs -n kafka -f -l app=kafka-consumer  # Consumer logs
```

### Kubernetes (AWS EKS)

```bash
make eks-deploy               # Deploy to EKS
kubectl get svc -n kafka      # Get services
kubectl logs -n kafka -l app=kafka-consumer -f  # Consumer logs
```

## Configuration

### Environment Variables

**Producer:**
- `KAFKA_BROKERS` - Kafka broker (default: localhost:9092)
- `KAFKA_TOPIC` - Topic name (default: test-topic)
- `MESSAGE_COUNT` - Messages to send (default: 10)
- `MESSAGE_INTERVAL` - Milliseconds between messages (default: 1000)

**Consumer:**
- `KAFKA_BROKERS` - Kafka broker (default: localhost:9092)
- `KAFKA_TOPIC` - Topic name (default: test-topic)
- `KAFKA_GROUP_ID` - Consumer group (default: consumer-group-1)

### Setting Variables

```bash
# Docker Compose - edit docker-compose.yaml
# Kubernetes - edit k8s/*.yaml or aws-eks/*.yaml manifests
# Direct execution - export before running
export KAFKA_BROKERS=my-kafka:9092
export MESSAGE_COUNT=100
./producer/producer
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Kafka not accessible | Check if port 9092 is forwarded: `kubectl port-forward svc/kafka 9092:9092` |
| Producer not sending | Check logs: `docker-compose logs producer` |
| Consumer not receiving | Check topic exists, verify Kafka is running |
| Docker build fails | Run `go mod download` in each directory |
| Minikube images not found | Load images: `minikube image load kafka-producer:latest` |

## File Locations

| Component | File |
|-----------|------|
| Producer | `producer/main.go` |
| Consumer | `consumer/main.go` |
| Local K8s | `k8s/*.yaml` |
| AWS EKS | `aws-eks/*.yaml` |
| Docker Compose | `docker-compose.yaml` |
| Scripts | `scripts/*.sh` |
| Makefile | `Makefile` |

## Documentation

- **README.md** - Project overview
- **DEVELOPMENT.md** - Development guide
- **LOCAL-K8S-DEPLOYMENT.md** - Local Kubernetes details
- **AWS-EKS-DEPLOYMENT.md** - AWS EKS details

## Resources

- [Producer Code](producer/main.go)
- [Consumer Code](consumer/main.go)
- [Kafka Documentation](https://kafka.apache.org/)
- [Go Kafka Client](https://github.com/segmentio/kafka-go)
