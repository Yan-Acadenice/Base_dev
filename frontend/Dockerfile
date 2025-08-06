# Use official Node image
FROM node:20-alpine

# Set working directory
WORKDIR /app

# Copie le script d'entrée
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Copie le dossier app si présent (pour le cas CREATE_NEW_PROJECT=false)
COPY app ./app

# Définit la variable d'environnement par défaut
ENV CREATE_NEW_PROJECT=false

# Install dependencies
# Installe serve pour le mode production
RUN npm install -g serve && npm install react-router-dom && npm install typescript @types/react

# Expose React's default port
EXPOSE 3000

# Run entrypoint script
ENTRYPOINT ["/entrypoint.sh"]
