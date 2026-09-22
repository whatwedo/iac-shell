#!/usr/bin/env bash
set -euo pipefail

# Versions of everything we fetch from outside Debian. Every one of these is an
# exact version on purpose: with them floating, two builds of the same commit
# produced different shells, and there was no way to say which tools a given
# image held. Bump them here, in a commit, so the change is reviewable.
NODE_MAJOR=24
PRETTIER_VERSION=3.9.8
NVIM_VERSION=v0.12.5
# sha256 of nvim-linux-x86_64.tar.gz at that tag. A release asset can be
# replaced; the checksum is what actually pins the bytes.
NVIM_SHA256=bce0f56eda1f1b1db6eee8f4133d7a38813ea07933837dd1777411ca384c6875

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
  ssh \
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
  https://deb.nodesource.com/node_${NODE_MAJOR}.x nodistro main" \
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
npm install -g "prettier@${PRETTIER_VERSION}"

# Neovim, at the pinned release rather than whatever "latest" resolves to today.
curl -fsSL "https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim-linux-x86_64.tar.gz" -o /tmp/nvim.tar.gz
echo "${NVIM_SHA256}  /tmp/nvim.tar.gz" | sha256sum -c -
tar -xzf /tmp/nvim.tar.gz -C /tmp
cp -r /tmp/nvim-linux-x86_64/* /usr/local/
rm -rf /tmp/nvim.tar.gz /tmp/nvim-linux-x86_64

# cleanup to reduce image size
apt-get clean
rm -rf /var/lib/apt/lists/*
