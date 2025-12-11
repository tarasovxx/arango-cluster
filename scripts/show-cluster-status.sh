#!/bin/bash

echo "=== Swarm Nodes ==="
docker node ls 2>/dev/null || echo "(run on manager)"

echo ""
echo "=== Services ==="
docker service ls --filter "name=arango_"

echo ""
echo "=== Traefik ==="
docker service ps arango_traefik --format "table {{.Name}}\t{{.Node}}\t{{.CurrentState}}" 2>/dev/null || echo "(not deployed)"

echo ""
echo "=== Coordinators (Load Balanced) ==="
docker service ps arango_arango-coordinator \
    --filter "desired-state=running" \
    --format "table {{.Name}}\t{{.Node}}\t{{.CurrentState}}" 2>/dev/null

echo ""
echo "=== DB Servers ==="
docker service ps arango_arango-dbserver \
    --filter "desired-state=running" \
    --format "table {{.Name}}\t{{.Node}}\t{{.CurrentState}}" 2>/dev/null

echo ""
echo "=== Agents (RAFT Consensus) ==="
for i in 1 2 3; do
    docker service ps arango_arango-agent-$i \
        --filter "desired-state=running" \
        --format "Agent-$i: {{.Node}} - {{.CurrentState}}" 2>/dev/null
done

echo ""
echo "=== Health Check ==="
# Check via HTTPS (ignore certificate)
HTTP_CODE=$(curl -sk -o /dev/null -w "%{http_code}" --max-time 5 https://127.0.0.1/_api/version 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "401" ]; then
    echo "Traefik HTTPS: OK (HTTP $HTTP_CODE)"
    if [ "$HTTP_CODE" = "200" ]; then
        echo "Cluster health:"
        curl -sk https://127.0.0.1/_admin/cluster/health 2>/dev/null | head -c 500 || true
    fi
else
    echo "Traefik HTTPS: UNAVAILABLE (HTTP $HTTP_CODE)"
    echo "Cluster may still be starting..."
fi
echo ""

echo ""
echo "=== Access URLs ==="
echo "ArangoDB:  https://192.168.56.11"
echo "Dashboard: https://192.168.56.11/dashboard/"
echo ""
