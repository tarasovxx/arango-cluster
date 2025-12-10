#!/bin/bash

echo "=== Swarm Nodes ==="
docker node ls 2>/dev/null || echo "(run on manager)"

echo ""
echo "=== Services ==="
docker service ls --filter "name=arango_"

echo ""
echo "=== Traefik Status ==="
docker service ps arango_traefik --format "table {{.Name}}\t{{.Node}}\t{{.CurrentState}}" 2>/dev/null || echo "(traefik not deployed)"

echo ""
echo "=== Coordinator Distribution ==="
docker service ps arango_arango-coordinator \
    --filter "desired-state=running" \
    --format "table {{.Name}}\t{{.Node}}\t{{.CurrentState}}" 2>/dev/null

echo ""
echo "=== DBServer Distribution ==="
docker service ps arango_arango-dbserver \
    --filter "desired-state=running" \
    --format "table {{.Name}}\t{{.Node}}\t{{.CurrentState}}" 2>/dev/null

echo ""
echo "=== Health Check ==="
# Try HTTPS first (via Traefik), then HTTP direct
if curl -sk https://127.0.0.1/_api/version 2>/dev/null | grep -q "server"; then
    echo "Traefik HTTPS: OK"
    curl -sk https://127.0.0.1/_admin/cluster/health 2>/dev/null | head -c 300 || true
elif curl -s http://127.0.0.1:8529/_api/version 2>/dev/null | grep -q "server"; then
    echo "Direct HTTP: OK"
    curl -s http://127.0.0.1:8529/_admin/cluster/health 2>/dev/null | head -c 300 || true
else
    echo "(API unavailable - cluster may still be starting)"
fi
echo ""
