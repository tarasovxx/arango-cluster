# 🚀 Быстрый старт ArangoDB кластера

## Предварительные требования

- ✅ Vagrant 2.0+
- ✅ VirtualBox 6.0+
- ✅ Минимум 6GB RAM
- ✅ Порты 80, 443, 8080 свободны

## Запуск одной командой

```bash
# Клонируйте репозиторий и перейдите в директорию
cd arango_devops

# Запустите полное развертывание
make deploy
```

## Альтернативный способ

```bash
# Или используйте скрипт напрямую
chmod +x scripts/*.sh
./scripts/deploy-cluster.sh
```

## После развертывания

1. **Получите IP manager ноды:**
   ```bash
   vagrant ssh node1 -c "hostname -I | awk '{print \$1}'"
   ```

2. **Добавьте в hosts файл:**
   ```bash
   # Linux/Mac: /etc/hosts
   # Windows: C:\Windows\System32\drivers\etc\hosts
   <MANAGER_IP> arango.localhost traefik.localhost
   ```

3. **Доступ к сервисам:**
   - ArangoDB: http://arango.localhost
   - Traefik Dashboard: http://traefik.localhost:8080

## Основные команды

```bash
# Статус кластера
make status

# Проверка здоровья
make health

# Тестирование
make test

# Логи
make logs

# Масштабирование
make scale-coordinator REPLICAS=5

# Rolling update
make update-coordinator VERSION=3.11.1

# Остановка
make clean-stack
```

## Устранение неполадок

```bash
# Перезапуск кластера
make restart

# Полная очистка
make clean

# Подключение к ноде
make ssh-manager
```

## Помощь

```bash
make help
make examples
```

---
📖 **Подробная документация:** [DEPLOYMENT.md](DEPLOYMENT.md)
