#!/bin/bash

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Конфигурация
LOCAL_IMAGE_NAME="auxxxxx/vnedreid2025-ml_model:latest"
DOCKER_USERNAME="auxxxxx"
REPOSITORY_NAME="vnedreid2025-ml_model"
TAG="latest"

# Функция для вывода справки
show_help() {
    echo -e "${BLUE}Использование: $0 [OPTIONS]${NC}"
    echo -e "${BLUE}Опции:${NC}"
    echo -e "  -u, --username USERNAME    Docker Hub username (по умолчанию: auxxxxx)"
    echo -e "  -r, --repository REPO      Название репозитория (по умолчанию: vnedreid2025-ml_model)"
    echo -e "  -t, --tag TAG             Тег образа (по умолчанию: latest)"
    echo -e "  -h, --help                Показать эту справку"
    echo
    echo -e "${BLUE}Примеры:${NC}"
    echo -e "  $0                        # Использовать значения по умолчанию"
    echo -e "  $0 -t v1.0               # Изменить только тег"
    echo -e "  $0 -u myuser -r myapp -t v1.0"
}

# Парсинг аргументов командной строки
while [[ $# -gt 0 ]]; do
    case $1 in
        -u|--username)
            DOCKER_USERNAME="$2"
            shift 2
            ;;
        -r|--repository)
            REPOSITORY_NAME="$2"
            shift 2
            ;;
        -t|--tag)
            TAG="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Неизвестная опция: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# Обновляем имена образов с новыми параметрами
LOCAL_IMAGE_NAME="$DOCKER_USERNAME/$REPOSITORY_NAME:$TAG"
REMOTE_IMAGE_NAME="$DOCKER_USERNAME/$REPOSITORY_NAME:$TAG"

echo -e "${YELLOW}🚀 Отправка Docker образа в Docker Hub...${NC}"
echo -e "${BLUE}📦 Образ: $LOCAL_IMAGE_NAME${NC}"

# Проверка существования локального образа или сборка через docker compose
if [ ! "$(docker images -q $LOCAL_IMAGE_NAME)" ]; then
    echo -e "${YELLOW}⚠️  Локальный образ $LOCAL_IMAGE_NAME не найден!${NC}"
    echo -e "${YELLOW}🔨 Выполняется сборка через docker compose...${NC}"
    
    # Сборка образа через docker compose
    docker compose build --no-cache
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Ошибка при сборке образа через docker compose!${NC}"
        exit 1
    fi
    
    # Получаем ID образа из docker compose и тегируем его
    SERVICE_IMAGE_ID=$(docker compose images -q backend)
    if [ -n "$SERVICE_IMAGE_ID" ]; then
        echo -e "${YELLOW}🏷️  Тегирование образа...${NC}"
        docker tag $SERVICE_IMAGE_ID $LOCAL_IMAGE_NAME
    else
        echo -e "${RED}❌ Не удалось получить ID образа из docker compose!${NC}"
        exit 1
    fi
fi

# Проверка авторизации в Docker Hub
echo -e "${YELLOW}🔐 Проверка авторизации в Docker Hub...${NC}"
if ! docker info | grep -q "Username: $DOCKER_USERNAME"; then
    echo -e "${YELLOW}🔑 Необходима авторизация в Docker Hub...${NC}"
    docker login
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Ошибка авторизации в Docker Hub!${NC}"
        exit 1
    fi
fi

# Отправка образа в Docker Hub
echo -e "${YELLOW}⬆️  Отправка образа в Docker Hub...${NC}"
docker push $REMOTE_IMAGE_NAME

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Образ успешно отправлен в Docker Hub!${NC}"
    echo -e "${GREEN}🌐 Образ доступен по адресу: https://hub.docker.com/r/$DOCKER_USERNAME/$REPOSITORY_NAME${NC}"
    echo -e "${GREEN}📦 Для использования: docker pull $REMOTE_IMAGE_NAME${NC}"
    echo
    echo -e "${BLUE}🚀 Команды для запуска на другом сервере:${NC}"
    echo -e "${BLUE}# Простой запуск:${NC}"
    echo -e "${BLUE}docker run -d --name damage-detection -p 8000:8000 $REMOTE_IMAGE_NAME${NC}"
    echo -e "${BLUE}# Или с docker compose (если есть docker-compose.yml):${NC}"
    echo -e "${BLUE}docker compose pull && docker compose up -d${NC}"
else
    echo -e "${RED}❌ Ошибка при отправке образа в Docker Hub!${NC}"
    exit 1
fi

# Показать информацию об образе
echo -e "${YELLOW}📋 Информация об образе:${NC}"
docker images --filter "reference=$LOCAL_IMAGE_NAME" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}" 