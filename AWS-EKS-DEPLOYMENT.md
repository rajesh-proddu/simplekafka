# AWS EKS Deployment Guide

This guide provides detailed instructions for deploying SimpleKafka to AWS EKS.

## Prerequisites

1. **AWS Account** with EKS cluster created
2. **AWS CLI** installed and configured
3. **kubectl** installed and configured
4. **Docker** installed for building images
5. **ECR** (Elastic Container Registry) access

## Step 1: Prepare AWS Environment

### Create EKS Cluster (if not already created)

```bash
aws eks create-cluster \
  --name kafka-cluster \
  --version 1.27 \
  --role-arn arn:aws:iam::YOUR_ACCOUNT_ID:role/eks-service-role \
  --resources-vpc-config subnetIds=subnet-xxx,subnet-yyy \
  --region us-east-1
```

### Configure kubectl

```bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name kafka-cluster
```

## Step 2: Set Environment Variables

```bash
# Get your AWS Account ID
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Set AWS Region
export AWS_REGION=us-east-1

# Set EKS Cluster Name
export EKS_CLUSTER_NAME=kafka-cluster

# Construct ECR Registry URL
export ECR_REGISTRY_URL=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
```

## Step 3: Create IAM Role for ECR Access (Optional)

If your nodes don't have ECR access, create an IAM role:

```bash
aws iam create-role \
  --role-name eks-ecr-access \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  }' \
  --region $AWS_REGION

aws iam attach-role-policy \
  --role-name eks-ecr-access \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly
```

## Step 4: Deploy Applications

### Automated Deployment

```bash
./scripts/deploy-aws-eks.sh
```

This script will:
1. Configure kubectl for your cluster
2. Create ECR repositories
3. Build and push Docker images to ECR
4. Apply Kubernetes manifests
5. Deploy Kafka, Producer, and Consumer

### Manual Deployment Steps

#### 4.1 Login to ECR

```bash
aws ecr get-login-password --region $AWS_REGION | \
  docker login --username AWS --password-stdin $ECR_REGISTRY_URL
```

#### 4.2 Create ECR Repositories

```bash
aws ecr create-repository \
  --repository-name kafka-producer \
  --region $AWS_REGION

aws ecr create-repository \
  --repository-name kafka-consumer \
  --region $AWS_REGION
```

#### 4.3 Build and Push Images

```bash
# Producer
docker build -f producer/Dockerfile -t kafka-producer:latest producer/
docker tag kafka-producer:latest $ECR_REGISTRY_URL/kafka-producer:latest
docker push $ECR_REGISTRY_URL/kafka-producer:latest

# Consumer
docker build -f consumer/Dockerfile -t kafka-consumer:latest consumer/
docker tag kafka-consumer:latest $ECR_REGISTRY_URL/kafka-consumer:latest
docker push $ECR_REGISTRY_URL/kafka-consumer:latest
```

#### 4.4 Update Manifests

Replace placeholder registry URLs in manifests:

```bash
sed -i "s|ACCOUNT_ID.dkr.ecr.REGION.amazonaws.com|${ECR_REGISTRY_URL}|g" \
  aws-eks/producer-deployment.yaml \
  aws-eks/consumer-deployment.yaml
```

#### 4.5 Apply Kubernetes Manifests

```bash
# Create namespace
kubectl create namespace kafka

# Deploy Kafka
kubectl apply -f aws-eks/kafka-statefulset.yaml

# Wait for Kafka to be ready
kubectl wait --for=condition=ready pod -l app=kafka-broker -n kafka --timeout=600s

# Deploy Producer and Consumer
kubectl apply -f aws-eks/producer-deployment.yaml
kubectl apply -f aws-eks/consumer-deployment.yaml
```

## Step 5: Monitor Deployment

### Check Pod Status

```bash
kubectl get pods -n kafka
kubectl get pods -n kafka -o wide
```

### View Logs

```bash
# Producer logs
kubectl logs -n kafka -l app=kafka-producer -f

# Consumer logs
kubectl logs -n kafka -l app=kafka-consumer -f

# Kafka logs
kubectl logs -n kafka -l app=kafka-broker -f
```

### Check Services

```bash
kubectl get svc -n kafka
```

### Get Kafka LoadBalancer Endpoint

```bash
kubectl get svc -n kafka kafka-lb \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

## Step 6: Scaling

### Check HPA (Horizontal Pod Autoscaler)

```bash
kubectl get hpa -n kafka
kubectl describe hpa kafka-consumer-hpa -n kafka
```

### Manually Scale Services

```bash
# Scale consumer to 5 replicas
kubectl scale deployment kafka-consumer -n kafka --replicas=5

# Scale producer to 3 replicas
kubectl scale deployment kafka-producer -n kafka --replicas=3
```

## Step 7: Cleanup

### Delete Kubernetes Resources

```bash
# Delete namespace (removes all resources)
kubectl delete namespace kafka
```

### Delete ECR Repositories

```bash
aws ecr delete-repository \
  --repository-name kafka-producer \
  --force \
  --region $AWS_REGION

aws ecr delete-repository \
  --repository-name kafka-consumer \
  --force \
  --region $AWS_REGION
```

### Delete EKS Cluster

```bash
aws eks delete-cluster \
  --name kafka-cluster \
  --region $AWS_REGION
```

## Troubleshooting

### Images Not Found in ECR

Make sure you're pushing to the correct registry and tags:

```bash
aws ecr describe-repositories --region $AWS_REGION
docker image ls | grep kafka
```

### Pods Cannot Pull Images

Check authentication between cluster and ECR:

```bash
# Create image pull secret (if using private repositories)
kubectl create secret docker-registry ecr-secret \
  --docker-server=$ECR_REGISTRY_URL \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region $AWS_REGION) \
  --docker-email=user@example.com \
  -n kafka
```

Then update deployments to use this secret:

```yaml
spec:
  template:
    spec:
      imagePullSecrets:
      - name: ecr-secret
```

### Kafka Pods Not Starting

Check resource availability:

```bash
kubectl describe pod -n kafka kafka-broker-0
kubectl top nodes
kubectl top pods -n kafka
```

### Consumer Lag Issues

Check consumer group status:

```bash
kubectl exec -n kafka kafka-broker-0 -- \
  kafka-consumer-groups \
  --bootstrap-server localhost:9092 \
  --group consumer-group-1 \
  --describe
```

## Cost Optimization Tips

1. Use smaller EBS volumes after initial setup
2. Configure pod resource limits appropriately
3. Use managed Kafka services if available in your region
4. Implement lifecycle policies for log retention
5. Monitor and adjust replica counts based on actual load

## Additional Resources

- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [ECR Getting Started](https://docs.aws.amazon.com/AmazonECR/latest/userguide/getting-started-ecr.html)
- [Kafka on Kubernetes Best Practices](https://kafka.apache.org/documentation/#bestpractices)
