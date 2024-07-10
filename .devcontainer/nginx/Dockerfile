# Stage 1: Install MongoDB in a separate stage
FROM debian:buster-slim
USER root

# Install required dependencies and development packages
RUN apt-get update \
    && apt-get install -y gnupg wget curl xz-utils nginx-extras openssl git libcurl4 gettext luarocks luajit software-properties-common moreutils build-essential

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


# Set working directory for the Node app
WORKDIR /workspace

RUN mkdir /workspace/.logs

# Copy the application's source code
COPY . .
COPY nginx.conf /etc/nginx/nginx.conf
RUN rm -rf /etc/nginx/conf.d
COPY conf.d /etc/nginx/conf.d

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


# Expose ports
EXPOSE 80 443 12010 12030 12040 12000 12050

ENTRYPOINT ["/workspace/entrypoint.sh"]