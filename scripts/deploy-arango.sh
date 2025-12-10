#!/bin/bash
set -e

STACK_FILE="${STACK_FILE:-/vagrant/docker-stack.yml}"

# Default domain (change for production)
export DOMAIN="${DOMAIN:-localhost}"

echo "Deploying ArangoDB cluster with Traefik..."
echo "Domain: $DOMAIN"
echo ""

# Clean mode
if [ "$1" = "--clean" ]; then
    echo "Cleaning up existing stack..."
    if docker stack ls | grep -q arango; then
        docker stack rm arango
        echo "Waiting for cleanup..."
        sleep 20
    fi
    docker volume rm arango_dbserver-data 2>/dev/null || true
    docker volume rm arango_traefik-letsencrypt 2>/dev/null || true
fi

# Create networks if they don't exist
docker network create --driver overlay --attachable arango-net 2>/dev/null || true
docker network create --driver overlay --attachable traefik-public 2>/dev/null || true

# Deploy stack
echo "Deploying stack..."
docker stack deploy -c "$STACK_FILE" arango

echo ""
echo "Waiting for services to start..."
sleep 30

echo ""
echo "=== Service Status ==="
docker service ls --filter "name=arango_"

echo ""
echo "=== Access URLs ==="
echo "ArangoDB Web UI: https://arangodb.${DOMAIN}"
echo "Traefik Dashboard: https://traefik.${DOMAIN}"
echo ""
echo "Direct access (fallback): http://192.168.56.11:8529"
echo ""
echo "Default Traefik login: admin / admin"
echo "ArangoDB login: root (set password on first login)"
