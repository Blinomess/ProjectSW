#!/bin/bash

# Скрипт для остановки деплоя в Minikube
echo "=== Stopping Minikube deployment ==="

# Удаляем все ресурсы из namespace
echo "Deleting all resources from scidata namespace..."
kubectl delete namespace scidata

# Показываем статус
echo "Checking remaining resources..."
kubectl get all --all-namespaces | grep scidata || echo "No scidata resources found"

echo "Minikube deployment stopped!"
