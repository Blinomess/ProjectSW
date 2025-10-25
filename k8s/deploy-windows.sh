#!/bin/bash

# Windows-совместимый скрипт для развертывания приложения в Minikube
# Этот скрипт работает через Git Bash или WSL на Windows

echo "Starting deployment to Minikube..."

# Проверяем, что Minikube запущен
if ! minikube status > /dev/null 2>&1; then
    echo "Minikube is not running. Starting Minikube..."
    minikube start
fi

echo "Creating namespace..."
kubectl apply -f k8s/namespace.yaml

echo "Creating ConfigMaps and Secrets..."
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secret.yaml

echo "Creating PersistentVolumes and StorageClass..."
kubectl apply -f k8s/persistent-volume.yaml

echo "Creating PersistentVolumeClaims..."
kubectl apply -f k8s/persistent-volume-claim.yaml

echo "Deploying PostgreSQL..."
kubectl apply -f k8s/postgres-deployment.yaml

echo "Waiting for PostgreSQL to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/postgres -n project-sw

echo "Deploying authentication service..."
kubectl apply -f k8s/auth-deployment.yaml

echo "Deploying data service..."
kubectl apply -f k8s/data-deployment.yaml

echo "Deploying processing service..."
kubectl apply -f k8s/processing-deployment.yaml

echo "Creating nginx ConfigMap..."
kubectl apply -f k8s/nginx-configmap.yaml

echo "Deploying frontend..."
kubectl apply -f k8s/frontend-deployment.yaml

echo "Creating Ingress..."
kubectl apply -f k8s/ingress.yaml

echo "Waiting for all services to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/auth-service -n project-sw
kubectl wait --for=condition=available --timeout=300s deployment/data-service -n project-sw
kubectl wait --for=condition=available --timeout=300s deployment/processing-service -n project-sw
kubectl wait --for=condition=available --timeout=300s deployment/frontend -n project-sw

echo "Getting service information..."
echo "Services:"
kubectl get services -n project-sw

echo "Pods:"
kubectl get pods -n project-sw

echo "Getting application URL..."
minikube service frontend-service -n project-sw --url

echo "Deployment completed!"
echo "To access the application, run: minikube service frontend-service -n project-sw"
