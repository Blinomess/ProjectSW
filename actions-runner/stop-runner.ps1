# PowerShell скрипт для остановки self-hosted runner

Write-Host "Остановка self-hosted runner..." -ForegroundColor Red

# Проверяем, что конфигурация выполнена
if (-not (Test-Path ".runner")) {
    Write-Host "Ошибка: Runner не настроен" -ForegroundColor Red
    exit 1
}

Write-Host "Удаление runner из GitHub..." -ForegroundColor Yellow
& .\config.cmd remove --token BPOJQPLVZGRKRVTMBI7MK4LI7VAJI

Write-Host "Runner остановлен и удален!" -ForegroundColor Green
