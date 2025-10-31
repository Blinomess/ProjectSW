set -e  # Остановка при ошибке

echo "🚀 Запуск CI/CD Pipeline для File Manager"

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для логирования
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Проверка зависимостей
check_dependencies() {
    log "Проверка зависимостей..."
    
    if ! command -v docker &> /dev/null; then
        error "Docker не установлен"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        error "Docker Compose не установлен"
        exit 1
    fi
    
    if ! command -v python3 &> /dev/null; then
        error "Python 3 не установлен"
        exit 1
    fi
    
    success "Все зависимости установлены"
}

# Установка зависимостей для тестов
install_test_dependencies() {
    log "Установка зависимостей для тестов..."
    
    # Python зависимости
    pip install -r ./requirements-test.txt
    
    success "Зависимости установлены"
}

run_backend_tests() {
    log "Запуск unit тестов для backend сервисов..."
    
    log "Тестирование auth-service..."
    cd backend/authentification_service
    python -m pytest tests/ -v --cov=. --cov-report=xml --cov-report=html
    cd ../..
    
    log "Тестирование data-service..."
    cd backend/data_service
    python -m pytest tests/ -v --cov=. --cov-report=xml --cov-report=html
    cd ../..
    
    log "Тестирование processing-service..."
    cd backend/processing_service
    python -m pytest tests/ -v --cov=. --cov-report=xml --cov-report=html
    cd ../..
    
    success "Backend тесты завершены"
}

run_frontend_tests() {
    log "Запуск тестов для frontend..."
    
    if [ -f "frontend/test-frontend.sh" ]; then
        chmod +x frontend/test-frontend.sh || true
        ./frontend/test-frontend.sh
    else
        warning "frontend/test-frontend.sh не найден — пропускаю фронтенд тесты"
    fi
    
    success "Frontend тесты завершены"
}

run_integration_tests() {
    log "Запуск интеграционных тестов..."

    log "Запуск тестовых сервисов..."
    docker-compose -f docker-compose.test.yml up -d

    log "Ожидание запуска сервисов..."
    sleep 30

    docker-compose -f docker-compose.test.yml ps

    log "Выполнение интеграционных тестов..."
    python -m pytest tests/integration/ -v
    
    log "Остановка тестовых сервисов..."
    docker-compose -f docker-compose.test.yml down
    
    success "Интеграционные тесты завершены"
}

run_security_scan() {
    log "Запуск security сканирования..."
    
    if ! command -v trivy &> /dev/null; then
        log "Установка Trivy..."
        curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
    fi

    log "Сканирование файловой системы..."
    trivy fs --format json --output trivy-results.json .

    log "Сканирование Docker образов..."
    docker build -t auth-service-test ./backend/authentification_service
    docker build -t data-service-test ./backend/data_service
    docker build -t processing-service-test ./backend/processing_service
    docker build -t frontend-test ./frontend
    
    trivy image --format json --output trivy-images.json auth-service-test data-service-test processing-service-test frontend-test
    
    log "Запуск Bandit security linter..."
    pip install bandit
    bandit -r backend/ -f json -o bandit-report.json

    log "Запуск Safety check..."
    pip install safety
    safety check --json --output safety-report.json
    
    success "Security сканирование завершено"
}

build_docker_images() {
    log "Сборка Docker образов..."
    
    docker build -t auth-service:latest ./backend/authentification_service
    docker build -t data-service:latest ./backend/data_service
    docker build -t processing-service:latest ./backend/processing_service
    docker build -t frontend:latest ./frontend
    
    success "Docker образы собраны"
}

cleanup() {
    log "Очистка временных файлов..."
    
    docker-compose -f docker-compose.test.yml down 2>/dev/null || true
    
    docker rmi auth-service-test data-service-test processing-service-test frontend-test 2>/dev/null || true
    
    rm -f trivy-results.json trivy-images.json bandit-report.json safety-report.json
    
    success "Очистка завершена"
}

main() {
    log "Начало выполнения CI/CD pipeline"
    
    SKIP_TESTS=false
    SKIP_SECURITY=false
    SKIP_BUILD=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --skip-tests)
                SKIP_TESTS=true
                shift
                ;;
            --skip-security)
                SKIP_SECURITY=true
                shift
                ;;
            --skip-build)
                SKIP_BUILD=true
                shift
                ;;
            --help)
                echo "Использование: $0 [опции]"
                echo "Опции:"
                echo "  --skip-tests     Пропустить тесты"
                echo "  --skip-security  Пропустить security сканирование"
                echo "  --skip-build     Пропустить сборку Docker образов"
                echo "  --help           Показать эту справку"
                exit 0
                ;;
            *)
                error "Неизвестная опция: $1"
                exit 1
                ;;
        esac
    done
    
    check_dependencies
    install_test_dependencies
    
    if [ "$SKIP_TESTS" = false ]; then
        run_backend_tests
        run_frontend_tests
        run_integration_tests
    else
        warning "Пропуск тестов"
    fi
    
    if [ "$SKIP_SECURITY" = false ]; then
        run_security_scan
    else
        warning "Пропуск security сканирования"
    fi
    
    if [ "$SKIP_BUILD" = false ]; then
        build_docker_images
    else
        warning "Пропуск сборки Docker образов"
    fi
    
    success "CI/CD pipeline успешно завершен! 🎉"
}

trap cleanup EXIT INT TERM

main "$@"
