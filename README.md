# whatwedo iac-shell

shell in a container with tools for managing our infrastructure:

- ansible
- molecule (ansible testing)
- borg (inspect and restore from our remote backups)
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

### Backups (borg)

`borg` reaches the repositories over SSH, with the same keys as everything else,
so the shell can inspect and restore from a backup without touching the host that
made it. Point it at a repo:

```sh
export BORG_REPO='ssh://borg@backup.example.com/./repos/myhost'
export BORG_PASSCOMMAND='/usr/bin/op read op://Infra/borg-myhost/password'
export BORG_RSH='ssh -o IdentitiesOnly=yes -i ~/.ssh/iac.pub'
```

> `BORG_PASSCOMMAND` runs without a shell, so use an absolute path and no `~` or
> pipes. `BORG_PASSPHRASE`, if set, silently wins over it.

With `BORG_REPO` set, `::` means the repo and `::name` one archive in it:

```sh
borg list                       # every archive, oldest first — so the last line is the newest
borg info ::                    # repo totals: original / compressed / deduplicated size
borg info ::myhost-2026-09-18   # one archive: when it ran, how long it took, what it cost
borg list ::myhost-2026-09-18   # the files in it
borg check --repository-only    # verify repo consistency without reading all the data
```

Restore by extracting. Borg writes paths relative to the working directory, so
`cd` somewhere scratch first — never into `/` or the repo you are working on:

```sh
mkdir -p /tmp/restore && cd /tmp/restore
borg extract --dry-run --list ::myhost-2026-09-18 var/lib/something   # what would land
borg extract ::myhost-2026-09-18 var/lib/something
```

`/tmp` is a tmpfs, so a restore staged there disappears with the container. Extract
under `/workspace` instead when you need to keep it.

`borg mount` is **not** available: it needs FUSE, which would mean handing the
container `/dev/fuse` and `SYS_ADMIN`. Use `borg extract` instead.

The image carries Debian 13's borg (1.4.x), which speaks to any borg 1.x
`borg serve`. A repository created by borg 2 cannot be read by it.

### SSH keys

Keys stored in 1Password are used by default; the host's agent socket is mounted in
and applied to every host via `/etc/ssh/ssh_config.d/10-1password.conf`. Approval
prompts appear on the host.

The YubiKey still works alongside it, on the shell's own agent:

```sh
ssh-add -K          # load resident FIDO2 keys from the token
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
