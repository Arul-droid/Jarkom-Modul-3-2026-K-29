#!/bin/bash

# 1. Set nameserver awal untuk instalasi paket
echo "nameserver 192.168.122.1" > /etc/resolv.conf

# 2. Instalasi Nginx, PHP-FPM, dan ekstensi PHP-MySQL
apt-get update
apt-get install -y nginx php-fpm php-mysql

# 3. Deteksi otomatis socket PHP-FPM
PHP_SOCK=$(find /run/php/ -name "php*-fpm.sock" | head -n 1)
if [ -z "$PHP_SOCK" ]; then
    for svc in $(service --status-all 2>&1 | grep -o 'php.*-fpm'); do
        service "$svc" start
    done
    PHP_SOCK=$(find /run/php/ -name "php*-fpm.sock" | head -n 1)
fi
echo "Menggunakan PHP Socket: $PHP_SOCK"

# 4. Sesuaikan IP Yaga (DB Master) dan IP Geto (Internal Load Balancer)
IP_YAGA="10.78.4.9"
IP_GETO="10.78.4.2"

# 5. Buat skrip API PHP yang mencatat log ke database yaga
mkdir -p /var/www/jujutsu
cat << PHP > /var/www/jujutsu/index.php
<?php
header('Content-Type: application/json');

\$worker_name = gethostname();
\$trusted_proxy = '${IP_GETO}';
\$remote_addr = \$_SERVER['REMOTE_ADDR'] ?? '0.0.0.0';

// Ambil IP asli klien HANYA jika trafik berasal dari proxy terpercaya (geto)
\$client_ip = \$remote_addr;
if (\$remote_addr === \$trusted_proxy || \$remote_addr === '127.0.0.1') {
    if (!empty(\$_SERVER['HTTP_X_REAL_IP'])) {
        \$client_ip = trim(\$_SERVER['HTTP_X_REAL_IP']);
    } elseif (!empty(\$_SERVER['HTTP_X_FORWARDED_FOR'])) {
        \$ip_list = explode(',', \$_SERVER['HTTP_X_FORWARDED_FOR']);
        \$client_ip = trim(\$ip_list[0]);
    }
}

// Koneksi ke MariaDB Master (yaga) sesuai kredensial Soal 13
\$db_host = '${IP_YAGA}';
\$db_user = 'shibuya_app';
\$db_pass = 'shibuya_pass';
\$db_name = 'db_shibuya_k29';

\$mysqli = @new mysqli(\$db_host, \$db_user, \$db_pass, \$db_name);

if (\$mysqli->connect_error) {
    http_response_code(500);
    echo json_encode([
        'status' => 'error',
        'worker' => \$worker_name,
        'message' => 'DB Connection Failed: ' . \$mysqli->connect_error
    ]);
    exit;
}

\$stmt = \$mysqli->prepare("INSERT INTO request_logs (worker_name, client_ip) VALUES (?, ?)");
\$stmt->bind_param("ss", \$worker_name, \$client_ip);
\$stmt->execute();
\$insert_id = \$stmt->insert_id;
\$stmt->close();
\$mysqli->close();

echo json_encode([
    'status' => 'success',
    'worker' => \$worker_name,
    'client_ip' => \$client_ip,
    'log_id' => \$insert_id
]) . "\n";
?>
PHP
chown -R www-data:www-data /var/www/jujutsu

# 6. Konfigurasi Virtual Host & Pembatasan Akses (Hanya izinkan dari geto)
cat << NGINX > /etc/nginx/sites-available/jujutsu_api
# Blokir request dengan Host header yang tidak dikenal
server {
    listen 80 default_server;
    server_name _;
    return 444;
}

# Virtual Host Layanan API
server {
    listen 80;
    server_name jujutsu.k29.com www.jujutsu.k29.com api.jujutsu.k29.com api_cluster geto ${IP_GETO};

    root /var/www/jujutsu;
    index index.php;

    # Batasi akses: Worker API hanya menerima trafik melalui geto
    allow ${IP_GETO};
    allow 127.0.0.1;
    deny all;

    # Hanya percaya header IP klien yang dikirim oleh geto (Soal 17)
    set_real_ip_from ${IP_GETO};
    real_ip_header X-Real-IP;
    real_ip_recursive on;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location /api {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:${PHP_SOCK};
    }
}
NGINX

# 7. Aktifkan konfigurasi dan restart service
rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/jujutsu_api /etc/nginx/sites-enabled/jujutsu_api

PHP_SVC=$(service --status-all 2>&1 | grep -o 'php.*-fpm' | head -n 1)
service "\$PHP_SVC" restart
nginx -t && service nginx restart
