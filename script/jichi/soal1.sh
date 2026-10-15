#!/bin/bash
echo "Konfigurasi jichi dimulai..."

dhclient -v eth0

ip addr flush dev eth1; ip addr add 10.78.1.1/24 dev eth1; ip link set eth1 up
ip addr flush dev eth2; ip addr add 10.78.2.1/24 dev eth2; ip link set eth2 up
ip addr flush dev eth3; ip addr add 10.78.3.1/24 dev eth3; ip link set eth3 up
ip addr flush dev eth4; ip addr add 10.78.4.1/24 dev eth4; ip link set eth4 up

echo 1 > /proc/sys/net/ipv4/ip_forward
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf

apt-get update
apt-get install -y iptables

iptables -t nat -F
iptables -F FORWARD
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -P FORWARD ACCEPT

echo "Konfigurasi jichi selesai."
