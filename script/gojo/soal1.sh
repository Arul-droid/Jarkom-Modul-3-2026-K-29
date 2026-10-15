#!/bin/bash
echo "Konfigurasi IP Statis gojo..."
ip addr flush dev eth0
ip addr add 10.78.1.4/24 dev eth0
ip link set eth0 up
ip route add default via 10.78.1.1
echo "nameserver 192.168.122.1" > /etc/resolv.conf

echo "Test koneksi ke internet:"
ping -c 3 8.8.8.8
