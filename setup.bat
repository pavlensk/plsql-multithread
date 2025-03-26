@echo off
setlocal enabledelayedexpansion

:: Укажите параметры подключения к Oracle
set ORACLE_USER=debt_monitor
set ORACLE_PASS=debt_monitor
set ORACLE_SID=oradb23c

:: Проверяем наличие sqlplus
where sqlplus >nul 2>nul
if %errorlevel% neq 0 (
    echo Ошибка: sqlplus не найден. Убедитесь, что он доступен в PATH.
    exit /b 1
)

:: Устанавливаем файлы в нужном порядке
echo Запуск установки SQL-скриптов...

sqlplus %ORACLE_USER%/%ORACLE_PASS%@%ORACLE_SID% @setup.sql

echo Установка завершена!
pause
