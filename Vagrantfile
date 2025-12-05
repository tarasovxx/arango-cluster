# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"
  config.vm.box_check_update = false

  config.vm.provider "virtualbox" do |vb|
    vb.memory = "2048"
    vb.cpus = 2
    vb.name = "arango-swarm-node"
  end
  
  config.ssh.insert_key = false
  
  config.vm.provision "shell", inline: <<-SHELL
    apt-get update
    apt-get upgrade -y
    
    apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
    
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    usermod -aG docker vagrant
    
    # Включение и запуск Docker
    systemctl enable docker
    systemctl start docker
    
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    
    mkdir -p /opt/docker-swarm
    
    cp /vagrant/docker-stack.yml /opt/docker-swarm/
    if [ -d /vagrant/secrets ]; then
      cp -r /vagrant/secrets /opt/docker-swarm/
      chmod 600 /opt/docker-swarm/secrets/*
    fi
    if [ -d /vagrant/docker ]; then
      cp -r /vagrant/docker /opt/docker-swarm/
    fi
    if [ -f /vagrant/scripts/*.sh ]; then
      cp -r /vagrant/scripts /opt/docker-swarm/
      chmod +x /opt/docker-swarm/scripts/*.sh
    fi
    
    # Сборка кастомного образа ArangoDB с поддержкой Docker Secrets
    echo "Сборка кастомного образа ArangoDB с поддержкой Docker Secrets..."
    cd /opt/docker-swarm/docker
    docker build -t arangodb-secrets:3.8.9 .
    
    # Установка прав владельца для пользователя vagrant
    chown -R vagrant:vagrant /opt/docker-swarm
  SHELL

  (1..3).each do |i|
    config.vm.define "node#{i}" do |node|
      node.vm.hostname = "arango-node#{i}"
      
      node.vm.network "private_network", ip: "192.168.56.#{10 + i}", virtualbox__intnet: "arango-swarm-network"
      
      if i == 1
        node.vm.network "forwarded_port", guest: 8529, host: 8529, host_ip: "127.0.0.1"
      end
      
      node.vm.provider "virtualbox" do |vb|
        vb.name = "arango-swarm-node#{i}"
        vb.memory = "2048"
        vb.cpus = 2
        # Enable CPU features for compatibility with ArangoDB
        # vb.customize ["modifyvm", :id, "--cpu-profile", "host"]
        # vb.customize ["modifyvm", :id, "--paravirtprovider", "kvm"]
      end
      
      if i == 1
        node.vm.provision "shell", inline: <<-SHELL
          # Инициализация Docker Swarm на manager ноде
          docker swarm init --advertise-addr 192.168.56.11
          
          # Сохранение токена для присоединения worker нод
          docker swarm join-token worker -q > /vagrant/worker-token.txt
          
          # Создание overlay сети (имя должно совпадать с docker-stack.yml)
          docker network create --driver overlay --attachable arango-net || true
        SHELL
      else
        node.vm.provision "shell", inline: <<-SHELL
          # Ожидание готовности manager ноды
          sleep 30
          
          # Присоединение к Swarm кластеру как worker
          if [ -f /vagrant/worker-token.txt ]; then
            TOKEN=$(cat /vagrant/worker-token.txt)
            docker swarm join --token $TOKEN 192.168.56.11:2377
          else
            echo "Worker token not found. Manager node may not be ready yet."
          fi
        SHELL
      end
    end
  end
end