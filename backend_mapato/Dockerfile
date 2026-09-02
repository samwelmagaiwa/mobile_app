FROM php:8.2-fpm-alpine

RUN apk add --no-cache libzip-dev icu-dev oniguruma-dev nginx supervisor \
 && docker-php-ext-install pdo_mysql mbstring zip bcmath intl opcache \
 && rm -rf /var/cache/apk/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html
COPY composer.json composer.lock ./
RUN composer install --no-dev --no-scripts --no-autoloader --prefer-dist --no-interaction

COPY . .
RUN composer dump-autoload --optimize \
 && chown -R www-data:www-data storage bootstrap/cache

COPY docker/nginx-prod.conf /etc/nginx/http.d/default.conf
COPY docker/supervisord.conf /etc/supervisord.conf

EXPOSE 80
CMD ["supervisord", "-c", "/etc/supervisord.conf"]
