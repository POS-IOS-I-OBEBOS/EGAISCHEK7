@echo off

if "%LOGGING_ACTIVE%"=="" (
    set "SCRIPT_DIR=%~dp0"
    if "%SCRIPT_DIR%"=="" set "SCRIPT_DIR=%CD%\"
    set "LOG_DIR=%SCRIPT_DIR%logs"
    if not exist "%LOG_DIR%" (
        mkdir "%LOG_DIR%" >nul 2>&1
    )
    set "LOG_FILE=%LOG_DIR%\build_and_run.log"
    for /f "delims=" %%I in ('powershell -NoLogo -NoProfile -Command "[DateTime]::Now.ToString('yyyy-MM-dd_HH-mm-ss')"') do set "LOG_FILE=%LOG_DIR%\build_and_run_%%~I.log"
    powershell -NoLogo -NoProfile -Command ^
        "$env:LOGGING_ACTIVE='1';" ^
        "$env:LOG_FILE='%LOG_FILE%';" ^
        "cmd /c \"\"%~f0\" %*\" | Tee-Object -FilePath $env:LOG_FILE -Encoding UTF8; exit $LASTEXITCODE"
    exit /b %errorlevel%
)

setlocal EnableDelayedExpansion
set "EXIT_CODE=0"

for /f "tokens=2 delims=: " %%I in ('chcp') do set "OLD_CP=%%I"
set "OLD_CP=!OLD_CP: =!"
chcp 65001 >nul

if not exist "requirements.txt" (
    echo Скрипт необходимо запускать из корневой директории проекта.
    set "EXIT_CODE=1"
    goto cleanup
)

echo Проверка наличия Python...
py -3 --version >nul 2>&1
if errorlevel 1 (
    echo Python 3 не найден. Установите Python 3.12+ и повторите попытку.
    set "EXIT_CODE=1"
    goto cleanup
)

if not exist ".venv\Scripts\python.exe" (
    echo Создание виртуального окружения...
    py -3 -m venv .venv
    if errorlevel 1 (
        echo Не удалось создать виртуальное окружение.
        set "EXIT_CODE=1"
        goto cleanup
    )
)

call ".venv\Scripts\activate.bat"
if errorlevel 1 (
    echo Не удалось активировать виртуальное окружение.
    set "EXIT_CODE=1"
    goto cleanup
)

echo Обновление pip и установка зависимостей...
python -m pip install --upgrade pip
if errorlevel 1 (
    echo Ошибка при обновлении pip.
    set "EXIT_CODE=1"
    goto cleanup
)

pip install -r requirements.txt
if errorlevel 1 (
    echo Ошибка установки зависимостей.
    set "EXIT_CODE=1"
    goto cleanup
)

echo.
echo Введите учётные данные Aspose Cloud.
:ask_client_id
set /p ASPOSE_CLIENT_ID=Введите Aspose Client ID:
if "!ASPOSE_CLIENT_ID!"=="" (
    echo Client ID не может быть пустым.
    goto ask_client_id
)

:ask_client_secret
set /p ASPOSE_CLIENT_SECRET=Введите Aspose Client Secret:
if "!ASPOSE_CLIENT_SECRET!"=="" (
    echo Client Secret не может быть пустым.
    goto ask_client_secret
)

echo.
set /p FLASK_SECRET_KEY=Введите Flask Secret Key (опционально, Enter - пропустить):
set /p USER_PORT=Введите порт для запуска (по умолчанию 5000, Enter - пропустить):

set "TARGET_PORT=!USER_PORT!"
if "!TARGET_PORT!"=="" set "TARGET_PORT=5000"

if exist ".env" (
    echo.
    echo Предупреждение: существующий файл .env будет перезаписан текущими значениями.
)

set "PORT=!TARGET_PORT!"

set "TMP_SCRIPT=%TEMP%\write_env_!RANDOM!.py"
(
    echo import os, pathlib
    echo lines = [
    echo     f"ASPOSE_CLIENT_ID={os.environ['ASPOSE_CLIENT_ID']}",
    echo     f"ASPOSE_CLIENT_SECRET={os.environ['ASPOSE_CLIENT_SECRET']}",
    echo ]
    echo secret = os.environ.get("FLASK_SECRET_KEY")
    echo if secret:
    echo     lines.append(f"FLASK_SECRET_KEY={secret}")
    echo port = os.environ.get("USER_PORT")
    echo if port:
    echo     lines.append(f"PORT={port}")
    echo pathlib.Path(".env").write_text("\n".join(lines) + "\n", encoding="utf-8")
) > "!TMP_SCRIPT!"

python "!TMP_SCRIPT!"
if errorlevel 1 (
    echo Не удалось записать файл .env.
    del "!TMP_SCRIPT!" >nul 2>&1
    set "EXIT_CODE=1"
    goto cleanup
)

del "!TMP_SCRIPT!" >nul 2>&1

echo Файл .env обновлён.

echo Запуск веб-приложения...
echo Откроем браузер по адресу http://127.0.0.1:!TARGET_PORT!
start "" http://127.0.0.1:!TARGET_PORT!
python app.py
set "EXIT_CODE=!ERRORLEVEL!"

:cleanup
if defined OLD_CP chcp !OLD_CP! >nul
if defined LOG_FILE echo Полный лог работы скрипта: %LOG_FILE%
endlocal
exit /b %EXIT_CODE%
