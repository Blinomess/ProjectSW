# Развертывание проекта ProjectSW в Kubernetes с Minikube

## Обзор

Проект ProjectSW теперь полностью готов для развертывания в Kubernetes с использованием Minikube. Все необходимые манифесты, скрипты и конфигурации созданы в директории `k8s/`.

## Архитектура

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   Auth Service  │    │  Data Service   │
│   (nginx:80)    │◄───┤   (FastAPI:8000)│◄───┤  (FastAPI:8001) │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Ingress       │    │   PostgreSQL    │    │Processing Service│
│   (LoadBalancer)│    │   (Port:5432)   │    │  (FastAPI:8002) │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Компоненты

### 1. Namespace
- **project-sw** - изолированное пространство для всех ресурсов

### 2. Сервисы
- **postgres** - база данных PostgreSQL с PersistentVolume
- **auth-service** - сервис аутентификации (2 реплики)
- **data-service** - сервис данных с общим хранилищем (2 реплики)
- **processing-service** - сервис анализа CSV (2 реплики)
- **frontend** - веб-интерфейс с nginx (2 реплики)

### 3. Хранилище
- **postgres-pv** - 10Gi для данных PostgreSQL
- **storage-pv** - 5Gi для файлов пользователей (ReadWriteMany)

### 4. Сеть
- **ClusterIP** сервисы для внутренней коммуникации
- **LoadBalancer** для внешнего доступа к фронтенду
- **Ingress** для маршрутизации (опционально)

## Быстрый старт

### Предварительные требования

1. **Minikube** установлен
2. **kubectl** настроен
3. **Docker** для сборки образов

### Шаг 1: Сборка образов

```bash
cd k8s
./build-images.sh
```

Этот скрипт:
- Запускает Minikube
- Настраивает Docker окружение
- Собирает все Docker образы
- Создает необходимые директории для PersistentVolumes

### Шаг 2: Развертывание

```bash
./deploy.sh
```

Этот скрипт:
- Создает namespace и конфигурации
- Развертывает все сервисы в правильном порядке
- Ждет готовности всех компонентов
- Выводит URL для доступа к приложению

### Шаг 3: Доступ к приложению

```bash
minikube service frontend-service -n project-sw
```

## Ручное развертывание

Если нужно развернуть компоненты по отдельности:

```bash
# 1. Namespace и конфигурация
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secret.yaml

# 2. Хранилище
kubectl apply -f k8s/persistent-volume.yaml
kubectl apply -f k8s/persistent-volume-claim.yaml

# 3. База данных
kubectl apply -f k8s/postgres-deployment.yaml

# 4. Микросервисы
kubectl apply -f k8s/auth-deployment.yaml
kubectl apply -f k8s/data-deployment.yaml
kubectl apply -f k8s/processing-deployment.yaml

# 5. Фронтенд
kubectl apply -f k8s/nginx-configmap.yaml
kubectl apply -f k8s/frontend-deployment.yaml

# 6. Ingress (опционально)
kubectl apply -f k8s/ingress.yaml
```

## Мониторинг и отладка

### Проверка статуса

```bash
# Все поды
kubectl get pods -n project-sw

# Все сервисы
kubectl get services -n project-sw

# PersistentVolumes
kubectl get pv
kubectl get pvc -n project-sw
```

### Логи

```bash
# Логи конкретного сервиса
kubectl logs -f deployment/auth-service -n project-sw
kubectl logs -f deployment/data-service -n project-sw
kubectl logs -f deployment/processing-service -n project-sw
kubectl logs -f deployment/frontend -n project-sw
kubectl logs -f deployment/postgres -n project-sw
```

### Health Checks

Все сервисы имеют endpoint `/health`:

```bash
# Проверка health endpoints
kubectl port-forward service/auth-service 8000:8000 -n project-sw
curl http://localhost:8000/health
```

## Масштабирование

```bash
# Увеличить количество реплик
kubectl scale deployment auth-service --replicas=3 -n project-sw
kubectl scale deployment data-service --replicas=3 -n project-sw
kubectl scale deployment processing-service --replicas=3 -n project-sw
kubectl scale deployment frontend --replicas=3 -n project-sw
```

## Очистка

```bash
# Полная очистка
cd k8s
./cleanup.sh

# Или вручную
kubectl delete namespace project-sw
kubectl delete pv postgres-pv storage-pv
kubectl delete storageclass local-storage
```

## Особенности конфигурации

### Ресурсы
- **CPU**: 50m-200m на контейнер
- **Memory**: 64Mi-256Mi на контейнер

### Health Checks
- **Liveness Probe**: проверка каждые 10 секунд
- **Readiness Probe**: проверка каждые 5 секунд

### Сетевая конфигурация
- Внутренняя коммуникация через DNS имена сервисов
- CORS настроен для localhost и порта 80
- nginx проксирует запросы к соответствующим сервисам

### Безопасность
- Secrets для чувствительных данных (пароли БД)
- ConfigMaps для обычной конфигурации
- Изолированный namespace

## Troubleshooting

### Проблемы с образами
```bash
# Проверить образы в Minikube
minikube ssh
docker images | grep -E "(auth-service|data-service|processing-service|frontend)"
```

### Проблемы с PersistentVolumes
```bash
# Проверить статус PV
kubectl describe pv postgres-pv
kubectl describe pv storage-pv
```

### Проблемы с сетью
```bash
# Проверить DNS
kubectl run test-pod --image=busybox --rm -it -- nslookup auth-service.project-sw.svc.cluster.local
```

### Проблемы с базой данных
```bash
# Подключиться к PostgreSQL
kubectl exec -it deployment/postgres -n project-sw -- psql -U user -d scidata
```

## Дальнейшее развитие

1. **Helm Charts** - для более удобного управления
2. **Monitoring** - Prometheus + Grafana
3. **Logging** - ELK Stack
4. **CI/CD** - автоматическое развертывание
5. **Security** - NetworkPolicies, RBAC
6. **Auto-scaling** - HPA (Horizontal Pod Autoscaler)

## Файлы проекта

```
k8s/
├── namespace.yaml              # Namespace
├── configmap.yaml             # Конфигурация приложения
├── secret.yaml                # Секреты
├── persistent-volume.yaml     # PersistentVolumes и StorageClass
├── persistent-volume-claim.yaml # PVC
├── postgres-deployment.yaml   # PostgreSQL
├── auth-deployment.yaml       # Сервис аутентификации
├── data-deployment.yaml       # Сервис данных
├── processing-deployment.yaml # Сервис обработки
├── nginx-configmap.yaml       # Конфигурация nginx
├── frontend-deployment.yaml   # Фронтенд
├── ingress.yaml              # Ingress
├── build-images.sh           # Скрипт сборки образов
├── deploy.sh                 # Скрипт развертывания
├── cleanup.sh                # Скрипт очистки
└── README.md                 # Документация
```

Проект готов к развертыванию в Kubernetes! 🚀
