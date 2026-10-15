#!/bin/bash
# Konfigurasi Passive Health Check & Backup Server (Kirara) pada Geto (Soal 18)
PREFIX_IP="10.78"
IP_GOJO="${PREFIX_IP}.1.4"
IP_NANAMI="${PREFIX_IP}.4.14"
IP_TODO="${PREFIX_IP}.4.15"
IP_KIRARA="${PREFIX_IP}.4.16"

cat <<EOF > /etc/nginx/sites-available/api_lb
upstream api_cluster {
    # Primary workers dengan passive health check (max_fails=2, fail_timeout=5s)
    server ${IP_NANAMI}:80 weight=3 max_fails=2 fail_timeout=5s;
    server ${IP_TODO}:80 weight=1 max_fails=2 fail_timeout=5s;

    # Backup worker: Kirara hanya menerima trafik saat primary mati
    server ${IP_KIRARA}:80 backup;
}

server {
    listen 80;
    server_name _;

    set_real_ip_from ${IP_GOJO};
    real_ip_header X-Real-IP;
    real_ip_recursive on;

    location / {
        proxy_pass http://api_cluster;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;

        # Parameter timeout agar failover cepat ke backup
        proxy_connect_timeout 2s;
        proxy_read_timeout 3s;
        proxy_next_upstream error timeout http_500 http_502 http_503 http_504;
    }
}
EOF

ln -sf /etc/nginx/sites-available/api_lb /etc/nginx/sites-enabled/api_lb
rm -f /etc/nginx/sites-enabled/default
nginx -t && service nginx reload
