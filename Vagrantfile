# -*- mode: ruby -*-
# vi: set ft=ruby :

NODES = 3

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"
  config.vm.box_check_update = false
  config.ssh.insert_key = false

  # Общий provisioning для всех нод
  config.vm.provision "shell", inline: <<-SHELL
    # Docker installation
    apt-get update
    apt-get install -y ca-certificates curl
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io
    usermod -aG docker vagrant

    # Build custom image
    cd /vagrant/docker && docker build -t arangodb-secrets:3.8.9 .
  SHELL

  (1..NODES).each do |i|
    config.vm.define "node#{i}" do |node|
      node.vm.hostname = "arango-node#{i}"
      
      # Host-only network (быстрее чем intnet, есть доступ с хоста)
      node.vm.network "private_network", ip: "192.168.56.#{10 + i}"
      
      # Port forward только на первой ноде (manager)
      if i == 1
        node.vm.network "forwarded_port", guest: 80, host: 80      # HTTP (Traefik)
        node.vm.network "forwarded_port", guest: 443, host: 443    # HTTPS (Traefik)
        node.vm.network "forwarded_port", guest: 8529, host: 8529  # ArangoDB direct (fallback)
      end

      node.vm.provider "virtualbox" do |vb|
        vb.name = "arango-node#{i}"
        vb.memory = 2048
        vb.cpus = 2
        vb.linked_clone = true
      end

      # Swarm init/join
      if i == 1
        node.vm.provision "shell", inline: <<-SHELL
          docker swarm init --advertise-addr 192.168.56.11
          docker swarm join-token worker -q > /vagrant/worker-token.txt
          docker network create --driver overlay --attachable arango-net || true
        SHELL
      else
        node.vm.provision "shell", inline: <<-SHELL
          sleep 10
          TOKEN=$(cat /vagrant/worker-token.txt)
          docker swarm join --token $TOKEN 192.168.56.11:2377
        SHELL
      end
    end
  end
end
