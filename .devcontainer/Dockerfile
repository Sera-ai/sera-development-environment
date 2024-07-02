# Stage 1: Install MongoDB in a separate stage
FROM debian:buster-slim as mongodb

# Add MongoDB to the sources list and install it
RUN apt-get update \
    && apt-get install -y gnupg wget \
    && wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc | apt-key add - \
    && echo "deb http://repo.mongodb.org/apt/debian buster/mongodb-org/4.2 main" | tee /etc/apt/sources.list.d/mongodb-org-4.2.list \
    && apt-get update \
    && apt-get install -y mongodb-org

# Install required dependencies and development packages
RUN apt-get update \
    && apt-get install -y gnupg wget curl xz-utils nginx-extras openssl git libcurl4 gettext luarocks luajit software-properties-common moreutils build-essential 

RUN wget -qO - https://openresty.org/package/pubkey.gpg | apt-key add -
RUN echo "deb http://openresty.org/package/debian buster openresty" | tee /etc/apt/sources.list.d/openresty.list

RUN apt-get update && apt-get install -y openresty

RUN git clone https://github.com/bigplum/lua-resty-mongol.git \
    && cd lua-resty-mongol \
    && make install

# Install lua-resty-http and other Lua modules
RUN luarocks install lua-resty-http \
    && luarocks install lua-resty-string \
    && luarocks install lua-resty-core \
    && luarocks install lua-resty-lrucache \
    && luarocks install lua-cjson \
    && luarocks install luasocket

RUN mkdir /usr/local/share/lua/5.1/resty/mongol/ \
    && cp -r /usr/local/openresty/lualib/resty/mongol/ /usr/local/share/lua/5.1/resty/

# Install Node.js and npm
RUN curl -fsSL https://nodejs.org/dist/v20.5.1/node-v20.5.1-linux-x64.tar.xz | tar -xJ -C /usr/local --strip-components=1 \
    && npm install -g npm@9.8.0 nodemon eslint prettier

# Install Docker
RUN apt-get update && \
    apt-get install -y apt-transport-https ca-certificates curl gnupg2 software-properties-common && \
    curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add - && \
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable" && \
    apt-get update && \
    apt-get install -y docker-ce-cli

# Install k3s
RUN curl -sfL https://get.k3s.io | sh -

# Install kubectl
RUN curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl" && \
    chmod +x ./kubectl && \
    mv ./kubectl /usr/local/bin/kubectl

# Create MongoDB data directory
RUN mkdir -p /data/db

# Set working directory for the Node app
WORKDIR /workspace

RUN mkdir /workspace/.logs

#Global node_modules
RUN mkdir /workspace/node_modules
COPY /workspace/.devcontainer/package.json /workspace/node_modules/package.json
RUN npm install --prefix ./node_modules

# Copy the application's source code
COPY . .

# Initialize and update submodules
RUN git submodule update --init --recursive --remote

# Create a shared node_modules volume
VOLUME [ "/workspace/node_modules" ]
VOLUME [ "/workspace/sera-db-mongo/models" ]
VOLUME [ "/workspace/.devcontainer/lua-scripts" ]


# Build Docker images for each submodule
# Submodule1
WORKDIR /workspace/be_Socket
RUN docker build -t backend_socket:latest .

# Submodule2
WORKDIR /workspace/be_Sequencer
RUN docker build -t backend_sequencer:latest .

# Submodule2
WORKDIR /workspace/be_Processor
RUN docker build -t backend_processor:latest .

# Submodule2
WORKDIR /workspace/be_Builder
RUN docker build -t backend_builder:latest .

# Submodule2
WORKDIR /workspace/fe_Catalog
RUN docker build -t frontend_catalog:latest .

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

# Copy the Nginx configuration template and Lua scripts
RUN ln -s  /workspace/.devcontainer/lua-scripts /etc/nginx/lua-scripts
RUN rm -rf /etc/nginx/conf.d && ln -s /workspace/.devcontainer/conf.d /etc/nginx/conf.d
RUN ln -s /etc/nginx /workspace/nginx-config


# Expose ports
EXPOSE 80 443 12010 12030 12040 12000 12050

# Convert CRLF to LF using sed
RUN sed -i 's/\r$//' ./.devcontainer/entrypoint.sh
RUN sed -i 's/\r$//' ./sera-db-mongo/entrypoint.sh

RUN chmod +x ./.devcontainer/entrypoint.sh ./sera-db-mongo/entrypoint.sh