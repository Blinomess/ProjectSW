#!/bin/bash

# Скрипт для очистки развертывания

echo "Удаление всех ресурсов из namespace project-sw..."
kubectl delete namespace project-sw

echo "Очистка PersistentVolumes..."
kubectl delete pv postgres-pv storage-pv

echo "Очистка StorageClass..."
kubectl delete storageclass local-storage

echo "Очистка завершена!"
