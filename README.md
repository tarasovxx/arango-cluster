# ArangoDB Docker Swarm Cluster

1) Автоматизация развертывания кластера Docker Swarm(минимум на 3х виртуальных машинах) и самого мультисервисного приложения.
2) Используя возможности Docker Swarm обеспечить отказоустойчивость и балансировку нагрузки. Также допускается использование обратного прокси-сервера Traefik/Nginx/HAproxy.
3) Реализовать автоматизацию обновлений всех сервисов кластера с помощью https://docs.docker.com/engine/swarm/swarm-tutorial/rolling-update/
4) В качестве средств автоматизации допускается использование инструментов Vagrant/Bash/Puppet/Chef/Ansible/Salt.
5) При необходимости допускается использование локального сервера Docker Registry
6) Все секреты (пароли, токены и т.д) должны передаваться через Docker Secrets. Понятно что не все сервисы из коробки данную функцию поддерживают. Поэтому допускается модификация образа для реализации данного требования.  


https://arango.ai/blog/deploying-and-securing-an-arangodb-cluster-using-docker/

vagrant@arango-node1:/vagrant$ curl -i http://localhost:8529/_api/version 