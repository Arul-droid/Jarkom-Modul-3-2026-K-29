#!/bin/bash
# Skrip konfigurasi untuk node gojo (Modul 3 - Kelompok K29)

# 1. Pastikan nameserver awal aktif untuk instalasi paket
echo "nameserver 192.168.122.1" > /etc/resolv.conf

# 2. Instalasi Nginx
apt-get update
apt-get install -y nginx

# 3. Variabel IP Backend
IP_MAKI="10.78.4.12"
IP_PANDA="10.78.4.13"
IP_GETO="10.78.4.2"

# 4. Buat konfigurasi Reverse Proxy untuk jujutsu.k29.com
cat <<EOF > /etc/nginx/sites-available/jujutsu.k29.com
upstream frontend_workers {
    # Round Robin ke worker frontend (Maki & Panda)
    server ${IP_MAKI}:80;
    server ${IP_PANDA}:80;
}

server {
    listen 80;
    server_name jujutsu.k29.com www.jujutsu.k29.com;

    # Routing untuk halaman utama (Frontend: Maki & Panda)
    location / {
        proxy_pass http://frontend_workers;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Path-Based Routing untuk /api (Diteruskan langsung ke Geto)
    location /api {
        proxy_pass http://${IP_GETO};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# 5. Aktifkan site dan hapus default vhost agar tidak bentrok
ln -sf /etc/nginx/sites-available/jujutsu.k29.com /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# 6. Uji sintaks dan muat ulang layanan Nginx
nginx -t && service nginx restart
