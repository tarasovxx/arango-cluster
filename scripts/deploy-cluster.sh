#!/bin/bash
set -e

vagrant up
sleep 30

vagrant ssh node1 -c "docker node ls"
# vagrant ssh node1 -c "docker stack deploy -c /vagrant/docker-stack.yml arango"
vagrant ssh node1 -c "/vagrant/scripts/deploy-arango.sh"

sleep 45
vagrant ssh node1 -c "docker service ls"

echo ""
echo "ArangoDB: https://localhost:8529"
echo "Login: root (empty password, set it after first login)"
