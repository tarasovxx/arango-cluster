#!/bin/bash
set -e

STACK_FILE="${1:-/vagrant/docker-stack.yml}"
VERSION="v-$(date +%Y%m%d-%H%M%S)"

echo "=============================================="
echo "  Rolling Update Test"
echo "=============================================="
echo ""
echo "New version: $VERSION"
echo "Stack file:  $STACK_FILE"
echo ""

# Check current state
echo "=== Current State ==="
docker service ls --filter "name=arango_arango-coordinator" --format "table {{.Name}}\t{{.Replicas}}\t{{.Image}}"
echo ""

# Update version in config (triggers rolling update)
echo "Updating DEPLOY_VERSION to $VERSION..."
sed -i "s/DEPLOY_VERSION=v[^ ]*/DEPLOY_VERSION=${VERSION}/" "$STACK_FILE"

# Deploy (this triggers the rolling update)
echo "Deploying..."
docker stack deploy -c "$STACK_FILE" arango 2>&1 | grep -v "could not be accessed" || true

echo ""
echo "=== Monitoring Rolling Update ==="
echo "(Press Ctrl+C to stop monitoring)"
echo ""
echo "Time     | API  | Update State | Replicas | Tasks"
echo "---------|------|--------------|----------|------"

STARTED=$(date +%s)
while true; do
    STATE=$(docker service inspect --format '{{.UpdateStatus.State}}' arango_arango-coordinator 2>/dev/null || echo "unknown")
    REPLICAS=$(docker service ls --filter "name=arango_arango-coordinator" --format "{{.Replicas}}" 2>/dev/null || echo "?/?")
    
    # Check API via Traefik HTTPS
    HTTP=$(curl -sk -o /dev/null -w "%{http_code}" --max-time 2 https://127.0.0.1/_api/version 2>/dev/null || echo "000")
    
    # Count running tasks
    RUNNING=$(docker service ps arango_arango-coordinator --filter "desired-state=running" --format "{{.CurrentState}}" 2>/dev/null | grep -c "Running" || echo "0")
    
    ELAPSED=$(($(date +%s) - STARTED))
    printf "%3ds     | %s  | %-12s | %-8s | %s running\n" "$ELAPSED" "$HTTP" "$STATE" "$REPLICAS" "$RUNNING"
    
    # Check if update completed
    if [ "$STATE" = "completed" ]; then
        echo ""
        echo "=== Rolling Update Completed! ==="
        echo "Duration: ${ELAPSED}s"
        echo ""
        docker service ps arango_arango-coordinator --filter "desired-state=running" --format "table {{.Name}}\t{{.Node}}\t{{.CurrentState}}"
        break
    fi
    
    # Check for rollback
    if [ "$STATE" = "rollback_completed" ]; then
        echo ""
        echo "=== Rolling Update Failed - Rolled Back ==="
        docker service ps arango_arango-coordinator --no-trunc
        exit 1
    fi
    
    # Timeout after 5 minutes
    if [ "$ELAPSED" -gt 300 ]; then
        echo ""
        echo "=== Timeout after 5 minutes ==="
        docker service ps arango_arango-coordinator --no-trunc
        exit 1
    fi
    
    sleep 3
done

echo ""
echo "=== Final Health Check ==="
curl -sk https://127.0.0.1/_api/version 2>/dev/null | head -c 200 || echo "API check failed"
echo ""
