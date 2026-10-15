#!/bin/bash
echo "=== PACKET CAPTURE PROTOKOL DORA DHCP (SOAL 8) ==="

# Instal tcpdump jika belum ada
apt-get update
apt-get install -y tcpdump

echo -e "\n[MENUNGGU PAKET DHCP...]"
echo "Buka terminal client (misal: itadori di Divisi A atau ino di Divisi B)."
echo "Jalankan perintah ini di client: ip addr flush dev eth0 && udhcpc -i eth0"
echo -e "Tekan Ctrl+C di sini untuk berhenti jika client sudah dapat IP.\n"
echo "------------------------------------------------------------------"

# Menjalankan tcpdump pada port 67 dan 68 (port standar DHCP) dengan output detail (-vvv)
tcpdump -i eth0 -n -vvv port 67 or port 68
