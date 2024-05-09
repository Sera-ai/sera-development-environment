# Stage 1: Install MongoDB in a separate stage
FROM debian:buster-slim as mongodb

# Add MongoDB to the sources list and install it
RUN apt-get update \
    && apt-get install -y gnupg wget \
    && wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc | apt-key add - \
    && echo "deb http://repo.mongodb.org/apt/debian buster/mongodb-org/4.2 main" | tee /etc/apt/sources.list.d/mongodb-org-4.2.list \
    && apt-get update \
    && apt-get install -y mongodb-org

RUN apt-get update && apt-get install -y gnupg wget curl xz-utils nginx-extras openssl git libcurl4 gettext luarocks

# Install lua-resty-http
# Install each required Lua module separately
RUN luarocks install lua-resty-http \
    && luarocks install lua-resty-string \
    && luarocks install lua-resty-core \
    && luarocks install lua-resty-lrucache \
    && luarocks install lua-cjson \
    && luarocks install lua-resty-mongol

# Install Node.js and npm
RUN curl -fsSL https://nodejs.org/dist/v20.5.1/node-v20.5.1-linux-x64.tar.xz | tar -xJ -C /usr/local --strip-components=1 \
    && npm install -g npm@9.8.0 nodemon eslint prettier

# Create MongoDB data directory
RUN mkdir -p /data/db

# Set working directory for the Node app
WORKDIR /workspace

# Copy the application's source code
COPY . .

# Initialize and update submodules
RUN git submodule update --init --recursive --remote

# Install Node.js dependencies for each submodule
RUN npm install --prefix ./fe_Catalog \
    && npm install --prefix ./be_Builder \
    && npm install --prefix ./be_Socket \
    && npm install --prefix ./be_Sequencer

# Clean up the apt cache by removing /var/lib/apt/lists
RUN rm -rf /var/lib/apt/lists/*

# Environment variables for SSL certificate generation
ENV SSL_COUNTRY="US"
ENV SSL_STATE="Florida"
ENV SSL_LOCALITY="Tampa"
ENV SSL_ORG="Sera"
ENV SSL_COMMON_NAME="localhost"

# Generate SSL certificates dynamically
RUN mkdir -p /etc/nginx/certs \
    && openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 \
    -subj "/C=$SSL_COUNTRY/ST=$SSL_STATE/L=$SSL_LOCALITY/O=$SSL_ORG/CN=$SSL_COMMON_NAME" \
    -keyout /etc/nginx/certs/server.key -out /etc/nginx/certs/server.crt

# Copy the Nginx configuration template
COPY ./.devcontainer/test.lua /etc/nginx/lua-scripts/test.lua
COPY ./.devcontainer/lua-scripts/ /etc/nginx/

# Expose ports
EXPOSE 80 443 12010 12030 12040 12000 12050

RUN chmod +x ./.devcontainer/entrypoint.sh ./sera-db-mongo/entrypoint.sh

# Set the new entrypoint
ENTRYPOINT ["./.devcontainer/entrypoint.sh"]