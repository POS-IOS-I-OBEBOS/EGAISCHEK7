# Веб-приложение для распознавания DataMatrix

Простое Flask-приложение, которое использует [Aspose Barcode Cloud SDK](https://products.aspose.cloud/barcode) версии 25.10.0 для распознавания DataMatrix-кодов на загруженных изображениях.

## Требования

- Python 3.12+
- Учётные данные Aspose Cloud (Client ID и Client Secret)

## Установка

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## Настройка окружения

1. Скопируйте файл `.env.example` в `.env`.
2. Укажите значения `ASPOSE_CLIENT_ID`, `ASPOSE_CLIENT_SECRET` и при необходимости `FLASK_SECRET_KEY`.

Приложение автоматически загрузит переменные из файла `.env`.

## Запуск

```bash
flask --app app run
```

Приложение будет доступно по адресу <http://127.0.0.1:5000>.

## Использование

1. Откройте главную страницу приложения.
2. Загрузите изображение с DataMatrix кодом.
3. Отправьте форму — распознанные значения будут показаны в разделе «Результаты распознавания».

## Переменные окружения

| Переменная              | Назначение                                                     |
|-------------------------|----------------------------------------------------------------|
| `ASPOSE_CLIENT_ID`      | Client ID для доступа к Aspose Barcode Cloud                   |
| `ASPOSE_CLIENT_SECRET`  | Client Secret для доступа к Aspose Barcode Cloud               |
| `FLASK_SECRET_KEY`      | Секретный ключ Flask для подписи cookies (опционально)         |
| `PORT`                  | Порт сервера (по умолчанию 5000 при запуске через `python app.py`) |

## Лицензия

Проект распространяется под лицензией MIT (при необходимости измените описание).
