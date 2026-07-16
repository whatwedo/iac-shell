FROM debian:13

ENV HOME=/home/wwd-admin
ARG USER_ID=1000
ENV ANSIBLE_NO_LOG=false
ENV USER=wwd-admin
ENV USER_ID=${USER_ID}

# Copy helper scripts and make executable
COPY ./container/scripts /tmp/container-scripts
RUN chmod -R +x /tmp/container-scripts

# Install packages and tools via script
RUN /tmp/container-scripts/install-packages.sh

# Create user and workspace
RUN useradd -u ${USER_ID} -m -s /bin/bash wwd-admin \
  && echo "wwd-admin ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers \
  && mkdir -p $HOME/.history \
  && chown -R wwd-admin:wwd-admin $HOME
RUN mkdir /opt/python-venv \
  && chown wwd-admin:wwd-admin /opt/python-venv

# Configure bash prompt and aliases via script
RUN /tmp/container-scripts/setup-shell.sh
ENV PATH="/opt/python-venv/bin:$PATH"
# we're using hosts podman, so redirect the socket
ENV CONTAINER_HOST=unix:///var/run/user/1000/podman/podman.sock
# the docker CLI is a thin client of that same forwarded socket: podman serves a
# Docker-API-compatible endpoint on it, so `docker ...` drives the host's podman
# just like `podman ...` does. No daemon runs inside this container.
ENV DOCKER_HOST=unix:///var/run/user/1000/podman/podman.sock
# also expose it at the conventional path for tools that hardcode the socket
# (e.g. testinfra/testcontainers, molecule's docker driver)
RUN ln -s /var/run/user/1000/podman/podman.sock /var/run/docker.sock

COPY ./container/scripts/bin /opt/iac-shell/bin
ENV PATH="/opt/iac-shell/bin:$PATH"

WORKDIR $HOME
USER wwd-admin

RUN /tmp/container-scripts/install-ansible.sh

HEALTHCHECK CMD [ "ls", "/" ]
