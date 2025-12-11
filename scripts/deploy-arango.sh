#!/bin/bash
set -e

STACK_FILE="${STACK_FILE:-/vagrant/docker-stack.yml}"
CERT_DIR="/vagrant/traefik/certs"

echo "=============================================="
echo "  ArangoDB Cluster Deployment (HTTPS)"
echo "=============================================="
echo ""

# Generate certificate if not exists
if [ ! -f "$CERT_DIR/traefik.crt" ]; then
    echo "Generating TLS certificate..."
    /vagrant/scripts/generate-certs.sh
    echo ""
fi

# Clean mode
if [ "$1" = "--clean" ]; then
    echo "Cleaning up existing stack..."
    if docker stack ls | grep -q arango; then
        docker stack rm arango
        echo "Waiting for cleanup..."
        sleep 20
    fi
    docker volume rm arango_dbserver-data 2>/dev/null || true
    echo "Cleanup complete."
    echo ""
fi

# Create networks
echo "Creating overlay networks..."
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
echo "=============================================="
echo "  Deployment Complete!"
echo "=============================================="
echo ""
echo "Access (use HTTPS!):"
echo ""
echo "  ArangoDB Web UI:    https://192.168.56.11"
echo "  Traefik Dashboard:  https://192.168.56.11/dashboard/"
echo ""
echo "Credentials:"
echo "  Traefik: admin / admin"
echo "  ArangoDB: root (set password on first login)"
echo ""
echo "Note: Browser will warn about self-signed certificate."
echo "      Click 'Advanced' -> 'Proceed' to continue."
echo ""
