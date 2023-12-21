FROM node:18-slim

WORKDIR /workspace

# Install Git and MongoDB tools
RUN apt-get update && apt-get install -y git

# Copy the entire repository context
COPY . .

# Initialize and update submodules
RUN git submodule update --init --recursive

# Install dependencies in each submodule
RUN npm install --prefix ./fe_Builder \
    && npm install --prefix ./fe_Catalog \
    && npm install --prefix ./be_Builder \
    && npm install --prefix ./be_Socket \
    && npm install --prefix ./be_Router \
    && npm install --prefix ./be_Sequencer

# Install global packages & tools
RUN npm install -g nodemon eslint prettier

# Clean up the apt cache by removing /var/lib/apt/lists
RUN rm -rf /var/lib/apt/lists/*

ENV NODE_ENV=development

EXPOSE 12020 12010 12030 12040 12000 12050 27017
