#!/bin/bash
echo "nameserver 192.168.122.1" > /etc/resolv.conf
apt-get update
apt-get install -y nginx

mkdir -p /var/www/html
echo "todo" > /var/www/html/index.html

cat << 'NGINX' > /etc/nginx/sites-available/default
server {
    listen 80 default_server;
    root /var/www/html;
    index index.html;
    server_name _;

    location / {
        try_files $uri $uri/ =404;
    }
}
NGINX

nginx -t && service nginx restart
