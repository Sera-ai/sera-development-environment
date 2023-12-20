# Use the official Node.js 16 image as a parent image
FROM node:18-slim

# Install git
RUN apt-get update && apt-get install -y git

# Set the working directory to /workspace
WORKDIR /workspace

RUN find / -mindepth 2 -maxdepth 2 -type d
# Now that git is installed, you can use it to update submodules
RUN git submodule update --init --recursive

# Copy package.json and package-lock.json for all submodules
COPY fe_Builder/package*.json ./fe_Builder/
COPY fe_Catalog/package*.json ./fe_Catalog/
COPY be_Builder/package*.json ./be_Builder/
COPY be_Socket/package*.json ./be_Socket/
COPY be_Router/package*.json ./be_Router/
COPY be_Sequencer/package*.json ./be_Sequencer/

# Install dependencies in each submodule
RUN cd fe_Builder && npm install && cd ..
RUN cd fe_Catalog && npm install && cd ..
RUN cd be_Builder && npm install && cd ..
RUN cd be_Socket && npm install && cd ..
RUN cd be_Router && npm install && cd ..
RUN cd be_Sequencer && npm install && cd ..

# Install global packages & tools
RUN npm install -g nodemon eslint prettier

# Install MongoDB tools
RUN apt-get update && apt-get install -y mongodb-clients

# Clean up the apt cache by removing /var/lib/apt/lists
RUN rm -rf /var/lib/apt/lists/*

# Set up environment variables
ENV NODE_ENV=development

# Expose ports (the numbers should match the ones used by your applications)
EXPOSE 12020 12010 12030 12040 12000 12050 27017

# Use nodemon to start the application by default
CMD ["nodemon", "index.js"]
