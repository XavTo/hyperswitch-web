# Utilisation de Node 24 Alpine
FROM node:24-alpine

# Installation des dépendances système nécessaires + GIT
RUN apk add --no-cache make gcc g++ python3 bash git

WORKDIR /usr/src/app

# 1. On gère les dépendances npm en premier
COPY package*.json ./
RUN npm install --ignore-scripts

# 2. On copie tout le projet
COPY . .

# 3. FORCE CLONE DES SUBMODULES (Le fix magique)
# On vérifie si le dossier est vide, si oui, on clone manuellement
RUN if [ ! -f "shared-code/sdk-utils/package.json" ]; then \
    echo "Dossier shared-code vide ou incomplet. Récupération manuelle..." && \
    rm -rf shared-code && \
    git clone https://github.com/juspay/hyperswitch-sdk-utils.git shared-code; \
    fi

# 4. Injection des variables d'environnement pour Webpack
# (Assure-toi que ces variables sont bien dans l'onglet "Variables" de Railway)
ARG sdkUrl
ARG backendUrl
ENV sdkUrl=$sdkUrl
ENV backendUrl=$backendUrl

# 5. Compilation ReScript et Webpack
# On lance re:build pour compiler le shared-code puis le sdk
RUN npm run re:build && npm run build:integ

# 6. Organisation des dossiers pour HyperLoader
RUN VERSION=$(node -p "require('./package.json').version") && \
    mkdir -p dist/web/$VERSION/v1 && \
    cp -r dist/integ/v1/* dist/web/$VERSION/v1/

EXPOSE 9050

# 7. Serveur statique
CMD npx -y serve -s dist -l tcp://0.0.0.0:9050
