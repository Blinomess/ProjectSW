#!/bin/bash

# Git Bash скрипт для развертывания приложения в Minikube на Windows
# Этот скрипт работает через Git Bash и использует Windows-совместимые команды

set -e  # Остановить при ошибке

echo "🚀 Starting deployment to Minikube via Git Bash..."

# Проверяем, что мы в правильной директории
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ Error: docker-compose.yml not found. Please run from project root."
    exit 1
fi

# Проверяем, что Minikube запущен
echo "🔍 Checking Minikube status..."
if ! minikube status > /dev/null 2>&1; then
    echo "⚠️  Minikube is not running. Starting Minikube..."
    minikube start
    echo "✅ Minikube started successfully"
else
    echo "✅ Minikube is already running"
fi

# Проверяем kubectl
if ! command -v kubectl &> /dev/null; then
    echo "❌ Error: kubectl not found. Please install kubectl."
    exit 1
fi

echo "📦 Creating namespace..."
kubectl apply -f k8s/namespace.yaml

echo "🔐 Creating ConfigMaps and Secrets..."
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secret.yaml

echo "💾 Creating PersistentVolumes and StorageClass..."
kubectl apply -f k8s/persistent-volume.yaml

echo "📁 Creating PersistentVolumeClaims..."
kubectl apply -f k8s/persistent-volume-claim.yaml

echo "🐘 Deploying PostgreSQL..."
kubectl apply -f k8s/postgres-deployment.yaml

echo "⏳ Waiting for PostgreSQL to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/postgres -n project-sw

echo "🔑 Deploying authentication service..."
kubectl apply -f k8s/auth-deployment.yaml

echo "📊 Deploying data service..."
kubectl apply -f k8s/data-deployment.yaml

echo "⚙️  Deploying processing service..."
kubectl apply -f k8s/processing-deployment.yaml

echo "🌐 Creating nginx ConfigMap..."
kubectl apply -f k8s/nginx-configmap.yaml

echo "🎨 Deploying frontend..."
kubectl apply -f k8s/frontend-deployment.yaml

echo "🔗 Creating Ingress..."
kubectl apply -f k8s/ingress.yaml

echo "⏳ Waiting for all services to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/auth-service -n project-sw
kubectl wait --for=condition=available --timeout=300s deployment/data-service -n project-sw
kubectl wait --for=condition=available --timeout=300s deployment/processing-service -n project-sw
kubectl wait --for=condition=available --timeout=300s deployment/frontend -n project-sw

echo "📋 Getting service information..."
echo "Services:"
kubectl get services -n project-sw

echo ""
echo "Pods:"
kubectl get pods -n project-sw

echo ""
echo "🌍 Getting application URL..."
minikube service frontend-service -n project-sw --url

echo ""
echo "🎉 Deployment completed successfully!"
echo "💡 To access the application, run: minikube service frontend-service -n project-sw"
