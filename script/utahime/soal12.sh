#!/bin/bash
echo "Menambahkan A Record, CNAME, PTR, dan Forwarder di utahime..."

# Asumsi IP Gojo (UBAH JIKA BERBEDA)
IP_GOJO="10.78.1.4"
OCTET_TERAKHIR="4"  # Angka terakhir dari IP Gojo (dari 10.78.1.4)

# 1. Menambahkan Forwarder ke 192.168.122.1
cat << 'EOF' > /etc/bind/named.conf.options
options {
    directory "/var/cache/bind";
    
    forwarders {
        192.168.122.1;
    };
    
    allow-query { any; };
    dnssec-validation no;
    listen-on-v6 { any; };
};
EOF

# 2. Update File Zona Forward (Menambahkan A record Gojo & CNAME www)
# Perhatikan Serial dinaikkan menjadi 2026101503
cat << 'EOF' > /etc/bind/jujutsu/jujutsu.k29.com
$TTL    604800
@       IN      SOA     utahime.jujutsu.k29.com. root.jujutsu.k29.com. (
                              2026101503 ; Serial
                              604800     ; Refresh
                              86400      ; Retry
                              2419200    ; Expire
                              604800 )   ; Negative Cache TTL
;
@       IN      NS      utahime.jujutsu.k29.com.
@       IN      NS      shoko.jujutsu.k29.com.
@       IN      A       10.78.1.4
www     IN      CNAME   jujutsu.k29.com.
gojo    IN      A       10.78.1.4
utahime IN      A       10.78.1.2
shoko   IN      A       10.78.1.3
EOF

# 3. Mendaftarkan Zona Reverse di named.conf.local
# Jika IP Gojo 10.78.1.4, maka zona reverse-nya adalah 1.78.10.in-addr.arpa
cat << 'EOF' > /etc/bind/named.conf.local
zone "jujutsu.k29.com" {
    type master;
    file "/etc/bind/jujutsu/jujutsu.k29.com";
    allow-transfer { 10.78.1.3; };
};

zone "1.78.10.in-addr.arpa" {
    type master;
    file "/etc/bind/jujutsu/10.78.1.rev";
};
EOF

# 4. Membuat File Zona Reverse (PTR)
cat << 'EOF' > /etc/bind/jujutsu/10.78.1.rev
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
4       IN      PTR     jujutsu.k29.com.
EOF

# Restart Layanan BIND9 (named)
service named restart

echo "Konfigurasi Soal 12 Selesai. Status BIND9:"
service named status
