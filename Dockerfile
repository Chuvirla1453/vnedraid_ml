# Базовый образ Python
FROM python:3.10-slim

# Установка системных зависимостей для OpenCV
RUN apt-get update && apt-get install -y \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

# Рабочая директория
WORKDIR /app

# Копирование файла зависимостей
COPY requirements.txt .

# Установка PyTorch и связанных библиотек
RUN pip3 install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu

# Установка ultralytics без зависимостей
RUN pip install "ultralytics~=8.3.151" --no-deps

# Установка остальных зависимостей
RUN pip install -r requirements.txt

# Копирование исходного кода
COPY . .

# Установка переменных окружения
ENV PYTHONPATH=/app
ENV PYTHONUNBUFFERED=1

# Открытие порта
EXPOSE 8000

# Запуск приложения
CMD ["python", "web_app.py"]