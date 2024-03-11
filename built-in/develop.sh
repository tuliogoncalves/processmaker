#!/bin/sh
set -ex

# Set NGINX server_name
sed -i 's|server_name localhost;|server_name '"${URL}"';|' /etc/nginx/http.d/processmaker.conf

if [ $WAIT_FOR_DEPENDENTS == "1" ]; then
    sh /bin/test-services.sh
fi

if [ ! -d  "/opt/processmaker/public" ]
then
    source /opt/.env
    if [[ ! -z "${PM_branch}" ]];
    then   
        cd /opt
        chown -R nginx:nginx processmaker
        sudo -u nginx git clone --branch $PM_branch https://github.com/ProcessMaker/processmaker.git
        sudo -u nginx cp --force /opt/.env /opt/processmaker/.env
    fi
fi
if [ ! -f  "/opt/processmaker/storage/my_build.ini" ] ;
then
    cd /opt/processmaker
    sudo -u nginx COMPOSER_MEMORY_LIMIT=-1 COMPOSER_PROCESS_TIMEOUT=-1 composer install --prefer-dist
    sudo -u nginx npm install --unsafe-perm=true
    sudo -u nginx npm run dev

    sudo -u nginx php /opt/processmaker/artisan key:generate --force
    sudo -u nginx php /opt/processmaker/artisan package:discover
    sudo -u nginx php /opt/processmaker/artisan migrate --force

    sudo -u nginx php /opt/processmaker/artisan db:seed --force
    sudo -u nginx php /opt/processmaker/artisan passport:install
    sudo -u nginx php /opt/processmaker/artisan storage:link

    mkdir -p /tmp/sdk-javascript
    mkdir -p /tmp/sdk-javascript-ssr
    mkdir -p /tmp/sdk-lua
    mkdir -p /tmp/sdk-php

    php /opt/processmaker/artisan docker-executor-php:install --no-interaction
    php /opt/processmaker/artisan docker-executor-lua:install --no-interaction
    php /opt/processmaker/artisan docker-executor-node:install --no-interaction

    sudo -u nginx php /opt/processmaker/artisan horizon:publish
    sudo -u nginx cat /opt/processmaker/.env > /opt/.env
    chown -R nginx:nginx /opt/processmaker

    echo true > /opt/processmaker/storage/my_build.ini
fi

if [ -d  "/root/.ssh/authorized_keys" ] ; then chown root:root /root/.ssh/authorized_keys ;fi

# Fixing ownership /opt/processmaker
cd /opt && find processmaker ! -user nginx -exec chown nginx:nginx {} \; >/dev/null 2>&1

# Csdk
mkdir -p /tmp/sdk-javascript
mkdir -p /tmp/sdk-javascript-ssr
mkdir -p /tmp/sdk-lua
mkdir -p /tmp/sdk-php

php /opt/processmaker/artisan docker-executor-php:install --no-interaction
php /opt/processmaker/artisan docker-executor-lua:install --no-interaction
php /opt/processmaker/artisan docker-executor-node:install --no-interaction

chown -R nginx:nginx /tmp/sdk*


# Update Security-Policy
if [ -z "${CUSTOM_SECURITY_POLICY}" ]
then
    echo "No custom security policy"
else
    sed -i 's|https:\/\/\*.processmaker.net|https:\/\/\*.processmaker.net '"${CUSTOM_SECURITY_POLICY}"'|g'  /etc/nginx/http.d/processmaker.conf
fi

#env
sudo rm -rf /opt/processmaker/.env
sudo -u nginx  ln -s  /opt/.env /opt/processmaker/.env

cd /opt/processmaker && sudo -u nginx php artisan optimize:clear
cd /opt/processmaker && sudo -u nginx php artisan processmaker:regenerate-css

# Cleaning the cache config
sudo -u nginx php artisan config:cache

echo "ProcessMaker UI installed."
if [ ! -f  "/opt/processmaker/storage/${WORKSPACE}_installed.ini" ]
then
    echo true > /opt/processmaker/storage/${WORKSPACE}_installed.ini
fi
# For Develop
if cat .env | grep "BROADCAST_DRIVER=redis"
then 
    npx laravel-echo-server start&
fi
chmod -R 733 /opt/scripts
/usr/bin/supervisord -c /etc/supervisord.conf