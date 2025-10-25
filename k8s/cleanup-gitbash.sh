#!/bin/bash

# Git Bash скрипт для полной очистки Minikube на Windows

set -e  # Остановить при ошибке

echo "🧹 Full cleanup of Minikube environment..."

# Проверяем kubectl
if ! command -v kubectl &> /dev/null; then
    echo "❌ Error: kubectl not found. Please install kubectl."
    exit 1
fi

echo "🗑️  Deleting all resources from project-sw namespace..."
kubectl delete namespace project-sw --ignore-not-found=true

echo "🛑 Stopping Minikube..."
minikube stop

echo "🗑️  Deleting Minikube cluster..."
minikube delete

echo "🧹 Cleaning up Docker images..."
docker rmi $(docker images -q auth-service data-service processing-service frontend) 2>/dev/null || true

echo "✅ Full cleanup completed!"
echo "💡 To start fresh, run: minikube start && ./k8s/deploy-gitbash.sh"
