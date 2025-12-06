#!/bin/bash
set -e

MANAGER_IP=$(ip addr show enp0s8 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)

if ! docker info | grep -q "Swarm: active"; then
    docker swarm init --advertise-addr "$MANAGER_IP"
    docker swarm join-token worker -q > /vagrant/worker-token.txt
fi

docker network create --driver overlay --attachable arango-net 2>/dev/null || true

echo "Swarm ready. Manager: $MANAGER_IP"
echo "Worker token: $(cat /vagrant/worker-token.txt)"
