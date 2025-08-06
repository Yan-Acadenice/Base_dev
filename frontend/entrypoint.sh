  #!/bin/sh
set -e

# Désactiver l'historique bash
export HISTFILE=/dev/null
unset HISTFILESIZE
unset HISTSIZE
unset HISTFILE
export HISTCONTROL=ignorespace
export HISTIGNORE="*"

cd / 

if [ "$CREATE_NEW_PROJECT" = "true" ]; then
  echo "Création d'un nouveau projet React..."
  
  # Configurer Git temporairement pour éviter les erreurs
  git config --global user.email "temp@example.com" 2>/dev/null || true
  git config --global user.name "Temp User" 2>/dev/null || true
  
  # Créer le projet sans Git ou gérer l'erreur
  npx create-react-app app --template typescript || {
    echo "Erreur lors de la création, nettoyage et création sans Git..."
    rm -rf app
    npx create-react-app app --skip-git
  }
  
  # Supprimer le dossier .git s'il existe
#   rm -rf temp-app/.git
  
#   rm -rf temp-app/*
#   rm -rf app
#   mv temp-app app
fi

cd app
npm install


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
