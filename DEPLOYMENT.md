# ArangoDB Docker Swarm Cluster

Этот проект реализует автоматизированное развертывание кластера ArangoDB с использованием Docker Swarm на нескольких виртуальных машинах через Vagrant.

## Архитектура

- **3 виртуальные машины** (Ubuntu 22.04 LTS)
  - node1: Manager нода Docker Swarm
  - node2, node3: Worker ноды Docker Swarm
- **ArangoDB кластер** с компонентами:
  - 3 Coordinator ноды (для обработки запросов)
  - 3 Agent ноды (для управления кластером)
  - 3 DBServer ноды (для хранения данных)
- **Traefik** для балансировки нагрузки и обратного прокси
- **Docker Secrets** для управления паролями и токенами

## Требования

- Vagrant 2.0+
- VirtualBox 6.0+
- Минимум 6GB RAM (2GB на каждую VM)
- Порты 80, 443, 8080 должны быть свободны

## Быстрый старт

1. **Клонирование и запуск:**
   ```bash
   git clone <repository-url>
   cd arango_devops
   chmod +x scripts/*.sh
   ./scripts/deploy-cluster.sh
   ```

2. **Добавление записей в hosts файл:**
   ```bash
   # Получите IP manager ноды
   vagrant ssh node1 -c "hostname -I | awk '{print \$1}'"
   
   # Добавьте в /etc/hosts (Linux/Mac) или C:\Windows\System32\drivers\etc\hosts (Windows)
   <MANAGER_IP> arango.localhost
   <MANAGER_IP> traefik.localhost
   ```

3. **Доступ к сервисам:**
   - ArangoDB: http://arango.localhost
   - Traefik Dashboard: http://traefik.localhost:8080

## Управление кластером

### Основные команды

```bash
# Статус кластера
vagrant ssh node1 -c "sudo /opt/docker-swarm/scripts/cluster-manage.sh status"

# Проверка здоровья
vagrant ssh node1 -c "sudo /opt/docker-swarm/scripts/cluster-manage.sh health"

# Логи сервиса
vagrant ssh node1 -c "sudo /opt/docker-swarm/scripts/cluster-manage.sh logs arango-coordinator"

# Масштабирование сервиса
vagrant ssh node1 -c "sudo /opt/docker-swarm/scripts/cluster-manage.sh scale arango-coordinator 5"
```

### Rolling Updates

```bash
# Обновление сервиса
vagrant ssh node1 -c "sudo /opt/docker-swarm/scripts/rolling-update.sh arango-coordinator arangodb/arangodb:3.11.1"

# Обновление всех сервисов
vagrant ssh node1 -c "sudo /opt/docker-swarm/scripts/rolling-update.sh arango-agent arangodb/arangodb:3.11.1"
vagrant ssh node1 -c "sudo /opt/docker-swarm/scripts/rolling-update.sh arango-dbserver arangodb/arangodb:3.11.1"
```

### Управление секретами

```bash
# Просмотр секретов
vagrant ssh node1 -c "docker secret ls"

# Создание нового секрета
vagrant ssh node1 -c "echo 'new-password' | docker secret create new_secret -"

# Удаление секрета
vagrant ssh node1 -c "docker secret rm secret_name"
```

## Мониторинг и отладка

### Проверка статуса нод
```bash
vagrant ssh node1 -c "docker node ls"
```

### Проверка сервисов
```bash
vagrant ssh node1 -c "docker stack services arango"
```

### Детальная информация о сервисе
```bash
vagrant ssh node1 -c "docker service ps arango_arango-coordinator --no-trunc"
```

### Логи всех сервисов
```bash
vagrant ssh node1 -c "docker service logs arango_arango-coordinator"
vagrant ssh node1 -c "docker service logs arango_arango-agent"
vagrant ssh node1 -c "docker service logs arango_arango-dbserver"
vagrant ssh node1 -c "docker service logs arango_traefik"
```

## Отказоустойчивость

Кластер обеспечивает отказоустойчивость через:

1. **Репликацию сервисов** - каждый компонент запущен в нескольких экземплярах
2. **Автоматический перезапуск** - Docker Swarm автоматически перезапускает упавшие контейнеры
3. **Rolling updates** - обновления происходят без остановки сервиса
4. **Балансировка нагрузки** - Traefik распределяет запросы между репликами

## Масштабирование

```bash
# Увеличение количества coordinator нод
vagrant ssh node1 -c "docker service scale arango_arango-coordinator=5"

# Увеличение количества dbserver нод
vagrant ssh node1 -c "docker service scale arango_arango-dbserver=5"
```

## Остановка и очистка

```bash
# Остановка кластера
vagrant halt

# Полная очистка
vagrant destroy -f

# Остановка только ArangoDB stack
vagrant ssh node1 -c "docker stack rm arango"
```

## Структура проекта

```
arango_devops/
├── Vagrantfile              # Конфигурация виртуальных машин
├── docker-stack.yml         # Docker Compose stack для ArangoDB
├── traefik.yml             # Конфигурация Traefik
├── scripts/
│   ├── deploy-cluster.sh   # Главный скрипт развертывания
│   ├── setup-swarm.sh      # Инициализация Docker Swarm
│   ├── deploy-arango.sh    # Развертывание ArangoDB stack
│   ├── rolling-update.sh   # Rolling updates
│   └── cluster-manage.sh   # Управление кластером
└── README.md               # Этот файл
```

## Устранение неполадок

### Проблемы с сетью
```bash
# Проверка сетей
vagrant ssh node1 -c "docker network ls"

# Пересоздание overlay сети
vagrant ssh node1 -c "docker network rm arango-network"
vagrant ssh node1 -c "docker network create --driver overlay --attachable arango-network"
```

### Проблемы с сервисами
```bash
# Перезапуск сервиса
vagrant ssh node1 -c "docker service update --force arango_arango-coordinator"

# Проверка задач сервиса
vagrant ssh node1 -c "docker service ps arango_arango-coordinator"
```

### Проблемы с секретами
```bash
# Пересоздание секретов
vagrant ssh node1 -c "docker secret rm arango_root_password"
vagrant ssh node1 -c "echo 'new-password' | docker secret create arango_root_password -"
```

## Дополнительные возможности

### Локальный Docker Registry
```bash
# Запуск локального registry
vagrant ssh node1 -c "docker service create --name registry --publish 5000:5000 registry:2"

# Использование локального registry в docker-stack.yml
# image: localhost:5000/arangodb:3.11.0
```

### Мониторинг с Prometheus
Добавьте сервис Prometheus в docker-stack.yml для мониторинга метрик.

### Логирование с ELK Stack
Добавьте Elasticsearch, Logstash и Kibana для централизованного логирования.
