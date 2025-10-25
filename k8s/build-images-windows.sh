#!/bin/bash

# Windows-совместимый скрипт для сборки Docker образов

echo "Building Docker images..."

echo "Building authentication service..."
docker build -t auth-service:latest ./backend/authentification_service

echo "Building data service..."
docker build -t data-service:latest ./backend/data_service

echo "Building processing service..."
docker build -t processing-service:latest ./backend/processing_service

echo "Building frontend..."
docker build -t frontend:latest ./frontend

echo "All Docker images built successfully!"
