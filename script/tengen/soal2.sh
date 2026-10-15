#!/bin/bash
echo "Memulai konfigurasi DHCP Server pada tengen..."

# 1. Update dan instal DHCP Server
apt-get update
apt-get install -y isc-dhcp-server

# 2. Atur Interface DHCP agar mendengarkan di eth0
echo 'INTERFACESv4="eth0"' > /etc/default/isc-dhcp-server

# 3. Tulis ulang isi dhcpd.conf
cat << 'CONF' > /etc/dhcp/dhcpd.conf
# Konfigurasi Global
default-lease-time 600;
max-lease-time 7200;
authoritative;

# Deklarasi Network 4 (Subnet Lokal tengen)
subnet 10.78.4.0 netmask 255.255.255.0 {
}

# Deklarasi Scope Network 2 (Divisi A)
subnet 10.78.2.0 netmask 255.255.255.0 {
    range 10.78.2.10 10.78.2.100;
    option routers 10.78.2.1;
    option domain-name-servers 192.168.122.1;
}

# Deklarasi Scope Network 3 (Divisi B)
subnet 10.78.3.0 netmask 255.255.255.0 {
    range 10.78.3.10 10.78.3.100;
    option routers 10.78.3.1;
    option domain-name-servers 192.168.122.1;
}
CONF

# 4. Restart layanan dan tampilkan status
service isc-dhcp-server restart
echo "Status isc-dhcp-server:"
service isc-dhcp-server status
