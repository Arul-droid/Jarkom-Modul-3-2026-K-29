#!/bin/bash
# Konfigurasi Nginx Proxy Caching & Rate Limiting pada Gojo (Soal 19)
PREFIX_IP="10.78"
KELOMPOK="k29"
IP_GETO="${PREFIX_IP}.4.2"
IP_MAKI="${PREFIX_IP}.4.12"
IP_PANDA="${PREFIX_IP}.4.13"

# 1. Konfigurasi zona cache dan limit_req zone pada nginx.conf jika belum ada
cat << 'EOF' > /etc/nginx/conf.d/cache_and_limit.conf
# Zona cache proxy (10m keys, 100m cache storage)
proxy_cache_path /var/cache/nginx/proxy_cache levels=1:2 keys_zone=STATIC_CACHE:10m max_size=100m inactive=60m use_temp_path=off;

# Zona rate limiting: 10 request per detik per client IP
limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;
limit_req_status 429;
EOF

mkdir -p /var/cache/nginx/proxy_cache
chown -R www-data:www-data /var/cache/nginx/proxy_cache

# 2. Konfigurasi Virtual Host jujutsu dengan Cache dan Rate Limit
cat <<EOF > /etc/nginx/sites-available/jujutsu
upstream frontend_cluster {
    server ${IP_MAKI};
    server ${IP_PANDA};
}

server {
    listen 80;
    server_name jujutsu.${KELOMPOK}.com www.jujutsu.${KELOMPOK}.com;

    location / {
        proxy_pass http://frontend_cluster;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;

        # Proxy Cache (10 menit)
        proxy_cache STATIC_CACHE;
        proxy_cache_valid 200 302 10m;
        proxy_cache_valid 404 1m;
        add_header X-Cache-Status \$upstream_cache_status;
    }

    location /api {
        # Rate Limiting 10 r/s
        limit_req zone=api_limit burst=5 nodelay;

        proxy_pass http://${IP_GETO};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

ln -sf /etc/nginx/sites-available/jujutsu /etc/nginx/sites-enabled/jujutsu
rm -f /etc/nginx/sites-enabled/default
nginx -t && service nginx restart
