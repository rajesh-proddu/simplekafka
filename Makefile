# Makefile for SimpleKafka

.PHONY: help build build-producer build-consumer \
        docker-build docker-build-producer docker-build-consumer \
        compose-up compose-down compose-logs \
        k8s-deploy k8s-deploy-local k8s-clean \
        eks-deploy eks-clean \
        fmt lint test clean

help:
	@echo "SimpleKafka Makefile Commands"
	@echo ""
	@echo "Build Commands:"
	@echo "  make build                 - Build all applications"
	@echo "  make build-producer        - Build producer"
	@echo "  make build-consumer        - Build consumer"
	@echo ""
	@echo "Docker Commands:"
	@echo "  make docker-build          - Build Docker images"
	@echo "  make docker-build-producer - Build producer image"
	@echo "  make docker-build-consumer - Build consumer image"
	@echo ""
	@echo "Docker Compose:"
	@echo "  make compose-up            - Start Docker Compose stack"
	@echo "  make compose-down          - Stop Docker Compose stack"
	@echo "  make compose-logs          - View Docker Compose logs"
	@echo ""
	@echo "Kubernetes Local:"
	@echo "  make k8s-deploy            - Deploy to local Kubernetes"
	@echo "  make k8s-status            - Check deployment status"
	@echo "  make k8s-logs              - View Kubernetes logs"
	@echo "  make k8s-clean             - Delete Kubernetes deployment"
	@echo ""
	@echo "AWS EKS:"
	@echo "  make eks-deploy            - Deploy to AWS EKS"
	@echo "  make eks-clean             - Delete EKS deployment"
	@echo ""
	@echo "Development:"
	@echo "  make fmt                   - Format code"
	@echo "  make test                  - Run tests"
	@echo "  make clean                 - Clean build artifacts"

build: build-producer build-consumer

build-producer:
	@echo "Building producer..."
	cd producer && go build -o producer .
	@echo "Producer built: producer/producer"

build-consumer:
	@echo "Building consumer..."
	cd consumer && go build -o consumer .
	@echo "Consumer built: consumer/consumer"

docker-build: docker-build-producer docker-build-consumer

docker-build-producer:
	@echo "Building producer Docker image..."
	docker build -f producer/Dockerfile -t kafka-producer:latest producer/
	@echo "Producer image built: kafka-producer:latest"

docker-build-consumer:
	@echo "Building consumer Docker image..."
	docker build -f consumer/Dockerfile -t kafka-consumer:latest consumer/
	@echo "Consumer image built: kafka-consumer:latest"

compose-up: docker-build
	@echo "Starting Docker Compose stack..."
	docker-compose up -d
	@echo "Stack started. View logs with: make compose-logs"

compose-down:
	@echo "Stopping Docker Compose stack..."
	docker-compose down
	@echo "Stack stopped"

compose-logs:
	docker-compose logs -f

k8s-deploy: docker-build
	@echo "Deploying to local Kubernetes..."
	./scripts/deploy-local-k8s.sh

k8s-status:
	@echo "Kafka namespace pods:"
	kubectl get pods -n kafka
	@echo ""
	@echo "Kafka namespace services:"
	kubectl get svc -n kafka

k8s-logs:
	@echo "Producer logs:"
	kubectl logs -n kafka -l app=kafka-producer --tail=50
	@echo ""
	@echo "Consumer logs:"
	kubectl logs -n kafka -l app=kafka-consumer --tail=50

k8s-clean:
	kubectl delete namespace kafka

eks-deploy: docker-build
	@echo "Deploying to AWS EKS..."
	./scripts/deploy-aws-eks.sh

eks-clean:
	kubectl delete namespace kafka

fmt:
	@echo "Formatting code..."
	gofmt -s -w producer/ consumer/
	@echo "Code formatted"

test:
	@echo "Running tests..."
	go test ./...

clean:
	@echo "Cleaning build artifacts..."
	rm -f producer/producer
	rm -f consumer/consumer
	@echo "Cleaned"
