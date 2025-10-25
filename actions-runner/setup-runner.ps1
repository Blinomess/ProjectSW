# PowerShell скрипт для настройки self-hosted runner

Write-Host "Настройка self-hosted runner для GitHub Actions..." -ForegroundColor Green

# Проверяем, что мы в правильной папке
if (-not (Test-Path "config.cmd")) {
    Write-Host "Ошибка: config.cmd не найден. Убедитесь, что вы находитесь в папке actions-runner" -ForegroundColor Red
    exit 1
}

Write-Host "Запуск конфигурации runner..." -ForegroundColor Yellow
Write-Host "Вам нужно будет ввести токен из GitHub:" -ForegroundColor Cyan
Write-Host "1. Перейдите в Settings > Actions > Runners" -ForegroundColor Cyan
Write-Host "2. Нажмите 'New self-hosted runner'" -ForegroundColor Cyan
Write-Host "3. Скопируйте токен и вставьте его ниже" -ForegroundColor Cyan

# Запускаем конфигурацию
& .\config.cmd --url https://github.com/Blinomess/ProjectSW --token BPOJQPLVZGRKRVTMBI7MK4LI7VAJI

Write-Host "Конфигурация завершена!" -ForegroundColor Green
Write-Host "Для запуска runner выполните: .\run.cmd" -ForegroundColor Cyan
