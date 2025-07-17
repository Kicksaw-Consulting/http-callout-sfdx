FROM mcr.microsoft.com/vscode/devcontainers/python:3.12

SHELL ["/bin/bash", "-c"]

# Update package lists first
RUN apt-get update



# Install node and npm
RUN apt install -y ca-certificates gnupg && \
  mkdir -p /etc/apt/keyrings && \
  curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
  NODE_MAJOR=20 && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list && \
  apt update && \
  apt install -y nodejs && \
  rm -rf /var/lib/apt/lists/*
RUN npm install -g npm@latest

# Install Salesforce CLI (sf v2)
RUN npm install -g @salesforce/cli

# Verify installation
RUN sf --version

# Install prettier
RUN npm install -g prettier




# Install vim (fixed: update package lists first)
RUN apt-get update && \
  apt-get install -y vim && \
  rm -rf /var/lib/apt/lists/*

RUN apt-get update && \
  apt-get install -y ca-certificates curl gnupg && \
  install -m 0755 -d /etc/apt/keyrings && \
  curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
  chmod a+r /etc/apt/keyrings/docker.gpg && \
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
  apt-get update && \
  apt-get install -y docker-ce-cli docker-buildx-plugin docker-compose-plugin && \
  rm -rf /var/lib/apt/lists/*

ENV UV_LINK_MODE=copy