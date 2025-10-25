#!/bin/bash

# Скрипт для развертывания приложения в Minikube

echo "Создание namespace..."
kubectl apply -f k8s/namespace.yaml

echo "Создание ConfigMaps и Secrets..."
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secret.yaml

echo "Создание PersistentVolumes и StorageClass..."
kubectl apply -f k8s/persistent-volume.yaml

echo "Создание PersistentVolumeClaims..."
kubectl apply -f k8s/persistent-volume-claim.yaml

echo "Развертывание PostgreSQL..."
kubectl apply -f k8s/postgres-deployment.yaml

echo "Ожидание готовности PostgreSQL..."
kubectl wait --for=condition=available --timeout=300s deployment/postgres -n project-sw

echo "Развертывание сервиса аутентификации..."
kubectl apply -f k8s/auth-deployment.yaml

echo "Развертывание сервиса данных..."
kubectl apply -f k8s/data-deployment.yaml

echo "Развертывание сервиса обработки..."
kubectl apply -f k8s/processing-deployment.yaml

echo "Создание nginx ConfigMap..."
kubectl apply -f k8s/nginx-configmap.yaml

echo "Развертывание фронтенда..."
kubectl apply -f k8s/frontend-deployment.yaml

echo "Создание Ingress..."
kubectl apply -f k8s/ingress.yaml

echo "Ожидание готовности всех сервисов..."
kubectl wait --for=condition=available --timeout=300s deployment/auth-service -n project-sw
kubectl wait --for=condition=available --timeout=300s deployment/data-service -n project-sw
kubectl wait --for=condition=available --timeout=300s deployment/processing-service -n project-sw
kubectl wait --for=condition=available --timeout=300s deployment/frontend -n project-sw

echo "Получение информации о сервисах..."
echo "Сервисы:"
kubectl get services -n project-sw

echo "Поды:"
kubectl get pods -n project-sw

echo "Получение URL для доступа к приложению..."
minikube service frontend-service -n project-sw --url

echo "Развертывание завершено!"
echo "Для доступа к приложению выполните: minikube service frontend-service -n project-sw"