#!/bin/bash

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Конфигурация
IMAGE_NAME="auxxxxx/vnedreid2025-ml_model:latest"
SERVICE_NAME="backend"
PORT=8000

echo -e "${BLUE}🚀 Сборка и запуск приложения обнаружения повреждений${NC}"
echo -e "${BLUE}📦 Образ: $IMAGE_NAME${NC}"
echo -e "${BLUE}🌐 Порт: $PORT${NC}"

# Остановка существующих контейнеров
echo -e "${YELLOW}🛑 Остановка существующих контейнеров...${NC}"
docker compose down --remove-orphans

# Очистка старых образов (опционально)
echo -e "${YELLOW}🧹 Очистка старых образов...${NC}"
if [ "$(docker images -q $IMAGE_NAME)" ]; then
    docker rmi $IMAGE_NAME 2>/dev/null || true
fi

# Сборка образа через docker compose
echo -e "${YELLOW}🔨 Сборка образа через docker compose...${NC}"
docker compose build --no-cache --pull

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Ошибка при сборке образа!${NC}"
    exit 1
fi

# Тегирование образа
echo -e "${YELLOW}🏷️  Тегирование образа...${NC}"
SERVICE_IMAGE_ID=$(docker compose images -q $SERVICE_NAME 2>/dev/null)
if [ -n "$SERVICE_IMAGE_ID" ]; then
    docker tag $SERVICE_IMAGE_ID $IMAGE_NAME
    echo -e "${GREEN}✅ Образ успешно собран и заtagирован!${NC}"
else
    echo -e "${YELLOW}⚠️  Не удалось получить ID образа, но продолжаем...${NC}"
fi

# Запуск контейнеров
echo -e "${YELLOW}🚀 Запуск контейнеров...${NC}"
docker compose up -d

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Ошибка при запуске контейнеров!${NC}"
    echo -e "${YELLOW}📋 Логи для диагностики:${NC}"
    docker compose logs $SERVICE_NAME
    exit 1
fi

# Ожидание запуска сервиса
echo -e "${YELLOW}⏳ Ожидание запуска сервиса...${NC}"
sleep 10

# Проверка статуса
echo -e "${YELLOW}📊 Статус контейнеров:${NC}"
docker compose ps

# Проверка здоровья сервиса
echo -e "${YELLOW}🔍 Проверка доступности сервиса...${NC}"
for i in {1..5}; do
    if curl -s http://localhost:$PORT/docs > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Сервис доступен!${NC}"
        break
    else
        echo -e "${YELLOW}⏳ Ожидание... попытка $i/5${NC}"
        sleep 3
    fi
    
    if [ $i -eq 5 ]; then
        echo -e "${RED}❌ Сервис недоступен после 5 попыток${NC}"
        echo -e "${YELLOW}📋 Логи контейнера:${NC}"
        docker compose logs --tail=20 $SERVICE_NAME
    fi
done

# Показать полезную информацию
echo -e "${GREEN}🎉 Развертывание завершено!${NC}"
echo -e "${GREEN}🌐 Приложение: http://localhost:$PORT${NC}"
echo -e "${GREEN}📖 API документация: http://localhost:$PORT/model/docs${NC}"
echo -e "${GREEN}🔍 Эндпоинт анализа: POST http://localhost:$PORT/model/analyze${NC}"
echo -e "${GREEN}🔍 Альтернативный эндпоинт: POST http://localhost:$PORT/model/damage-detection/analyze${NC}"

# Показать последние логи
echo -e "${YELLOW}📋 Последние логи сервиса:${NC}"
docker compose logs --tail=10 $SERVICE_NAME

echo -e "${BLUE}💡 Для остановки используйте: ./stop.sh${NC}"
echo -e "${BLUE}💡 Для отправки в Docker Hub: ./push.sh${NC}" 