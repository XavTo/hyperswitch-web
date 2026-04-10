FROM node:24-alpine
RUN apk add --no-cache make gcc g++ python3 bash git
WORKDIR /usr/src/app

COPY package*.json ./
RUN npm install --ignore-scripts

COPY . .

RUN if [ ! -f "shared-code/sdk-utils/package.json" ]; then \
    rm -rf shared-code && \
    git clone https://github.com/juspay/hyperswitch-sdk-utils.git shared-code; \
    fi

RUN envSdkUrl=https://hyperswitch-web-production-a54e.up.railway.app \
    envBackendUrl=https://hyperswitch-router-production.up.railway.app \
    npm run re:build && \
    envSdkUrl=https://hyperswitch-web-production-a54e.up.railway.app \
    envBackendUrl=https://hyperswitch-router-production.up.railway.app \
    npm run build:integ

RUN VERSION=$(node -p "require('./package.json').version") && \
    mkdir -p dist/web/$VERSION/v1 && \
    cp -r dist/integ/v1/* dist/web/$VERSION/v1/ && \
    cp dist/integ/v1/HyperLoader.js dist/HyperLoader.js

EXPOSE 9050
CMD npx -y serve -s dist -l tcp://0.0.0.0:9050
