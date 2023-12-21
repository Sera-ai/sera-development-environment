# Start from the Node.js 18 (or any version you prefer) slim image
FROM node:18-slim

# Set environment variables for MongoDB
ENV MONGO_DB_VERSION 5.0

# Add MongoDB to the sources list
RUN apt-get update && apt-get install -y wget gnupg \
    && wget -qO - https://www.mongodb.org/static/pgp/server-${MONGO_DB_VERSION}.asc | apt-key add - \
    && echo "deb http://repo.mongodb.org/apt/debian buster/mongodb-org/${MONGO_DB_VERSION} main" | tee /etc/apt/sources.list.d/mongodb-org-${MONGO_DB_VERSION}.list

# Install MongoDB
RUN apt-get update \
    && apt-get install -y mongodb-org \
    && rm -rf /var/lib/apt/lists/*

# Create the MongoDB data directory
RUN mkdir -p /data/db

WORKDIR /workspace

# Copy the entire repository context
COPY . .

# Initialize and update submodules
RUN git submodule update --init --recursive

# Install global packages & tools
RUN npm install -g nodemon eslint prettier

# Install dependencies in each submodule
RUN npm install --prefix ./fe_Builder && (npm --prefix ./fe_Builder run dev &) \
    && npm install --prefix ./fe_Catalog && (npm --prefix ./fe_Catalog run dev &) \
    && npm install --prefix ./be_Builder && (npm --prefix ./be_Builder run dev &) \
    && npm install --prefix ./be_Socket && (npm --prefix ./be_Socket run dev &) \
    && npm install --prefix ./be_Router && (npm --prefix ./be_Router run dev &) \
    && npm install --prefix ./be_Sequencer && (npm --prefix ./be_Sequencer run dev &)

# Clean up the apt cache by removing /var/lib/apt/lists
RUN rm -rf /var/lib/apt/lists/*

ENV NODE_ENV=development

EXPOSE 12020 12010 12030 12040 12000 12050
