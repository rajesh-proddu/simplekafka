# Local Kubernetes Deployment Guide

This guide provides detailed instructions for deploying SimpleKafka to a local Kubernetes cluster.

## Prerequisites

1. **Local Kubernetes Cluster**
   - [Minikube](https://minikube.sigs.k8s.io/) (Recommended)
   - [Docker Desktop with Kubernetes enabled](https://www.docker.com/products/docker-desktop)
   - [kind](https://kind.sigs.k8s.io/)
   - Any other local k8s setup

2. **kubectl** - Kubernetes command-line tool
3. **Docker** - For building container images
4. **make** - Optional but recommended (Makefile support)

## Step 1: Start Local Kubernetes Cluster

### Using Minikube (Recommended)

```bash
# Start minikube
minikube start --cpus=4 --memory=8192 --disk-size=20000

# Configure docker to use minikube's Docker daemon
eval $(minikube docker-env)

# Verify cluster is running
kubectl cluster-info
```

### Using Docker Desktop

1. Open Docker Desktop
2. Go to Preferences → Kubernetes
3. Check "Enable Kubernetes"
4. Wait for cluster to be ready

### Using kind

```bash
# Create cluster
kind create cluster --name kafka-local

# Configure kubectl
export KUBECONFIG="$(kind get kubeconfig-path --name="kafka-local")"
```

## Step 2: Verify Kubectl Connection

```bash
kubectl cluster-info
kubectl get nodes
```

## Step 3: Deploy SimpleKafka

### Automated Deployment

```bash
# Using the deployment script
./scripts/deploy-local-k8s.sh
```

### Using Make (if installed)

```bash
make k8s-deploy
```

### Manual Deployment Steps

#### 3.1 Build Docker Images

```bash
# Build producer image
docker build -f producer/Dockerfile -t kafka-producer:latest producer/

# Build consumer image
docker build -f consumer/Dockerfile -t kafka-consumer:latest consumer/
```

#### 3.2 Create Kubernetes Resources

```bash
# Create kafka namespace
kubectl create namespace kafka

# Deploy Kafka infrastructure
kubectl apply -f k8s/kafka-statefulset.yaml

# Wait for Kafka to be ready
kubectl wait --for=condition=ready pod -l app=kafka-broker -n kafka --timeout=300s

# Deploy Producer
kubectl apply -f k8s/producer-deployment.yaml

# Deploy Consumer
kubectl apply -f k8s/consumer-deployment.yaml
```

## Step 4: Monitor Deployment

### Check Pod Status

```bash
# Get all pods in kafka namespace
kubectl get pods -n kafka

# Get detailed view
kubectl get pods -n kafka -o wide

# Watch pods in real-time
kubectl get pods -n kafka -w
```

### Check Services

```bash
kubectl get svc -n kafka
```

### View Logs

```bash
# Producer logs (live)
kubectl logs -n kafka -l app=kafka-producer -f

# Consumer logs (live)
kubectl logs -n kafka -l app=kafka-consumer -f

# Last 100 lines of producer logs
kubectl logs -n kafka -l app=kafka-producer --tail=100

# Get logs from specific pod
kubectl logs -n kafka kafka-producer-xxxxx
```

### Describe Pods

```bash
# Get detailed information about a pod
kubectl describe pod -n kafka kafka-producer-xxxxx

# Get Kafka broker pod details
kubectl describe pod -n kafka kafka-broker-0
```

## Step 5: Access Kafka Locally

### Port Forward to Kafka

```bash
# Forward local port 9092 to Kafka
kubectl port-forward -n kafka svc/kafka 9092:9092 &

# Verify connection
nc -zv localhost 9092
```

### Port Forward to Zookeeper

```bash
kubectl port-forward -n kafka svc/zookeeper 2181:2181 &
```

### Test with Kafka Tools (Optional)

If you have Kafka installed locally:

```bash
# Create a test topic
kafka-topics --bootstrap-server localhost:9092 --create --topic test --partitions 1 --replication-factor 1

# List topics
kafka-topics --bootstrap-server localhost:9092 --list

# Produce a message
echo "Test message" | kafka-console-producer --broker-list localhost:9092 --topic test-topic

# Consume messages
kafka-console-consumer --bootstrap-server localhost:9092 --topic test-topic --from-beginning
```

## Step 6: Advanced Operations

### Access Pod Terminal

```bash
# Get shell access to a pod
kubectl exec -it -n kafka kafka-consumer-xxxxx -- /bin/sh

# Run a command in the pod
kubectl exec -n kafka kafka-consumer-xxxxx -- ps aux
```

### Scale Deployments

```bash
# Scale producer to 3 replicas
kubectl scale deployment kafka-producer -n kafka --replicas=3

# Scale consumer to 2 replicas
kubectl scale deployment kafka-consumer -n kafka --replicas=2

# Check scaling status
kubectl get deployment -n kafka
```

### Update Environment Variables

```bash
# Edit producer deployment
kubectl edit deployment kafka-producer -n kafka

# Edit consumer deployment
kubectl edit deployment kafka-consumer -n kafka
```

### View Event Logs

```bash
# Get namespace events
kubectl get events -n kafka

# Watch events
kubectl get events -n kafka -w
```

### Resource Usage

```bash
# View resource usage by pods
kubectl top pods -n kafka

# View resource usage by nodes
kubectl top nodes
```

## Step 7: Cleaning Up

### Delete Deployments Individually

```bash
# Delete producer
kubectl delete deployment kafka-producer -n kafka

# Delete consumer
kubectl delete deployment kafka-consumer -n kafka

# Delete Kafka services
kubectl delete statefulset kafka-broker -n kafka
kubectl delete statefulset zookeeper -n kafka
```

### Delete Entire Namespace

```bash
# This removes everything in the namespace
kubectl delete namespace kafka
```

### Stop Minikube (if using Minikube)

```bash
minikube stop
```

## Troubleshooting

### Pods Not Starting

```bash
# Check pod status
kubectl describe pod -n kafka <pod-name>

# Check system pods
kubectl get pods --all-namespaces

# Check resource availability
kubectl top nodes
```

### Images Not Found

For Minikube, make sure images are built in minikube's Docker context:

```bash
# Minikube only: load local images
minikube image load kafka-producer:latest
minikube image load kafka-consumer:latest
```

### Kafka Connection Refused

```bash
# Verify Kafka pod is running
kubectl get pod -n kafka kafka-broker-0

# Check Kafka logs
kubectl logs -n kafka kafka-broker-0

# Port forward and test
kubectl port-forward -n kafka svc/kafka 9092:9092
nc -zv localhost 9092
```

### Consumer Not Receiving Messages

```bash
# Check if messages are in topic
kubectl exec -n kafka kafka-broker-0 -- \
  kafka-run-class kafka.tools.JmxTool \
  --object-name kafka.server:type=ReplicaManager,name=LeaderLogEndOffset,clientId=ReplicaFetcherManager,broker_id=0,partition=0,topic=test-topic

# Check consumer group
kubectl exec -n kafka kafka-broker-0 -- \
  kafka-consumer-groups --bootstrap-server localhost:9092 --group consumer-group-1 --describe
```

### Out of Resources

If you get "Insufficient CPU" or "Insufficient memory":

```bash
# For Minikube, increase resources
minikube delete
minikube start --cpus=8 --memory=16384
```

## Performance Tuning

### Increase Replicas for Testing

```bash
kubectl scale deployment kafka-consumer -n kafka --replicas=5
```

### Adjust Resource Limits

Edit the deployment YAML files and update:

```yaml
resources:
  requests:
    memory: "512Mi"    # Increase for better performance
    cpu: "250m"        # Increase for better performance
  limits:
    memory: "1Gi"
    cpu: "1000m"
```

Then apply changes:

```bash
kubectl apply -f k8s/consumer-deployment.yaml
```

## Next Steps

- Explore [Kubernetes documentation](https://kubernetes.io/docs/)
- Set up ingress for external access
- Configure persistent storage for production use
- Implement monitoring with Prometheus
- Set up logging with ELK stack
- Implement network policies for security

## Useful Aliases

Add these to your `.bashrc` or `.zshrc`:

```bash
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgn='kubectl get nodes'
alias kdesc='kubectl describe'
alias klogs='kubectl logs'
alias kexec='kubectl exec -it'
```
