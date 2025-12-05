# Docker Swarm Cheat Sheet

Update the running my-service service to add an environment variable, change the number of replicas, and update the image version
using a rolling update with no delay between replicas.
```
$ docker service update --env-add KEY-VALUE my-service
$ docker service update --replicas=6 my-service
$ docker service update --image my-image:v2 my-service
```

List all nodes in the cluster.
```
$ docker node ls
```

Check detailed error messages for a failed service (use --no-trunc to see full error messages):
```
$ docker service ps <service-id> --no-trunc
```

View logs for a specific service:
```
$ docker service logs <service-name>
$ docker service logs arango_arango-agent-1
```

```
$ docker node ls
```

Remove a failed stack and clean up:
```
$ docker stack rm arango
$ docker rm $(docker ps -a -q -f "name=arango_")
```

Deploy the ArangoDB stack:
```
vagrant ssh node1 -c "sudo cp /vagrant/docker-stack.yml /opt/docker-swarm/ && docker stack deploy -c /opt/docker-swarm/docker-stack.yml arango"
```

Check deployment status:
```
vagrant ssh node1 -c "docker stack services arango"
```