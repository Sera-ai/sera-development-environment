
# Sera Development Environment
![DevContainer](https://img.shields.io/badge/DevContainer-Ready-blue?logo=visual-studio-code)  ![CodeSpaces](https://img.shields.io/badge/GitHub-CodeSpaces-blue?logo=github)

## Overview

Welcome to the **Sera Dev Environment** repository. This project is designed to provide an efficient development environment using DevContainers and GitHub CodeSpaces. The repository includes git submodules for modular code management and a `Dockerfile`/`.devcontainer.json` to build the development environment with a single click.

## Table of Contents

  - [Features](#features)
  - [Getting Started](#getting-started)
    - [Prerequisites](#prerequisites)
    - [Setup](#setup)
    - [Using DevContainers](#using-devcontainers)
    - [Using GitHub CodeSpaces](#using-github-codespaces)
  - [Project Structure](#project-structure)
  - [Contributing](#contributing)
  - [License](#license)

## Features

- One-click setup for development environment
- Integration with VS Code DevContainers and GitHub CodeSpaces
- Modular code management using git submodules
- Pre-configured Docker environment
- Seamless development experience

## Getting Started

### Prerequisites

Ensure you have the following installed:

- [Docker](https://www.docker.com/get-started)
- [Visual Studio Code](https://code.visualstudio.com/)
- [Dev Containers Extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
- [Git](https://git-scm.com/)

### Setup

1. **Clone the repository**:
    ```sh
    git clone --recurse-submodules https://github.com/Sera-ai/sera-development-environment.git
    cd sera-development-environment
    ```

2. **Initialize submodules**:
    ```sh
    git submodule update --init --recursive
    ```

3. **Open in VS Code**:
    ```sh
    code .
    ```

### Using DevContainers

1. Open the project in VS Code.
2. You should see a popup asking if you want to reopen the project in a container. Click "Reopen in Container".
3. VS Code will build the container using the provided `Dockerfile`/`.devcontainer.json` and open the project inside the container.

### Using GitHub CodeSpaces

1. Navigate to the sera-development-environment repository on GitHub.
2. Click the green "Code" button and select "Open with Codespaces".
3. GitHub will create a new codespace and set up the development environment as defined in the repository.

## Project Structure

    sera-development-environment/
    ├── .devcontainer/
    │ ├── devcontainer.json
    │ └── Dockerfile
    ├── sera-artifacts/
    ├── sera-backend-core/
    ├── sera-backend-processor/
    ├── sera-backend-sequencer/
    ├── sera-backend-socket/
    ├── sera-frontend/
    ├── sera-mongodb/
    ├── sera-nginx/
    ├── .gitmodules
    └── README.md

## Contributing

We welcome contributions! Please read our [Contributing Guide](CONTRIBUTING.md) to learn how you can help.
