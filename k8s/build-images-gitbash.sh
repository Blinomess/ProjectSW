#!/bin/bash

# Git Bash скрипт для сборки Docker образов на Windows

set -e  # Остановить при ошибке

echo "🐳 Building Docker images via Git Bash..."

# Проверяем Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Error: Docker not found. Please install Docker Desktop."
    exit 1
fi

echo "🔍 Checking Docker status..."
if ! docker info > /dev/null 2>&1; then
    echo "❌ Error: Docker is not running. Please start Docker Desktop."
    exit 1
fi

echo "✅ Docker is running"

echo "🔑 Building authentication service..."
docker build -t auth-service:latest ./backend/authentification_service
echo "✅ Authentication service built"

echo "📊 Building data service..."
docker build -t data-service:latest ./backend/data_service
echo "✅ Data service built"

echo "⚙️  Building processing service..."
docker build -t processing-service:latest ./backend/processing_service
echo "✅ Processing service built"

echo "🎨 Building frontend..."
docker build -t frontend:latest ./frontend
echo "✅ Frontend built"

echo ""
echo "🎉 All Docker images built successfully!"
echo "📋 Built images:"
docker images | grep -E "(auth-service|data-service|processing-service|frontend)"
