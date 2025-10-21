# Настройка GitHub Environments для CI/CD

## 🎯 Что такое GitHub Environments?

GitHub Environments — это способ создания **изолированных сред развертывания** с отдельными настройками, секретами и правилами защиты.

## 🔧 Как настроить Environments в вашем репозитории

### Шаг 1: Перейдите в настройки репозитория
1. Откройте ваш репозиторий на GitHub
2. Нажмите на вкладку **"Settings"** (Настройки)
3. В левом меню найдите **"Environments"** (Среды)

### Шаг 2: Создайте Environment "staging"
1. Нажмите **"New environment"**
2. Введите название: `staging`
3. Нажмите **"Configure environment"**

**Настройки для staging:**
- **Protection rules:** Оставьте пустым (для тестовой среды)
- **Environment secrets:** Добавьте секреты (см. ниже)
- **Environment variables:** Добавьте переменные (см. ниже)

### Шаг 3: Создайте Environment "production"
1. Нажмите **"New environment"**
2. Введите название: `production`
3. Нажмите **"Configure environment"**

**Настройки для production:**
- **Protection rules:** 
  - ✅ **Required reviewers:** Добавьте себя как ревьюера
  - ✅ **Wait timer:** 5 минут (опционально)
- **Environment secrets:** Добавьте секреты (см. ниже)
- **Environment variables:** Добавьте переменные (см. ниже)

## 🔐 Необходимые секреты (Environment Secrets)

### Для обоих environments добавьте:

| Название секрета | Описание | Пример значения |
|------------------|----------|-----------------|
| `POSTGRES_PASSWORD` | Пароль для PostgreSQL | `postgres_passwd_1234` |
| `JWT_SECRET` | Секретный ключ для JWT токенов | `jwt_scrt_1234` |

### Как добавить секреты:
1. В настройках Environment нажмите **"Add secret"**
2. Введите название секрета
3. Введите значение секрета
4. Нажмите **"Add secret"**

## 🌍 Необходимые переменные (Environment Variables)

### Для обоих environments добавьте:

| Название переменной | Описание | Пример значения |
|---------------------|----------|-----------------|
| `DATABASE_URL` | URL подключения к БД | `postgresql://user:password@postgres-service:5432/scidata` |
| `POSTGRES_DB` | Название базы данных | `scidata` |
| `POSTGRES_USER` | Пользователь БД | `user` |
| `AUTH_SERVICE_URL` | URL сервиса аутентификации | `http://auth-service:8000` |
| `DATA_SERVICE_URL` | URL сервиса данных | `http://data-service:8001` |
| `PROCESSING_SERVICE_URL` | URL сервиса обработки | `http://processing-service:8002` |

### Как добавить переменные:
1. В настройках Environment нажмите **"Add variable"**
2. Введите название переменной
3. Введите значение переменной
4. Нажмите **"Add variable"**

## 🚀 Как это работает в CI/CD

### Staging Environment
- **Когда срабатывает:** При push в ветку `develop`
- **Что происходит:** 
  - Запускается `deploy-staging` job
  - Используются секреты и переменные из `staging` environment
  - Развертывание в тестовую среду

### Production Environment
- **Когда срабатывает:** При push в ветку `main`
- **Что происходит:**
  - Запускается `deploy-production` job
  - Используются секреты и переменные из `production` environment
  - **Требуется одобрение ревьюера** (если настроено)
  - Развертывание в продакшн среду

## 📋 Пример настройки

### Staging Environment:
```
Название: staging
Protection rules: Нет
Secrets:
  - POSTGRES_PASSWORD: staging_password_123
  - JWT_SECRET: staging_jwt_secret_456
Variables:
  - DATABASE_URL: postgresql://user:staging_password_123@postgres-service:5432/scidata
  - POSTGRES_DB: scidata
  - POSTGRES_USER: user
```

### Production Environment:
```
Название: production
Protection rules:
  - Required reviewers: [ваш_username]
  - Wait timer: 5 минут
Secrets:
  - POSTGRES_PASSWORD: production_secure_password_789
  - JWT_SECRET: production_jwt_secret_012
Variables:
  - DATABASE_URL: postgresql://user:production_secure_password_789@postgres-service:5432/scidata
  - POSTGRES_DB: scidata
  - POSTGRES_USER: user
```

## ⚠️ Важные замечания

1. **Безопасность:** Никогда не коммитьте секреты в код
2. **Разные пароли:** Используйте разные пароли для staging и production
3. **Ревьюеры:** В production добавьте себя как обязательного ревьюера
4. **Тестирование:** Сначала протестируйте на staging, потом на production

## 🔍 Проверка работы

После настройки environments:

1. **Создайте ветку `develop`** и сделайте push
2. **Проверьте** что сработал `deploy-staging`
3. **Создайте Pull Request** из `develop` в `main`
4. **После мержа** в `main` проверьте что сработал `deploy-production`

Теперь ваш CI/CD pipeline будет использовать правильные секреты и переменные для каждой среды! 🎉
