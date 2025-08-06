# Centralis - Guide de déploiement sur serveur

Ce guide explique comment déployer et faire fonctionner le projet Centralis sur un serveur, en configurant correctement le fichier `.env` et en adaptant le `docker-compose.yml` pour un environnement de production avec Traefik.

## 1. Prérequis

- Docker et Docker Compose installés sur le serveur
- Un nom de domaine pointant vers l’IP du serveur
- Traefik déjà configuré sur le serveur (réseau Docker `admin_proxy` existant)

## 2. Structure du projet

```
centralis/
├── .env.example           # Exemple de configuration d'environnement
├── docker-compose.yml     # Configuration des conteneurs Docker
├── README.md              # Ce guide
├── core/                  # Backend principal (Laravel)
├── frontend/              # Frontend (React)
├── subsequent/            # Application Laravel secondaire
└── ...
```

## 3. Configuration du fichier .env

Avant tout, créez votre fichier `.env` à partir du modèle fourni :

```bash
cp .env.example .env
```

Ouvrez `.env` et renseignez les variables selon votre environnement. Exemple :

```dotenv
# Configuration de la base de données
DB_USER="example_user"
DB_PASSWORD="example_password"
SF_DB_NAME="example_sf_db"
CO_DB_NAME="example_core_db"
PRENOM="votreprenom"  # Prénom ou identifiant pour personnaliser les routes

# Configuration du domaine pour Traefik
DOMAIN_NAME="votredomaine.fr"
```

**Important :**
- La variable `PRENOM` permet de personnaliser automatiquement les sous-domaines pour chaque étudiant (ex : `prenom-api.votredomaine.fr`).
- Adaptez les autres variables selon vos besoins (voir `.env.example`).

## 4. Modification du docker-compose.yml

Dans le fichier `docker-compose.yml`, chaque service exposé via Traefik doit utiliser la variable `${PRENOM}` dans ses labels pour générer des sous-domaines personnalisés. Exemple pour un service :

```yaml
services:
  api-yan:
    build:
      context: ./core
      dockerfile: Dockerfile
    container_name: api-yan
    labels:
      - "traefik.enable=true"
      - "traefik.docker.network=admin_proxy"
      - "traefik.http.routers.core-secure.entrypoints=websecure"
      - "traefik.http.routers.core-secure.rule=Host(`\${PRENOM}-api.\${DOMAIN_NAME}`)"
      - "traefik.http.routers.core-secure.service=core"
      - "traefik.http.services.core.loadbalancer.server.port=8000"
    networks:
      - centralis
```

**À faire pour chaque service exposé :**
- Remplacez les valeurs statiques dans les labels Traefik par `\${PRENOM}-api.\${DOMAIN_NAME}` ou la variante adaptée à votre service.
- Vérifiez que tous les services utilisent bien le réseau `centralis` et que ce réseau est bien déclaré comme `external: true` à la fin du fichier :

```yaml
networks:
  centralis:
    external: true
```

## 5. Lancement du projet

Lancez tous les services en arrière-plan :

```bash
docker-compose up -d
```

Pour reconstruire les images (si vous modifiez le code) :

```bash
docker-compose up -d --build
```

Pour vérifier l’état des conteneurs :

```bash
docker-compose ps
```

Pour voir les logs d’un service :

```bash
docker-compose logs -f nomduservice
```

## 6. Accès à l’application

Une fois les conteneurs démarrés, accédez à vos applications via les sous-domaines générés :

- Backend principal : `https://prenom-api.votredomaine.fr`
- Frontend : `https://prenom-frontend.votredomaine.fr` (si configuré)
- Autres services : adaptez selon la configuration

## 7. Conseils et dépannage

- Vérifiez que le DNS de votre domaine pointe bien vers l’IP du serveur
- Le réseau Docker `admin_proxy` doit exister et être partagé avec Traefik
- Les certificats HTTPS sont générés automatiquement par Traefik
- En cas de problème, consultez les logs des services et de Traefik

## 8. Exemple de .env.example

```dotenv
# Configuration de la base de données
DB_USER="example_user"
DB_PASSWORD="example_password"
SF_DB_NAME="example_sf_db"
CO_DB_NAME="example_core_db"
PRENOM="example"  # Prénom ou identifiant pour personnaliser les routes

# Configuration du domaine pour Traefik
DOMAIN_NAME="example.com"
```

---

Pour toute question ou problème, contactez votre encadrant ou consultez la documentation du projet.