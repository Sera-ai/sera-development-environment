# Stage 1: Install MongoDB in a separate stage
FROM debian:buster-slim
USER root

#####################################################################################################################
# Set working directory for the Node app

WORKDIR /workspace
RUN mkdir /workspace/.logs
RUN mkdir /workspace/.devcontainer

COPY .devcontainer /workspace/.devcontainer
# Copy the application's source code
COPY . .

#####################################################################################################################
#Install Dependencies

RUN apt-get update \
    && apt-get install -y gnupg wget curl xz-utils nginx-extras openssl git libcurl4 gettext luarocks luajit software-properties-common moreutils build-essential

#####################################################################################################################
# Add MongoDB to the sources list and install it
RUN wget -qO - https://www.mongodb.org/static/pgp/server-7.0.asc | apt-key add - \
    && echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/debian buster/mongodb-org/7.0 main" | tee /etc/apt/sources.list.d/mongodb-org-7.0.list \
    && apt-get update \
    && apt-get install -y mongodb-org

# Create MongoDB data directory
RUN mkdir -p /data/db

#####################################################################################################################
# Doing NGINX/Openresty Stuff

RUN wget -qO - https://openresty.org/package/pubkey.gpg | apt-key add -
RUN echo "deb http://openresty.org/package/debian buster openresty" | tee /etc/apt/sources.list.d/openresty.list

RUN apt-get update && apt-get install -y openresty
RUN apt-get update && apt-get install -y libbson-dev libmongoc-dev lua5.1-dev


# Install lua-resty-http and other Lua modules
RUN luarocks install lua-resty-http \
    && luarocks install lua-resty-string \
    && luarocks install lua-resty-core \
    && luarocks install lua-resty-lrucache \
    && luarocks install lua-cjson \
    && luarocks install luasocket \
    && luarocks install lua-resty-openssl 
# && luarocks install lua-mongo 


RUN wget https://luarocks.org/manifests/neoxic/lua-mongo-1.2.3-2.src.rock
RUN luarocks unpack lua-mongo-1.2.3-2.src.rock

# Combine the steps to ensure the correct directory is used
RUN cd lua-mongo-1.2.3-2/lua-mongo/src && \
    gcc -I/usr/include/lua5.1 -I/usr/include/libbson-1.0 -I/usr/include/libmongoc-1.0 -L/usr/lib/x86_64-linux-gnu -lbson-1.0 -lmongoc-1.0 -llua5.1 -shared -o mongo.so *.c && \
    cp mongo.so /usr/local/lib/lua/5.1/

#####################################################################################################################
# Install Node.js and npm

RUN curl -fsSL https://nodejs.org/dist/v20.5.1/node-v20.5.1-linux-x64.tar.xz | tar -xJ -C /usr/local --strip-components=1 \
    && npm install -g npm@9.8.0 nodemon eslint prettier



#####################################################################################################################
# Initialize and update submodules
# Initialize the Git repository
RUN git submodule update --init --recursive --remote

#####################################################################################################################

# Install Node.js dependencies for each submodule
RUN npm install --prefix ./sera-frontend
# Download the node_modules.tar.gz and extract it into each submodule
RUN wget https://github.com/Sera-ai/k8s-Artifacts/releases/download/v1.0.0/node_modules.tar.gz -O /tmp/node_modules.tar.gz \
    && mkdir -p /shared-node-modules \
    && tar -xzf /tmp/node_modules.tar.gz -C /shared-node-modules \
    && ln -s /shared-node-modules /workspace/sera-backend-core/node_modules \
    && ln -s /shared-node-modules /workspace/sera-backend-processor/node_modules \
    && ln -s /shared-node-modules /workspace/sera-backend-sequencer/node_modules \
    && ln -s /shared-node-modules /workspace/sera-backend-socket/node_modules

