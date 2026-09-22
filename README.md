# whatwedo iac-shell

shell in a container with tools for managing our infrastructure:

- ansible
- molecule (ansible testing)
- prettier, yamllint, ...

## Requirements

- podman
- the [1Password desktop app](https://1password.com/downloads) and the
  [1Password CLI](https://developer.1password.com/docs/cli/get-started/) on the host

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

### 1Password

The shell gets both its SSH keys and its secrets from 1Password, so `iac` refuses
to start until it is set up.

In the 1Password app, enable Settings > Developer > **Use the SSH agent**. Set
_Ask approval for each new_ to **application**, so a playbook across many hosts
asks once rather than per host.

Secrets come from a service account:

1. Create a vault (`Infra` in the examples below) for the shared secrets. Service
   accounts **cannot** read Private, Personal, Employee or the default Shared vault.
2. Create a service account with `read_items` on it. Vault permissions are fixed
   at creation.
3. Save its token to your own vault, e.g. `op://Private/iac-shell-sa/credential`.

`iac` reads that token at launch and passes it in, so nothing is stored on disk.
Override the reference with `IAC_OP_SERVICE_ACCOUNT_REF`.

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

### Secrets (1Password)

`op` is authenticated inside the shell:

```sh
op read op://Infra/some-item/password
op run --env-file=.env.tpl -- ./some-script
```

In playbooks, look secrets up from 1Password:

```yaml
- name: Fetch the secrets this play needs, once
  ansible.builtin.set_fact:
    pihole_password: "{{ lookup('community.general.onepassword', 'pihole', field='password', vault='Infra') }}"
  run_once: true
  no_log: true
```

> Read values once into facts, as above. Every lookup shells out to `op` and counts
> against the service account's rate limit.

For borg, in the infra repo:

```sh
export BORG_PASSCOMMAND='/usr/bin/op read op://Infra/borg-myhost/password'
export BORG_RSH='ssh -o IdentitiesOnly=yes -i ~/.ssh/iac.pub'
```

> `BORG_PASSCOMMAND` runs without a shell, so use an absolute path and no `~` or
> pipes. `BORG_PASSPHRASE`, if set, silently wins over it.

### SSH keys

Keys stored in 1Password are used by default; the host's agent socket is mounted in
and applied to every host via `/etc/ssh/ssh_config.d/10-1password.conf`. Approval
prompts appear on the host.

A key added by hand lands in the shell's own agent, which that `IdentityAgent`
shadows. Point a host back at it explicitly:

```sh
ssh-add ~/.ssh/some-key
ssh -o IdentityAgent=SSH_AUTH_SOCK my-server
```

To make that the default for a host, add to `~/.ssh/config`:

```sshconfig
Host legacy-box
  IdentityAgent SSH_AUTH_SOCK
```

On `Too many authentication failures`, the agent is offering more keys than the
server's `MaxAuthTries` allows. Pin one:

```sshconfig
Host *
  IdentityFile ~/.ssh/iac.pub    # the PUBLIC key
  IdentitiesOnly yes
```

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
