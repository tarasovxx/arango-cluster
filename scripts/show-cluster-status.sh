#!/bin/bash

echo "=== Swarm Nodes ==="
docker node ls 2>/dev/null || echo "(run on manager)"

echo ""
echo "=== Services ==="
docker service ls --filter "name=arango_"

echo ""
echo "=== Distribution ==="
docker service ps arango_arango-dbserver arango_arango-coordinator \
    --filter "desired-state=running" \
    --format "table {{.Name}}\t{{.Node}}\t{{.CurrentState}}" 2>/dev/null

echo ""
echo "=== Health ==="
curl -sk https://127.0.0.1:8529/_admin/cluster/health 2>/dev/null | head -c 300 || echo "(API unavailable)"
echo ""
