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

# storage/api-docs/ is gitignored (it's generated output), so a fresh
# container has no api-docs.json until someone generates one -- bake it
# into the image at build time instead of depending on a runtime env var
# or a manual step after every deploy. Scanning PHP attributes needs no
# DB/app config, so this is safe to run during the build.
RUN php artisan l5-swagger:generate \
 && chown -R www-data:www-data storage/api-docs

COPY docker/nginx-prod.conf /etc/nginx/http.d/default.conf
COPY docker/supervisord.conf /etc/supervisord.conf
COPY docker/php-fpm-pool.conf /usr/local/etc/php-fpm.d/zzz-pool-override.conf

EXPOSE 80
CMD ["supervisord", "-c", "/etc/supervisord.conf"]
