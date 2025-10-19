# Kubernetes развертывание проекта ProjectSW

Этот каталог содержит все необходимые манифесты для развертывания проекта в Kubernetes с использованием Minikube.

## Структура проекта

- **Namespace**: `project-sw` - изолированное пространство для всех ресурсов
- **Сервисы**:
  - `postgres` - база данных PostgreSQL
  - `auth-service` - сервис аутентификации (порт 8000)
  - `data-service` - сервис данных (порт 8001)
  - `processing-service` - сервис обработки CSV (порт 8002)
  - `frontend` - веб-интерфейс с nginx (порт 80)

## Предварительные требования

1. **Minikube** установлен и запущен
2. **kubectl** настроен для работы с Minikube
3. **Docker** для сборки образов

## Быстрый старт

### 1. Сборка Docker образов

```bash
chmod +x build-images.sh
./build-images.sh
```

### 2. Развертывание приложения

```bash
chmod +x deploy.sh
./deploy.sh
```

### 3. Доступ к приложению

```bash
minikube service frontend-service -n project-sw
```

## Ручное развертывание

Если вы хотите развернуть компоненты по отдельности:

```bash
# 1. Создание namespace
kubectl apply -f namespace.yaml

# 2. Конфигурация
kubectl apply -f configmap.yaml
kubectl apply -f secret.yaml

# 3. Хранилище
kubectl apply -f persistent-volume.yaml
kubectl apply -f persistent-volume-claim.yaml

# 4. База данных
kubectl apply -f postgres-deployment.yaml

# 5. Микросервисы
kubectl apply -f auth-deployment.yaml
kubectl apply -f data-deployment.yaml
kubectl apply -f processing-deployment.yaml

# 6. Фронтенд
kubectl apply -f nginx-configmap.yaml
kubectl apply -f frontend-deployment.yaml

# 7. Ingress
kubectl apply -f ingress.yaml
```

## Мониторинг

### Проверка статуса подов

```bash
kubectl get pods -n project-sw
```

### Проверка сервисов

```bash
kubectl get services -n project-sw
```

### Логи сервисов

```bash
# Логи конкретного сервиса
kubectl logs -f deployment/auth-service -n project-sw
kubectl logs -f deployment/data-service -n project-sw
kubectl logs -f deployment/processing-service -n project-sw
kubectl logs -f deployment/frontend -n project-sw
```

### Проверка PersistentVolumes

```bash
kubectl get pv
kubectl get pvc -n project-sw
```

## Масштабирование

Для изменения количества реплик сервисов:

```bash
kubectl scale deployment auth-service --replicas=3 -n project-sw
kubectl scale deployment data-service --replicas=3 -n project-sw
kubectl scale deployment processing-service --replicas=3 -n project-sw
kubectl scale deployment frontend --replicas=3 -n project-sw
```

## Очистка

Для полного удаления развертывания:

```bash
chmod +x cleanup.sh
./cleanup.sh
```

Или вручную:

```bash
kubectl delete namespace project-sw
kubectl delete pv postgres-pv storage-pv
kubectl delete storageclass local-storage
```

## Особенности конфигурации

### PersistentVolumes

- **postgres-pv**: 10Gi для данных PostgreSQL
- **storage-pv**: 5Gi для файлов пользователей (ReadWriteMany)

### Ресурсы

Каждый сервис имеет ограничения:
- **CPU**: 100m-200m
- **Memory**: 128Mi-256Mi

### Health Checks

Все сервисы имеют проверки готовности и жизнеспособности.

### Сетевая конфигурация

- Внутренняя коммуникация через ClusterIP сервисы
- Внешний доступ через LoadBalancer (frontend-service)
- Ingress настроен для `project-sw.local`

## Troubleshooting

### Проблемы с PersistentVolumes

```bash
# Проверка статуса PV
kubectl describe pv postgres-pv
kubectl describe pv storage-pv

# Проверка PVC
kubectl describe pvc postgres-pvc -n project-sw
kubectl describe pvc storage-pvc -n project-sw
```

### Проблемы с образами

```bash
# Проверка доступности образов в Minikube
minikube ssh
docker images | grep -E "(auth-service|data-service|processing-service|frontend)"
```

### Проблемы с сетью

```bash
# Проверка DNS разрешения
kubectl run test-pod --image=busybox --rm -it -- nslookup auth-service.project-sw.svc.cluster.local
```
