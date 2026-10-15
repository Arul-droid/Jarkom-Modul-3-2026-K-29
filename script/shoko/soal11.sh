#!/bin/bash
echo "Konfigurasi DNS Slave (shoko)..."

apt-get update
apt-get install -y bind9 bind9utils

# Konfigurasi zona slave yang menunjuk ke IP utahime
cat << 'EOF' > /etc/bind/named.conf.local
zone "jujutsu.k29.com" {
    type slave;
    masters { 10.78.1.2; };
    file "/var/lib/bind/jujutsu.k29.com";
};
EOF

# Menjalankan layanan menggunakan nama 'named'
service named restart

echo "Status Layanan DNS Slave:"
ps aux | grep named | grep -v grep
