#!/bin/bash
sudo yum update -y
sudo yum install nginx -y
sudo systemctl enable nginx
sudo systemctl start nginx

BACKEND_IP=$1
sudo tee /etc/nginx/conf.d/reverse-proxy.conf > /dev/null <<EOF
server {
    listen 5000;
    location / {
        proxy_pass http://192.168.49.2:30080;
    }
}
}
EOF
sleep 2
sudo systemctl reload nginx


