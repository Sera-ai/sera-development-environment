FROM debian:buster-slim

# Install necessary packages
RUN apt-get update \
    && apt-get install -y gnupg wget curl xz-utils

# Install Node.js and npm
RUN curl -fsSL https://nodejs.org/dist/v20.5.1/node-v20.5.1-linux-x64.tar.xz -o node.tar.xz \
    && tar -xJf node.tar.xz -C /usr/local --strip-components=1 \
    && rm node.tar.xz \
    && npm install -g npm@9.8.0

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && chmod +x ./kubectl \
    && mv ./kubectl /usr/local/bin/kubectl

# Create a non-root user
RUN useradd -m vscode -s /bin/bash

# Set the working directory
WORKDIR /workspace

# Copy the project files
COPY . .

# Switch to the non-root user
USER root
