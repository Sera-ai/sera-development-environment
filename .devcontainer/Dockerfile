# Stage 1: Install MongoDB in a separate stage
FROM debian:buster-slim as mongodb

# Add MongoDB to the sources list and install it
RUN apt-get update \
    && apt-get install -y gnupg wget \
    && wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc | apt-key add - \
    && echo "deb http://repo.mongodb.org/apt/debian buster/mongodb-org/4.2 main" | tee /etc/apt/sources.list.d/mongodb-org-4.2.list \
    && apt-get update \
    && apt-get install -y mongodb-org

# Install dependencies
RUN apt-get update && apt-get install -y curl xz-utils openssl git libcurl4 nginx

# Download and install Node.js v20.5.1
RUN curl -fsSL https://nodejs.org/dist/v20.5.1/node-v20.5.1-linux-x64.tar.xz | tar -xJ -C /usr/local --strip-components=1

# Update npm to version 9.8.0
RUN npm install -g npm@9.8.0 nodemon eslint prettier

# Create the MongoDB data directory
RUN mkdir -p /data/db

# Set the working directory for the Node app
WORKDIR /workspace

# Copy the rest of the application's source code
COPY . .

# Initialize and update submodules
RUN git submodule update --init --recursive --remote

# Install dependencies in each submodule
RUN npm install --prefix ./fe_Catalog \
    && npm install --prefix ./be_Builder \
    && npm install --prefix ./be_Socket \
    && npm install --prefix ./be_Sequencer

# Clean up the apt cache by removing /var/lib/apt/lists
RUN rm -rf /var/lib/apt/lists/*

# Set environment variables for certificate generation
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

# Copy the Nginx configuration file from the parent folder
COPY ./nginx.conf /etc/nginx/nginx.conf

ENV NODE_ENV=development
ENV DB_HOST=mongodb+srv://sera-user:4048WWDfkhORZ0Qo@sera.kloehqy.mongodb.net

# Expose other ports for your application
EXPOSE 80 443 12010 12030 12040 12000 12050
