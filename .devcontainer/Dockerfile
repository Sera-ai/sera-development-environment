# Stage 1: Install MongoDB in a separate stage
FROM debian:buster-slim as mongodb

# Add MongoDB to the sources list and install it
RUN apt-get update \
    && apt-get install -y gnupg wget \
    && wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc | apt-key add - \
    && echo "deb http://repo.mongodb.org/apt/debian buster/mongodb-org/4.2 main" | tee /etc/apt/sources.list.d/mongodb-org-4.2.list \
    && apt-get update \
    && apt-get install -y mongodb-org

# Install Node.js
# Replace "setup_14.x" with "setup_18.x" for Node.js 18 or the version you need
RUN curl -sL https://deb.nodesource.com/setup_14.x | bash - \
    && apt-get install -y nodejs npm

# Create the MongoDB data directory
RUN mkdir -p /data/db

# Set the working directory for the Node app
WORKDIR /workspace

RUN apt-get update && apt-get install -y git libcurl4

# Copy the rest of the application's source code
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

CMD ["./entrypoint.sh"]
