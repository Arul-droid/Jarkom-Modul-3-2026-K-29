#!/bin/bash
echo "Memulai konfigurasi Multi-Pool DHCP pada tengen..."

cat << 'CONF' > /etc/dhcp/dhcpd.conf
# Konfigurasi Global
default-lease-time 600;
max-lease-time 7200;
authoritative;

# ----------------- KELAS MAC ADDRESS -----------------
# Kelas untuk Tim Dev (itadori, fushiguro)
class "tim-dev" {
    match hardware;
}
# UBAH MAC ADDRESS DI BAWAH INI (biarkan angka 1: di depannya)
subclass "tim-dev" 1:02:42:24:21:1a:00; # MAC itadori
subclass "tim-dev" 1:02:42:30:24:4c:00; # MAC fushiguro

# Kelas untuk Tim Support (zenin, okkotsu)
class "tim-support" {
    match hardware;
}
# UBAH MAC ADDRESS DI BAWAH INI (biarkan angka 1: di depannya)
subclass "tim-support" 1:02:42:28:b9:c0:00; # MAC zenin
subclass "tim-support" 1:02:42:d3:fe:e9:00; # MAC okkotsu

# ----------------- DEKLARASI SUBNET -----------------
# Deklarasi Network 4 (Subnet Lokal tengen)
subnet 10.78.4.0 netmask 255.255.255.0 {
}

# Deklarasi Scope Network 2 (Divisi A) dengan Multi-Pool
subnet 10.78.2.0 netmask 255.255.255.0 {
    option routers 10.78.2.1;
    option domain-name-servers 192.168.122.1;

    # Pool 1: Khusus untuk member kelas "tim-dev"
    pool {
        allow members of "tim-dev";
        range 10.78.2.10 10.78.2.35;
    }

    # Pool 2: Khusus untuk member kelas "tim-support"
    pool {
        allow members of "tim-support";
        range 10.78.2.70 10.78.2.95;
    }
}

# Deklarasi Scope Network 3 (Divisi B)
subnet 10.78.3.0 netmask 255.255.255.0 {
    range 10.78.3.10 10.78.3.100;
    option routers 10.78.3.1;
    option domain-name-servers 192.168.122.1;
}
CONF

# Restart layanan
service isc-dhcp-server restart
echo "Status isc-dhcp-server:"
service isc-dhcp-server status
