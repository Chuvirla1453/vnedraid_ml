#!/bin/bash

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Конфигурация
SERVICE_NAME="backend"

echo -e "${YELLOW}🛑 Остановка приложения обнаружения повреждений...${NC}"

# Проверка статуса сервисов
echo -e "${YELLOW}📊 Текущий статус сервисов:${NC}"
docker compose ps

# Остановка и удаление контейнеров через docker compose
echo -e "${YELLOW}🔄 Остановка и удаление контейнеров...${NC}"
docker compose down

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Все контейнеры остановлены и удалены!${NC}"
else
    echo -e "${RED}❌ Ошибка при остановке контейнеров!${NC}"
    exit 1
fi

# Показать статус после остановки
echo -e "${YELLOW}📊 Статус после остановки:${NC}"
docker compose ps

# Опционально: удаление volumes (раскомментировать если нужно)
# echo -e "${YELLOW}🗑️  Удаление volumes...${NC}"
# docker compose down -v
# echo -e "${GREEN}✅ Volumes удалены!${NC}"

# Опционально: удаление образов (раскомментировать если нужно)
# IMAGE_NAME="auxxxxx/vnedreid2025-ml_model:latest"
# if [ "$(docker images -q $IMAGE_NAME)" ]; then
#     echo -e "${YELLOW}🗑️  Удаление образа $IMAGE_NAME...${NC}"
#     docker rmi $IMAGE_NAME
#     echo -e "${GREEN}✅ Образ удален!${NC}"
# fi

# Показать оставшиеся контейнеры проекта
echo -e "${YELLOW}📋 Проверка оставшихся ресурсов проекта:${NC}"
echo "Контейнеры:"
docker ps -a --filter "name=damage-detection"
echo "Образы:"
docker images --filter "reference=auxxxxx/vnedreid2025-ml_model"

echo -e "${GREEN}🏁 Приложение полностью остановлено и очищено!${NC}" 