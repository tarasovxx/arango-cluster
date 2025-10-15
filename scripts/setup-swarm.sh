#!/bin/bash

# Скрипт для инициализации Docker Swarm кластера
# Использование: ./setup-swarm.sh

set -e

echo "=== Инициализация Docker Swarm кластера ==="

# Проверка, что мы на manager ноде
if [ ! -f /opt/docker-swarm/manager-token.txt ]; then
    echo "Ошибка: Скрипт должен запускаться на manager ноде"
    exit 1
fi

# Получение IP адреса manager ноды (private network)
MANAGER_IP=$(ip addr show enp0s8 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
echo "Manager IP: $MANAGER_IP"

# Инициализация Swarm (если еще не инициализирован)
if ! docker info | grep -q "Swarm: active"; then
    echo "Инициализация Docker Swarm..."
    docker swarm init --advertise-addr $MANAGER_IP
    
    # Сохранение токенов
    docker swarm join-token worker > /opt/docker-swarm/worker-token.txt
    docker swarm join-token manager > /opt/docker-swarm/manager-token.txt
    
    echo "Токены сохранены в /opt/docker-swarm/"
else
    echo "Docker Swarm уже инициализирован"
fi

# Создание overlay сети
if ! docker network ls | grep -q "arango-network"; then
    echo "Создание overlay сети..."
    docker network create --driver overlay --attachable arango-network
else
    echo "Сеть arango-network уже существует"
fi

# Создание секретов
echo "Создание секретов..."
if ! docker secret ls | grep -q "arango_root_password"; then
    echo "arango-root-password-$(date +%s)" | docker secret create arango_root_password -
    echo "Секрет arango_root_password создан"
else
    echo "Секрет arango_root_password уже существует"
fi

if ! docker secret ls | grep -q "traefik_admin_password"; then
    echo "traefik-admin-$(date +%s)" | docker secret create traefik_admin_password -
    echo "Секрет traefik_admin_password создан"
else
    echo "Секрет traefik_admin_password уже существует"
fi

echo "=== Docker Swarm кластер готов ==="
echo "Для присоединения worker нод используйте команду:"
echo "docker swarm join --token \$(cat /opt/docker-swarm/worker-token.txt | grep -o 'SWMTKN-[^[:space:]]*') $MANAGER_IP:2377"
