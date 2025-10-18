# 🚀 Быстрый старт ArangoDB кластера

Полное руководство по запуску кластера ArangoDB на Docker Swarm с использованием Vagrant и VirtualBox.

## ⚙️ Предварительные требования

### Необходимое ПО:
- **Vagrant** 2.0+ - [Скачать](https://www.vagrantup.com/downloads)
- **VirtualBox** 6.0+ - [Скачать](https://www.virtualbox.org/wiki/Downloads)
- **Git** (опционально) - для клонирования репозитория

### Системные требования:
- **RAM:** Минимум 6GB свободной оперативной памяти
- **CPU:** 6+ ядер (для 3 VM по 2 ядра каждая)
- **Диск:** ~15GB свободного места
- **Порты:** 8529 должен быть свободен на хост-машине

### Проверка:
```bash
# Проверить версию Vagrant
vagrant --version
# Ожидаемый вывод: Vagrant 2.x.x

# Проверить VirtualBox
vboxmanage --version
# Ожидаемый вывод: 6.x.x или 7.x.x

# Проверить свободный порт
# Windows PowerShell:
netstat -an | findstr :8529

# Linux/Mac:
lsof -i :8529
# Порт должен быть свободен (команда не должна ничего вернуть)
```

---

## 📦 Шаг 1: Получение проекта

```bash
# Клонировать репозиторий
git clone <your-repository-url>
cd arango_devops

# Или скачать архив и распаковать
```

---

## 🚀 Шаг 2: Запуск кластера

### Автоматический запуск всех нод:

```bash
# Из корневой директории проекта
vagrant up
```

Это займет **5-7 минут** при первом запуске:
1. ⏬ Скачивание Ubuntu 22.04 образа (~500MB, только первый раз)
2. 🖥️ Создание 3 виртуальных машин
3. 🐳 Установка Docker на каждой ноде
4. 📦 Предзагрузка образа ArangoDB 3.8.9
5. 🔧 Инициализация Docker Swarm кластера
6. 🚀 Развертывание стека ArangoDB

### Что происходит:

```
┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│  node1      │  │  node2      │  │  node3      │
│  (Manager)  │  │  (Worker)   │  │  (Worker)   │
│  .11        │  │  .12        │  │  .13        │
└─────────────┘  └─────────────┘  └─────────────┘
      ↓                ↓                ↓
┌──────────────────────────────────────────────┐
│         Docker Swarm Cluster                 │
│  ┌────────┐  ┌────────┐  ┌────────┐         │
│  │ Agent  │  │ Agent  │  │ Agent  │         │
│  └────────┘  └────────┘  └────────┘         │
│  ┌────────┐  ┌────────┐  ┌────────┐         │
│  │DBServer│  │DBServer│  │DBServer│         │
│  └────────┘  └────────┘  └────────┘         │
│  ┌────────┐  ┌────────┐  ┌────────┐         │
│  │Coord   │  │Coord   │  │Coord   │         │
│  └────────┘  └────────┘  └────────┘         │
└──────────────────────────────────────────────┘
```

---

## ✅ Шаг 3: Проверка развертывания

### 3.1 Проверить статус виртуальных машин:

```bash
vagrant status
```

**Ожидаемый результат:**
```
Current machine states:

node1                     running (virtualbox)
node2                     running (virtualbox)
node3                     running (virtualbox)
```

### 3.2 Проверить Docker Swarm:

```bash
vagrant ssh node1 -c "docker node ls"
```

**Ожидаемый результат:**
```
ID                            HOSTNAME       STATUS    AVAILABILITY   MANAGER STATUS
xxx *                         arango-node1   Ready     Active         Leader
xxx                           arango-node2   Ready     Active
xxx                           arango-node3   Ready     Active
```

### 3.3 Проверить сервисы ArangoDB:

```bash
vagrant ssh node1 -c "docker service ls"
```

**Ожидаемый результат:**
```
NAME                        MODE         REPLICAS
arango_arango-agent-1       replicated   1/1
arango_arango-agent-2       replicated   1/1
arango_arango-agent-3       replicated   1/1
arango_arango-coordinator   replicated   3/3 (max 1 per node)
arango_arango-dbserver      replicated   3/3 (max 1 per node)
```

---

## 🌐 Шаг 4: Доступ к кластеру

### Через браузер:

Откройте в браузере:
```
http://localhost:8529
```

### Веб-интерфейс ArangoDB:

```
http://localhost:8529/_db/_system/_admin/aardvark/index.html
```

**Вход:**
- **Username:** оставьте пустым или введите `root`
- **Password:** оставьте пустым
- Нажмите **Login**

### Через API:

```bash
# Проверить версию
curl http://localhost:8529/_api/version

# Проверить здоровье кластера
curl http://localhost:8529/_admin/cluster/health

# Список координаторов
curl http://localhost:8529/_admin/cluster/endpoints
```

---

## 📊 Шаг 5: Тестирование кластера

### Создать базу данных:

```bash
curl -X POST http://localhost:8529/_api/database \
  -H "Content-Type: application/json" \
  -d '{"name": "testdb"}'
```

### Создать коллекцию:

```bash
curl -X POST http://localhost:8529/_db/testdb/_api/collection \
  -H "Content-Type: application/json" \
  -d '{"name": "users", "replicationFactor": 2, "numberOfShards": 3}'
```

### Вставить документы:

```bash
# Добавить пользователя
curl -X POST http://localhost:8529/_db/testdb/_api/document/users \
  -H "Content-Type: application/json" \
  -d '{"name": "Alice", "age": 30, "city": "Moscow"}'

curl -X POST http://localhost:8529/_db/testdb/_api/document/users \
  -H "Content-Type: application/json" \
  -d '{"name": "Bob", "age": 25, "city": "SPB"}'
```

### Выполнить AQL запрос:

```bash
curl -X POST http://localhost:8529/_db/testdb/_api/cursor \
  -H "Content-Type: application/json" \
  -d '{"query": "FOR u IN users RETURN u"}'
```

---

## 🎮 Управление кластером

### Просмотр логов:

```bash
# Логи координаторов
vagrant ssh node1 -c "docker service logs arango_arango-coordinator"

# Логи DBServers
vagrant ssh node1 -c "docker service logs arango_arango-dbserver"

# Логи агентов
vagrant ssh node1 -c "docker service logs arango_arango-agent-1"
```

### Масштабирование:

```bash
# Увеличить количество координаторов до 5
vagrant ssh node1 -c "docker service scale arango_arango-coordinator=5"

# Вернуть обратно
vagrant ssh node1 -c "docker service scale arango_arango-coordinator=3"
```

### Перезапуск стека:

```bash
vagrant ssh node1 -c "cd /vagrant && docker stack rm arango && sleep 15 && docker stack deploy -c docker-stack.yml arango"
```

### Остановка кластера:

```bash
# Остановить все VM (можно будет возобновить)
vagrant halt

# Удалить все VM (полная очистка)
vagrant destroy -f

# Удалить конкретную ноду
vagrant destroy node2 -f
```

---

## 🔧 Устранение проблем

### Проблема: Порт 8529 занят

**Решение:** Измените порт в `Vagrantfile`

```ruby
# Найдите строку:
node.vm.network "forwarded_port", guest: 8529, host: 8529, host_ip: "127.0.0.1"

# Замените на:
node.vm.network "forwarded_port", guest: 8529, host: 8530, host_ip: "127.0.0.1"
```

Затем:
```bash
vagrant reload node1
```

Теперь доступ будет через `http://localhost:8530`

### Проблема: Не все сервисы запустились

**Проверка:**
```bash
vagrant ssh node1 -c "docker service ls"
```

**Решение:**
```bash
# Посмотреть ошибки
vagrant ssh node1 -c "docker service ps arango_arango-coordinator --no-trunc"

# Проверить логи
vagrant ssh node1 -c "docker service logs arango_arango-coordinator"

# Перезапустить
vagrant ssh node1 -c "cd /vagrant && docker stack rm arango && sleep 15 && docker stack deploy -c docker-stack.yml arango"
```

### Проблема: Нода Down в Swarm

**Проверка:**
```bash
vagrant ssh node1 -c "docker node ls"
```

**Решение:**
```bash
# Перезапустить проблемную ноду
vagrant reload node2

# Проверить Docker
vagrant ssh node2 -c "systemctl status docker"
```

### Проблема: Недостаточно памяти

**Решение:** Уменьшите выделенную память в `Vagrantfile`

```ruby
vb.memory = "1536"  # Вместо 2048
```

Затем:
```bash
vagrant reload
```

---

## 📚 Дальнейшие шаги

1. **Изучите веб-интерфейс:** Откройте http://localhost:8529 и изучите разделы:
   - Databases - создание баз данных
   - Collections - создание коллекций
   - Queries - выполнение AQL запросов
   - Graphs - работа с графами
   - Cluster - информация о кластере

2. **Почитайте документацию:**
   - [DEPLOYMENT.md](DEPLOYMENT.md) - детальная документация
   - [EXTERNAL_ACCESS.md](EXTERNAL_ACCESS.md) - настройка доступа
   - [swarm_cheat_sheet.md](swarm_cheat_sheet.md) - Docker Swarm команды

3. **Включите аутентификацию** для безопасности (см. README.md)

4. **Попробуйте работать с графами** - сильная сторона ArangoDB

---

## 💡 Полезные команды

```bash
# SSH в ноды
vagrant ssh node1
vagrant ssh node2
vagrant ssh node3

# Обновить код на нодах
vagrant rsync

# Проверить использование ресурсов
vagrant ssh node1 -c "docker stats --no-stream"

# Резервное копирование (бэкап)
vagrant ssh node1 -c "docker exec \$(docker ps -qf name=coordinator | head -1) arangodump --output-directory /backup"

# Полная статистика кластера
vagrant ssh node1 -c "curl -s http://localhost:8529/_admin/cluster/statistics | jq ."
```

---

## 🎉 Готово!

Ваш кластер ArangoDB готов к работе! Вы можете:
- Создавать базы данных и коллекции
- Выполнять AQL запросы
- Работать с графами
- Тестировать отказоустойчивость
- Масштабировать координаторы

**Удачи в работе с ArangoDB!** 🚀

---

📖 **Нужна помощь?** Смотрите полную документацию в [DEPLOYMENT.md](DEPLOYMENT.md)
