# ArangoDB Docker Swarm Cluster

Автоматизированное развертывание кластера ArangoDB с использованием Docker Swarm на нескольких виртуальных машинах через Vagrant.

## ✅ Реализованные требования

1) ✅ **Автоматизация развертывания кластера Docker Swarm** на 3+ виртуальных машинах с мультисервисным приложением ArangoDB
2) ✅ **Отказоустойчивость и балансировка нагрузки** через Docker Swarm + Traefik обратный прокси
3) ✅ **Автоматизация rolling updates** всех сервисов кластера
4) ✅ **Средства автоматизации**: Vagrant + Bash скрипты
5) ✅ **Поддержка локального Docker Registry** (опционально)
6) ✅ **Управление секретами** через Docker Secrets

## 🚀 Быстрый старт

```bash
# Клонирование и запуск
git clone <repository-url>
cd arango_devops
chmod +x scripts/*.sh
./scripts/deploy-cluster.sh
```

## 📋 Архитектура

- **3 виртуальные машины** (Ubuntu 22.04 LTS)
- **ArangoDB кластер**: 3 Coordinator + 3 Agent + 3 DBServer ноды
- **Traefik** для балансировки нагрузки
- **Docker Secrets** для управления паролями
- **Rolling updates** для бесшовных обновлений

## 📖 Документация

Подробная документация доступна в [DEPLOYMENT.md](DEPLOYMENT.md)

## 🛠️ Управление

```bash
# Статус кластера
vagrant ssh node1 -c "sudo /opt/docker-swarm/scripts/cluster-manage.sh status"

# Rolling update
vagrant ssh node1 -c "sudo /opt/docker-swarm/scripts/rolling-update.sh arango-coordinator arangodb/arangodb:3.11.1"

# Масштабирование
vagrant ssh node1 -c "sudo /opt/docker-swarm/scripts/cluster-manage.sh scale arango-coordinator 5"
```

## 🌐 Доступ к сервисам

- **ArangoDB**: http://arango.localhost
- **Traefik Dashboard**: http://traefik.localhost:8080  


1) Автоматизация развертывания кластера Docker Swarm(минимум на 3х виртуальных машинах) и самого 
мультисервисного приложения.
2) Используя возможности Docker Swarm обеспечить отказоустойчивость и балансировку нагрузки. 
Также допускается использование обратного прокси-сервера Traefik/Nginx/HAproxy.
3) Реализовать автоматизацию обновлений всех сервисов кластера с помощью https://docs.docker.com/
engine/swarm/swarm-tutorial/rolling-update/
4) В качестве средств автоматизации допускается использование инструментов Vagrant/Bash/Puppet/
Chef/Ansible/Salt.
5) При необходимости допускается использование локального сервера Docker Registry
6) Все секреты (пароли, токены и т.д) должны передаваться через Docker Secrets. Понятно что не 
все сервисы из коробки данную функцию поддерживают. Поэтому допускается модификация образа для 
реализации данного требования. 