#!/bin/bash

# Скрипт для развертывания приложения в Minikube с Docker Hub

# Настройки
NAMESPACE="project-sw"
DOCKER_USER="blinomesss"
IMAGE_TAG="latest"

echo "Создание namespace..."
kubectl apply -f namespace.yaml

echo "Создание ConfigMaps и Secrets..."
kubectl apply -f configmap.yaml
kubectl apply -f secret.yaml

echo "Создание PersistentVolumes и StorageClass..."
kubectl apply -f persistent-volume.yaml

echo "Создание PersistentVolumeClaims..."
kubectl apply -f persistent-volume-claim.yaml

echo "Развертывание PostgreSQL..."
kubectl apply -f postgres-deployment.yaml

echo "Ожидание готовности PostgreSQL..."
kubectl wait --for=condition=available --timeout=300s deployment/postgres -n $NAMESPACE

echo "Обновление образов сервисов с Docker Hub..."
kubectl set image deployment/auth-service auth-service=$DOCKER_USER/auth-service:$IMAGE_TAG -n $NAMESPACE
kubectl set image deployment/data-service data-service=$DOCKER_USER/data-service:$IMAGE_TAG -n $NAMESPACE
kubectl set image deployment/processing-service processing-service=$DOCKER_USER/processing-service:$IMAGE_TAG -n $NAMESPACE
kubectl set image deployment/frontend frontend=$DOCKER_USER/frontend:$IMAGE_TAG -n $NAMESPACE

echo "Создание nginx ConfigMap..."
kubectl apply -f nginx-configmap.yaml

echo "Обновление/развертывание Ingress..."
kubectl apply -f ingress.yaml

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
