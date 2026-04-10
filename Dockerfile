FROM node:24-alpine

RUN apk add --no-cache make gcc g++ python3 bash git

WORKDIR /usr/src/app

# 1
COPY package*.json ./
RUN npm install --ignore-scripts

# 2
COPY . .

# 3
RUN if [ ! -f "shared-code/sdk-utils/package.json" ]; then \
    echo "Dossier shared-code vide ou incomplet. Récupération manuelle..." && \
    rm -rf shared-code && \
    git clone https://github.com/juspay/hyperswitch-sdk-utils.git shared-code; \
    fi

# 4
ARG envSdkUrl
ARG envBackendUrl
ENV envSdkUrl=$envSdkUrl
ENV envBackendUrl=$envBackendUrl

# 5
RUN envSdkUrl=$envSdkUrl envBackendUrl=$envBackendUrl npm run re:build && \
    envSdkUrl=$envSdkUrl envBackendUrl=$envBackendUrl npm run build:integ

# 6
RUN VERSION=$(node -p "require('./package.json').version") && \
    mkdir -p dist/web/$VERSION/v1 && \
    cp -r dist/integ/v1/* dist/web/$VERSION/v1/ && \
    cp dist/integ/v1/HyperLoader.js dist/HyperLoader.js

EXPOSE 9050

# 7
CMD npx -y serve -s dist -l tcp://0.0.0.0:9050
