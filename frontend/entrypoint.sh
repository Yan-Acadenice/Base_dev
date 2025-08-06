#!/bin/sh
set -e

# Désactiver l'historique bash
export HISTFILE=/dev/null
unset HISTFILESIZE
unset HISTSIZE
unset HISTFILE
export HISTCONTROL=ignorespace
export HISTIGNORE="*"

if [ "$CREATE_NEW_PROJECT" = "true" ]; then
  echo "Création d'un nouveau projet React..."
  npx create-react-app temp-app
  rm -rf app
  mv temp-app app
fi

cd app
npm install

echo "Variables d'environnement configurées :"
cat .env

if [ "$DEV" = "true" ]; then
  echo "Lancement en mode développement avec Vite..."
  npm start --host=0.0.0.0
else
  echo "Lancement en mode production..."

  # Build avec Vite si pas déjà fait
  if [ ! -d "dist" ]; then
    echo "Building application with Vite..."
    npm run prod
  fi

  echo "Starting production server with SPA routing..."
  # Servir avec support SPA complet
  serve -s dist -p 3000 -l 3000 --single --host-rewrite --cors
fi