#!/bin/bash
echo "nameserver 192.168.122.1" > /etc/resolv.conf

apt-get update
apt-get install -y nginx

cat << 'NGINX' > /etc/nginx/sites-available/default
upstream api_cluster {
    server 10.78.4.14:80 weight=3; # nanami
    server 10.78.4.15:80 weight=1; # todo
}

server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;

    location / {
        proxy_pass http://api_cluster;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
NGINX

ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default
nginx -t && service nginx restart
