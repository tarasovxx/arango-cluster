#!/bin/bash

# Скрипт для очистки существующих VM и сетей VirtualBox
# Использование: ./cleanup-vbox.sh

set -e

echo "=== Очистка VirtualBox окружения ==="

# Остановка и удаление существующих VM
echo "1. Остановка и удаление существующих VM..."
if vagrant status | grep -q "running"; then
    echo "Остановка VM..."
    vagrant halt
fi

if vagrant status | grep -q "created"; then
    echo "Удаление VM..."
    vagrant destroy -f
fi

# Удаление существующих host-only сетей VirtualBox
echo ""
echo "2. Очистка host-only сетей VirtualBox..."

# Получение списка host-only сетей
HOST_ONLY_NETS=$(VBoxManage list hostonlyifs | grep "Name:" | awk '{print $2}' || true)

if [ -n "$HOST_ONLY_NETS" ]; then
    echo "Найденные host-only сети:"
    echo "$HOST_ONLY_NETS"
    
    for net in $HOST_ONLY_NETS; do
        echo "Удаление сети: $net"
        VBoxManage hostonlyif remove "$net" 2>/dev/null || echo "Не удалось удалить сеть $net (возможно, используется)"
    done
else
    echo "Host-only сети не найдены"
fi

# Очистка NAT сетей
echo ""
echo "3. Очистка NAT сетей..."
NAT_NETS=$(VBoxManage list natnets | grep "NetworkName:" | awk '{print $2}' || true)

if [ -n "$NAT_NETS" ]; then
    echo "Найденные NAT сети:"
    echo "$NAT_NETS"
    
    for net in $NAT_NETS; do
        if [[ "$net" == *"arango"* ]]; then
            echo "Удаление NAT сети: $net"
            VBoxManage natnet remove --netname "$net" 2>/dev/null || echo "Не удалось удалить NAT сеть $net"
        fi
    done
else
    echo "NAT сети не найдены"
fi

# Очистка DHCP серверов
echo ""
echo "4. Очистка DHCP серверов..."
DHCP_SERVERS=$(VBoxManage list dhcpservers | grep "NetworkName:" | awk '{print $2}' || true)

if [ -n "$DHCP_SERVERS" ]; then
    echo "Найденные DHCP серверы:"
    echo "$DHCP_SERVERS"
    
    for server in $DHCP_SERVERS; do
        if [[ "$server" == *"arango"* ]] || [[ "$server" == *"192.168.56"* ]]; then
            echo "Удаление DHCP сервера: $server"
            VBoxManage dhcpserver remove --network "$server" 2>/dev/null || echo "Не удалось удалить DHCP сервер $server"
        fi
    done
else
    echo "DHCP серверы не найдены"
fi

# Очистка файлов Vagrant
echo ""
echo "5. Очистка файлов Vagrant..."
if [ -d ".vagrant" ]; then
    echo "Удаление директории .vagrant..."
    rm -rf .vagrant
fi

echo ""
echo "=== Очистка завершена ==="
echo ""
echo "Теперь можно запустить развертывание:"
echo "  ./scripts/deploy-cluster.sh"
echo "  или"
echo "  make deploy"
