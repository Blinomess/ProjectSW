#!/bin/bash

# Windows-совместимый скрипт для остановки Minikube

echo "Stopping Minikube deployment..."

echo "Deleting all resources from project-sw namespace..."
kubectl delete namespace project-sw

echo "Stopping Minikube..."
minikube stop

echo "Cleanup completed!"
