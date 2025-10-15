#!/bin/bash

# Главный скрипт для автоматического развертывания ArangoDB кластера
# Использование: ./deploy-cluster.sh

set -e

echo "=== Автоматическое развертывание ArangoDB кластера ==="

# Очистка существующего окружения
# echo "0. Очистка существующего окружения..."
# if [ -f "scripts/cleanup-vbox.sh" ]; then
#     chmod +x scripts/cleanup-vbox.sh
#     ./scripts/cleanup-vbox.sh
# else
#     echo "Скрипт очистки не найден, пропускаем..."
# fi

# Проверка наличия Vagrant
if ! command -v vagrant &> /dev/null; then
    echo "Ошибка: Vagrant не установлен"
    echo "Установите Vagrant с https://www.vagrantup.com/"
    exit 1
fi

# Проверка наличия VirtualBox
# if ! command -v vboxmanage &> /dev/null; then
#     echo "Ошибка: VirtualBox не установлен"
#     echo "Установите VirtualBox с https://www.virtualbox.org/"
#     exit 1
# fi

# Проверка наличия Vagrantfile
if [ ! -f "Vagrantfile" ]; then
    echo "Ошибка: Vagrantfile не найден"
    exit 1
fi

echo "1. Запуск виртуальных машин..."
vagrant up

echo ""
echo "2. Ожидание готовности машин..."
sleep 30

echo ""
echo "3. Инициализация Docker Swarm на manager ноде..."
vagrant ssh node1 -c "sudo /opt/docker-swarm/scripts/setup-swarm.sh"

echo ""
echo "4. Получение токена для присоединения worker нод..."
WORKER_TOKEN=$(vagrant ssh node1 -c "cat /opt/docker-swarm/worker-token.txt | grep -o 'SWMTKN-[^[:space:]]*'" | tr -d '\r')
MANAGER_IP=$(vagrant ssh node1 -c "ip addr show enp0s8 | grep 'inet ' | awk '{print \$2}' | cut -d/ -f1" | tr -d '\r')

echo "Worker token: $WORKER_TOKEN"
echo "Manager IP: $MANAGER_IP"

echo ""
echo "5. Присоединение worker нод к кластеру..."
for i in 2 3; do
    echo "Присоединение node$i..."
    vagrant ssh node$i -c "docker swarm join --token $WORKER_TOKEN $MANAGER_IP:2377"
done

echo ""
echo "6. Проверка статуса кластера..."
vagrant ssh node1 -c "docker node ls"

echo ""
echo "7. Развертывание ArangoDB stack..."
vagrant ssh node1 -c "sudo /opt/docker-swarm/scripts/deploy-arango.sh"

echo ""
echo "8. Ожидание запуска сервисов..."
sleep 60

echo ""
echo "9. Проверка статуса сервисов..."
vagrant ssh node1 -c "docker stack services arango"

echo ""
echo "=== Развертывание завершено ==="
echo ""
echo "Доступные сервисы:"
echo "- ArangoDB: http://arango.localhost (добавьте в /etc/hosts: $MANAGER_IP arango.localhost)"
echo "- Traefik Dashboard: http://traefik.localhost:8080 (добавьте в /etc/hosts: $MANAGER_IP traefik.localhost)"
echo ""
echo "Управление кластером:"
echo "- Статус: vagrant ssh node1 -c 'sudo /opt/docker-swarm/scripts/cluster-manage.sh status'"
echo "- Логи: vagrant ssh node1 -c 'sudo /opt/docker-swarm/scripts/cluster-manage.sh logs arango-coordinator'"
echo "- Rolling update: vagrant ssh node1 -c 'sudo /opt/docker-swarm/scripts/rolling-update.sh arango-coordinator arangodb/arangodb:3.11.1'"
echo ""
echo "Остановка кластера:"
echo "- vagrant halt"
echo "- vagrant destroy -f"
