# SimpleKafka

A production-ready Kafka producer and consumer implementation in Go with Docker containerization and Kubernetes deployment support for local clusters and AWS EKS.

## 📋 Features

- **Kafka Producer**: Sends messages to Kafka topics with configurable intervals
- **Kafka Consumer**: Consumes messages from Kafka topics with consumer group support
- **Docker Containers**: Multi-stage Dockerfile builds for efficient image sizes
- **Kubernetes Support**: Ready-to-deploy manifests for local k8s and AWS EKS
- **Auto-scaling**: HPA configured for AWS EKS deployments
- **Health Checks**: Liveness and readiness probes configured
- **Security**: Non-root user, read-only filesystems, RBAC enabled

## 📁 Project Structure

```
.
├── producer/                 # Kafka Producer application
│   ├── main.go              # Producer implementation
│   ├── Dockerfile           # Multi-stage Docker build
│   └── go.mod               # Go module definition
├── consumer/                 # Kafka Consumer application
│   ├── main.go              # Consumer implementation
│   ├── Dockerfile           # Multi-stage Docker build
│   └── go.mod               # Go module definition
├── k8s/                      # Local Kubernetes manifests
│   ├── kafka-statefulset.yaml        # Kafka + Zookeeper setup
│   ├── producer-deployment.yaml      # Producer deployment
│   └── consumer-deployment.yaml      # Consumer deployment
├── aws-eks/                  # AWS EKS deployment manifests
│   ├── kafka-statefulset.yaml        # EKS-optimized Kafka setup
│   ├── producer-deployment.yaml      # EKS producer with ECR images
│   └── consumer-deployment.yaml      # EKS consumer with HPA
├── scripts/                  # Deployment scripts
│   ├── deploy-local-k8s.sh           # Deploy to local Kubernetes
│   └── deploy-aws-eks.sh             # Deploy to AWS EKS
├── docker-compose.yaml       # Local Docker Compose setup
└── README.md                 # This file
```

## 🚀 Quick Start

### Prerequisites

- Go 1.25 or higher
- Docker
- kubectl (for Kubernetes deployments)
- AWS CLI (for AWS EKS deployments)

### Local Docker Compose (Quickest)

```bash
# Start all services (Zookeeper, Kafka, Producer, Consumer)
docker-compose up -d

# View logs
docker-compose logs -f producer
docker-compose logs -f consumer

# Stop services
docker-compose down
```

### Local Kubernetes Deployment

```bash
# Prerequisites: minikube or local k8s cluster running

# Run deployment script (builds images and deploys)
./scripts/deploy-local-k8s.sh

# Check status
kubectl get pods -n kafka
kubectl get svc -n kafka

# View logs
kubectl logs -n kafka -l app=kafka-producer --tail=100
kubectl logs -n kafka -l app=kafka-consumer --tail=100

# Port-forward to Kafka
kubectl port-forward -n kafka svc/kafka 9092:9092

# Cleanup
kubectl delete namespace kafka
```

### AWS EKS Deployment

```bash
# Prerequisites: AWS EKS cluster created and kubectl configured

# Set environment variables
export AWS_ACCOUNT_ID=123456789012
export ECR_REGISTRY_URL=123456789012.dkr.ecr.us-east-1.amazonaws.com
export AWS_REGION=us-east-1
export EKS_CLUSTER_NAME=my-kafka-cluster

# Run deployment script
./scripts/deploy-aws-eks.sh

# Check status
kubectl get pods -n kafka
kubectl get svc -n kafka

# View logs
kubectl logs -n kafka -l app=kafka-producer --tail=100
kubectl logs -n kafka -l app=kafka-consumer --tail=100

# Get Kafka LoadBalancer endpoint
kubectl get svc -n kafka kafka-lb -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Cleanup
kubectl delete namespace kafka
```

## ⚙️ Configuration

### Producer Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `KAFKA_BROKERS` | `localhost:9092` | Kafka broker addresses (comma-separated) |
| `KAFKA_TOPIC` | `test-topic` | Topic to publish messages to |
| `MESSAGE_COUNT` | `10` | Number of messages to send |
| `MESSAGE_INTERVAL` | `1000` | Interval between messages (milliseconds) |

### Consumer Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `KAFKA_BROKERS` | `localhost:9092` | Kafka broker addresses (comma-separated) |
| `KAFKA_TOPIC` | `test-topic` | Topic to consume messages from |
| `KAFKA_GROUP_ID` | `consumer-group-1` | Consumer group identifier |

## 🔨 Building

### Build Everything

```bash
go build ./...
```

### Build Producer

```bash
cd producer
go build -o producer .
```

### Build Consumer

