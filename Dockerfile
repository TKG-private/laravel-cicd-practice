FROM php:8.1-apache

# これを外すとページ遷移時に403 Forbiddenとなる(※要詳細な調査)
ENV APACHE_DOCUMENT_ROOT='/var/www/public/'
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf

RUN apt update -y \
&& apt install -y vim git zip unzip

# Redisクライアントのインストール
RUN git clone https://github.com/phpredis/phpredis.git /usr/src/php/ext/redis \
&& docker-php-ext-install redis

# MySQLのドライバをインストール
RUN docker-php-ext-install pdo_mysql

# Composerのインストール
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
&& php composer-setup.php \
&& mv composer.phar /usr/bin/composer \
&& php -r "unlink('composer-setup.php');"

# Node.jsのインストール
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
&& apt-get install -y nodejs

# sslの設定
# COPY ssl/server.crt /etc/ssl/certs/
# COPY ssl/server.key /etc/ssl/private/
# RUN sed -i 's!/etc/ssl/certs/ssl-cert-snakeoil.pem!/etc/ssl/certs/server.crt!g' /etc/apache2/sites-available/default-ssl.conf \
# && sed -i 's!/etc/ssl/private/ssl-cert-snakeoil.key!/etc/ssl/private/server.key!g' /etc/apache2/sites-available/default-ssl.conf
# RUN a2enmod ssl && a2ensite default-ssl.conf

COPY ./laravel-project /var/www/

WORKDIR /var/www/

RUN composer install \
&& php artisan key:generate \
&& cp -n .env.example .env \
&& chmod 777 -R storage/ \
&& chmod 777 -R bootstrap/