RUN sed -i -e "s|const mime = require('mime');|let mime;\n(async () => {\n  mime = await import('/shared-node-modules/mime/dist/src/index.js');\n  // Use mime as needed in this block or make it available elsewhere\n})();|" \
    -e "s|const flat\$1 = require('flat');|let flat\$1;\n(async () => {\n  flat\$1 = await import('/shared-node-modules/flat/index.js');\n  // Use flat\$1 as needed in this block or make it available elsewhere\n})();|" \
    /shared-node-modules/@lykmapipo/common/lib/index.js

#####################################################################################################################

# Install etcd
RUN curl -L https://github.com/etcd-io/etcd/releases/download/v3.5.14/etcd-v3.5.14-linux-amd64.tar.gz -o /tmp/etcd-linux-amd64.tar.gz
RUN tar -xzvf /tmp/etcd-linux-amd64.tar.gz -C /tmp
RUN rm /tmp/etcd-linux-amd64.tar.gz
RUN mv /tmp/etcd-v3.5.14-linux-amd64/etcd /usr/local/bin/ \
    && mv /tmp/etcd-v3.5.14-linux-amd64/etcdctl /usr/local/bin/

#####################################################################################################################

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

#####################################################################################################################

# Copy the Nginx configuration template and Lua scripts
RUN ln -s  /workspace/sera-artifacts/sera-nginx /etc/nginx/lua-scripts
RUN ln -s  /workspace/sera-artifacts/sera-nginx /workspace/sera-backend-sequencer/src/lua-scripts

RUN mkdir /workspace/sera-backend-sequencer/src/event-scripts
RUN ln -s  /workspace/sera-backend-sequencer/src/event-scripts /workspace/sera-backend-processor/src/event-scripts

RUN rm -rf /etc/nginx/conf.d && ln -s /workspace/sera-nginx/conf.d /etc/nginx/conf.d
RUN ln -s /etc/nginx /workspace/nginx-config
# Create symbolic links to the models directory in each /src folder
RUN mkdir -p /workspace/sera-backend-core/src/models/
RUN mkdir -p /workspace/sera-backend-socket/src/models/
RUN mkdir -p /workspace/sera-backend-sequencer/src/models/
RUN mkdir -p /workspace/sera-backend-processor/src/models/

RUN cp -r /workspace/sera-artifacts/sera-mongodb/* /workspace/sera-backend-core/src/models/
RUN cp -r /workspace/sera-artifacts/sera-mongodb/* /workspace/sera-backend-socket/src/models/
RUN cp -r /workspace/sera-artifacts/sera-mongodb/* /workspace/sera-backend-sequencer/src/models/
RUN cp -r /workspace/sera-artifacts/sera-mongodb/* /workspace/sera-backend-processor/src/models/

#####################################################################################################################

# Expose ports
EXPOSE 80 443 5173 9876 12000 12030 12040 12050 27017

#####################################################################################################################

#set env vars that are usually set in devcontainer
ENV DOMAIN_NAME "example.sera"
ENV FE_CATALOG_PORT "5173"
ENV BE_ROUTER_PORT "12000"
ENV BE_BUILDER_PORT "12030"
ENV BE_SOCKET_PORT "12040"
ENV BE_SEQUENCER_PORT "12050"
ENV BE_PROCESSOR_PORT "12060"
ENV DB_HOST "mongodb://localhost:27017"
ENV NODE_PATH=/shared-node-modules

#####################################################################################################################

# Convert CRLF to LF using sed
RUN sed -i 's/\r$//' /workspace/.devcontainer/entrypoint.sh
RUN sed -i 's/\r$//' /workspace/.devcontainer/docker-entrypoint.sh
RUN sed -i 's/\r$//' /workspace/sera-mongodb/entrypoint.sh
RUN sed -i 's/\r$//' /workspace/sera-nginx/entrypoint.sh

RUN chmod +x /workspace/.devcontainer/entrypoint.sh /workspace/.devcontainer/docker-entrypoint.sh /workspace/sera-mongodb/entrypoint.sh /workspace/sera-nginx/entrypoint.sh

#####################################################################################################################

# Single Container Run Settings
ENTRYPOINT ["/bin/sh", "-c", "/workspace/.devcontainer/entrypoint.sh && /workspace/.devcontainer/docker-entrypoint.sh"]