```bash
cd consumer
go build -o consumer .
```

## 🐳 Docker Images

### Build Images

```bash
docker build -f producer/Dockerfile -t kafka-producer:latest producer/
docker build -f consumer/Dockerfile -t kafka-consumer:latest consumer/
```

### Run Producer Container

```bash
docker run -e KAFKA_BROKERS=kafka:9092 \
           -e KAFKA_TOPIC=test-topic \
           -e MESSAGE_COUNT=100 \
           --network kafka-network \
           kafka-producer:latest
```

### Run Consumer Container

```bash
docker run -e KAFKA_BROKERS=kafka:9092 \
           -e KAFKA_TOPIC=test-topic \
           -e KAFKA_GROUP_ID=consumer-group-1 \
           --network kafka-network \
           kafka-consumer:latest
```

## ☸️ Kubernetes Deployments

### Local Kubernetes

The `k8s/` directory contains manifests optimized for local development:
- Single-replica Zookeeper and Kafka
- Minimal resource requests
- Local image loading (no registry required)

### AWS EKS

The `aws-eks/` directory contains production-ready manifests:
- Multi-replica Kafka cluster (3 replicas)
- EBS volume storage for data persistence
- Pod anti-affinity for high availability
- Horizontal Pod Autoscaler (HPA) for consumers
- LoadBalancer service for external access
- RBAC enabled with ServiceAccounts
- Health checks and resource limits

## 📊 Monitoring

### View Pod Status

```bash
# Get all pods in kafka namespace
kubectl get pods -n kafka

# Get detailed pod information
kubectl get pods -n kafka -o wide

# Describe specific pod
kubectl describe pod -n kafka kafka-consumer-xxx
```

### View Logs

```bash
# Tail producer logs
kubectl logs -n kafka -l app=kafka-producer -f

# Tail consumer logs
kubectl logs -n kafka -l app=kafka-consumer -f

# Get logs from specific pod
kubectl logs -n kafka kafka-producer-xxx
```

### Port Forwarding

```bash
# Access Kafka from localhost
kubectl port-forward -n kafka svc/kafka 9092:9092

# Access Zookeeper from localhost
kubectl port-forward -n kafka svc/zookeeper 2181:2181
```

## 🔍 Troubleshooting

### Kafka Broker Connection Issues

```bash
# Check if Kafka is running
kubectl get pods -n kafka -l app=kafka-broker

# Check Kafka logs
kubectl logs -n kafka kafka-broker-0

# Verify service is accessible
kubectl exec -n kafka -it <consumer-pod> -- nc -zv kafka 9092
```

### Producer Not Sending Messages

```bash
# Check producer logs
kubectl logs -n kafka -l app=kafka-producer

# Verify Kafka is accessible from producer pod
kubectl exec -n kafka -it <producer-pod> -- /bin/sh
```

### Consumer Not Receiving Messages

```bash
# Check consumer logs
kubectl logs -n kafka -l app=kafka-consumer

# Check consumer group status (if you have kafka tools)
kubectl exec -n kafka kafka-broker-0 -- kafka-consumer-groups --bootstrap-server localhost:9092 --list
```

## 🔄 Development Workflow

### Making Changes

1. Update `producer/main.go` or `consumer/main.go`
2. Test locally with Docker Compose
3. Rebuild Docker images
4. For AWS EKS: push to ECR and rollout update

```bash
# Rebuild and restart locally
docker-compose down
docker-compose up -d

# Rebuild for AWS EKS
docker build -f producer/Dockerfile -t kafka-producer:latest producer/
docker tag kafka-producer:latest $ECR_REGISTRY_URL/kafka-producer:latest
docker push $ECR_REGISTRY_URL/kafka-producer:latest

# Rollout update
kubectl rollout restart deployment kafka-producer -n kafka
```

## 📈 Scaling

### Local Kubernetes

Edit `k8s/producer-deployment.yaml` and `k8s/consumer-deployment.yaml` to change `replicas`.

### AWS EKS

The consumer deployment has HPA configured and will automatically scale based on:
- CPU utilization > 70%
- Memory utilization > 80%

Check HPA status:

```bash
kubectl get hpa -n kafka
kubectl describe hpa kafka-consumer-hpa -n kafka
```

## 🔐 Security Considerations

- Containers run as non-root user (UID 1000)
- Read-only root filesystems enforced
- RBAC enabled with minimal permissions
- Pod security policies recommended (if available)
- Consider enabling network policies between pods

## 📝 Dependencies

- `github.com/segmentio/kafka-go` - Go Kafka client library

## 🤝 Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss proposed changes.

## 📄 License

This project is open source and available for use.
