#!/bin/bash

# Git Bash скрипт для остановки Minikube на Windows

set -e  # Остановить при ошибке

echo "🛑 Stopping Minikube deployment..."

# Проверяем kubectl
if ! command -v kubectl &> /dev/null; then
    echo "❌ Error: kubectl not found. Please install kubectl."
    exit 1
fi

echo "🗑️  Deleting all resources from project-sw namespace..."
kubectl delete namespace project-sw --ignore-not-found=true

echo "⏹️  Stopping Minikube..."
minikube stop

echo "🧹 Cleanup completed successfully!"
echo "💡 To start again, run: ./k8s/deploy-gitbash.sh"
