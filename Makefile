# Makefile для управления ArangoDB кластером

.PHONY: help deploy start stop restart status logs test clean

# Переменные
MANAGER_NODE = node1
STACK_NAME = arango

help: ## Показать справку
	@echo "Доступные команды:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

deploy: ## Полное развертывание кластера
	@echo "🚀 Развертывание ArangoDB кластера..."
	chmod +x scripts/*.sh
	./scripts/deploy-cluster.sh

start: ## Запуск виртуальных машин
	@echo "▶️  Запуск виртуальных машин..."
	vagrant up

stop: ## Остановка виртуальных машин
	@echo "⏹️  Остановка виртуальных машин..."
	vagrant halt

restart: ## Перезапуск виртуальных машин
	@echo "🔄 Перезапуск виртуальных машин..."
	vagrant reload

status: ## Показать статус кластера
	@echo "📊 Статус кластера..."
	vagrant ssh $(MANAGER_NODE) -c "sudo /opt/docker-swarm/scripts/cluster-manage.sh status"

health: ## Проверить здоровье кластера
	@echo "🏥 Проверка здоровья кластера..."
	vagrant ssh $(MANAGER_NODE) -c "sudo /opt/docker-swarm/scripts/cluster-manage.sh health"

logs: ## Показать логи сервисов
	@echo "📝 Логи сервисов..."
	vagrant ssh $(MANAGER_NODE) -c "sudo /opt/docker-swarm/scripts/cluster-manage.sh logs arango-coordinator"

test: ## Запустить тесты кластера
	@echo "🧪 Тестирование кластера..."
	vagrant ssh $(MANAGER_NODE) -c "sudo /opt/docker-swarm/scripts/test-cluster.sh"

scale-coordinator: ## Масштабировать coordinator ноды (использование: make scale-coordinator REPLICAS=5)
	@echo "📈 Масштабирование coordinator нод до $(REPLICAS) реплик..."
	vagrant ssh $(MANAGER_NODE) -c "sudo /opt/docker-swarm/scripts/cluster-manage.sh scale arango-coordinator $(REPLICAS)"

scale-dbserver: ## Масштабировать dbserver ноды (использование: make scale-dbserver REPLICAS=5)
	@echo "📈 Масштабирование dbserver нод до $(REPLICAS) реплик..."
	vagrant ssh $(MANAGER_NODE) -c "sudo /opt/docker-swarm/scripts/cluster-manage.sh scale arango-dbserver $(REPLICAS)"

update-coordinator: ## Обновить coordinator ноды (использование: make update-coordinator VERSION=3.11.1)
	@echo "🔄 Обновление coordinator нод до версии $(VERSION)..."
	vagrant ssh $(MANAGER_NODE) -c "sudo /opt/docker-swarm/scripts/rolling-update.sh arango-coordinator arangodb/arangodb:$(VERSION)"

update-dbserver: ## Обновить dbserver ноды (использование: make update-dbserver VERSION=3.11.1)
	@echo "🔄 Обновление dbserver нод до версии $(VERSION)..."
	vagrant ssh $(MANAGER_NODE) -c "sudo /opt/docker-swarm/scripts/rolling-update.sh arango-dbserver arangodb/arangodb:$(VERSION)"

update-agent: ## Обновить agent ноды (использование: make update-agent VERSION=3.11.1)
	@echo "🔄 Обновление agent нод до версии $(VERSION)..."
	vagrant ssh $(MANAGER_NODE) -c "sudo /opt/docker-swarm/scripts/rolling-update.sh arango-agent arangodb/arangodb:$(VERSION)"

backup: ## Создать бэкап конфигурации
	@echo "💾 Создание бэкапа конфигурации..."
	vagrant ssh $(MANAGER_NODE) -c "sudo /opt/docker-swarm/scripts/cluster-manage.sh backup"

ssh-manager: ## Подключиться к manager ноде
	@echo "🔐 Подключение к manager ноде..."
	vagrant ssh $(MANAGER_NODE)

ssh-worker: ## Подключиться к worker ноде (использование: make ssh-worker NODE=2)
	@echo "🔐 Подключение к worker ноде node$(NODE)..."
	vagrant ssh node$(NODE)

clean: ## Полная очистка (удаление всех VM)
	@echo "🧹 Полная очистка..."
	vagrant destroy -f

cleanup-vbox: ## Очистка VirtualBox окружения (VM, сети, DHCP)
	@echo "🧹 Очистка VirtualBox окружения..."
	chmod +x scripts/cleanup-vbox.sh
	./scripts/cleanup-vbox.sh

fix-network: ## Исправить проблемы с сетью VirtualBox
	@echo "🔧 Исправление проблем с сетью..."
	chmod +x scripts/fix-network.sh
	./scripts/fix-network.sh

clean-stack: ## Остановить только ArangoDB stack
	@echo "🧹 Остановка ArangoDB stack..."
	vagrant ssh $(MANAGER_NODE) -c "docker stack rm $(STACK_NAME)"

info: ## Показать информацию о кластере
	@echo "ℹ️  Информация о кластере:"
	@echo "Manager IP:"
	@vagrant ssh $(MANAGER_NODE) -c "hostname -I | awk '{print \$$1}'" 2>/dev/null || echo "VM не запущена"
	@echo ""
	@echo "Доступные сервисы:"
	@echo "- ArangoDB: http://arango.localhost"
	@echo "- Traefik Dashboard: http://traefik.localhost:8080"
	@echo ""
	@echo "Для добавления в hosts файл:"
	@echo "echo '<MANAGER_IP> arango.localhost traefik.localhost' >> /etc/hosts"

# Примеры использования
examples: ## Показать примеры использования
	@echo "📚 Примеры использования:"
	@echo ""
	@echo "Полное развертывание:"
	@echo "  make deploy"
	@echo ""
	@echo "Управление кластером:"
	@echo "  make status"
	@echo "  make health"
	@echo "  make logs"
	@echo ""
	@echo "Масштабирование:"
	@echo "  make scale-coordinator REPLICAS=5"
	@echo "  make scale-dbserver REPLICAS=3"
	@echo ""
	@echo "Обновления:"
	@echo "  make update-coordinator VERSION=3.11.1"
	@echo "  make update-dbserver VERSION=3.11.1"
	@echo ""
	@echo "Тестирование:"
	@echo "  make test"
	@echo ""
	@echo "Очистка:"
	@echo "  make clean-stack"
	@echo "  make clean"
