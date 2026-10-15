#!/bin/bash
echo "Memulai konfigurasi Lease Time dan Options pada tengen..."

cat << 'CONF' > /etc/dhcp/dhcpd.conf
# Konfigurasi Global
default-lease-time 600;
max-lease-time 7200;
authoritative;

# ----------------- KELAS NETWORK 2 (Soal 4) -----------------
class "tim-dev" { match hardware; }
subclass "tim-dev" 1:02:42:24:21:1a:00; # MAC itadori
subclass "tim-dev" 1:02:42:30:24:4c:00; # MAC fushiguro

class "tim-support" { match hardware; }
subclass "tim-support" 1:02:42:28:b9:c0:00; # MAC zenin
subclass "tim-support" 1:02:42:d3:fe:e9:00; # MAC okkotsu

# ----------------- KELAS NETWORK 3 (Soal 5) -----------------
class "short-lease" { match hardware; }
subclass "short-lease" 1:02:42:8a:f1:0f:00; # MAC ino
subclass "short-lease" 1:02:42:a5:de:b3:00; # MAC kusakabe

class "long-lease" { match hardware; }
subclass "long-lease" 1:02:42:80:41:bf:00; # MAC miwa

# ----------------- DEKLARASI SUBNET -----------------
# Deklarasi Network 4
subnet 10.78.4.0 netmask 255.255.255.0 {
}

# Deklarasi Network 2 (Divisi A)
subnet 10.78.2.0 netmask 255.255.255.0 {
    option routers 10.78.2.1;
    option domain-name-servers 192.168.122.1;

    pool {
        allow members of "tim-dev";
        range 10.78.2.10 10.78.2.35;
    }
    pool {
        allow members of "tim-support";
        range 10.78.2.70 10.78.2.95;
    }
}

# Deklarasi Network 3 (Divisi B)
subnet 10.78.3.0 netmask 255.255.255.0 {
    option routers 10.78.3.1;
    
    # DHCP Options Spesifik Network 3
    option domain-name-servers 10.78.1.2, 10.78.1.3;
    option domain-name "k29.com";

    # Pool 1: Short Lease (30 menit = 1800 detik)
    pool {
        allow members of "short-lease";
        range 10.78.3.10 10.78.3.89;
        default-lease-time 1800;
        max-lease-time 1800;
    }

    # Pool 2: Long Lease (12 jam = 43200 detik)
    pool {
        allow members of "long-lease";
        range 10.78.3.100 10.78.3.199;
        default-lease-time 43200;
        max-lease-time 43200;
    }
}
CONF

# Restart layanan DHCP Server
service isc-dhcp-server restart
echo "Status isc-dhcp-server:"
service isc-dhcp-server status
