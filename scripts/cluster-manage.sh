#!/bin/bash

# Скрипт для управления ArangoDB кластером
# Использование: ./cluster-manage.sh [start|stop|restart|status|logs|scale]

set -e

ACTION=${1:-"status"}
SERVICE_NAME=${2:-""}
REPLICAS=${3:-"3"}

echo "=== Управление ArangoDB кластером ==="
echo "Действие: $ACTION"

# Проверка, что мы на manager ноде
if ! docker info | grep -q "Swarm: active"; then
    echo "Ошибка: Docker Swarm не активен"
    exit 1
fi

case $ACTION in
    "start")
        echo "Запуск ArangoDB stack..."
        docker stack deploy -c /opt/docker-swarm/docker-stack.yml arango
        echo "Stack запущен"
        ;;
    
    "stop")
        echo "Остановка ArangoDB stack..."
        docker stack rm arango
        echo "Stack остановлен"
        ;;
    
    "restart")
        echo "Перезапуск ArangoDB stack..."
        docker stack rm arango
        sleep 10
        docker stack deploy -c /opt/docker-swarm/docker-stack.yml arango
        echo "Stack перезапущен"
        ;;
    
    "status")
        echo "=== Статус ArangoDB кластера ==="
        echo "--- Swarm ноды ---"
        docker node ls
        echo ""
        echo "--- Сервисы ---"
        docker stack services arango
        echo ""
        echo "--- Сети ---"
        docker network ls | grep arango
        echo ""
        echo "--- Секреты ---"
        docker secret ls
        echo ""
        echo "--- Volumes ---"
        docker volume ls | grep arango
        ;;
    
    "logs")
        if [ -z "$SERVICE_NAME" ]; then
            echo "Доступные сервисы:"
            docker stack services arango --format "table {{.Name}}\t{{.Image}}\t{{.Mode}}\t{{.Replicas}}"
            echo ""
            echo "Использование: $0 logs [service-name]"
            exit 1
        fi
        
        echo "Логи сервиса: $SERVICE_NAME"
        docker service logs -f arango_$SERVICE_NAME
        ;;
    
    "scale")
        if [ -z "$SERVICE_NAME" ]; then
            echo "Доступные сервисы:"
            docker stack services arango --format "table {{.Name}}\t{{.Image}}\t{{.Mode}}\t{{.Replicas}}"
            echo ""
            echo "Использование: $0 scale [service-name] [replicas]"
            exit 1
        fi
        
        echo "Масштабирование сервиса $SERVICE_NAME до $REPLICAS реплик..."
        docker service scale arango_$SERVICE_NAME=$REPLICAS
        echo "Сервис масштабирован"
        ;;
    
    "health")
        echo "=== Проверка здоровья кластера ==="
        
        # Проверка нод
        echo "--- Проверка нод ---"
        docker node ls --format "table {{.Hostname}}\t{{.Status}}\t{{.Availability}}\t{{.ManagerStatus}}"
        
        # Проверка сервисов
        echo ""
        echo "--- Проверка сервисов ---"
        for service in $(docker stack services arango --format "{{.Name}}"); do
            REPLICAS=$(docker service inspect $service --format '{{.Spec.Mode.Replicated.Replicas}}')
            RUNNING=$(docker service ps $service --filter desired-state=running --format "{{.Name}}" | wc -l)
            echo "$service: $RUNNING/$REPLICAS реплик запущено"
        done
        
        # Проверка доступности ArangoDB
        echo ""
        echo "--- Проверка доступности ArangoDB ---"
        if curl -s http://arango.localhost/_api/version > /dev/null 2>&1; then
            echo "ArangoDB доступен"
        else
            echo "ArangoDB недоступен"
        fi
        ;;
    
    "backup")
        echo "=== Создание бэкапа конфигурации ==="
        BACKUP_DIR="/opt/docker-swarm/backups/$(date +%Y%m%d-%H%M%S)"
        mkdir -p $BACKUP_DIR
        
        # Бэкап конфигурации сервисов
        for service in $(docker stack services arango --format "{{.Name}}"); do
            docker service inspect $service > "$BACKUP_DIR/${service}.json"
        done
        
        # Бэкап конфигурации stack
        cp /opt/docker-swarm/docker-stack.yml "$BACKUP_DIR/"
        
        echo "Бэкап создан в $BACKUP_DIR"
        ;;
    
    *)
        echo "Неизвестное действие: $ACTION"
        echo ""
        echo "Доступные действия:"
        echo "  start     - Запустить ArangoDB stack"
        echo "  stop      - Остановить ArangoDB stack"
        echo "  restart   - Перезапустить ArangoDB stack"
        echo "  status    - Показать статус кластера"
        echo "  logs      - Показать логи сервиса"
        echo "  scale     - Масштабировать сервис"
        echo "  health    - Проверить здоровье кластера"
        echo "  backup    - Создать бэкап конфигурации"
        echo ""
        echo "Примеры использования:"
        echo "  $0 status"
        echo "  $0 logs arango-coordinator"
        echo "  $0 scale arango-coordinator 5"
        exit 1
        ;;
esac

echo "=== Операция завершена ==="
