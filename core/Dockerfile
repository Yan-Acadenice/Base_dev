# Dockerfile pour Core Centralis avec Filament
FROM php:8.4.7-zts-alpine3.20

# Installation des dépendances avec apk (gestionnaire de paquets d'Alpine)
RUN apk add --no-cache \
    icu-dev \
    postgresql-dev \
    libzip-dev \
    zip \
    unzip \
    bash \
    git \
    npm \
    nodejs \
    && docker-php-ext-install \
    intl \
    pdo \
    pdo_mysql \
    pgsql \
    pdo_pgsql \
    zip \
    && docker-php-ext-enable pdo_pgsql \
    && adduser -u 1000 -h /home/laravel -D laravel \
    && addgroup -g 1001 -S devlopper

# Installation de Composer et Laravel en tant que root
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && composer global require laravel/installer

# Copier le script d'entrée
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh && \
    mkdir -p /api && \
    chown -R laravel:devlopper /api /entrypoint.sh

# Nous ne changeons pas d'utilisateur dans le Dockerfile
# USER laravel:devlopper

WORKDIR /api

# Variable d'environnement pour contrôler le mode de création
ENV CREATE_NEW_PROJECT="no"
ENV PROJECT_NAME="core_app"

# Port exposé
EXPOSE 8000



# Utiliser le script comme point d'entrée
ENTRYPOINT ["/entrypoint.sh"]