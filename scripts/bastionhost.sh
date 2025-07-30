#!/bin/bash

sudo yum update -y
sudo yum install -y ansible
ansible --version
sudo yum install nginx -y
sudo systemctl enable nginx
sudo systemctl start nginx

sudo tee /etc/nginx/conf.d/reverse-proxy.conf > /dev/null <<EOF
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    location / {
        proxy_pass http://10.0.1.10:5000;
    }
}
EOF
sleep 5
sudo systemctl reload nginx