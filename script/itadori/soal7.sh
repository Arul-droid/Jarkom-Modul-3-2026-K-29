#!/bin/bash
echo "=== VALIDASI KONFIGURASI JARINGAN CLIENT (SOAL 7) ==="

echo -e "\n1. IP Address, Subnet Mask (/24), dan Broadcast:"
ip a show eth0

echo -e "\n2. Tabel Routing (Default Gateway):"
ip route

echo -e "\n3. Konfigurasi DNS Server dan Domain:"
cat /etc/resolv.conf

echo -e "\n=== VALIDASI SELESAI ==="
