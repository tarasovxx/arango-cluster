#!/bin/bash

# Скрипт для развертывания ArangoDB stack
# Использование: ./deploy-arango.sh

set -e

echo "=== Развертывание ArangoDB Stack ==="

# Проверка, что мы на manager ноде
if ! docker info | grep -q "Swarm: active"; then
    echo "Ошибка: Docker Swarm не активен. Запустите setup-swarm.sh сначала"
    exit 1
fi

# Проверка наличия необходимых файлов
if [ ! -f "/opt/docker-swarm/docker-stack.yml" ]; then
    echo "Ошибка: Файл docker-stack.yml не найден"
    exit 1
fi

# Проверка секретов
echo "Проверка секретов..."
if ! docker secret ls | grep -q "arango_root_password"; then
    echo "Ошибка: Секрет arango_root_password не найден"
    exit 1
fi

if ! docker secret ls | grep -q "traefik_admin_password"; then
    echo "Ошибка: Секрет traefik_admin_password не найден"
    exit 1
fi

# Проверка сети
if ! docker network ls | grep -q "arango-network"; then
    echo "Ошибка: Сеть arango-network не найдена"
    exit 1
fi

# Развертывание stack
echo "Развертывание ArangoDB stack..."
docker stack deploy -c /opt/docker-swarm/docker-stack.yml arango

# Ожидание запуска сервисов
echo "Ожидание запуска сервисов..."
sleep 30

# Проверка статуса сервисов
echo "=== Статус сервисов ==="
docker stack services arango

echo "=== Детальная информация о сервисах ==="
for service in $(docker stack services arango --format "{{.Name}}"); do
    echo "--- Сервис: $service ---"
    docker service ps $service --no-trunc
    echo
done

echo "=== ArangoDB Stack развернут ==="
echo "ArangoDB доступен по адресу: http://arango.localhost"
echo "Traefik dashboard: http://traefik.localhost:8080"
echo ""
echo "Для проверки статуса используйте:"
echo "docker stack services arango"
echo "docker service logs arango_arango-coordinator"
