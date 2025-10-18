# Docker Swarm Cheat Sheet

Initialize the local Docker service as a swarm manager. As a guideline, in production you should have 3 to 5 managers. Swarm is
managed through port 2377, which should be blocked from external access.
```
$ docker swarm init
```

Join an existing swarm as a worker node. Replace $SWARM_MANAGER with the IP address or domain name of a swarm manager node.
```
$ docker swarm join $SWARM_MANAGER:2377 --token $(docker -H $SWARM_MANAGER:2345 swarm join-token -q worker)
```

List all nodes in the cluster.
```
$ docker node ls
```

Create an encrypted overlay network called "my-net".
```
$ docker network create -d overlay --opt encrypted my-net
```

Create a service, which is a higher-level group of containers, called my-service on the my-net network with 2 replicas of
the my-image container image. Then list all running services. Finally check the processes running on the local machine. If you
have two nodes in the swarm, then you should see only one replica running on this node, and the other replica on the other node.
```
$ docker service create --name my-service --network my-net --replicas 2 -p 80:80 my-image:latest
$ docker service ls
$ docker ps
```

List all replicas on the my-service service across the entire cluster. Then list only the replicas running on the local node.
```
$ docker service ps my-service
$ docker node ps self
```

Scale the my-service service up to 5 replicas, then down to 3.
```
$ docker service scale my-service=5
$ docker service scale my-service=3
```

Update the running my-service service to add an environment variable, change the number of replicas, and update the image version
using a rolling update with no delay between replicas.
```
$ docker service update --env-add KEY-VALUE my-service
$ docker service update --replicas=6 my-service
$ docker service update --image my-image:v2 my-service
```

Update the running my-service service to update the image version updating 2 replicas at a time, and delaying 10 seconds after
each batch.
```
$ docker service update --update-delay=10s --update-parallelism=2 --image my-image:v3 my-service
```

Create a compose file for a swarm service stack.
```
version: "3"
services:
  some-db:
    image: my-db:latest
    volumes:
      - db-data:/data
    networks:
      my-net:
        aliases:
          - db
    deploy:
      placement:
        constraints: [node.role == manager]

  some-app:
    image: some-app:latest
    networks:
      - my-net
    depends_on:
      - some-db
    deploy:
      mode: replicated
      replicas: 2
      labels: [APP=SOME-APP]
      resources:
        limits:
          cpus: '0.25'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 256M
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
        window: 120s
      update_config:
        parallelism: 1
        delay: 10s
        failure_action: continue
        monitor: 60s
        max_failure_ratio: 0.3
      placement:
        constraints: [node.role == worker]

networks:
  my-app:

volumes:
  db-data:
```

Deploy a stack using a compose file, then list all stacks, list the services in a given stack, and then list the running containers
in a stack.
```
$ docker stack deploy --compose-file docker-compose.yml my-stack
$ docker stack ls
$ docker stack services my-stack
$ docker stack ps my-stack
```

Remove the stack called my-stack, shutting down and destroying all services, containers, and networks in the process. Note that
this sometimes leaves some abandoned containers that are shut down but not removed, so next remove all stopped containers with
names starting with "my-stack_".
```
$ docker stack rm my-stack
$ docker rm $(docker ps -a -q -f "name=my-stack_")
```

List all worker nodes, then use the ID of any worker node returned to set the worker node's availability to drain. which shuffles
everything from that worker node to other nodes. Finally, set the worker node's availability back to active, which does NOT
shuffle containers back from other nodes. Future allocations of containers will rebalance the nodes.
```
$ docker node ls
$ docker node update $WORKER_NODE_ID --availability drain
$ docker node update $WORKER_NODE_ID --availability active
```

## Image Management

Pull an image on all nodes in the swarm (important: do this BEFORE deploying a stack to avoid "No such image" errors).
```
$ docker node ls -q | xargs -I {} docker node inspect {} --format '{{.Description.Hostname}}' | xargs -I {} ssh {} docker pull my-image:tag
```

For the Vagrant setup, pull images on all nodes:
```
vagrant ssh node1 -c "docker pull my-image:tag"
vagrant ssh node2 -c "docker pull my-image:tag"
vagrant ssh node3 -c "docker pull my-image:tag"
```

Check if an image exists on a specific node:
```
vagrant ssh node1 -c "docker images | grep arangodb"
```

## Troubleshooting

Check detailed error messages for a failed service (use --no-trunc to see full error messages):
```
$ docker service ps <service-id> --no-trunc
```

View logs for a specific service:
```
$ docker service logs <service-name>
$ docker service logs arango_arango-agent-1
```

Check if all nodes are active and available:
```
$ docker node ls
```

Remove a failed stack and clean up:
```
$ docker stack rm arango
$ docker rm $(docker ps -a -q -f "name=arango_")
```

## ArangoDB Deployment Commands

Pull ArangoDB images on all nodes before deploying (use 3.8 for VirtualBox CPU compatibility):
```
vagrant ssh node1 -c "docker pull arangodb/arangodb:3.8"
vagrant ssh node2 -c "docker pull arangodb/arangodb:3.8"
vagrant ssh node3 -c "docker pull arangodb/arangodb:3.8"
```

Deploy the ArangoDB stack:
```
vagrant ssh node1 -c "sudo cp /vagrant/docker-stack.yml /opt/docker-swarm/ && docker stack deploy -c /opt/docker-swarm/docker-stack.yml arango"
```

Check deployment status:
```
vagrant ssh node1 -c "docker stack services arango"
```