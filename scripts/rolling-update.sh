#!/bin/bash

# Скрипт для выполнения rolling updates ArangoDB сервисов
# Использование: ./rolling-update.sh [service-name] [new-image]

set -e

SERVICE_NAME=${1:-"arango-coordinator"}
NEW_IMAGE=${2:-"arangodb/arangodb:3.11.1"}

echo "=== Rolling Update для сервиса: $SERVICE_NAME ==="
echo "Новый образ: $NEW_IMAGE"

# Проверка, что мы на manager ноде
if ! docker info | grep -q "Swarm: active"; then
    echo "Ошибка: Docker Swarm не активен"
    exit 1
fi

# Проверка существования сервиса
if ! docker service ls | grep -q "$SERVICE_NAME"; then
    echo "Ошибка: Сервис $SERVICE_NAME не найден"
    echo "Доступные сервисы:"
    docker service ls --format "table {{.Name}}\t{{.Image}}\t{{.Mode}}\t{{.Replicas}}"
    exit 1
fi

# Получение текущего образа
CURRENT_IMAGE=$(docker service inspect $SERVICE_NAME --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}')
echo "Текущий образ: $CURRENT_IMAGE"

if [ "$CURRENT_IMAGE" = "$NEW_IMAGE" ]; then
    echo "Образ уже обновлен до $NEW_IMAGE"
    exit 0
fi

# Создание бэкапа текущей конфигурации
echo "Создание бэкапа конфигурации..."
docker service inspect $SERVICE_NAME > "/opt/docker-swarm/backup-${SERVICE_NAME}-$(date +%Y%m%d-%H%M%S).json"

# Обновление сервиса
echo "Обновление сервиса $SERVICE_NAME..."
docker service update \
    --image $NEW_IMAGE \
    --update-parallelism 1 \
    --update-delay 30s \
    --update-failure-action rollback \
    --update-monitor 60s \
    --update-max-failure-ratio 0.3 \
    $SERVICE_NAME

# Мониторинг процесса обновления
echo "Мониторинг процесса обновления..."
while true; do
    UPDATE_STATUS=$(docker service inspect $SERVICE_NAME --format '{{.UpdateStatus.State}}')
    echo "Статус обновления: $UPDATE_STATUS"
    
    case $UPDATE_STATUS in
        "completed")
            echo "Обновление завершено успешно!"
            break
            ;;
        "rollback_completed")
            echo "Обновление откачено!"
            exit 1
            ;;
        "paused")
            echo "Обновление приостановлено!"
            exit 1
            ;;
        "updating"|"")
            echo "Обновление в процессе..."
            sleep 10
            ;;
        *)
            echo "Неизвестный статус: $UPDATE_STATUS"
            sleep 10
            ;;
    esac
done

# Проверка статуса сервиса после обновления
echo "=== Статус сервиса после обновления ==="
docker service ps $SERVICE_NAME --no-trunc

echo "=== Rolling Update завершен ==="
echo "Сервис $SERVICE_NAME обновлен до образа $NEW_IMAGE"
