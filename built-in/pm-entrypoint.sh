#!/bin/bash
set -ex

if [ $WAIT_FOR_DEPENDENTS == "1" ]; then
    sh /bin/test-services.sh  
fi

if [ ! -d  "/opt/processmaker/public" ]
then
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
    sudo -u nginx COMPOSER_MEMORY_LIMIT=-1 composer install --prefer-dist
    sudo -u nginx npm install --unsafe-perm=true
    sudo -u nginx npm run dev

    sudo -u nginx php /opt/processmaker/artisan key:generate --force
    sudo -u nginx php /opt/processmaker/artisan package:discover
    sudo -u nginx php /opt/processmaker/artisan migrate:fresh --force

    sudo -u nginx php /opt/processmaker/artisan db:seed --force --class=UserSeeder
    sudo -u nginx php /opt/processmaker/artisan db:seed --force --class=PermissionSeeder
    sudo -u nginx php /opt/processmaker/artisan db:seed --force --class=ProcessSystemCategorySeeder
    sudo -u nginx php /opt/processmaker/artisan db:seed --force --class=GroupSeeder
    sudo -u nginx php /opt/processmaker/artisan db:seed --force --class=ScreenTypeSeeder
    sudo -u nginx php /opt/processmaker/artisan db:seed --force --class=CategorySystemSeeder
    sudo -u nginx php /opt/processmaker/artisan db:seed --force --class=ScreenSystemSeeder
    sudo -u nginx php /opt/processmaker/artisan db:seed --force --class=SignalSeeder
    sudo -u nginx php /opt/processmaker/artisan db:seed --force --class=AnonymousUserSeeder
    sudo -u nginx php artisan db:seed --class=PermissionSeeder --force

    sudo -u nginx php /opt/processmaker/artisan passport:install
    sudo -u nginx php /opt/processmaker/artisan storage:link

    php /opt/processmaker/artisan docker-executor-php:install --no-interaction
    php /opt/processmaker/artisan docker-executor-lua:install --no-interaction
    php /opt/processmaker/artisan docker-executor-node:install --no-interaction

    #sudo -u nginx php /opt/processmaker/artisan horizon:assets
    sudo -u nginx cat /opt/processmaker/.env > /opt/.env
    chown -R nginx:nginx /opt/processmaker

    echo true > /opt/processmaker/storage/my_build.ini
fi

if [ -d  "/opt/scripts" ] ; then chown -R nginx:nginx /opt/scripts ;fi
if [ -d  "/root/.ssh/authorized_keys" ] ; then chown root:root /root/.ssh/authorized_keys ;fi

# Package discover
sudo -u nginx php /opt/processmaker/artisan package:discover
# Migrate and seed database
sudo -u nginx php /opt/processmaker/artisan migrate --force

# Install Docker Executors
php /opt/processmaker/artisan docker-executor-php:install --no-interaction
php /opt/processmaker/artisan docker-executor-lua:install --no-interaction
php /opt/processmaker/artisan docker-executor-node:install --no-interaction

mkdir -p /tmp/sdk-csharp
mkdir -p /tmp/sdk-java
mkdir -p /tmp/sdk-javascript
mkdir -p /tmp/sdk-javascript-ssr
mkdir -p /tmp/sdk-lua
mkdir -p /tmp/sdk-php
mkdir -p /tmp/sdk-python
mkdir -p /tmp/sdk-python-selenium
mkdir -p /tmp/sdk-r
chown -R nginx:nginx /tmp/sdk*
chown -R nginx:nginx /opt/processmaker/storage/api-docs

sudo rm -rf /opt/processmaker/.env
sudo rm -rf /opt/processmaker/laravel-echo-server.lock
sudo -u nginx  ln -s  /opt/.env /opt/processmaker/.env

cd /opt/processmaker && sudo -u nginx php artisan optimize:clear
cd /opt/processmaker && sudo -u nginx php artisan processmaker:regenerate-css

sudo -u nginx php artisan config:cache

echo "ProcessMaker 4 Loaded."
/usr/bin/supervisord -c /etc/supervisord.conf
