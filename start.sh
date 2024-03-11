set -ex
echo ${PM_APP_URL}

    php artisan processmaker:install --no-interaction \
    --url=http://localhost\
    --broadcast-host=http://localhost:6001 \
    --username=admin \
    --password=admin123 \
    --email=admin@processmaker.com \
    --first-name=Admin \
    --last-name=User \
    --db-host=mysql \
    --db-port=3306 \
    --db-name=processmaker \
    --db-username=root \
    --db-password="Psswd#123" \
    --data-driver=mysql \
    --data-host=mysql \
    --data-port=3306 \
    --data-name=processmaker \
    --data-username=pm \
    --data-password=pass \
    --redis-host=redis
