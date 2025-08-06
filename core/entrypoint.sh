#!/bin/bash

# Désactiver l'historique bash
export HISTFILE=/dev/null
unset HISTFILESIZE
unset HISTSIZE
unset HISTFILE
export HISTCONTROL=ignorespace
export HISTIGNORE="*"

# Les opérations se feront en tant que root pour pouvoir gérer les volumes montés
# puis on basculera vers l'utilisateur laravel pour exécuter les commandes
# export HOME_DIR="/home/laravel"

# # S'assurer que les permissions sont correctes sur /api
# if [ -d "/api" ]; then
#   chown -R laravel:devlopper /api || echo "Avertissement: Impossible de changer les permissions de /api"
# fi

# # Créer un répertoire pour composer et s'assurer qu'il est accessible
# mkdir -p $HOME_DIR/.composer
# chown -R laravel:devlopper $HOME_DIR

# Fonction pour mettre à jour une variable dans le fichier .env
update_env_var() {
    local key=$1
    local value=$2
    local env_file=$3
    
    # Vérifier si la variable existe et la mettre à jour, sinon l'ajouter
    if grep -q "^${key}=" "$env_file"; then
        # Échapper les caractères spéciaux dans la valeur pour sed
        value=$(echo "$value" | sed 's/[\/&]/\\&/g')
        sed -i "s/^${key}=.*/${key}=${value}/" "$env_file"
    else
        echo "${key}=${value}" >> "$env_file"
    fi
}

# Fonction pour décommenter une variable dans le fichier .env
uncomment_env_var() {
    local key=$1
    local env_file=$2
    
    # Vérifie si la variable est commentée et la décommente
    if grep -q "^#[[:space:]]*${key}=" "$env_file"; then
        sed -i "s/^#[[:space:]]*\(${key}=.*\)/\1/" "$env_file"
    fi
}

if [ "$CREATE_NEW_PROJECT" = "yes" ]; then
     echo "Création d'un nouveau projet Laravel..."
    
    cd /
    
    # Si le dossier app contient déjà des fichiers (sauf entrypoint.sh), on les supprime
    if [ "$(ls -A /api)" ]; then
        find /api -mindepth 1 -delete
    fi
    echo "ou je suis ? $(pwd)"
    rm -rf /api/* /api/.* 2>/dev/null || true
    chown laravel:devlopper /api

    # Création du nouveau projet Laravel
    echo "ls de /api avant création du projet :"
    ls -la /api
    # Création du nouveau projet Laravel
    composer clearcache
    composer selfupdate
    su laravel -c "composer create-project laravel/laravel /api"    
    # Déplacement dans le dossier du projet
    cd api
    
    # Génération d'une clé et lancement du serveur
    # php artisan key:generate
    
    su laravel -c "php artisan key:generate"
    
    # Installation de Filament
    su laravel -c "composer require filament/filament"
    su laravel -c "php artisan filament:install --panels"
    php artisan filament:install --panels
    
    # Synchronisation des variables d'environnement Docker avec .env
    env_file=".env"
    
    # S'assurer que le fichier .env est accessible
    chown laravel:devlopper .env
    
    # Décommenter les variables de base de données
    db_vars=("DB_HOST" "DB_PORT" "DB_DATABASE" "DB_USERNAME" "DB_PASSWORD")
    for var in "${db_vars[@]}"; do
        uncomment_env_var "$var" "$env_file"
    done
    
    # Liste des variables d'environnement à synchroniser
    env_vars=("APP_NAME" "APP_ENV" "APP_KEY" "APP_DEBUG" "APP_URL" 
              "DB_CONNECTION" "DB_HOST" "DB_PORT" "DB_DATABASE" "DB_USERNAME" "DB_PASSWORD"
              "CACHE_DRIVER" "SESSION_DRIVER" "REDIS_HOST" "REDIS_PORT" "MAIL_DRIVER"
              "MAIL_HOST" "MAIL_PORT" "MAIL_USERNAME" "MAIL_PASSWORD" "MAIL_ENCRYPTION"
              "PUSHER_APP_ID" "PUSHER_APP_KEY" "PUSHER_APP_SECRET")
    
    for var in "${env_vars[@]}"; do
        if [ ! -z "${!var}" ]; then
            update_env_var "$var" "${!var}" "$env_file"
        fi
    done
    chgrp -R devlopper /api    
    chmod -R 775 /api
    
    php artisan serve --host=0.0.0.0 --port=8000
else
    echo "Utilisation du projet Laravel existant..."
    
    # On est déjà dans /api, qui contient le projet existant
    composer install
    
    # Vérifier si .env existe, sinon copier .env.example
    if [ ! -f .env ]; then
        cp .env.example .env
        php artisan key:generate
    fi
    
    # Décommenter les variables de base de données
    env_file=".env"
    db_vars=("DB_HOST" "DB_PORT" "DB_DATABASE" "DB_USERNAME" "DB_PASSWORD")
    for var in "${db_vars[@]}"; do
        uncomment_env_var "$var" "$env_file"
    done
    
    # Synchronisation des variables d'environnement Docker avec .env
    # Liste des variables d'environnement à synchroniser
    env_vars=("APP_NAME" "APP_ENV" "APP_KEY" "APP_DEBUG" "APP_URL" 
              "DB_CONNECTION" "DB_HOST" "DB_PORT" "DB_DATABASE" "DB_USERNAME" "DB_PASSWORD"
              "CACHE_DRIVER" "SESSION_DRIVER" "REDIS_HOST" "REDIS_PORT" "MAIL_DRIVER"
              "MAIL_HOST" "MAIL_PORT" "MAIL_USERNAME" "MAIL_PASSWORD" "MAIL_ENCRYPTION"
              "PUSHER_APP_ID" "PUSHER_APP_KEY" "PUSHER_APP_SECRET")
    
    for var in "${env_vars[@]}"; do
        if [ ! -z "${!var}" ]; then
            update_env_var "$var" "${!var}" "$env_file"
        fi
    done
    
    # Exécution des migrations seulement si DB_DEV=yes
    if [ "$DB_DEV" = "yes" ]; then
        chmod -R 775 ./
        echo "Exécution des migrations et des seeders..."
        su laravel -c "php artisan migrate:fresh --seed"
    else
        echo "Mode sans migration activé, aucune modification de la base de données."
    fi
    
    # Lancement du serveur en tant que laravel
    su laravel -c "php artisan serve --host=0.0.0.0 --port=8000"
fi