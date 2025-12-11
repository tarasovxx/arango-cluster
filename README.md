# ArangoDB Docker Swarm Cluster

1) Автоматизация развертывания кластера Docker Swarm(минимум на 3х виртуальных машинах) и самого мультисервисного приложения.
2) Используя возможности Docker Swarm обеспечить отказоустойчивость и балансировку нагрузки. Также допускается использование обратного прокси-сервера Traefik/Nginx/HAproxy.
3) Реализовать автоматизацию обновлений всех сервисов кластера с помощью https://docs.docker.com/engine/swarm/swarm-tutorial/rolling-update/
4) В качестве средств автоматизации допускается использование инструментов Vagrant/Bash/Puppet/Chef/Ansible/Salt.
5) При необходимости допускается использование локального сервера Docker Registry
6) Все секреты (пароли, токены и т.д) должны передаваться через Docker Secrets. Понятно что не все сервисы из коробки данную функцию поддерживают. Поэтому допускается модификация образа для реализации данного требования.  


https://arango.ai/blog/deploying-and-securing-an-arangodb-cluster-using-docker/

vagrant@arango-node1:/vagrant$ curl -i http://localhost:8529/_api/version 


                    HTTPS (443)
                        │
                        ▼
              ┌─────────────────┐
              │     Traefik     │ (load balancer + TLS termination)
              │   192.168.56.11 │
              └────────┬────────┘
                       │
        ┌──────────────┼──────────────┐
        ▼              ▼              ▼
┌───────────┐  ┌───────────┐  ┌───────────┐
│Coordinator│  │Coordinator│  │Coordinator│  ← 3 координатора
│  node1    │  │  node2    │  │  node3    │    (любой может обслужить запрос)
└─────┬─────┘  └─────┬─────┘  └─────┬─────┘
      │              │              │
      └──────────────┼──────────────┘
                     │
        ┌────────────┼────────────┐
        ▼            ▼            ▼
┌──────────┐  ┌──────────┐  ┌──────────┐
│ DBServer │  │ DBServer │  │ DBServer │  ← 3 DB сервера
│  node1   │  │  node2   │  │  node3   │    (данные реплицированы)
└──────────┘  └──────────┘  └──────────┘
        │            │            │
        └────────────┼────────────┘
                     │
        ┌────────────┼────────────┐
        ▼            ▼            ▼
┌─────────┐   ┌─────────┐   ┌─────────┐
│ Agent 1 │   │ Agent 2 │   │ Agent 3 │   ← 3 агента RAFT
│  node1  │   │  node2  │   │  node3  │     (кворум 2 из 3)
└─────────┘   └─────────┘   └─────────┘





# add node


config.vm.define "node4" do |node|
  node.vm.hostname = "arango-node4"
  node.vm.network "private_network", ip: "192.168.56.14"
  node.vm.provider "virtualbox" do |vb|
    vb.name = "arango-node4"
    vb.memory = 2048
    vb.cpus = 2
    vb.linked_clone = true
  end
end

vagrant up node4

vagrant ssh node4

# Установите Docker
sudo apt-get update
sudo apt-get install -y ca-certificates curl dos2unix
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo tee /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io
sudo usermod -aG docker vagrant
exit

vagrant ssh node4

/vagrant/scripts/add-node.sh

vagrant ssh node1

docker node ls

/vagrant/scripts/scale-cluster.sh 4 4

docker service ps arango_arango-coordinator
docker service ps arango_arango-dbserver