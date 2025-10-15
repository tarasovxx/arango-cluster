#!/bin/bash

# Скрипт для тестирования ArangoDB кластера
# Использование: ./test-cluster.sh

set -e

echo "=== Тестирование ArangoDB кластера ==="

# Проверка, что мы на manager ноде
if ! docker info | grep -q "Swarm: active"; then
    echo "Ошибка: Docker Swarm не активен"
    exit 1
fi

# Функция для проверки доступности сервиса
check_service() {
    local service_name=$1
    local url=$2
    local max_attempts=30
    local attempt=1
    
    echo "Проверка доступности $service_name..."
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s "$url" > /dev/null 2>&1; then
            echo "✅ $service_name доступен"
            return 0
        fi
        
        echo "Попытка $attempt/$max_attempts - ожидание..."
        sleep 10
        ((attempt++))
    done
    
    echo "❌ $service_name недоступен после $max_attempts попыток"
    return 1
}

# Проверка статуса нод
echo "--- Проверка нод ---"
docker node ls

# Проверка сервисов
echo ""
echo "--- Проверка сервисов ---"
docker stack services arango

# Проверка задач сервисов
echo ""
echo "--- Проверка задач сервисов ---"
for service in $(docker stack services arango --format "{{.Name}}"); do
    echo "Сервис: $service"
    docker service ps $service --no-trunc | head -5
    echo ""
done

# Проверка сетей
echo "--- Проверка сетей ---"
docker network ls | grep arango

# Проверка секретов
echo ""
echo "--- Проверка секретов ---"
docker secret ls

# Проверка доступности ArangoDB
echo ""
echo "--- Проверка доступности ArangoDB ---"
if check_service "ArangoDB" "http://arango.localhost/_api/version"; then
    echo "Получение версии ArangoDB..."
    curl -s http://arango.localhost/_api/version | jq . 2>/dev/null || curl -s http://arango.localhost/_api/version
fi

# Проверка доступности Traefik
echo ""
echo "--- Проверка доступности Traefik ---"
if check_service "Traefik Dashboard" "http://traefik.localhost:8080/api/rawdata"; then
    echo "Traefik Dashboard доступен"
fi

# Тест создания базы данных
echo ""
echo "--- Тест создания базы данных ---"
if curl -s http://arango.localhost/_api/version > /dev/null 2>&1; then
    echo "Создание тестовой базы данных..."
    
    # Создание базы данных
    DB_RESPONSE=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -d '{"name": "test_db"}' \
        http://arango.localhost/_api/database)
    
    if echo "$DB_RESPONSE" | grep -q "test_db"; then
        echo "✅ База данных test_db создана успешно"
        
        # Создание коллекции
        COLLECTION_RESPONSE=$(curl -s -X POST \
            -H "Content-Type: application/json" \
            -d '{"name": "test_collection"}' \
            http://arango.localhost/_db/test_db/_api/collection)
        
        if echo "$COLLECTION_RESPONSE" | grep -q "test_collection"; then
            echo "✅ Коллекция test_collection создана успешно"
            
            # Вставка тестового документа
            DOC_RESPONSE=$(curl -s -X POST \
                -H "Content-Type: application/json" \
                -d '{"name": "test_document", "value": 123}' \
                http://arango.localhost/_db/test_db/_api/document/test_collection)
            
            if echo "$DOC_RESPONSE" | grep -q "_key"; then
                echo "✅ Тестовый документ создан успешно"
            else
                echo "❌ Ошибка создания тестового документа"
            fi
        else
            echo "❌ Ошибка создания коллекции"
        fi
        
        # Удаление тестовой базы данных
        curl -s -X DELETE http://arango.localhost/_api/database/test_db > /dev/null
        echo "Тестовая база данных удалена"
    else
        echo "❌ Ошибка создания базы данных"
    fi
else
    echo "❌ ArangoDB недоступен для тестирования"
fi

# Проверка отказоустойчивости
echo ""
echo "--- Тест отказоустойчивости ---"
echo "Проверка репликации сервисов..."

for service in $(docker stack services arango --format "{{.Name}}"); do
    REPLICAS=$(docker service inspect $service --format '{{.Spec.Mode.Replicated.Replicas}}')
    RUNNING=$(docker service ps $service --filter desired-state=running --format "{{.Name}}" | wc -l)
    
    if [ "$RUNNING" -eq "$REPLICAS" ]; then
        echo "✅ $service: все $REPLICAS реплик запущены"
    else
        echo "⚠️  $service: запущено $RUNNING из $REPLICAS реплик"
    fi
done

# Проверка балансировки нагрузки
echo ""
echo "--- Тест балансировки нагрузки ---"
echo "Отправка множественных запросов к ArangoDB..."

for i in {1..10}; do
    RESPONSE=$(curl -s http://arango.localhost/_api/version 2>/dev/null || echo "ERROR")
    if [ "$RESPONSE" != "ERROR" ]; then
        echo "Запрос $i: ✅ Успешно"
    else
        echo "Запрос $i: ❌ Ошибка"
    fi
    sleep 1
done

echo ""
echo "=== Тестирование завершено ==="
echo ""
echo "Для дополнительной диагностики используйте:"
echo "- docker service logs arango_arango-coordinator"
echo "- docker service ps arango_arango-coordinator --no-trunc"
echo "- docker node ls"
echo "- docker stack services arango"
