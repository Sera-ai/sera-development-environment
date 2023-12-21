FROM node:18-slim

WORKDIR /workspace

# Install Git and MongoDB tools
RUN apt-get update && apt-get install -y git mongodb

# Copy the entire repository context
COPY . .

# Initialize and update submodules
RUN git submodule update --init --recursive

# Start MongoDB and import the backup
RUN service mongodb start \
    && mongorestore /workspace/sera-db-mongo
    
# Install global packages & tools
RUN npm install -g nodemon eslint prettier

# Install dependencies in each submodule
RUN npm install --prefix ./fe_Builder \
    && npm install --prefix ./fe_Catalog \
    && npm install --prefix ./be_Builder \
    && npm install --prefix ./be_Socket \
    && npm install --prefix ./be_Router \
    && npm install --prefix ./be_Sequencer

# Clean up the apt cache by removing /var/lib/apt/lists
RUN rm -rf /var/lib/apt/lists/*

ENV NODE_ENV=development

EXPOSE 12020 12010 12030 12040 12000 12050 27017
