# PowerShell скрипт для запуска self-hosted runner

# Проверяем, что конфигурация выполнена
if (-not (Test-Path ".runner")) {
    exit 1
}

& .\run.cmd
