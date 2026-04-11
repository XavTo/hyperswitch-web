FROM node:24-alpine
RUN apk add --no-cache make gcc g++ python3 bash git
WORKDIR /usr/src/app

# Build arguments (passed by Railway via build args)
ARG envSdkUrl
ARG envBackendUrl

COPY package*.json ./
RUN npm install --ignore-scripts
COPY . .

RUN if [ ! -f "shared-code/sdk-utils/package.json" ]; then \
    rm -rf shared-code && \
    git clone https://github.com/juspay/hyperswitch-sdk-utils.git shared-code; \
    fi

RUN echo "Building with envSdkUrl=$envSdkUrl envBackendUrl=$envBackendUrl" && \
    ENV_SDK_URL=$envSdkUrl \
    ENV_BACKEND_URL=$envBackendUrl \
    sdkEnv=integ \
    npm run re:build && \
    ENV_SDK_URL=$envSdkUrl \
    ENV_BACKEND_URL=$envBackendUrl \
    sdkEnv=integ \
    npm run build:integ

RUN VERSION=$(node -p "require('./package.json').version") && \
    mkdir -p dist/web/$VERSION/v1 && \
    cp -r dist/integ/v1/* dist/web/$VERSION/v1/ && \
    cp dist/integ/v1/HyperLoader.js dist/HyperLoader.js && \
    cp dist/integ/v1/HyperLoader.js.map dist/HyperLoader.js.map 2>/dev/null || true && \
    cp dist/integ/v1/app.js dist/app.js 2>/dev/null || true && \
    cp dist/integ/v1/app.js.map dist/app.js.map 2>/dev/null || true && \
    cp dist/integ/v1/app.css dist/app.css 2>/dev/null || true && \
    cp dist/integ/v1/app.css.map dist/app.css.map 2>/dev/null || true

EXPOSE 9050
CMD npx -y http-server dist -p 9050 -a 0.0.0.0 --cors
