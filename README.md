# whatwedo iac-shell

shell in a container with tools for managing our infrastructure:

- ansible
- molecule (ansible testing)
- prettier, yamllint, ...

## Requirements

- podman

## Setup

Clone the repository, then source `source.sh` from your local clone:

```sh
git clone https://github.com/whatwedo/iac-shell.git ~/git/whatwedo/iac-shell.git
source ~/git/whatwedo/iac-shell.git/source.sh
```

Any path works — `~/git/whatwedo/iac-shell.git` as an example

To get the `iac` command in every shell, add the `source` line to your
`~/.bashrc`:

```sh
echo 'source ~/git/whatwedo/iac-shell.git/source.sh' >> ~/.bashrc
```

Keep it up to date with:

```sh
git -C ~/git/whatwedo/iac-shell.git pull
```

## Usage

`iac` opens the shell. Your current directory is mounted at `/workspace` inside
it, so run it from the repository you want to work on:

```sh
cd ~/git/whatwedo/some-infra-repo
iac
```

Pass `--pull` to fetch the latest image before starting:

```sh
iac --pull
```

Arguments after `--` are passed straight through to `podman run`.

## Tools

### Containers (podman / docker)

The host's rootless podman socket is forwarded into the container, so both the
`podman` and `docker` CLIs work inside the shell — they are thin clients driving
the **host's** podman (which serves a Docker-API-compatible endpoint on the same
socket). Nothing runs a container engine daemon inside the shell.

```sh
podman ps          # host podman
docker ps          # same host podman, via the Docker API
docker compose up  # docker-compose-plugin is installed
```

`DOCKER_HOST` / `CONTAINER_HOST` both point at the forwarded socket, and it is
also symlinked to `/var/run/docker.sock` for tools that hardcode that path.

### Helper Commands

**go**: does `ssh` and `sudo su -` in one single command, usage: `go my-server`

## Open Source ❤️

<p align="left">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset=".assets/whatwedo-logo-white.svg">
    <source media="(prefers-color-scheme: light)" srcset=".assets/whatwedo-logo-black.svg">
    <img alt="whatwedo" src=".assets/whatwedo-logo-black.svg" width="280">
  </picture>
</p>

We love [whatwedo](https://whatwedo.ch) — a software studio in Bern, Switzerland,
fighting the good fight against bad software. But here's the thing: we also love
**open source**.

Curious what else we've been building in the open? → **[github.com/whatwedo](https://github.com/whatwedo)**
