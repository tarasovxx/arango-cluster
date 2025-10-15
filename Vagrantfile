# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # Общие настройки для всех машин
  config.vm.box = "ubuntu/jammy64"
  config.vm.box_check_update = false
  
  # Настройки сети будут определены для каждой ноды индивидуально
  
  # Настройки провайдера VirtualBox
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "2048"
    vb.cpus = 2
    vb.name = "arango-swarm-node"
  end
  
  # Настройки SSH
  config.ssh.insert_key = false
  
  # Provisioning скрипт для установки Docker
  config.vm.provision "shell", inline: <<-SHELL
    # Обновление системы
    apt-get update
    apt-get upgrade -y
    
    # Установка необходимых пакетов
    apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
    
    # Добавление Docker GPG ключа
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # Добавление Docker репозитория
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Установка Docker
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    # Добавление пользователя vagrant в группу docker
    usermod -aG docker vagrant
    
    # Включение и запуск Docker
    systemctl enable docker
    systemctl start docker
    
    # Установка Docker Compose
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    
    # Создание директории для Docker Swarm
    mkdir -p /opt/docker-swarm
    
    # Копирование конфигурационных файлов
    cp /vagrant/docker-stack.yml /opt/docker-swarm/
    cp /vagrant/traefik.yml /opt/docker-swarm/
    cp -r /vagrant/scripts /opt/docker-swarm/
    
    # Установка прав доступа
    chmod +x /opt/docker-swarm/scripts/*.sh
  SHELL

  # Определение виртуальных машин
  (1..3).each do |i|
    config.vm.define "node#{i}" do |node|
      node.vm.hostname = "arango-node#{i}"
      
      # Настройки сети для каждой ноды
      node.vm.network "private_network", ip: "192.168.56.#{10 + i}", virtualbox__intnet: "arango-swarm-network"
      
      # Настройки VirtualBox для каждой ноды
      node.vm.provider "virtualbox" do |vb|
        vb.name = "arango-swarm-node#{i}"
        vb.memory = "2048"
        vb.cpus = 2
      end
      
      # Дополнительный provisioning для manager ноды
      if i == 1
        node.vm.provision "shell", inline: <<-SHELL
          # Инициализация Docker Swarm на manager ноде
          docker swarm init --advertise-addr 192.168.56.11
          
          # Сохранение токена для присоединения worker нод
          docker swarm join-token worker > /opt/docker-swarm/worker-token.txt
          docker swarm join-token manager > /opt/docker-swarm/manager-token.txt
          
          # Создание overlay сети
          docker network create --driver overlay --attachable arango-network
          
          # Создание секретов
          echo "arango-root-password" | docker secret create arango_root_password -
          echo "traefik-admin-password" | docker secret create traefik_admin_password -
        SHELL
      else
        node.vm.provision "shell", inline: <<-SHELL
          # Ожидание готовности manager ноды
          sleep 30
          
          # Присоединение к Swarm кластеру как worker
          # Токен будет получен от manager ноды
          if [ -f /vagrant/worker-token.txt ]; then
            $(cat /vagrant/worker-token.txt)
          else
            echo "Worker token not found, please run setup-swarm.sh manually"
          fi
        SHELL
      end
    end
  end
end
