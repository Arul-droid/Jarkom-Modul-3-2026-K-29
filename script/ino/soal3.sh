#!/bin/bash
# Hapus IP yang mungkin tersisa
ip addr flush dev eth0

# Panggil DHCP client bawaan Alpine (udhcpc)
udhcpc -i eth0

# Cek IP yang didapatkan
ip a show eth0
