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
RUN npm install --prefix ./fe_Builder && npm --prefix ./fe_Builder run dev & \
    && npm install --prefix ./fe_Catalog && npm --prefix ./fe_Catalog run dev & \
    && npm install --prefix ./be_Builder && cd npm --prefix ./be_Builder run dev & \
    && npm install --prefix ./be_Socket && cd npm --prefix ./be_Socket run dev & \
    && npm install --prefix ./be_Router && cd npm --prefix ./be_Router run dev & \
    && npm install --prefix ./be_Sequencer && npm --prefix ./be_Sequencer run dev &

# Clean up the apt cache by removing /var/lib/apt/lists
RUN rm -rf /var/lib/apt/lists/*

ENV NODE_ENV=development

EXPOSE 12020 12010 12030 12040 12000 12050
