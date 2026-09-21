#!/usr/bin/env bash
set -euo pipefail

# Every package is pinned to an exact version. An unpinned name here does not
# mean "current" — it means "whatever PyPI served during that build", which is
# how two images built a few days apart ended up with different test tooling.
#
# `testinfra` used to be in this list unpinned. It is a transitional shim that
# has not been released since 6.0.0 and whose only job is to pull in
# pytest-testinfra — unpinned. We depend on the real package directly.
python3 -m venv /opt/python-venv
pip install --no-cache-dir --upgrade pip==26.0.1 \
  molecule==26.3.0 \
  ansible==13.4.0 \
  kubernetes==35.0.0 \
  pytest==9.1.1 \
  pytest-testinfra==10.2.2 \
  yamllint==1.38.0 \
  "molecule-plugins[podman]==25.8.12"
