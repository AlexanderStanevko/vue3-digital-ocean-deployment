#!/bin/bash
set -x

# Удаление символов возврата каретки и сохранение SSH-ключа для подключения к load balancer
echo "$SSH_PRIVATE_KEY_DIGITAL_OCEAN_LOAD_BALANCER" | tr -d '\r' > load_balancer_key.pem
chmod 600 load_balancer_key.pem

# Получение текущего активного upstream на load balancer
active_upstream=$(ssh -i load_balancer_key.pem -o StrictHostKeyChecking=no root@$LOAD_BALANCER_SERVER_IP "grep proxy_pass /etc/nginx/nginx.conf")

# Определение активного сервера
if [[ $active_upstream == *"prod_blue"* ]]; then
  active_server=$PROD_1_IP
  target_server=$PROD_2_IP
  target_ssh_key=$SSH_PRIVATE_KEY_DIGITAL_OCEAN_PROD_2
else
  active_server=$PROD_2_IP
  target_server=$PROD_1_IP
  target_ssh_key=$SSH_PRIVATE_KEY_DIGITAL_OCEAN_PROD_1
fi

# Установка переменных окружения
echo "SERVER_IP=$target_server" >> $GITHUB_ENV
echo "SSH_PRIVATE_KEY=$(echo "$target_ssh_key" | tr -d '\r')" >> $GITHUB_ENV

set +x
