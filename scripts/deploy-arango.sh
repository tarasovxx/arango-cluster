#!/bin/bash
set -e

STACK_FILE="${STACK_FILE:-/vagrant/docker-stack.yml}"

# Clean mode
if [ "$1" = "--clean" ] && docker stack ls | grep -q arango; then
    docker stack rm arango
    sleep 15
    docker volume rm arango_dbserver-data 2>/dev/null || true
fi

# Deploy
docker network create --driver overlay --attachable arango-net 2>/dev/null || true
docker stack deploy -c "$STACK_FILE" arango

echo "Waiting for services..."
sleep 30
docker service ls --filter "name=arango_"
