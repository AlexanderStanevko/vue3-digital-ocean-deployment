#!/bin/bash

# Удаление символов возврата каретки и сохранение SSH-ключа для подключения к load balancer
echo "$SSH_PRIVATE_KEY_DIGITAL_OCEAN_LOAD_BALANCER" | tr -d '\r' > load_balancer_key.pem
chmod 600 load_balancer_key.pem

# Получение текущего активного сервера
active_upstream=$(ssh -i load_balancer_key.pem -o StrictHostKeyChecking=no root@$LOAD_BALANCER_SERVER_IP "grep proxy_pass /etc/nginx/nginx.conf")

# Определение нового upstream в зависимости от активного сервера
if [[ $active_upstream == *"prod_blue"* ]]; then
  new_upstream="prod_green"
  new_active_server_ip=$PROD_2_IP
  new_active_server_ssh_key=$SSH_PRIVATE_KEY_DIGITAL_OCEAN_PROD_2
else
  new_upstream="prod_blue"
  new_active_server_ip=$PROD_1_IP
  new_active_server_ssh_key=$SSH_PRIVATE_KEY_DIGITAL_OCEAN_PROD_1
fi

# Обновление конфигурации Nginx на load balancer
ssh -i load_balancer_key.pem -o StrictHostKeyChecking=no root@$LOAD_BALANCER_SERVER_IP "
  sed -i 's/proxy_pass http:\/\/prod_.*;/proxy_pass http:\/\/$new_upstream;/' /etc/nginx/nginx.conf
  nginx -s reload
"

# Обновление переменной окружения для активного сервера
echo "SERVER_IP=$new_active_server_ip" >> $GITHUB_ENV
echo "SSH_PRIVATE_KEY<<EOF" >> $GITHUB_ENV
echo "$new_active_server_ssh_key" | tr -d '\r' >> $GITHUB_ENV
echo "EOF" >> $GITHUB_ENV
