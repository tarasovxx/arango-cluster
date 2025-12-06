#!/bin/bash
set -e

MANAGER_IP="${1:-}"
TOKEN="${2:-}"

if [ -z "$MANAGER_IP" ] || [ -z "$TOKEN" ]; then
    echo "Usage: $0 <manager_ip> <worker_token>"
    echo ""
    echo "Get token on manager: docker swarm join-token worker -q"
    exit 1
fi

# Build image if Dockerfile exists
if [ -f /vagrant/docker/Dockerfile ]; then
    docker build -t arangodb-secrets:3.8.9 /vagrant/docker/
elif [ -f /opt/docker-swarm/docker/Dockerfile ]; then
    docker build -t arangodb-secrets:3.8.9 /opt/docker-swarm/docker/
fi

docker swarm join --token "$TOKEN" "${MANAGER_IP}:2377"

echo "Node joined. Scale services on manager:"
echo "  docker service scale arango_arango-dbserver=4 arango_arango-coordinator=4"
echo "  or: ./scripts/scale-cluster.sh 4 4"
