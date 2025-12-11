#!/bin/bash
set -e

# Script to add a new node to the ArangoDB cluster
# Run this script ON THE NEW NODE

MANAGER_IP="${1:-192.168.56.11}"
TOKEN="${2:-}"

echo "=============================================="
echo "  Add Node to ArangoDB Cluster"
echo "=============================================="
echo ""

# If no token provided, try to read from file
if [ -z "$TOKEN" ]; then
    if [ -f /vagrant/worker-token.txt ]; then
        TOKEN=$(cat /vagrant/worker-token.txt)
        echo "Token loaded from /vagrant/worker-token.txt"
    else
        echo "Usage: $0 [manager_ip] <worker_token>"
        echo ""
        echo "Get token on manager node:"
        echo "  docker swarm join-token worker -q"
        echo ""
        echo "Example:"
        echo "  $0 192.168.56.11 SWMTKN-1-xxx"
        exit 1
    fi
fi

echo "Manager IP: $MANAGER_IP"
echo ""

# Step 1: Build the ArangoDB image
echo "Step 1: Building ArangoDB image..."
if [ -f /vagrant/docker/Dockerfile ]; then
    cd /vagrant/docker && docker build -t arangodb-secrets:3.8.9 .
else
    echo "ERROR: Dockerfile not found at /vagrant/docker/Dockerfile"
    exit 1
fi
echo ""

# Step 2: Join the Swarm
echo "Step 2: Joining Docker Swarm..."
docker swarm join --token "$TOKEN" "${MANAGER_IP}:2377"
echo ""

# Step 3: Verify
echo "Step 3: Verifying..."
docker node ls 2>/dev/null || echo "(Run 'docker node ls' on manager to verify)"
echo ""

echo "=============================================="
echo "  Node Added Successfully!"
echo "=============================================="
echo ""
echo "Next steps (run on MANAGER node 192.168.56.11):"
echo ""
echo "1. Check node joined:"
echo "   docker node ls"
echo ""
echo "2. Scale services to use the new node:"
echo "   docker service scale arango_arango-dbserver=4 arango_arango-coordinator=4"
echo ""
echo "   Or use the script:"
echo "   /vagrant/scripts/scale-cluster.sh 4 4"
echo ""
echo "3. Verify distribution:"
echo "   docker service ps arango_arango-coordinator"
echo "   docker service ps arango_arango-dbserver"
echo ""
