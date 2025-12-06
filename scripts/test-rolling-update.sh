#!/bin/bash
set -e

STACK_FILE="${1:-/vagrant/docker-stack.yml}"
VERSION="v-$(date +%s)"

echo "Triggering rolling update: $VERSION"

# Update version in config
sed -i "s/DEPLOY_VERSION=v[^ ]*/DEPLOY_VERSION=${VERSION}/" "$STACK_FILE"

# Deploy
docker stack deploy -c "$STACK_FILE" arango 2>&1 | grep -v "could not be accessed"

echo ""
echo "Monitoring (Ctrl+C to stop)..."
echo ""

while true; do
    STATE=$(docker service inspect --format '{{.UpdateStatus.State}}' arango_arango-coordinator 2>/dev/null || echo "unknown")
    REPLICAS=$(docker service ls --filter "name=arango_arango-coordinator" --format "{{.Replicas}}")
    HTTP=$(curl -sk -o /dev/null -w "%{http_code}" --max-time 2 https://127.0.0.1:8529/_api/version 2>/dev/null || echo "000")
    
    echo "$(date +%H:%M:%S) | API: $HTTP | State: $STATE | Replicas: $REPLICAS"
    
    [ "$STATE" = "completed" ] && echo "Done!" && break
    sleep 3
done
