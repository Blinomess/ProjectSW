#!/bin/bash

# Скрипт для сборки Docker образов для Minikube

echo "Запуск Minikube..."
minikube start

echo "Настройка Docker окружения для Minikube..."
eval $(minikube docker-env)

echo "Сборка образа для сервиса аутентификации..."
docker build -t auth-service:latest ./backend/authentification_service/

echo "Сборка образа для сервиса данных..."
docker build -t data-service:latest ./backend/data_service/

echo "Сборка образа для сервиса обработки..."
docker build -t processing-service:latest ./backend/processing_service/

echo "Сборка образа для фронтенда..."
docker build -t frontend:latest ./frontend/

echo "Создание директорий для PersistentVolumes..."
minikube ssh "sudo mkdir -p /data/postgres /data/storage"
minikube ssh "sudo chmod 777 /data/postgres /data/storage"

echo "Все образы собраны успешно!"
echo "Теперь можно запустить: ./k8s/deploy.sh"
