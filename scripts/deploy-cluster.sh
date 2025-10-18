#!/bin/bash

# Главный скрипт для автоматического развертывания ArangoDB кластера
# Использование: ./deploy-cluster.sh

set -e

echo "╔═══════════════════════════════════════════════════════╗"
echo "║   ArangoDB Docker Swarm Cluster - Развертывание      ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo ""

# Проверка наличия Vagrant
if ! command -v vagrant &> /dev/null; then
    echo "❌ Ошибка: Vagrant не установлен"
    echo "📥 Установите Vagrant с https://www.vagrantup.com/"
    exit 1
fi

# Проверка наличия VirtualBox
if ! command -v vboxmanage &> /dev/null; then
    echo "⚠️  Предупреждение: VirtualBox может быть не установлен"
    echo "📥 Установите VirtualBox с https://www.virtualbox.org/"
fi

# Проверка наличия Vagrantfile
if [ ! -f "Vagrantfile" ]; then
    echo "❌ Ошибка: Vagrantfile не найден"
    echo "📂 Запустите скрипт из корневой директории проекта"
    exit 1
fi

# Проверка наличия docker-stack.yml
if [ ! -f "docker-stack.yml" ]; then
    echo "❌ Ошибка: docker-stack.yml не найден"
    exit 1
fi

echo "1️⃣  Запуск виртуальных машин (это займет 5-7 минут)..."
vagrant up

echo ""
echo "2️⃣  Ожидание полной инициализации Docker Swarm..."
sleep 30

echo ""
echo "3️⃣  Проверка статуса Docker Swarm..."
vagrant ssh node1 -c "docker node ls"

echo ""
echo "4️⃣  Развертывание ArangoDB кластера..."
vagrant ssh node1 -c "cd /vagrant && docker stack deploy -c docker-stack.yml arango"

echo ""
echo "5️⃣  Ожидание запуска сервисов (это займет 30-60 секунд)..."
sleep 45

echo ""
echo "6️⃣  Проверка статуса сервисов..."
vagrant ssh node1 -c "docker service ls"

echo ""
echo "7️⃣  Проверка здоровья кластера ArangoDB..."
sleep 15
vagrant ssh node1 -c "curl -s http://localhost:8529/_api/version 2>/dev/null || echo 'Кластер еще инициализируется...'"

echo ""
echo "╔═══════════════════════════════════════════════════════╗"
echo "║              ✅ Развертывание завершено!              ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo ""
echo "🌐 Доступ к ArangoDB:"
echo "   • Веб-интерфейс: http://localhost:8529"
echo "   • Aardvark UI:   http://localhost:8529/_db/_system/_admin/aardvark/index.html"
echo "   • API:           curl http://localhost:8529/_api/version"
echo ""
echo "🔑 Вход (без пароля):"
echo "   • Username: root (или оставьте пустым)"
echo "   • Password: (оставьте пустым)"
echo ""
echo "📊 Проверка кластера:"
echo "   • Статус сервисов:"
echo "     vagrant ssh node1 -c 'docker service ls'"
echo ""
echo "   • Здоровье кластера:"
echo "     curl http://localhost:8529/_admin/cluster/health"
echo ""
echo "   • Логи координаторов:"
echo "     vagrant ssh node1 -c 'docker service logs arango_arango-coordinator'"
echo ""
echo "🛠️  Управление:"
echo "   • Перезапуск кластера:"
echo "     vagrant ssh node1 -c 'cd /vagrant && docker stack rm arango && sleep 15 && docker stack deploy -c docker-stack.yml arango'"
echo ""
echo "   • Остановка VM:"
echo "     vagrant halt"
echo ""
echo "   • Полное удаление:"
echo "     vagrant destroy -f"
echo ""
echo "📚 Документация:"
echo "   • README.md"
echo "   • QUICKSTART.md"
echo "   • EXTERNAL_ACCESS.md"
echo ""
