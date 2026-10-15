#!/bin/bash
PREFIX_IP="10.78"
KELOMPOK="k29"
IP_GETO="${PREFIX_IP}.4.2"
IP_MAKI="${PREFIX_IP}.4.12"
IP_PANDA="${PREFIX_IP}.4.13"

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
    }

    location /api {
        proxy_pass http://${IP_GETO};
        proxy_set_header Host \$host;
        # Meneruskan IP asli klien yang terhubung ke gojo
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

ln -sf /etc/nginx/sites-available/jujutsu /etc/nginx/sites-enabled/jujutsu
rm -f /etc/nginx/sites-enabled/default
nginx -t && service nginx reload
