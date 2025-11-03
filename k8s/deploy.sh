#!/bin/bash
set -e

NAMESPACE="project-sw"
DOCKER_USER="blinomess"
IMAGE_TAG="latest"

echo "Используем namespace: $NAMESPACE"
echo "Docker Hub пользователь: $DOCKER_USER"
echo "Тег образов: $IMAGE_TAG"

echo "Создание namespace..."
kubectl apply -f namespace.yaml

echo "Создание ConfigMaps и Secrets..."
kubectl apply -f configmap.yaml -n $NAMESPACE
kubectl apply -f secret.yaml -n $NAMESPACE

echo "Создание PersistentVolumes и StorageClass..."
kubectl apply -f persistent-volume.yaml -n $NAMESPACE

echo "Создание PersistentVolumeClaims..."
kubectl apply -f persistent-volume-claim.yaml -n $NAMESPACE

echo "Развертывание PostgreSQL..."
kubectl apply -f postgres-deployment.yaml -n $NAMESPACE

echo "Ожидание готовности PostgreSQL..."
kubectl wait --for=condition=available --timeout=300s deployment/postgres -n $NAMESPACE

echo "Создание/обновление деплойментов сервисов..."
kubectl apply -f auth-deployment.yaml -n $NAMESPACE
kubectl apply -f data-deployment.yaml -n $NAMESPACE
kubectl apply -f processing-deployment.yaml -n $NAMESPACE
kubectl apply -f frontend-deployment.yaml -n $NAMESPACE

echo "Обновление образов сервисов с Docker Hub..."
kubectl set image deployment/auth-service auth-service=$DOCKER_USER/auth-service:$IMAGE_TAG -n $NAMESPACE
kubectl set image deployment/data-service data-service=$DOCKER_USER/data-service:$IMAGE_TAG -n $NAMESPACE
kubectl set image deployment/processing-service processing-service=$DOCKER_USER/processing-service:$IMAGE_TAG -n $NAMESPACE
kubectl set image deployment/frontend frontend=$DOCKER_USER/frontend:$IMAGE_TAG -n $NAMESPACE

echo "Создание nginx ConfigMap..."
kubectl apply -f nginx-configmap.yaml -n $NAMESPACE

echo "Обновление/развертывание Ingress..."
kubectl apply -f ingress.yaml -n $NAMESPACE

echo "Ожидание готовности всех сервисов..."
kubectl wait --for=condition=available --timeout=300s deployment/auth-service -n $NAMESPACE
kubectl wait --for=condition=available --timeout=300s deployment/data-service -n $NAMESPACE
kubectl wait --for=condition=available --timeout=300s deployment/processing-service -n $NAMESPACE
kubectl wait --for=condition=available --timeout=300s deployment/frontend -n $NAMESPACE

echo "Получение информации о сервисах и подах..."
kubectl get services -n $NAMESPACE
kubectl get pods -n $NAMESPACE

echo "Получение URL для доступа к приложению..."
minikube service frontend-service -n $NAMESPACE --url

echo "Развертывание завершено!"
echo "Для доступа к приложению выполните: minikube service frontend-service -n $NAMESPACE"
