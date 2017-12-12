#!/bin/bash

apt-get update
apt-get install -y nginx php7.0-mcrypt php7.0-fpm php7.0-curl php7.0-mysql \
  php7.0-cli php7.0-xsl php7.0-json php7.0-intl php7.0-dev php-pear php7.0-mbstring \
  php7.0-common php7.0-zip php7.0-gd php-soap curl libcurl3
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer
composer.phar config http-basic.repo.magento.com ${MAGENTO_AUTH_PUBLIC_KEY} ${MAGENTO_AUTH_PRIVATE_KEY}
composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition /var/www/magento2
chown -R www-data:www-data /var/www/magento2
cat > /etc/nginx/sites-available/magento << EOF
upstream fastcgi_backend {
    server  unix:/run/php/php7.0-fpm.sock;
}

server {
    listen 80;
    server_name ${DOMAIN_URL};
    set '$MAGE_ROOT' /var/www/magento2;
    set '$MAGE_MODE' developer;
    include /var/www/magento2/nginx.conf.sample;
}
EOF
ln -s /etc/nginx/sites-available/magento /etc/nginx/sites-enabled/
systemctl restart nginx
/var/www/magento2/bin/magento setup:install --backend-frontname="admin" \
--key="cja8Jadsjwoqpgk93670Dfhu47m7rrIp" \
--db-host=${DB_HOST_IP} \
--db-name=${DB_NAME} \
--db-user=${DB_USER} \
--db-password=${DB_PASSWORD} \
--use-rewrites=1 \
--use-secure=0 \
--base-url="http://${DOMAIN_URL}" \
--base-url-secure="https://${DOMAIN_URL}" \
--admin-user=${MAGENTO_ADMIN_USER} \
--admin-password=${MAGENTO_ADMIN_PASSWORD} \
--admin-email=${MAGENTO_ADMIN_EMAIL} \
--admin-firstname=${MAGENTO_ADMIN_FIRSTNAME} \
--admin-lastname=${MAGENTO_ADMIN_LASTNAME} > /var/log/bootstrap.log 2>&1