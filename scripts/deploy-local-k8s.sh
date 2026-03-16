#!/bin/bash

# Deploy to Local Kubernetes
# This script deploys Kafka, Producer, and Consumer to a local Kubernetes cluster

set -e

echo "=== Local Kubernetes Deployment Script ==="
echo ""

# Configuration
NAMESPACE="kafka"
CONTEXT=$(kubectl config current-context)

echo "Current kubectl context: $CONTEXT"
echo "Target namespace: $NAMESPACE"
echo ""

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "ERROR: kubectl is not installed or not in PATH"
    exit 1
fi

# Check if cluster is accessible
echo "Checking cluster connectivity..."
if ! kubectl cluster-info &> /dev/null; then
    echo "ERROR: Cannot connect to Kubernetes cluster"
    exit 1
fi

# Build Docker images for local k8s
echo "Building Docker images..."
echo "Building producer image..."
docker build -f producer/Dockerfile -t kafka-producer:latest producer/
echo "Building consumer image..."
docker build -f consumer/Dockerfile -t kafka-consumer:latest consumer/

echo ""
echo "Docker images built successfully"
echo ""

# Create namespace
echo "Creating namespace..."
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Deploy Kafka infrastructure
echo "Deploying Kafka infrastructure..."
kubectl apply -f k8s/kafka-statefulset.yaml

# Wait for Kafka to be ready
echo "Waiting for Kafka to be ready (this may take a minute)..."
kubectl wait --for=condition=ready pod -l app=kafka-broker -n $NAMESPACE --timeout=300s 2>/dev/null || true
sleep 10

# Deploy Producer
echo "Deploying Producer..."
kubectl apply -f k8s/producer-deployment.yaml

# Deploy Consumer
echo "Deploying Consumer..."
kubectl apply -f k8s/consumer-deployment.yaml

echo ""
echo "=== Deployment Complete ==="
echo ""
echo "To check deployment status:"
echo "  kubectl get pods -n $NAMESPACE"
echo "  kubectl get services -n $NAMESPACE"
echo ""
echo "To view logs:"
echo "  kubectl logs -n $NAMESPACE -l app=kafka-producer --tail=100"
echo "  kubectl logs -n $NAMESPACE -l app=kafka-consumer --tail=100"
echo ""
echo "To port-forward to Kafka:"
echo "  kubectl port-forward -n $NAMESPACE svc/kafka 9092:9092"
echo ""
echo "To delete all resources:"
echo "  kubectl delete namespace $NAMESPACE"
