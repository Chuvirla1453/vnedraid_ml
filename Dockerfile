# Базовый образ. По умолчанию берется из https://hub.docker.com/_/python
FROM python:3.10-slim

# Поменять рабочую директорию. Если ее нет, создать ее.
WORKDIR /app

# Установка системных зависимостей
RUN apt-get update && apt-get install -y \
    libgl1-mesa-glx \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Копирование файлов зависимостей
COPY requirements.txt .

# Установка Python зависимостей
RUN pip install --no-cache-dir -r requirements.txt

# Копирование исходного кода
COPY . .

# Создание директории для выходных данных
RUN mkdir -p output/runs/predict

# Установка переменных окружения
ENV PYTHONPATH=/app

# Открытие порта
EXPOSE 8000

# Запуск приложения
CMD ["uvicorn", "web_app:main", "--host", "0.0.0.0", "--port", "8000", "--reload"]