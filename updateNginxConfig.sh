# #!/bin/bash
# set -e

# # Проверка наличия необходимых переменных
# if [[ -z "$LOAD_BALANCER_SERVER_IP" ]]; then
#   echo "LOAD_BALANCER_SERVER_IP is not set"
#   exit 1
# fi

# # Сохранение SSH-ключа для подключения к load balancer
# echo "$SSH_PRIVATE_KEY_DIGITAL_OCEAN_LOAD_BALANCER" > load_balancer_key.pem
# chmod 600 load_balancer_key.pem

# # Получение текущего активного сервера
# active_server=$(ssh -i load_balancer_key.pem -o StrictHostKeyChecking=no root@$LOAD_BALANCER_SERVER_IP "grep proxy_pass /etc/nginx/nginx.conf")

# # Определение нового upstream в зависимости от активного сервера
# if [[ $active_server == *"prod_blue"* ]]; then
#   new_upstream="prod_green"
#   new_active_server=$PROD_2_IP
# else
#   new_upstream="prod_blue"
#   new_active_server=$PROD_1_IP
# fi

# # Обновление конфигурации Nginx на load balancer
# ssh -i load_balancer_key.pem -o StrictHostKeyChecking=no root@$LOAD_BALANCER_SERVER_IP "
#   sed -i 's/proxy_pass http:\/\/prod_.*;/proxy_pass http:\/\/$new_upstream;/' /etc/nginx/nginx.conf && nginx -s reload
# "

# # Проверка, что конфигурация обновлена
# new_config=$(ssh -i load_balancer_key.pem -o StrictHostKeyChecking=no root@$LOAD_BALANCER_SERVER_IP "grep proxy_pass /etc/nginx/nginx.conf")
# echo "New Nginx Configuration: $new_config"

# # Обновление переменной окружения для активного сервера
# echo "SERVER_IP=$new_active_server" >> $GITHUB_ENV


#!/bin/bash
set -e
set -x  # Включаем вывод команд

# Проверка наличия необходимых переменных
if [[ -z "$LOAD_BALANCER_SERVER_IP" ]]; then
  echo "LOAD_BALANCER_SERVER_IP is not set"
  exit 1
fi

echo "Current User: $(whoami)"  # Выводим текущего пользователя
echo "Checking permissions for nginx.conf"
ls -l /etc/nginx/nginx.conf  # Проверяем права доступа к файлу конфигурации Nginx

# Сохранение SSH-ключа для подключения к load balancer
echo "$SSH_PRIVATE_KEY_DIGITAL_OCEAN_LOAD_BALANCER" | tr -d '\r' > load_balancer_key.pem
chmod 600 load_balancer_key.pem

# Получение текущего активного сервера
active_server=$(ssh -i load_balancer_key.pem -o StrictHostKeyChecking=no -vvv root@$LOAD_BALANCER_SERVER_IP "grep proxy_pass /etc/nginx/nginx.conf")

# Определение нового upstream в зависимости от активного сервера
if [[ $active_server == *"prod_blue"* ]]; then
  new_upstream="prod_green"
  new_active_server=$PROD_2_IP
else
  new_upstream="prod_blue"
  new_active_server=$PROD_1_IP
fi

echo "Switching to $new_upstream"

# Обновление конфигурации Nginx на load balancer
ssh -i load_balancer_key.pem -o StrictHostKeyChecking=no -vvv root@$LOAD_BALANCER_SERVER_IP "
  sed -i 's/proxy_pass http:\/\/prod_.*;/proxy_pass http:\/\/$new_upstream;/' /etc/nginx/nginx.conf && nginx -s reload
"

# Проверка, что конфигурация обновлена
new_config=$(ssh -i load_balancer_key.pem -o StrictHostKeyChecking=no -vvv root@$LOAD_BALANCER_SERVER_IP "grep proxy_pass /etc/nginx/nginx.conf")
echo "New Nginx Configuration: $new_config"

set +x
