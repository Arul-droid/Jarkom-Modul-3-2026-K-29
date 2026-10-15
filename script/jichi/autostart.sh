#!/bin/bash
# Autostart konfigurasi IP dan DHCP Relay pada jichi pasca-reboot (Soal 10)
echo "/root/soal1.sh" >> /root/.bashrc
echo "service isc-dhcp-relay start" >> /root/.bashrc
echo "Autostart jichi berhasil ditambahkan ke /root/.bashrc"
