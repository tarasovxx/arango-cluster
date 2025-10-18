#!/bin/bash

# Скрипт для развертывания/обновления ArangoDB stack
# Использование: ./deploy-arango.sh [--clean]

set -e

echo "═══════════════════════════════════════════════════════"
echo "   Развертывание ArangoDB Stack"
echo "═══════════════════════════════════════════════════════"
echo ""

# Проверка что скрипт запущен на manager ноде
if ! docker info | grep -q "Swarm: active"; then
    echo "❌ Ошибка: Docker Swarm не активен"
    echo "💡 Этот скрипт должен выполняться на manager ноде"
    exit 1
fi

if ! docker node ls &>/dev/null; then
    echo "❌ Ошибка: Эта команда должна выполняться на manager ноде!"
    exit 1
fi

# Проверка наличия docker-stack.yml
STACK_FILE="/vagrant/docker-stack.yml"
if [ ! -f "$STACK_FILE" ]; then
    STACK_FILE="/opt/docker-swarm/docker-stack.yml"
    if [ ! -f "$STACK_FILE" ]; then
        echo "❌ Ошибка: docker-stack.yml не найден"
        exit 1
    fi
fi

# Опция для полной очистки
CLEAN=false
if [ "$1" == "--clean" ]; then
    CLEAN=true
    echo "⚠️  Режим полной очистки активирован"
fi

# Проверка существующего стека
if docker stack ls | grep -q "arango"; then
    echo "📦 Обнаружен существующий стек ArangoDB"
    
    if [ "$CLEAN" = true ]; then
        echo "🗑️  Удаление существующего стека..."
        docker stack rm arango
        
        echo "⏳ Ожидание удаления контейнеров (15 секунд)..."
        sleep 15
        
        echo "🗑️  Удаление volumes..."
        docker volume rm arango_dbserver-data 2>/dev/null || echo "Volume dbserver-data не найден"
        
        echo "✅ Очистка завершена"
    else
        echo "♻️  Обновление существующего стека..."
        echo "💡 Используйте --clean для полной переустановки"
    fi
fi

# Проверка и создание сети
if ! docker network ls | grep -q "arango-net"; then
    echo "📡 Создание overlay сети arango-net..."
    docker network create --driver overlay --attachable arango-net
else
    echo "✅ Сеть arango-net уже существует"
fi

# Развертывание стека
echo ""
echo "🚀 Развертывание ArangoDB кластера..."
docker stack deploy -c "$STACK_FILE" arango

echo ""
echo "⏳ Ожидание запуска сервисов (30 секунд)..."
sleep 30

# Проверка статуса сервисов
echo ""
echo "📊 Статус сервисов:"
docker service ls --filter "name=arango_"

# Ожидание полной готовности
echo ""
echo "⏳ Ожидание готовности кластера (еще 30 секунд)..."
sleep 30

# Проверка здоровья кластера
echo ""
echo "🏥 Проверка здоровья кластера..."
if curl -s http://localhost:8529/_api/version > /dev/null 2>&1; then
    echo "✅ Кластер ArangoDB доступен!"
    curl -s http://localhost:8529/_api/version | head -5
    echo ""
else
    echo "⚠️  Кластер еще инициализируется..."
    echo "💡 Проверьте статус через несколько минут:"
    echo "   docker service ls"
    echo "   docker service logs arango_arango-coordinator"
fi

# Детальная информация о сервисах
echo ""
echo "📋 Детальная информация о сервисах:"
echo ""

for service in $(docker service ls --filter "name=arango_" --format "{{.Name}}"); do
    REPLICAS=$(docker service ls --filter "name=$service" --format "{{.Replicas}}")
    echo "  • $service: $REPLICAS"
done

echo ""
echo "═══════════════════════════════════════════════════════"
echo "              ✅ Развертывание завершено!"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "🌐 Доступ к кластеру:"
echo "   • http://localhost:8529"
echo ""
echo "📊 Полезные команды:"
echo "   • Статус: docker service ls"
echo "   • Логи:   docker service logs arango_arango-coordinator"
echo "   • Health: curl http://localhost:8529/_admin/cluster/health"
echo ""
