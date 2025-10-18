# ArangoDB Docker Swarm Cluster

Автоматизированное развертывание кластера ArangoDB с использованием Docker Swarm на 3 виртуальных машинах через Vagrant.

## ✨ Возможности

- ✅ **Полностью автоматизированное развертывание** через Vagrant + Docker Swarm
- ✅ **Отказоустойчивый кластер** ArangoDB: 3 Агента + 3 DBServer + 3 Координатора
- ✅ **Автоматическая балансировка нагрузки** через Docker Swarm Ingress
- ✅ **Простой доступ** через localhost:8529 с вашего компьютера
- ✅ **Предзагрузка образов** Docker для быстрого старта
- ✅ **Без аутентификации** для разработки (можно легко включить)

## 🚀 Быстрый старт

### 1. Требования
- Vagrant 2.0+
- VirtualBox 6.0+
- Минимум 6GB RAM
- Свободный порт 8529 на хост-машине

### 2. Запуск кластера

```bash
# Клонировать репозиторий
git clone <repository-url>
cd arango_devops

# Запустить все 3 ноды
vagrant up

# После завершения (3-5 минут) кластер готов!
```

### 3. Доступ к ArangoDB

Откройте браузер:
```
http://localhost:8529
```

**Веб-интерфейс ArangoDB:**
```
http://localhost:8529/_db/_system/_admin/aardvark/index.html
```

**Логин:** Оставьте поля пустыми или введите `root` без пароля

**API доступ:**
```bash
curl http://localhost:8529/_api/version
curl http://localhost:8529/_admin/cluster/health
```

## 📊 Архитектура

```
Ваш компьютер
    ↓ (localhost:8529)
VirtualBox Port Forwarding
    ↓
VM node1 (192.168.56.11)
    ↓
Docker Swarm Ingress (автоматическая балансировка)
    ↓         ↓         ↓
Coordinator1  Coordinator2  Coordinator3
    ↓         ↓         ↓
3 DBServers (хранение данных, распределенно)
    ↓
3 Agents RAFT (координация и консенсус)
```

### Компоненты:

- **3 виртуальные машины** (Ubuntu 22.04 LTS, по 2GB RAM, 2 CPU каждая)
  - `arango-node1` (192.168.56.11) - Manager ноды Swarm
  - `arango-node2` (192.168.56.12) - Worker нода
  - `arango-node3` (192.168.56.13) - Worker нода

- **ArangoDB кластер:**
  - 3 Agent (RAFT консенсус для метаданных)
  - 3 DBServer (распределенное хранение данных)
  - 3 Coordinator (обработка запросов, stateless)

- **Docker Swarm:**
  - Автоматическая балансировка через Ingress Network (IPVS)
  - Автоматическое восстановление упавших контейнеров
  - По одному сервису каждого типа на каждой ноде

## 🛠️ Управление кластером

### Основные команды

```bash
# Статус виртуальных машин
vagrant status

# Статус сервисов в кластере
vagrant ssh node1 -c "docker service ls"

# Статус нод Swarm
vagrant ssh node1 -c "docker node ls"

# Здоровье кластера ArangoDB
vagrant ssh node1 -c "curl -s http://localhost:8529/_admin/cluster/health"

# Логи сервиса
vagrant ssh node1 -c "docker service logs arango_arango-coordinator"

# Перезапуск кластера ArangoDB
vagrant ssh node1 -c "cd /vagrant && docker stack rm arango && sleep 15 && docker stack deploy -c docker-stack.yml arango"
```

### Перезапуск VM

```bash
# Перезапуск одной ноды
vagrant reload node1

# Перезапуск всех нод
vagrant reload

# Остановка кластера
vagrant halt

# Полное удаление
vagrant destroy -f
```

## 📚 Документация

- [QUICKSTART.md](QUICKSTART.md) - Детальное руководство по быстрому старту
- [DEPLOYMENT.md](DEPLOYMENT.md) - Подробная документация по развертыванию
- [EXTERNAL_ACCESS.md](EXTERNAL_ACCESS.md) - Настройка внешнего доступа
- [swarm_cheat_sheet.md](swarm_cheat_sheet.md) - Шпаргалка по Docker Swarm

## 🔐 Безопасность

**⚠️ ВАЖНО:** Текущая конфигурация **отключает аутентификацию** (`ARANGO_NO_AUTH=1`)

Это подходит для:
- ✅ Локальной разработки
- ✅ Тестирования
- ✅ Обучения

**Для продакшена включите аутентификацию:**

Удалите `ARANGO_NO_AUTH=1` и добавьте пароль в `docker-stack.yml`:
```yaml
environment:
  - ARANGO_ROOT_PASSWORD=your_secure_password
```

## 🎯 Примеры использования

### Создание базы данных

```bash
# Через API
curl -X POST http://localhost:8529/_api/database \
  -H "Content-Type: application/json" \
  -d '{"name": "mydb"}'
```

### Создание коллекции

```bash
curl -X POST http://localhost:8529/_db/mydb/_api/collection \
  -H "Content-Type: application/json" \
  -d '{"name": "users"}'
```

### Вставка документа

```bash
curl -X POST http://localhost:8529/_db/mydb/_api/document/users \
  -H "Content-Type: application/json" \
  -d '{"name": "John Doe", "age": 30}'
```

## 🔧 Устранение неполадок

### Порт 8529 занят

Измените порт в `Vagrantfile`:
```ruby
node.vm.network "forwarded_port", guest: 8529, host: 8530, host_ip: "127.0.0.1"
```

### Сервисы не запускаются

```bash
# Проверить логи
vagrant ssh node1 -c "docker service logs arango_arango-coordinator"

# Перезапустить стек
vagrant ssh node1 -c "cd /vagrant && docker stack rm arango && sleep 15 && docker stack deploy -c docker-stack.yml arango"
```

### Нода Down в Swarm

```bash
# Проверить статус Docker на проблемной ноде
vagrant ssh node2 -c "systemctl status docker"

# Перезапустить ноду
vagrant reload node2
```

## 🤝 Дополнительные возможности

### Масштабирование координаторов

```bash
vagrant ssh node1 -c "docker service scale arango_arango-coordinator=5"
```

### Обновление версии ArangoDB

1. Измените версию в `docker-stack.yml`:
   ```yaml
   image: arangodb/arangodb:3.11.1
   ```

2. Обновите стек:
   ```bash
   vagrant ssh node1 -c "cd /vagrant && docker stack deploy -c docker-stack.yml arango"
   ```

### Резервное копирование

```bash
# Создать бэкап
vagrant ssh node1 -c "docker exec \$(docker ps -qf name=coordinator) arangodump --server.endpoint tcp://localhost:8529 --output-directory /backup"
```

## 📖 Дополнительная информация

- [ArangoDB Documentation](https://www.arangodb.com/docs/stable/)
- [Docker Swarm Documentation](https://docs.docker.com/engine/swarm/)
- [Vagrant Documentation](https://www.vagrantup.com/docs)

## 📝 Лицензия

Этот проект создан в образовательных целях.

---

**Автор:** DevOps практикум  
**Версия:** 1.0  
**ArangoDB:** 3.8.9  
**Docker Swarm:** Native mode
