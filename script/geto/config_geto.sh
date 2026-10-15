#!/bin/bash
PREFIX_IP="10.78"
IP_GOJO="${PREFIX_IP}.1.4"
IP_NANAMI="${PREFIX_IP}.4.14"
IP_TODO="${PREFIX_IP}.4.15"

cat <<EOF > /etc/nginx/sites-available/api_lb
upstream api_cluster {
    # Sesuai Soal 15: Weighted Round Robin 3:1 untuk nanami dan todo
    server ${IP_NANAMI} weight=3;
    server ${IP_TODO} weight=1;
}

server {
    listen 80;
    server_name _;

    # Mempercayai HANYA proxy gojo untuk ekstraksi IP asli klien
    set_real_ip_from ${IP_GOJO};
    real_ip_header X-Real-IP;
    real_ip_recursive on;

    location / {
        proxy_pass http://api_cluster;
        proxy_set_header Host \$host;
        # Karena real_ip_header aktif, \$remote_addr di sini sudah berisi IP asli klien
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

ln -sf /etc/nginx/sites-available/api_lb /etc/nginx/sites-enabled/api_lb
rm -f /etc/nginx/sites-enabled/default
nginx -t && service nginx reload
