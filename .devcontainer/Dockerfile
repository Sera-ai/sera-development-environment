FROM node:18-slim

WORKDIR /workspace

# Install Git
RUN apt-get update && apt-get install -y git 

# Copy the entire repository context
COPY . .

# Initialize and update submodules
RUN git submodule update --init --recursive

# Install global packages & tools
RUN npm install -g nodemon eslint prettier

# Install dependencies in each submodule
RUN npm install --prefix ./fe_Builder && npm --prefix ./fe_Builder start dev \
    && npm install --prefix ./fe_Catalog && npm --prefix ./fe_Catalog start dev \
    && npm install --prefix ./be_Builder && cd ./be_Builder && nodemon index.js && cd ../ \
    && npm install --prefix ./be_Socket && cd ./be_Socket && nodemon index.js && cd ../ \
    && npm install --prefix ./be_Router && cd ./be_Router && nodemon index.js && cd ../ \
    && npm install --prefix ./be_Sequencer && cd ./be_Sequencer && nodemon index.js

# Clean up the apt cache by removing /var/lib/apt/lists
RUN rm -rf /var/lib/apt/lists/*

ENV NODE_ENV=development

EXPOSE 12020 12010 12030 12040 12000 12050
