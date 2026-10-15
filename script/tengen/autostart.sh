#!/bin/bash
# Autostart DHCP Server pada tengen pasca-reboot (Soal 10)
echo "service isc-dhcp-server start" >> /root/.bashrc
echo "Autostart tengen berhasil ditambahkan ke /root/.bashrc"
