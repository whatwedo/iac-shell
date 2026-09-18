#!/usr/bin/env bash
set -euo pipefail

# Install OS packages, node, podman CLI and npm tools.
apt-get update

DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  ca-certificates \
  curl wget \
  less \
  gnupg \
  git git-lfs \
  dnsutils mtr iputils-ping ncat iproute2 \
  podman podman-compose slirp4netns fuse-overlayfs uidmap \
  shellcheck shfmt \
  qrencode \
  jq \
  bash-completion \
  rsync \
  borgbackup \
  ssh \
  libfido2-1 \
  sudo \
  lsb-release \
  python3 python3-pip python3-venv build-essential

install -m 0755 -d /etc/apt/keyrings

# NodeJS 24 — the NodeSource apt repo is registered by hand rather than by
# piping their setup script into a root shell. apt then verifies every package
# against the repo signing key below.
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
  -o /etc/apt/keyrings/nodesource.asc
chmod a+r /etc/apt/keyrings/nodesource.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/nodesource.asc] \
  https://deb.nodesource.com/node_24.x nodistro main" \
  >/etc/apt/sources.list.d/nodesource.list
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends nodejs

# Docker CLI — a thin client that talks to the host's podman through the
# forwarded, Docker-API-compatible socket (DOCKER_HOST is set in the
# Containerfile), the same way podman uses CONTAINER_HOST. No daemon runs here.
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
  https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  >/etc/apt/sources.list.d/docker.list
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  docker-ce-cli docker-compose-plugin

# 1Password CLI — reads secrets; authenticated by OP_SERVICE_ACCOUNT_TOKEN, which
# iac() passes in. The repo is keyed on architecture, not on the Debian codename.
curl -fsSL https://downloads.1password.com/linux/keys/1password.asc \
  | gpg --dearmor -o /etc/apt/keyrings/1password.gpg
chmod a+r /etc/apt/keyrings/1password.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/1password.gpg] \
  https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" \
  >/etc/apt/sources.list.d/1password.list
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends 1password-cli

# npm global tools
npm install -g prettier

# Install latest kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
curl -LO "https://dl.k8s.io/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl kubectl.sha256

# Install latest stable Neovim
NVIM_TAG=$(curl -fsSL "https://api.github.com/repos/neovim/neovim/releases/latest" | grep '"tag_name"' | head -1 | sed 's/.*"tag_name": "\(.*\)".*/\1/')
curl -fsSL "https://github.com/neovim/neovim/releases/download/${NVIM_TAG}/nvim-linux-x86_64.tar.gz" -o /tmp/nvim.tar.gz
tar -xzf /tmp/nvim.tar.gz -C /tmp
cp -r /tmp/nvim-linux-x86_64/* /usr/local/
rm -rf /tmp/nvim.tar.gz /tmp/nvim-linux-x86_64

# cleanup to reduce image size
apt-get clean
rm -rf /var/lib/apt/lists/*
