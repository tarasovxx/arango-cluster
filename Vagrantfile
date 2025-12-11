# -*- mode: ruby -*-
# vi: set ft=ruby :

NODES = 3

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"
  config.vm.box_check_update = false
  config.ssh.insert_key = false

  # Common provisioning for all nodes
  config.vm.provision "shell", inline: <<-SHELL
    apt-get update
    apt-get install -y ca-certificates curl dos2unix

    # Fix all shell scripts
    find /vagrant -name "*.sh" -exec dos2unix {} \; 2>/dev/null || true

    # Docker installation
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io
    usermod -aG docker vagrant

    cd /vagrant/docker && docker build -t arangodb-secrets:3.8.9 .
  SHELL

  (1..NODES).each do |i|
    config.vm.define "node#{i}" do |node|
      node.vm.hostname = "arango-node#{i}"
      
      # Private network (accessible from host)
      node.vm.network "private_network", ip: "192.168.56.#{10 + i}"
      
      # Port forwarding on manager node only
      if i == 1
        node.vm.network "forwarded_port", guest: 80, host: 80
        node.vm.network "forwarded_port", guest: 443, host: 443
      end

      node.vm.provider "virtualbox" do |vb|
        vb.name = "arango-node#{i}"
        vb.memory = 2048
        vb.cpus = 2
        vb.linked_clone = true
      end

      # Swarm setup
      if i == 1
        node.vm.provision "shell", inline: <<-SHELL
          docker swarm init --advertise-addr 192.168.56.11
          docker swarm join-token worker -q > /vagrant/worker-token.txt
          
          # Create overlay networks
          docker network create --driver overlay --attachable arango-net || true
          docker network create --driver overlay --attachable traefik-public || true

          # Generate TLS certificate
          /vagrant/scripts/generate-certs.sh
        SHELL
      else
        # Worker nodes - join swarm
        node.vm.provision "shell", inline: <<-SHELL
          sleep 10
          TOKEN=$(cat /vagrant/worker-token.txt)
          docker swarm join --token $TOKEN 192.168.56.11:2377
        SHELL
      end

      if i == NODES
        node.trigger.after :up do |trigger|
          trigger.name = "Deploy ArangoDB Cluster"
          trigger.info = "All nodes are up. Deploying ArangoDB cluster..."
          trigger.run = {inline: "vagrant ssh node1 -c '/vagrant/scripts/deploy-arango.sh'"}
        end
      end
    end
  end
  # config.vm.define "node4" do |node|
  #   node.vm.hostname = "arango-node4"
  #   node.vm.network "private_network", ip: "192.168.56.14"
  #   node.vm.provider "virtualbox" do |vb|
  #     vb.name = "arango-node4"
  #     vb.memory = 2048
  #     vb.cpus = 2
  #     vb.linked_clone = true
  #   end
  # end
end
