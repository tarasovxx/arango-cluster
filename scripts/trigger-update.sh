#!/bin/bash
set -e

STACK_FILE="${STACK_FILE:-/vagrant/docker-stack.yml}"
VERSION="${1:-v$(date +%s)}"

sed -i "s/DEPLOY_VERSION=v[^ ]*/DEPLOY_VERSION=${VERSION}/" "$STACK_FILE"
docker stack deploy -c "$STACK_FILE" arango

echo "Update triggered: $VERSION"
echo "Monitor: watch docker service ps arango_arango-coordinator"
