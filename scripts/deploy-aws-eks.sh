#!/bin/bash

# Deploy to AWS EKS
# This script deploys Kafka, Producer, and Consumer to AWS EKS

set -e

echo "=== AWS EKS Deployment Script ==="
echo ""

# Configuration - MODIFY THESE
AWS_REGION="${AWS_REGION:-us-east-1}"
EKS_CLUSTER_NAME="${EKS_CLUSTER_NAME:-my-kafka-cluster}"
AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID:-}"
ECR_REGISTRY_URL="${ECR_REGISTRY_URL:-}"
NAMESPACE="kafka"
DOCKER_USERNAME="AWS"

# Validate required parameters
if [ -z "$AWS_ACCOUNT_ID" ] || [ -z "$ECR_REGISTRY_URL" ]; then
    echo "ERROR: AWS_ACCOUNT_ID and ECR_REGISTRY_URL environment variables must be set"
    echo ""
    echo "Example:"
    echo "  export AWS_ACCOUNT_ID=123456789012"
    echo "  export ECR_REGISTRY_URL=123456789012.dkr.ecr.us-east-1.amazonaws.com"
    echo "  export AWS_REGION=us-east-1"
    echo "  ./scripts/deploy-aws-eks.sh"
    exit 1
fi

echo "AWS Region: $AWS_REGION"
echo "EKS Cluster: $EKS_CLUSTER_NAME"
echo "ECR Registry: $ECR_REGISTRY_URL"
echo "Target namespace: $NAMESPACE"
echo ""

# Check if required tools are available
for tool in kubectl aws docker; do
    if ! command -v $tool &> /dev/null; then
        echo "ERROR: $tool is not installed or not in PATH"
        exit 1
    fi
done

# Configure kubectl to use EKS cluster
echo "Configuring kubectl for EKS cluster..."
aws eks update-kubeconfig --region $AWS_REGION --name $EKS_CLUSTER_NAME

# Verify cluster connectivity
echo "Verifying cluster connectivity..."
if ! kubectl cluster-info &> /dev/null; then
    echo "ERROR: Cannot connect to EKS cluster"
    exit 1
fi

# Login to ECR
echo "Logging in to ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username $DOCKER_USERNAME --password-stdin $ECR_REGISTRY_URL

# Create ECR repositories if they don't exist
echo "Creating ECR repositories if they don't exist..."
for repo in kafka-producer kafka-consumer; do
    if ! aws ecr describe-repositories --repository-names $repo --region $AWS_REGION &> /dev/null; then
        echo "Creating ECR repository: $repo"
        aws ecr create-repository --repository-name $repo --region $AWS_REGION
    fi
done

# Build and push Docker images
echo ""
echo "Building and pushing Docker images to ECR..."
for image in producer consumer; do
    echo "Building $image image..."
    docker build -f $image/Dockerfile -t kafka-$image:latest $image/
    
    echo "Tagging $image image for ECR..."
    docker tag kafka-$image:latest $ECR_REGISTRY_URL/kafka-$image:latest
    
    echo "Pushing $image image to ECR..."
    docker push $ECR_REGISTRY_URL/kafka-$image:latest
done

echo ""
echo "Docker images pushed to ECR successfully"
echo ""

# Create namespace
echo "Creating namespace..."
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Update manifests with actual ECR registry URL
echo "Updating manifests with ECR registry URL..."
sed -i.bak "s|ACCOUNT_ID.dkr.ecr.REGION.amazonaws.com|${ECR_REGISTRY_URL}|g" aws-eks/producer-deployment.yaml
sed -i.bak "s|ACCOUNT_ID.dkr.ecr.REGION.amazonaws.com|${ECR_REGISTRY_URL}|g" aws-eks/consumer-deployment.yaml

# Deploy Kafka infrastructure
echo "Deploying Kafka infrastructure..."
kubectl apply -f aws-eks/kafka-statefulset.yaml

# Wait for Kafka to be ready
echo "Waiting for Kafka to be ready (this may take a few minutes)..."
kubectl wait --for=condition=ready pod -l app=kafka-broker -n $NAMESPACE --timeout=600s 2>/dev/null || true
sleep 15

# Deploy Producer
echo "Deploying Producer..."
kubectl apply -f aws-eks/producer-deployment.yaml

# Deploy Consumer
echo "Deploying Consumer..."
kubectl apply -f aws-eks/consumer-deployment.yaml

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
echo "To get Kafka LoadBalancer endpoint:"
echo "  kubectl get svc -n $NAMESPACE kafka-lb -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"
echo ""
echo "To delete all resources:"
echo "  kubectl delete namespace $NAMESPACE"
echo ""
