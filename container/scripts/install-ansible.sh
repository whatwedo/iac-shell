#!/usr/bin/env bash
set -euo pipefail

python3 -m venv /opt/python-venv
pip install --no-cache-dir --upgrade pip==26.0.1 \
  molecule==26.3.0 \
  ansible==13.4.0 \
  kubernetes==35.0.0 \
  pytest \
  testinfra \
  yamllint \
  "molecule-plugins[podman]==25.8.12"
