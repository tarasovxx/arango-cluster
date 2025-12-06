#!/bin/bash
set -e

DBSERVERS="${1:-}"
COORDINATORS="${2:-}"

if [ -z "$DBSERVERS" ]; then
    echo "Usage: $0 <dbservers> [coordinators]"
    echo "Example: $0 4 4"
    echo ""
    echo "Current state:"
    docker service ls --filter "name=arango_arango-dbserver" --filter "name=arango_arango-coordinator"
    exit 0
fi

COORDINATORS="${COORDINATORS:-$DBSERVERS}"

docker service scale \
    arango_arango-dbserver="$DBSERVERS" \
    arango_arango-coordinator="$COORDINATORS"

sleep 10
docker service ls --filter "name=arango_arango-dbserver" --filter "name=arango_arango-coordinator"
