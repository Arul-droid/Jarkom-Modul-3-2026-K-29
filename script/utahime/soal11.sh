#!/bin/bash
echo "Konfigurasi DNS Master (utahime)..."

apt-get update
apt-get install -y bind9 bind9utils

# Konfigurasi zona master dan allow-transfer ke IP shoko
cat << 'EOF' > /etc/bind/named.conf.local
zone "jujutsu.k29.com" {
    type master;
    file "/etc/bind/jujutsu/jujutsu.k29.com";
    allow-transfer { 10.78.1.3; };
};
EOF

# Membuat direktori dan file zona
mkdir -p /etc/bind/jujutsu
cat << 'EOF' > /etc/bind/jujutsu/jujutsu.k29.com
$TTL    604800
@       IN      SOA     utahime.jujutsu.k29.com. root.jujutsu.k29.com. (
                              2026101501 ; Serial
                              604800     ; Refresh
                              86400      ; Retry
                              2419200    ; Expire
                              604800 )   ; Negative Cache TTL
;
@       IN      NS      utahime.jujutsu.k29.com.
@       IN      NS      shoko.jujutsu.k29.com.
utahime IN      A       10.78.1.2
shoko   IN      A       10.78.1.3
EOF

# Menjalankan layanan menggunakan nama 'named'
service named restart

echo "Status Layanan DNS Master:"
ps aux | grep named | grep -v grep
