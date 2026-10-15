#!/bin/bash

# 1. Set nameserver awal untuk instalasi paket
echo "nameserver 192.168.122.1" > /etc/resolv.conf

# 2. Instalasi Nginx dan PHP-FPM
apt-get update
apt-get install -y nginx php-fpm

# 3. Deteksi otomatis versi & socket PHP-FPM yang terpasang di debinet
PHP_SOCK=$(find /run/php/ -name "php*-fpm.sock" | head -n 1)
if [ -z "$PHP_SOCK" ]; then
    for svc in $(service --status-all 2>&1 | grep -o 'php.*-fpm'); do
        service "$svc" start
    done
    PHP_SOCK=$(find /run/php/ -name "php*-fpm.sock" | head -n 1)
fi
echo "Menggunakan PHP Socket: $PHP_SOCK"

# 4. Siapkan direktori dan file PHP Frontend (menampilkan hostname masing-masing)
mkdir -p /var/www/jujutsu
cat << 'PHP' > /var/www/jujutsu/index.php
<?php
header('Content-Type: text/html; charset=utf-8');
$worker = gethostname();
echo "<h1>Jujutsu High Frontend Worker</h1>";
echo "<p>Responded by: <strong>" . htmlspecialchars($worker) . "</strong></p>";
?>
PHP
chown -R www-data:www-data /var/www/jujutsu

# 5. Konfigurasi Virtual Host & Pembatasan Akses (Hanya izinkan dari gojo)
IP_GOJO="10.78.1.4"

cat << NGINX > /etc/nginx/sites-available/jujutsu
# Blokir request yang tidak menggunakan domain layanan resmi
server {
    listen 80 default_server;
    server_name _;
    return 444;
}

# Virtual Host Utama Frontend
server {
    listen 80;
    server_name jujutsu.k29.com www.jujutsu.k29.com;

    root /var/www/jujutsu;
    index index.php index.html;

    # Batasi akses: Hanya terima trafik melalui reverse proxy gojo
    allow 10.78.1.4;
    allow 127.0.0.1;
    deny all;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:${PHP_SOCK};
    }
}
NGINX

# 6. Aktifkan konfigurasi dan restart service
rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/jujutsu /etc/nginx/sites-enabled/jujutsu

PHP_SVC=$(service --status-all 2>&1 | grep -o 'php.*-fpm' | head -n 1)
service "$PHP_SVC" restart
nginx -t && service nginx restart
