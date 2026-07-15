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
  dnsutils mtr iputils-ping ncat \
  podman podman-compose slirp4netns fuse-overlayfs uidmap \
  shellcheck shfmt \
  qrencode \
  jq \
  bash-completion \
  rsync \
  ssh \
  libfido2-1 \
  sudo \
  lsb-release \
  python3 python3-pip python3-venv build-essential

# NodeJS 24
curl -fsSL https://deb.nodesource.com/setup_24.x | bash -
apt-get install -y --no-install-recommends nodejs

# npm global tools
npm install -g prettier

# Install latest kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
curl -LO "https://dl.k8s.io/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl kubectl.sha256

# Install latest Helm
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install latest stable Neovim
NVIM_TAG=$(curl -fsSL "https://api.github.com/repos/neovim/neovim/releases/latest" | grep '"tag_name"' | head -1 | sed 's/.*"tag_name": "\(.*\)".*/\1/')
curl -fsSL "https://github.com/neovim/neovim/releases/download/${NVIM_TAG}/nvim-linux-x86_64.tar.gz" -o /tmp/nvim.tar.gz
tar -xzf /tmp/nvim.tar.gz -C /tmp
cp -r /tmp/nvim-linux-x86_64/* /usr/local/
rm -rf /tmp/nvim.tar.gz /tmp/nvim-linux-x86_64

# cleanup to reduce image size
apt-get clean
rm -rf /var/lib/apt/lists/*
